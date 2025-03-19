#!/bin/bash

echo "auto-extract-entities enabled"

# Run using GNU parallel. Be careful with numbering of columns in CSV
#tail -n +2 $subject_list | parallel -j 4 --colsep ',' run_dcm2bids.sh "{1}" {4} {5} 

SCRIPTS=$(dirname "$(realpath "$0")")

MR_ID="$1"
Subject="$2"
Session="$3"

if [[ -z "$MR_ID" ]]; then
  echo "XNAT session ID is empty. Exiting"
  exit 1
fi

# Default Session to "01" if not provided
if [[ "$Session" == *"4"* ]]; then
    Session="04"
elif [[ "$Session" == *"3"* ]]; then
    Session="03"
elif [[ "$Session" == *"2"* ]]; then
    Session="02"
else
    Session="01"
fi

echo "Running dcm2bids for Subject: $Subject, Session: $Session"

# Split MR_ID and build the -d options. Remeber to put MR_ID in "" if there there are two and more. 
IFS=' ' read -r -a mr_id_array <<< "$MR_ID"
dirs=()
for id in "${mr_id_array[@]}"; do
    dirs+=("./sourcedata/$id")
done

# Initialize command array with common elements
command=(
    'dcm2bids'
    '-p' "$Subject"
    '-s' "$Session"
    '-c' './code/config.json'
    '-o' './'
    '-d' "${dirs[@]}"
    '--auto_extract_entities'
)

# Execute the command
echo "${command[@]}"
"${command[@]}"

echo "Fieldmaps' paths will be repaired"
find sub-"$Subject" -type f -path "*/fmap/*.json" -exec $SCRIPTS/fmriprep/json_fmaps_repair.sh {} \;