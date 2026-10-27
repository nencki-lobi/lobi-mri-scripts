#!/usr/bin/env python
"""Generate an MRIQC-style group dashboard from subject JSON IQM files."""

from __future__ import annotations

import argparse
import csv
import html
import json
import math
import os
import re
from datetime import datetime, timezone
from io import StringIO
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from niworkflows.data import Loader
from sklearn.cluster import KMeans
from sklearn.impute import SimpleImputer
from sklearn.manifold import TSNE
from sklearn.metrics import silhouette_score
from sklearn.preprocessing import StandardScaler
from umap import UMAP

from mriqc import __version__ as mriqc_version
from mriqc.data.config import GroupTemplate


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate group.tsv, MRIQC boxplots, UMAP/t-SNE plots, and a compact HTML dashboard."
    )
    parser.add_argument("--input-dir", required=True, type=Path, help="Directory with sub-*.json QC files.")
    parser.add_argument("--output-dir", required=True, type=Path, help="Directory for generated outputs.")
    parser.add_argument("--random-state", default=42, type=int, help="Random seed for UMAP, t-SNE, and KMeans.")
    return parser.parse_args()


def natural_key(path: Path) -> list[object]:
    return [int(part) if part.isdigit() else part for part in re.split(r"(\d+)", path.stem)]


def numeric_scalar(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(float(value))


def atomic_paths(paths: list[Path]) -> dict[Path, Path]:
    tmp_paths = {path: path.with_name(f".{path.name}.tmp.{os.getpid()}") for path in paths}
    for tmp_path in tmp_paths.values():
        if tmp_path.exists():
            tmp_path.unlink()
    return tmp_paths


def replace_outputs(tmp_paths: dict[Path, Path]) -> None:
    stamp = datetime.now(tz=timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    for final_path, tmp_path in tmp_paths.items():
        if final_path.exists():
            backup_path = final_path.with_name(f"{final_path.name}.bak.{stamp}")
            if backup_path.exists():
                raise SystemExit(f"Backup path already exists: {backup_path}")
            final_path.rename(backup_path)
        os.replace(tmp_path, final_path)


def best_kmeans(features: np.ndarray, random_state: int) -> tuple[np.ndarray, int, float]:
    best_score = -np.inf
    best_labels = None
    best_k = 2

    for k in range(2, min(10, len(features) - 1) + 1):
        labels = KMeans(n_clusters=k, n_init=50, random_state=random_state).fit_predict(features)
        counts = np.bincount(labels)
        if counts.min() < 2:
            continue
        score = silhouette_score(features, labels)
        if score > best_score:
            best_score = float(score)
            best_labels = labels
            best_k = k

    if best_labels is None:
        best_labels = KMeans(n_clusters=2, n_init=50, random_state=random_state).fit_predict(features)
        best_score = float(silhouette_score(features, best_labels))

    return best_labels + 1, best_k, best_score


def scaled(values: np.ndarray, low: float, high: float, invert: bool = False) -> np.ndarray:
    vmin = float(np.min(values))
    vmax = float(np.max(values))
    if math.isclose(vmin, vmax):
        return np.full_like(values, (low + high) / 2, dtype=float)
    out = low + (values - vmin) * (high - low) / (vmax - vmin)
    return high - (out - low) if invert else out


def render_embedding_svg(
    names: pd.Series,
    clusters: np.ndarray,
    umap_xy: np.ndarray,
    tsne_xy: np.ndarray,
    palette: list[str],
) -> str:
    panel_width = 560
    panel_height = 420
    gap = 50
    margin = {"left": 58, "right": 18, "top": 44, "bottom": 56}
    width = panel_width * 2 + gap
    height = panel_height

    def panel(x_offset: int, xy: np.ndarray, title: str, xlabel: str, ylabel: str) -> str:
        x = scaled(xy[:, 0], margin["left"], panel_width - margin["right"])
        y = scaled(xy[:, 1], margin["top"], panel_height - margin["bottom"], invert=True)
        xmin, xmax = float(np.min(xy[:, 0])), float(np.max(xy[:, 0]))
        ymin, ymax = float(np.min(xy[:, 1])), float(np.max(xy[:, 1]))
        parts = [
            f'<g transform="translate({x_offset},0)">',
            f'<text x="{panel_width / 2:.1f}" y="24" text-anchor="middle" class="plot-title">{html.escape(title)}</text>',
            f'<line x1="{margin["left"]}" y1="{panel_height - margin["bottom"]}" x2="{panel_width - margin["right"]}" y2="{panel_height - margin["bottom"]}" class="axis"/>',
            f'<line x1="{margin["left"]}" y1="{margin["top"]}" x2="{margin["left"]}" y2="{panel_height - margin["bottom"]}" class="axis"/>',
            f'<text x="{panel_width / 2:.1f}" y="{panel_height - 14}" text-anchor="middle" class="axis-label">{html.escape(xlabel)}</text>',
            f'<text x="18" y="{panel_height / 2:.1f}" transform="rotate(-90 18 {panel_height / 2:.1f})" text-anchor="middle" class="axis-label">{html.escape(ylabel)}</text>',
            f'<text x="{margin["left"]}" y="{panel_height - margin["bottom"] + 22}" text-anchor="middle" class="tick">{xmin:.2f}</text>',
            f'<text x="{panel_width - margin["right"]}" y="{panel_height - margin["bottom"] + 22}" text-anchor="middle" class="tick">{xmax:.2f}</text>',
            f'<text x="{margin["left"] - 8}" y="{panel_height - margin["bottom"] + 4}" text-anchor="end" class="tick">{ymin:.2f}</text>',
            f'<text x="{margin["left"] - 8}" y="{margin["top"] + 4}" text-anchor="end" class="tick">{ymax:.2f}</text>',
        ]
        for name, cluster, xpos, ypos, raw_x, raw_y in zip(
            names.astype(str), clusters, x, y, xy[:, 0], xy[:, 1], strict=True
        ):
            color = palette[(int(cluster) - 1) % len(palette)]
            tooltip = (
                f"Subject: {html.escape(str(name))}<br>"
                f"Cluster: C{int(cluster)}<br>"
                f"{html.escape(xlabel)}: {raw_x:.4f}<br>"
                f"{html.escape(ylabel)}: {raw_y:.4f}"
            )
            parts.append(
                f'<circle class="embedding-point" cx="{xpos:.2f}" cy="{ypos:.2f}" r="5.5" '
                f'fill="{color}" tabindex="0" data-tooltip="{html.escape(tooltip, quote=True)}"></circle>'
            )
        parts.append("</g>")
        return "\n".join(parts)

    legend_items = []
    for cluster in sorted(set(clusters)):
        color = palette[(int(cluster) - 1) % len(palette)]
        lx = width - 104
        ly = 42 + 22 * (int(cluster) - 1)
        legend_items.append(
            f'<circle cx="{lx}" cy="{ly}" r="5.5" fill="{color}"><title>Cluster C{int(cluster)}</title></circle>'
            f'<text x="{lx + 14}" y="{ly + 4}" class="legend">C{int(cluster)}</text>'
        )

    svg = f"""<div class="embedding-interactive">
<svg class="embedding-svg" viewBox="0 0 {width} {height}" role="img" aria-label="UMAP and t-SNE embedding plots">
  <style>
    .embedding-interactive {{ position: relative; max-width: 1180px; }}
    .embedding-svg {{ width: 100%; max-width: 1180px; height: auto; border: 1px solid #d8dee4; background: #fff; }}
    .embedding-svg .axis {{ stroke: #444; stroke-width: 1; }}
    .embedding-svg .plot-title {{ font-size: 18px; font-weight: 600; }}
    .embedding-svg .axis-label {{ font-size: 13px; fill: #202124; }}
    .embedding-svg .tick {{ font-size: 10px; fill: #5f6368; }}
    .embedding-svg .legend {{ font-size: 12px; fill: #202124; }}
    .embedding-svg circle {{ stroke: #fff; stroke-width: 1; opacity: 0.88; cursor: pointer; }}
    .embedding-svg circle:hover, .embedding-svg circle:focus {{ stroke: #111; stroke-width: 2.2; opacity: 1; outline: none; }}
    .embedding-tooltip {{
      position: absolute;
      display: none;
      pointer-events: none;
      background: rgba(255, 255, 255, 0.96);
      border: 1px solid #8a8f98;
      border-radius: 3px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.16);
      color: #202124;
      font-size: 12px;
      line-height: 1.35;
      padding: 6px 8px;
      z-index: 20;
    }}
  </style>
  {panel(0, umap_xy, "UMAP", "UMAP 1", "UMAP 2")}
  {panel(panel_width + gap, tsne_xy, "t-SNE", "t-SNE 1", "t-SNE 2")}
  <g class="legend-group">
    <text x="{width - 118}" y="22" class="legend">cluster</text>
    {"".join(legend_items)}
  </g>
</svg>
<div class="embedding-tooltip"></div>
<script>
(function() {{
  document.querySelectorAll(".embedding-interactive").forEach(function(wrapper) {{
    var tooltip = wrapper.querySelector(".embedding-tooltip");
    if (!tooltip) {{
      return;
    }}

    function show(point) {{
      tooltip.innerHTML = point.getAttribute("data-tooltip") || "";
      tooltip.style.display = "block";
    }}

    function hide() {{
      tooltip.style.display = "none";
    }}

    function positionFromEvent(event) {{
      var rect = wrapper.getBoundingClientRect();
      tooltip.style.left = (event.clientX - rect.left + 12) + "px";
      tooltip.style.top = (event.clientY - rect.top + 12) + "px";
    }}

    function positionFromPoint(point) {{
      var wrapperRect = wrapper.getBoundingClientRect();
      var pointRect = point.getBoundingClientRect();
      tooltip.style.left = (pointRect.left - wrapperRect.left + pointRect.width + 8) + "px";
      tooltip.style.top = (pointRect.top - wrapperRect.top + pointRect.height + 8) + "px";
    }}

    wrapper.querySelectorAll(".embedding-point").forEach(function(point) {{
      point.addEventListener("mouseover", function(event) {{
        show(point);
        positionFromEvent(event);
      }});
      point.addEventListener("mousemove", positionFromEvent);
      point.addEventListener("mouseout", hide);
      point.addEventListener("focus", function() {{
        show(point);
        positionFromPoint(point);
      }});
      point.addEventListener("blur", hide);
    }});
  }});
}}());
</script>
</div>"""
    return svg


def full_iqm_label_boxplot_js(loader: Loader) -> str:
    """Patch MRIQC's group JS so y-axis labels keep full IQM names."""
    boxplots_js = loader("data/reports/embed_resources/boxplots.js").read_text()
    truncating_block = """    iqmName = chart.data[0][chart.settings.xName]
    if (iqmName.indexOf('_') > 0) {
        iqmName = iqmName.substr(0, iqmName.indexOf('_'))
    }
    chart.settings.axisLabels.yAxis = iqmName.toUpperCase()"""
    full_label_block = """    iqmName = chart.data[0][chart.settings.xName]
    chart.settings.axisLabels.yAxis = iqmName"""
    if truncating_block not in boxplots_js:
        raise SystemExit("Could not find expected MRIQC boxplot label truncation block")
    return boxplots_js.replace(truncating_block, full_label_block, 1)


def main() -> None:
    args = parse_args()
    input_dir = args.input_dir
    output_dir = args.output_dir
    random_state = args.random_state

    if not input_dir.is_dir():
        raise SystemExit(f"Input directory does not exist: {input_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)

    output_tsv = output_dir / "group.tsv"
    boxplot_html = output_dir / "group_boxplots.html"
    embedding_tsv = output_dir / "group_umap_tsne.tsv"
    embedding_html = output_dir / "group_umap_tsne.html"
    embedding_png = output_dir / "group_umap_tsne.png"
    dashboard_html = output_dir / "group_dashboard.html"
    summary_json = output_dir / "group_dashboard_summary.json"
    output_paths = [
        output_tsv,
        boxplot_html,
        embedding_tsv,
        embedding_html,
        embedding_png,
        dashboard_html,
        summary_json,
    ]
    tmp = atomic_paths(output_paths)

    json_files = sorted(input_dir.glob("sub-*.json"), key=natural_key)
    if not json_files:
        raise SystemExit(f"No subject JSON files found in {input_dir}")

    rows: list[dict[str, object]] = []
    metrics: list[str] = []
    for json_file in json_files:
        data = json.loads(json_file.read_text(encoding="utf-8"))
        row: dict[str, object] = {"bids_name": json_file.stem}
        for key, value in data.items():
            if isinstance(value, (dict, list)):
                continue
            if key not in metrics:
                metrics.append(key)
            row[key] = value
        rows.append(row)

    numeric_metrics = [
        metric
        for metric in metrics
        if all((row.get(metric) in ("", None)) or numeric_scalar(row.get(metric)) for row in rows)
    ]
    if not numeric_metrics:
        raise SystemExit("No numeric scalar metrics found")

    columns = ["bids_name"] + metrics
    with tmp[output_tsv].open("w", encoding="utf-8", newline="") as fobj:
        writer = csv.DictWriter(fobj, fieldnames=columns, delimiter="\t", extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)

    df = pd.DataFrame(rows, columns=columns)
    labels = df["bids_name"].astype(str).tolist()
    csv_groups = []
    for metric in numeric_metrics:
        plot_df = pd.DataFrame(
            {
                "iqm": [metric] * len(df),
                "value": pd.to_numeric(df[metric], errors="coerce"),
                "label": labels,
                "units": [None] * len(df),
            }
        ).dropna(subset=["value"])
        if plot_df.empty:
            continue
        buf = StringIO()
        plot_df[["iqm", "value", "label", "units"]].to_csv(buf, index=False)
        csv_groups.append(buf.getvalue())

    loader = Loader("mriqc")
    GroupTemplate().generate_conf(
        {
            "modality": "T1w",
            "timestamp": datetime.now(tz=timezone.utc).strftime("%Y-%m-%d, %H:%M"),
            "version": mriqc_version,
            "csv_groups": csv_groups,
            "failed": None,
            "boxplots_js": full_iqm_label_boxplot_js(loader),
            "d3_js": loader("data/reports/embed_resources/d3.min.js").read_text(),
            "boxplots_css": loader("data/reports/embed_resources/boxplots.css").read_text(),
        },
        tmp[boxplot_html],
    )

    numeric_df = df[numeric_metrics].apply(pd.to_numeric, errors="coerce")
    constant_metrics = [col for col in numeric_df.columns if numeric_df[col].nunique(dropna=True) <= 1]
    feature_df = numeric_df.drop(columns=constant_metrics)
    if len(df) < 4 or feature_df.shape[1] < 2:
        raise SystemExit("Need at least four samples and two non-constant metrics for embeddings")

    features = SimpleImputer(strategy="median").fit_transform(feature_df)
    features = StandardScaler().fit_transform(features)
    n_samples = len(df)
    n_neighbors = min(15, n_samples - 1)
    perplexity = min(30, max(5, (n_samples - 1) // 3))

    umap_xy = UMAP(
        n_components=2,
        n_neighbors=n_neighbors,
        min_dist=0.1,
        metric="euclidean",
        random_state=random_state,
    ).fit_transform(features)
    tsne_xy = TSNE(
        n_components=2,
        perplexity=perplexity,
        init="pca",
        learning_rate="auto",
        metric="euclidean",
        random_state=random_state,
        max_iter=1000,
    ).fit_transform(features)

    clusters, best_k, best_score = best_kmeans(features, random_state)
    embedding_df = pd.DataFrame(
        {
            "bids_name": df["bids_name"].astype(str),
            "cluster": clusters,
            "umap_1": umap_xy[:, 0],
            "umap_2": umap_xy[:, 1],
            "tsne_1": tsne_xy[:, 0],
            "tsne_2": tsne_xy[:, 1],
        }
    )
    embedding_df.to_csv(tmp[embedding_tsv], sep="\t", index=False)

    palette = [
        "#1f77b4",
        "#d62728",
        "#2ca02c",
        "#9467bd",
        "#ff7f0e",
        "#17becf",
        "#8c564b",
        "#e377c2",
    ]
    fig, axes = plt.subplots(1, 2, figsize=(12, 5), dpi=160, constrained_layout=True)
    for ax, xy, title, xlabel, ylabel in (
        (axes[0], umap_xy, "UMAP", "UMAP 1", "UMAP 2"),
        (axes[1], tsne_xy, "t-SNE", "t-SNE 1", "t-SNE 2"),
    ):
        for cluster in sorted(set(clusters)):
            mask = clusters == cluster
            ax.scatter(
                xy[mask, 0],
                xy[mask, 1],
                s=32,
                color=palette[(cluster - 1) % len(palette)],
                label=f"C{cluster}",
                alpha=0.88,
            )
        ax.set_title(title)
        ax.set_xlabel(xlabel)
        ax.set_ylabel(ylabel)
        ax.grid(True, color="#dddddd", linewidth=0.6)
    axes[0].legend(title="cluster", fontsize=8)
    fig.suptitle("MRIQC IQM embeddings")
    fig.savefig(tmp[embedding_png], format="png")
    plt.close(fig)

    png_bytes = tmp[embedding_png].read_bytes()
    if not png_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
        raise SystemExit("Embedding PNG failed signature validation")

    embedding_svg = render_embedding_svg(df["bids_name"], clusters, umap_xy, tsne_xy, palette)
    tmp[embedding_html].write_text(
        f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>MRIQC UMAP and t-SNE embeddings</title>
</head>
<body>
  <h1>MRIQC UMAP and t-SNE embeddings</h1>
  {embedding_svg}
</body>
</html>
""",
        encoding="utf-8",
    )

    boxplot_body = tmp[boxplot_html].read_text(encoding="utf-8")
    summary = {
        "created_utc": datetime.now(tz=timezone.utc).isoformat(),
        "mriqc_version": mriqc_version,
        "input_dir": str(input_dir),
        "output_dir": str(output_dir),
        "n_subject_json": len(json_files),
        "n_metrics": len(metrics),
        "n_numeric_metrics": len(numeric_metrics),
        "n_embedding_features": int(feature_df.shape[1]),
        "dropped_constant_metrics": constant_metrics,
        "umap": {"n_neighbors": n_neighbors, "min_dist": 0.1, "random_state": random_state},
        "tsne": {"perplexity": perplexity, "max_iter": 1000, "random_state": random_state},
        "kmeans": {
            "k": int(best_k),
            "silhouette": best_score,
            "cluster_sizes": {str(c): int((clusters == c).sum()) for c in sorted(set(clusters))},
        },
    }
    tmp[summary_json].write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")

    dashboard = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>MRIQC group dashboard</title>
  <style>
    body {{ margin: 0; font-family: Arial, sans-serif; color: #202124; background: #ffffff; }}
    header {{ padding: 18px 24px 10px; border-bottom: 1px solid #d8dee4; }}
    main {{ padding: 18px 24px 28px; }}
    h1 {{ margin: 0 0 8px; font-size: 24px; }}
    h2 {{ margin: 22px 0 12px; font-size: 18px; }}
    .meta {{ color: #5f6368; font-size: 13px; }}
    iframe {{ width: 100%; min-height: 860px; border: 1px solid #d8dee4; }}
    table {{ border-collapse: collapse; margin-top: 10px; }}
    td, th {{ border: 1px solid #d8dee4; padding: 5px 8px; font-size: 13px; }}
  </style>
</head>
<body>
  <header>
    <h1>MRIQC group dashboard</h1>
    <div class="meta">MRIQC {html.escape(mriqc_version)}; {len(df)} participants; {len(numeric_metrics)} numeric IQMs.</div>
  </header>
  <main>
    <h2>UMAP and t-SNE clustering</h2>
    {embedding_svg}
    <table>
      <tr><th>Model</th><th>Setting</th><th>Value</th></tr>
      <tr><td>UMAP</td><td>n_neighbors</td><td>{n_neighbors}</td></tr>
      <tr><td>t-SNE</td><td>perplexity</td><td>{perplexity}</td></tr>
      <tr><td>KMeans</td><td>k / silhouette</td><td>{best_k} / {best_score:.4f}</td></tr>
    </table>
    <h2>MRIQC boxplots</h2>
    <iframe srcdoc="{html.escape(boxplot_body, quote=True)}"></iframe>
  </main>
</body>
</html>
"""
    tmp[dashboard_html].write_text(dashboard, encoding="utf-8")

    embedding_html_text = tmp[embedding_html].read_text(encoding="utf-8")
    checks = {
        "group_tsv_rows": len(pd.read_csv(tmp[output_tsv], sep="\t")),
        "embedding_tsv_rows": len(pd.read_csv(tmp[embedding_tsv], sep="\t")),
        "embedding_has_tooltips": (
            'class="embedding-tooltip"' in embedding_html_text
            and 'class="embedding-point"' in embedding_html_text
            and 'data-tooltip="Subject:' in embedding_html_text
        ),
        "boxplot_charts": tmp[boxplot_html].read_text(encoding="utf-8").count('class="chart-wrapper"'),
        "dashboard_has_umap": "UMAP and t-SNE" in tmp[dashboard_html].read_text(encoding="utf-8"),
    }
    if checks["group_tsv_rows"] != len(json_files):
        raise SystemExit("group.tsv row count validation failed")
    if checks["embedding_tsv_rows"] != len(json_files):
        raise SystemExit("embedding TSV row count validation failed")
    if not checks["embedding_has_tooltips"]:
        raise SystemExit("embedding HTML tooltip validation failed")
    if checks["boxplot_charts"] != len(numeric_metrics):
        raise SystemExit("boxplot chart count validation failed")
    if not checks["dashboard_has_umap"]:
        raise SystemExit("dashboard validation failed")

    replace_outputs(tmp)

    print(f"Subject JSON files: {len(json_files)}")
    print(f"Numeric IQMs plotted: {len(numeric_metrics)}")
    print(f"Embedding features used: {feature_df.shape[1]}")
    print(f"KMeans clusters: k={best_k}, silhouette={best_score:.4f}")
    print(f"Wrote TSV: {output_tsv}")
    print(f"Wrote boxplot HTML: {boxplot_html}")
    print(f"Wrote embedding TSV: {embedding_tsv}")
    print(f"Wrote embedding HTML: {embedding_html}")
    print(f"Wrote embedding PNG: {embedding_png}")
    print(f"Wrote dashboard HTML: {dashboard_html}")
    print(f"Wrote summary JSON: {summary_json}")


if __name__ == "__main__":
    main()
