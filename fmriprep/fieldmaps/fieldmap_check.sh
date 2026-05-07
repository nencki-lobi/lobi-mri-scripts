  rm mismatch.txt
  
  for f in ~/KJ23a/sub-*/ses-*/func/sub-*_ses-01_task-alicja1_bold.json; do
      ./analysis_01_fmap_match.sh "$f" >> mismatch.txt
  done

  ./analysis_02_better_fmap_match.sh
