# XNAT sequence report

Skrypt `report.py` pobiera skany z projektu XNAT i zapisuje `report.csv`.
W kolumnach CSV znajduja sie krotkie nazwy sekwencji z pliku `sequences.config`,
a w komorkach liczba skanow dopasowanych dokladnie do pelnej nazwy sekwencji
dla osoby.

## Instalacja

Wymagany jest pakiet `pyxnat`:

```bash
pip install pyxnat
```

## Konfiguracja dostepu do XNAT

Skrypt uzywa natywnego logowania `pyxnat`, czyli `Interface()` czyta dane z
pliku `~/.xnatPass`.

Przykladowy `~/.xnatPass`:

```text
+username@https://xnat.nencki.edu.pl=password
```

Dla wlasnego konta podmien nazwe uzytkownika, adres serwera i haslo na swoje
dane dostepowe, zachowujac format `+user@https://server=password`.

## Konfiguracja sekwencji

Plik `sequences.config` zawiera jedna sekwencje na linie w formacie:

```text
krotka_nazwa,pelna_nazwa_sekwencji
```

Pełna nazwa jest porownywana **dokładnie** z wartosciami XNAT `type` albo `series_description`.
`krotka_nazwa` trafia do naglowka `report.csv`. Przecinek jest separatorem, wiec linia bez przecinka jest bledem konfiguracji.
Skrypt usuwa tylko znak konca linii, wiec pozostale spacje sa czescia nazwy.

Przyklad:

```text
fmap-ap,DistortionMap_PA
fmap-pa,DistortionMap_AP
bold,ep2d_bold_s8
dwi,ep2d_diff_biobank
dwi-b0,ep2d_diff_biobank 3b0 PA
t1-mprage,t1_mprage_sag_p2_iso
t1-vibe,t1_vibe_tra
swi,t2_fl3d_tra_p2_swi
t2-spc,t2_spc_da-fl_sag_p2_iso
```

## Uruchomienie

Podaj nazwe projektu XNAT jako argument:

```bash
python report.py PC26a
```

Domyslnie skrypt czyta `sequences.config` i zapisuje `report.csv`.
Mozna wskazac inne pliki:

```bash
python report.py PC26a --sequences my_sequences.config --output pc26a_report.csv
```
