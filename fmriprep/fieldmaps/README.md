# Fieldmaps

Zestaw skryptów do pracy z fieldmaps w BIDS i przygotowania ich pod `fmriprep`.

## Przegląd

W repozytorium są cztery powiązane kroki robocze:

1. `analysis_01_fmap_match.sh` sprawdza dopasowanie fieldmap dla pojedynczego pliku `func` i zwraca ścieżkę, jeśli dopasowanie wygląda źle.
2. `analysis_02_better_fmap_match.sh` czyta wynik z kroku 1, czyli `mismatch.txt`, i szuka lepszego dopasowania `AP` oraz `PA`.
3. `analysis_03_preflight_fieldmap_check.py` robi preflight pojedynczego skanu `func.nii.gz` i weryfikuje, czy wybrane fieldmapy mają poprawne metadane.
4. `topup-all.sh` buduje jedną wspólną mapę pola z wszystkich dostępnych skanów `fmap` dla danej sesji.

Skrypt [`fieldmap_check.sh`](/home/jovyan/lobi-mri-scripts/fmriprep/fieldmaps/fieldmap_check.sh) pokazuje typowy przebieg 1, 2 i 3 na jednej sesji.

## Skrypty

- [`analysis_01_fmap_match.sh`](/home/jovyan/lobi-mri-scripts/fmriprep/fieldmaps/analysis_01_fmap_match.sh) - przyjmuje jeden plik JSON z `func`, znajduje odpowiadający mu katalog `fmap` w tej samej sesji, porównuje `ImageOrientationPatientDICOM` i `ShimSetting` z domyślną parą `AP`/`PA` bez numeru `run` i wypisuje ścieżkę skanu, jeśli dopasowanie jest podejrzane.
- [`analysis_02_better_fmap_match.sh`](/home/jovyan/lobi-mri-scripts/fmriprep/fieldmaps/analysis_02_better_fmap_match.sh) - przyjmuje listę z `mismatch.txt`, przeszukuje wszystkie dostępne JSON-y fieldmap w danej sesji i zwraca `better_match.tsv` z propozycją lepszego `AP` i `PA`.
- [`analysis_03_preflight_fieldmap_check.py`](/home/jovyan/lobi-mri-scripts/fmriprep/fieldmaps/analysis_03_preflight_fieldmap_check.py) - przyjmuje pojedynczy plik `func.nii.gz`, znajduje siostrzany katalog `fmap`, sprawdza `IntendedFor`, a opcjonalnie także `ShimSetting` i orientację.
- [`fieldmap_check.sh`](/home/jovyan/lobi-mri-scripts/fmriprep/fieldmaps/fieldmap_check.sh) - pokazuje kompletny przykład uruchomienia 1, 2 i 3 w jednej sesji.
- [`topup-all.sh`](/home/jovyan/lobi-mri-scripts/fmriprep/fieldmaps/topup-all.sh) - scala wszystkie dostępne skany `fmap`, uruchamia `topup` i przygotowuje pliki wyjściowe pod `fmriprep`.

## Wspólny wzorzec wejścia

Skrypty 1 i 3 pracują na pojedynczym skanie i z samej ścieżki wejściowej wyciągają `sub-*` oraz `ses-*`, żeby przejść do `ses-*/fmap`.

- `analysis_01_fmap_match.sh` bierze `func` w formie JSON.
- `analysis_03_preflight_fieldmap_check.py` bierze `func.nii.gz`, a odpowiadający JSON sidecar odczytuje sam.

To oznacza, że dla obu skryptów najważniejsza jest ścieżka do skanu, a nie ręczne podawanie katalogu `fmap`.

## 1. Sprawdzenie dopasowania fieldmap

Ten etap służy do wykrycia przypadków, w których domyślne przypisanie fieldmapa nie wygląda poprawnie.

### `analysis_01_fmap_match.sh`

Wejście:

- jeden plik `func` w postaci JSON, np. `sub-001_ses-01_task-..._bold.json`.

Logika:

- skrypt wyciąga z nazwy pliku `subject` i `session`,
- przechodzi do odpowiadającego katalogu `fmap`,
- porównuje skan z fieldmapami `AP` i `PA` bez etykiety `run`,
- sprawdza `ImageOrientationPatientDICOM` i `ShimSetting`,
- jeśli dopasowanie nie wygląda dobrze, wypisuje pełną ścieżkę skanu `func`.

Wyjście:

- lista ścieżek do skanów, które trafiają do `mismatch.txt`.

### `analysis_02_better_fmap_match.sh`

Wejście:

- `mismatch.txt` z kroku 1.

Logika:

- skrypt czyta po jednej ścieżce `func` z `mismatch.txt`,
- dla każdej ścieżki przechodzi do `sub-*/ses-*/fmap`,
- przeszukuje wszystkie dostępne JSON-y `*_dir-AP*_epi.json` i `*_dir-PA*_epi.json`,
- zapisuje najlepszy match dla `AP` i `PA`,
- uznaje match tylko wtedy, gdy zgadzają się oba kryteria: orientacja i `ShimSetting`.

Wyjście:

- `better_match.tsv` z trzema kolumnami:
  - ścieżka do skanu `func`,
  - najlepiej pasujący fieldmap `AP`,
  - najlepiej pasujący fieldmap `PA`.

Jeśli dla jednej z osi nie ma pełnego dopasowania, odpowiednia kolumna pozostaje pusta.

### `fieldmap_check.sh`

To przykład, jak połączyć kroki 1, 2 i 3 dla jednej sesji:

```bash
: > mismatch.txt
for f in sub-*/ses-*/func/sub-*_ses-01_task-alicja1_bold.json; do
  ./analysis_01_fmap_match.sh "$f" >> mismatch.txt
done

./analysis_02_better_fmap_match.sh mismatch.txt

for f in sub-*/ses-*/func/sub-*_ses-01_task-alicja1_bold.nii.gz; do
  ./analysis_03_preflight_fieldmap_check.py \
    --custom-string acq-std \
    --shim \
    --position \
    "$f"
done
```

## 2. Preflight przed `fmriprep`

### `analysis_03_preflight_fieldmap_check.py`

Wejście:

- pojedynczy plik `func.nii.gz`.

Logika:

- skrypt przechodzi do `ses-*/fmap` położonego obok pliku `func`,
- szuka dwóch plików JSON fieldmap:
  - `*_dir-AP*_epi.json`
  - `*_dir-PA*_epi.json`
- sprawdza, czy `IntendedFor` istnieje, ma poprawny typ i zawiera bieżący run,
- waliduje wpisy `IntendedFor` jako poprawne ścieżki BIDS,
- opcjonalnie porównuje `ShimSetting`,
- opcjonalnie porównuje `ImageOrientationPatientDICOM`.

Parametry:

- `--custom-string`
  - fragment nazwy fieldmapy, np. `acq-std` albo `run-02`
  - domyślnie: `acq-std`
- `--shim`
  - włącza sprawdzanie `ShimSetting`
- `--position`
  - włącza sprawdzanie `ImageOrientationPatientDICOM`

Przykład:

```bash
python3 analysis_03_preflight_fieldmap_check.py \
  --custom-string run-02 \
  --shim \
  --position \
  /path/to/sub-005/ses-01/func/sub-005_ses-01_task-localizer_run-02_bold.nii.gz
```

Wynik:

- `0` jeśli `AP`, `PA`, `IntendedFor` i opcjonalne metadane są zgodne,
- `1` jeśli brakuje fieldmapy albo coś się nie zgadza.

## 3. Budowa fieldmapy z wielu skanów

### `topup-all.sh`

Skrypt przygotowuje pole z wszystkich dostępnych skanów `fmap` dla danej sesji.

Działanie:

- znajduje wszystkie `AP` i `PA` z prefiksem `acq-std` oraz numerem `run`,
- odrzuca obrazy o innym kształcie niż dominujący,
- zapisuje sidecary `acq-mean_fieldmap.json` i `acq-mean_magnitude.json`,
- ustawia `IntendedFor` na wszystkie skany `func/*_bold.nii.gz` z sesji,
- uruchamia `topup` z `module load fsl/6.0.7.22`,
- tworzy `acq-mean_fieldmap.nii.gz` oraz `acq-mean_magnitude.nii.gz`.

Przykład wywołania:

```bash
./topup-all.sh sub-01 ses-01 /path/to/bids
```

Wynik trafia do:

- `/path/to/bids/sub-01/ses-01/fmap/sub-01_ses-01_acq-mean_fieldmap.nii.gz`
- `/path/to/bids/sub-01/ses-01/fmap/sub-01_ses-01_acq-mean_fieldmap.json`
- `/path/to/bids/sub-01/ses-01/fmap/sub-01_ses-01_acq-mean_magnitude.nii.gz`
- `/path/to/bids/sub-01/ses-01/fmap/sub-01_ses-01_acq-mean_magnitude.json`
