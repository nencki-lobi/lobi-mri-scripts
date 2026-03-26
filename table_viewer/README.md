# Quality Control Procedure with Table Viewer

This tool allows you to load a CSV table and explore it in your web browser. It is useful for one-by-one QC analysis by scrolling line by line and rating rows using a dropdown menu. This tool has been used for mriqc, freesurfer (visual) qc and MR spectroscopy. Results can be saved as a new CSV table.

**Run with:**
`python -m http.server --cgi`
then go to:
`http://localhost:8000` and find 'table-viewer' directory

## Hints

* Use the **Save** button to persist your changes. **Changes are not saved automatically.**
* You can enter your own command executed for each table row, e.g.:
  `freeview -v $SUBJECTS_DIR/$subj/mri/T1w.mgz`
  Use `$subj` to insert subject labels. **It will work only if You use local http server and software installed on the same computer**
* Rows labeled **"low"** and **"high"** define lower and upper thresholds. Values outside these bounds are highlighted in yellow.
* Images named exactly like the index column (`{subj}.svg`) will be loaded automatically from `./imgs` if present.
  You can change the default image type (SVG) in the first line of `script.css`.
* Adjust image size by modifying CSS fields in `index.html`: `left`, `bottom`, and `width`.

---

## Example Workflow for **MRIQC** Analysis

Assuming you start in mriqc directory and table_viewer is located within it:

```bash
cd ./mriqc
cp -r ~/lobi-mri-scripts/table_viewer ./table_viewer
```
---

### **1. Prepare `data.csv` for the Table Viewer**

Export selected columns to a new CSV file inside **table_viewer** (select one of the following commands):

```bash
awk -F'\t' '{print $1","$2","$3","$5","$6","$13","}' group_T1w.tsv > table_viewer/data.csv

awk -F'\t' '{print $1","$23","$12","$45","}' group_bold.tsv > table_viewer/data.csv
```

If you want to select other columns You can identify their numbers by running:
```bash
awk -F'\t' 'NR==1 {for(i=1; i<=NF; i++) print i". " $i}' group_T1w.tsv
```

(Optional) Add lower and upper bounds for cell coloring:

* Add **two additional rows** named `low` and `high`. Below is a command to do it at the end of the file:
```bash
tail -n1 table_viewer/data.csv | sed 's/[^,]//g' | awk '{print "low"$0; print "upper"$0}' >> table_viewer/data.csv
```
* Set those threshold values for each column

---

### **2. Open the Table Viewer in your browser**

With the server still running in `./mriqc`, go to:

```
http://localhost:8000/table_viewer/
```

The viewer will automatically load:

* `data.csv`
* Images from `table_viewer/imgs` (if present)
* Configuration defined in the viewer directory

---

### Optional: Add Thumbnail Images

You may add thumbnails using **either** symbolic links or PNG conversion.

#### **Option A: Symlinks (recommended)**

Run this inside `./mriqc/table_viewer/imgs`:

```bash
desc=desc-zoomed
modality=T1w

for z in ../../sub-*/figures/*${desc}_${modality}.svg; do
  filename=$(basename "$z")
  link_name=$(echo "$filename" | sed "s/${desc}_//")
  ln -s "$z" "$link_name"
done
```

#### **Option B: Convert SVG to PNG**

```bash
sudo apt-get install librsvg2-bin
```

Run inside `./mriqc/table_viewer`:

```bash
desc=desc-zoomed
modality=T1w

mkdir -p ./imgs_png

for z in ../sub-*/figures/*${desc}_${modality}.svg; do
  filename=$(basename "$z")
  out_name=$(echo "$filename" | sed "s/${desc}_//")
  out_name_png="${out_name%.svg}.png"

  echo "Converting: $z → imgs_png/$out_name_png"
  rsvg-convert -w 600 -f png "$z" -o "./imgs_png/$out_name_png"
done
```


