# Co robić kiedy mam >1 Fieldmap?

**fmriprep nie użyje żadnego fieldmapa**, jeśli będzie ich więcej niż potrzeba. Musisz to wyjaśnić zanim uruchomisz preprocessing. Najprostszy algorytm "wybierz drugi" polega na utworzeniu skrótu `ln -s` do fieldmapa z etykietą `run-02`, z założeniem, że drugi jest lepszy niż żaden. Poniżej znajduje się kod umożliwiający wykonanie linków w pętli dla wszystkich badań.

Pamiętaj, że przy uruchomieniu `fmriprep` musisz użyć filtra, który zignoruje wszystkie niepotrzebne fieldmapy, czyli odrzuci te z etykietą `run-XX`.

```bash
for s in sub*; do
  for dir in AP PA; do
    for ext in json nii.gz; do
      cd "$s/ses-01/fmap" || continue
      src="${s}_ses-01_acq-std_dir-${dir}_run-02_epi.${ext}"
      dst="${s}_ses-01_acq-std_dir-${dir}_epi.${ext}"
      [ -e "$src" ] && ln -sf "$src" "$dst"
      cd - > /dev/null
    done
  done
done
```

Przykładowy `bids filter`:

```json
{
  "fmap": {
    "datatype": "fmap",
    "run": null
  }
}
```

# Fieldmap Check

Dla osób, które mają więcej niż jeden fieldmap, domyślnie przypisujemy fieldmapy `run-02`. Sprawdzamy, czy takie przypisanie ma sens.

## Co jest sprawdzane

Pierwszy etap tworzy listę `mismatch.txt`.

Skrypt [analysis_01_alicja_fmap_match.sh](/home/jovyan/PROJEKTY/fmaps/ses-01/analysis_01_alicja_fmap_match.sh:1):

- przyjmuje jeden plik fMRI jako argument,
- znajduje odpowiadający mu katalog `fmap` w tym samym `sub-*/ses-*`,
- porównuje skan z fieldmapami bez etykiety run: `sub-*_ses-*_acq-std_dir-AP_epi.json` oraz `sub-*_ses-*_acq-std_dir-PA_epi.json`,
- sprawdza dwa kryteria: `ImageOrientationPatientDICOM` oraz `ShimSetting`,
- jeśli przypisane fieldmapy nie spełniają tych warunków, wypisuje pełną ścieżkę skanu na `stdout`

W praktyce `mismatch.txt` zawiera skany, dla których domyślny link do `run-02` nie wygląda na poprawny.

## Jak szukane są lepsze dopasowania

Drugi etap czyta `mismatch.txt` i zapisuje `better_match.tsv`.

Skrypt [analysis_02_better_fmap_match.sh](/home/jovyan/PROJEKTY/fmaps/ses-01/analysis_02_better_fmap_match.sh:1):

- bierze każdy skan z `mismatch.txt`,
- przechodzi do odpowiadającego mu katalogu `../fmap` względem danego `func`, czyli do `sub-*/ses-*/fmap`,
- przeszukuje dostępne fieldmapy `*_dir-AP*_epi.json` i `*_dir-PA*_epi.json`,
- zapisuje osobno najlepszy match `AP` i `PA`,
- uznaje match tylko wtedy, gdy jednocześnie zgadzają się `ImageOrientationPatientDICOM` i `ShimSetting`

Plik `better_match.tsv` ma trzy kolumny:

- kolumna 1: ścieżka do fMRI
- kolumna 2: najlepiej pasujący fieldmap `AP`
- kolumna 3: najlepiej pasujący fieldmap `PA`

Jeśli dla `AP` albo `PA` nie ma pełnego dopasowania, odpowiednia kolumna zostaje pusta.

## Jak uruchomić

Przykładowe wywołanie jest w [fieldmap_check.sh](/home/jovyan/PROJEKTY/fmaps/ses-01/fieldmap_check.sh:1).

Schemat działania jest taki:

```bash
: > mismatch.txt
for f in sub-*/ses-*/func/sub-*_ses-01_task-alicja1_bold.json; do
    ./analysis_01_alicja_fmap_match.sh "$f" >> mismatch.txt
done

./analysis_02_better_fmap_match.sh
```

Po wykonaniu:

- `mismatch.txt` zawiera skany, dla których domyślny fieldmap bez etykiety run nie pasuje,
- `better_match.tsv` zawiera propozycje lepszych dopasowań `AP` i `PA`.
