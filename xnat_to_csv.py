from pyxnat import Interface
from dotenv import load_dotenv
import os
import csv
import re
import argparse

parser = argparse.ArgumentParser(description='Download list of all XNAT sessions to CSV file.')
parser.add_argument("--project", "-p", required=False, type=str, help="XNAT project name.")
parser.add_argument("--output", "-o", required=False, type=str, help="CSV output file name (default is current folder/subjects.csv file).")
args = parser.parse_args()

output = args.output or 'subjects.csv'

# load xnat credentials from .env file if available
load_dotenv()
XNAT_URL = os.getenv("XNAT_URL")
USERNAME = os.getenv("XNAT_USER")
PASSWORD = os.getenv("XNAT_PASS")
PROJECT = args.project or os.getenv("PROJECT")


# initiate the connection; use https:// as a prefix!
xnat = Interface(server=XNAT_URL, user=USERNAME, password=PASSWORD)

# load all sessions from the selected PROJECT
experiments = xnat.select.project(PROJECT).experiments()

# Prepare experiment data for sorting
experiment_data = []

for exp in experiments:
    xnat_id = exp.label()
    subject = exp.parent()
    subject_id = subject.label()
    guess_code = re.sub(r'\D', '', subject_id)
    
    experiment_data.append((xnat_id, subject_id, guess_code))

# Sort the experiment data based on subject_id
experiment_data.sort(key=lambda x: x[1])

# Save the sorted list to csv file
with open(output, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['MR ID', 'Subject_ID', 'subject', 'session'])
    
    for data in experiment_data:
        writer.writerow(data)

