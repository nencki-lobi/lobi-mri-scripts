#ls *.dat | xargs -n 1 ~/ls_dat.sh > list.csv
patient_name=$(grep -aPo -m 1 'PatientName">{\s*"\K[^"]*' "$1")
echo "$1,$patient_name"
