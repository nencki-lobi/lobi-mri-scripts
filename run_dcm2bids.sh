#!/bin/bash

# Run using GNU parallel. BE careful with numbering of columns inn CSV
#tail -n +2 $subject_list | parallel -j 4 --colsep ',' run_dcm2bids.sh {1} {4} {5} 
    
MR_ID="$1"
Subject="$2"
Session="$3"

if [[ -z "$MR_ID" ]]; then
  echo "XNAT session ID is empty. Exiting"
  exit 1
fi


# Default Session to "01" if not provided
#if [[ -z "$Session" ]]; then
#    Session="01"
if [[ "$Session" == *"2"* ]]; then
    Session="02"
else
    Session="01"
fi

echo "Running dcm2bids for Subject: $Subject, Session: $Session"

# Define the dcm2bids command
command=(
    'dcm2bids'
    '-d' "./sourcedata/$MR_ID"
    '-p' "$Subject"
    '-s' "$Session"
    '-c' './code/config.json'
    '-o' './'
    '--auto_extract_entities'
)

# Execute the command
"${command[@]}"
