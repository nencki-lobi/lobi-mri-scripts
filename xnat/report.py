import argparse
import csv
from collections import defaultdict


DEFAULT_SEQUENCES_CONFIG = "sequences.config"
DEFAULT_OUTPUT_CSV = "report.csv"

XNAT_SCAN_COLUMNS = [
    "xnat:subjectData/label",
    "xnat:imageSessionData/label",
    "xnat:imageScanData/type",
    "xnat:imageScanData/series_description",
]


def row_get(row, *names):
    for name in names:
        if hasattr(row, "get"):
            value = row.get(name)
        else:
            try:
                value = row[name]
            except (KeyError, TypeError):
                value = None

        if value not in (None, ""):
            return value

    if hasattr(row, "keys"):
        keys_by_lower = {
            str(key).lower(): key
            for key in row.keys()
        }

        for name in names:
            key = keys_by_lower.get(name.lower())
            if key is None:
                continue

            value = row.get(key)

            if value not in (None, ""):
                return value

    return ""


def load_sequences(path=DEFAULT_SEQUENCES_CONFIG):
    with open(path, newline="") as config:
        sequences = []

        for line_number, line in enumerate(config, start=1):
            line = line.removesuffix("\n").removesuffix("\r")

            if "," not in line:
                raise ValueError(
                    f"{path} line {line_number}: expected short_name,full_name"
                )

            short_name, full_name = line.split(",", 1)
            sequences.append((short_name, full_name))

        return sequences


def subject_from_row(row):
    subject = row_get(
        row,
        "subject_label",
        "xnat:subjectData/label",
        "xnat:mrSessionData/subject_id",
        "xnat:imageSessionData/subject_id",
        "subject_id",
        "subject",
    )
    return str(subject)


def scan_names_from_row(row):
    scan_type = row_get(
        row,
        "type",
        "scan_type",
        "xnat:mrScanData/type",
        "xnat:imageScanData/type",
    )
    series_description = row_get(
        row,
        "series_description",
        "xnat:mrScanData/series_description",
        "xnat:imageScanData/series_description",
    )

    return {
        name
        for name in (
            scan_type,
            series_description,
        )
        if name
    }


def build_subject_sequence_counts(scans, sequences):
    subjects = defaultdict(
        lambda: {
            short_name: 0
            for short_name, _ in sequences
        }
    )

    for row in scans:
        subject = subject_from_row(row)

        if not subject:
            continue

        scan_names = scan_names_from_row(row)

        for short_name, full_name in sequences:
            if full_name in scan_names:
                subjects[subject][short_name] += 1

    return subjects


def build_report_rows(scans, sequences):
    subjects = build_subject_sequence_counts(scans, sequences)

    return [
        (subject, subjects[subject])
        for subject in sorted(subjects)
    ]


def write_csv_report(path, rows, sequences):
    with open(path, "w", newline="") as output:
        writer = csv.writer(output)
        writer.writerow(
            [
                "Subject",
                *[
                    short_name
                    for short_name, _ in sequences
                ],
            ]
        )

        for subject, counts in rows:
            writer.writerow(
                [
                    subject,
                    *[
                        counts[short_name]
                        for short_name, _ in sequences
                    ],
                ]
            )


def connect_xnat():
    from pyxnat import Interface

    return Interface()


def load_project_scans(xnat, project_id):
    return xnat.array.scans(
        project_id=project_id,
        columns=XNAT_SCAN_COLUMNS,
    )


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Zapisuje raport sekwencji XNAT do pliku CSV."
    )
    parser.add_argument("project", help="Nazwa projektu XNAT, np. PC26a")
    parser.add_argument(
        "--sequences",
        default=DEFAULT_SEQUENCES_CONFIG,
        help=f"Plik z nazwami sekwencji, domyslnie {DEFAULT_SEQUENCES_CONFIG}",
    )
    parser.add_argument(
        "--output",
        default=DEFAULT_OUTPUT_CSV,
        help=f"Plik wyjsciowy CSV, domyslnie {DEFAULT_OUTPUT_CSV}",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    sequences = load_sequences(args.sequences)
    xnat = connect_xnat()

    print(f"Pobieram wszystkie skany projektu {args.project}...")

    scans = load_project_scans(xnat, args.project)

    print(f"Pobrano {len(scans)} skanow.")

    rows = build_report_rows(scans, sequences)
    write_csv_report(args.output, rows, sequences)

    print(f"Zapisano raport CSV: {args.output}")


if __name__ == "__main__":
    main()
