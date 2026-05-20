# analysis_03_preflight_fieldmap_check.py

Skrypt sprawdza pojedynczy plik `func.nii.gz` i ocenia, czy przypisane do niego fieldmapy `dir-AP` oraz `dir-PA` spełniają wymagania preflight.

## Logika

1. Skrypt bierze jako wejście jeden plik `func.nii.gz`.
2. Na podstawie ścieżki do `func` przechodzi do katalogu `ses-*/fmap`.
3. Szuka dwóch plików JSON fieldmap:
   - `*_dir-AP*_epi.json`
   - `*_dir-PA*_epi.json`
4. Jeśli nie ma obu plików, skrypt kończy się błędem.
5. Dla obu JSON-ów sprawdza pole `IntendedFor`:
   - musi istnieć,
   - musi być stringiem albo listą stringów,
   - musi zawierać dokładnie bieżący run `ses-XX/func/<nazwa_pliku_func>`.
6. Każdy wpis w `IntendedFor` jest walidowany jako poprawna ścieżka BIDS:
   - `ses-*/func/..._bold.nii.gz`
   - `ses-*/dwi/..._dwi.nii.gz`
7. Jeśli podano `--shim`, skrypt porównuje `ShimSetting` z pliku `func` i z fieldmap.
8. Jeśli podano `--position`, skrypt porównuje `ImageOrientationPatientDICOM` z pliku `func` i z fieldmap.

Jeśli którykolwiek warunek nie jest spełniony, skrypt wypisuje ścieżkę do pliku `func.nii.gz` i zwraca kod błędu.

## Parametry

- `--custom-string`
  - fragment nazwy fieldmapy, np. `acq-std` albo `run-02`
  - domyślnie: `acq-std`
- `--shim`
  - włącza sprawdzanie `ShimSetting`
- `--position`
  - włącza sprawdzanie `ImageOrientationPatientDICOM`

## Przykład

```bash
python3 analysis_03_preflight_fieldmap_check.py \
  --custom-string run-02 \
  --shim \
  --position \
  ~/PROJEKTY/AD25a/bids-dir/sub-005/ses-01/func/sub-005_ses-01_task-localizer_run-02_bold.nii.gz
```

Wynik:

- `0` jeśli `AP`, `PA`, `IntendedFor` i opcjonalne metadane są zgodne,
- `1` jeśli brakuje fieldmapy albo coś się nie zgadza.
