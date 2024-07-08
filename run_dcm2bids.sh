#!/bin/bash

# Run using GNU parallel. Be careful with numbering of columns in CSV
#tail -n +2 $subject_list | parallel -j 4 --colsep ',' run_dcm2bids.sh "{1}" {4} {5} 

MR_ID="$1"
Subject="$2"
Session="$3"

if [[ -z "$MR_ID" ]]; then
  echo "XNAT session ID is empty. Exiting"
  exit 1
fi

# Default Session to "01" if not provided
if [[ "$Session" == *"2"* ]]; then
    Session="02"
else
    Session="01"
fi

echo "Running dcm2bids for Subject: $Subject, Session: $Session"

# Split MR_ID and build the -d options. Remeber to put MR_ID in "" if there there are two and more. 
IFS=' ' read -r -a mr_id_array <<< "$MR_ID"

# Initialize command array with common elements
command=(
    'dcm2bids'
    '-p' "$Subject"
    '-s' "$Session"
    '-c' './code/config.json'
    '-o' './'
    '--auto_extract_entities'
)

# Append -d options to the command array
for id in "${mr_id_array[@]}"; do
    command+=('-d' "./sourcedata/$id")
done

# Execute the command
echo "${command[@]}"
"${command[@]}"
