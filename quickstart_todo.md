# quickstart_todo.md

Source note: this list is based only on `quickstart.ipynb` and focuses on clarity, consistency, and tutorial flow.

## Proposed quickstart improvements

1. Fix section numbering in section 3.
Current section labels are inconsistent: there is a `3.1 lobi_scripts` section and also a `3.1 MRIQC and fMRIPrep` section.
Make subsection numbering unique and align it with the actual tutorial structure.

2. Update the table of contents so it matches the current notebook.
The top-level table of contents still reflects an older layout and still mentions `FAQ`.
Refresh it so all section names and anchors match the current notebook exactly.

3. Add a short prerequisites block near the start.
State clearly that the tutorial assumes:
- Neurodesktop is running
- the user has Jupyter or Terminal access
- XNAT credentials are available
- helper tools like `xnat_dcm2bids`, `xnat_getcsv`, and `lobi_scripts` are installed

4. Clarify Jupyter syntax versus shell syntax early in the notebook.
The tutorial mentions `!`, `%`, and `{bidsdir}` substitution, but the explanation is easy to miss.
Add one short note with 2-3 concrete examples showing:
- Jupyter command syntax
- the equivalent terminal syntax
- that `{bidsdir}` is a notebook variable, not literal shell syntax

5. Standardize path notation throughout the notebook.
The tutorial currently mixes:
- `/home/jovyan/bids-dir`
- `~/bids-dir`
- `{bidsdir}`
- `./code`

Choose a primary convention and explain when each form is being used.

6. Resolve the config workflow ambiguity in section 2.6.
The notebook says users can link a config from `~/lobi-mri-scripts`, but the next cell writes a new `config.json` into `{bidsdir}/code`.
Clarify whether the intended workflow is:
- link a ready-made config
- copy and edit a ready-made config
- or create a config from scratch

7. Add a clearer recommendation for config management.
Explain when users should reuse a repository config and when they should customize their own local `config.json`.
This will make section `2.6` much easier to follow.

8. Rewrite the XNAT connection instructions as an explicit step-by-step workflow.
Current wording is understandable but dense.
Break it into short steps:
- run `xnat-ls`
- provide `xnat.nencki.edu.pl`
- enter username and password
- confirm success by checking that projects are listed

9. Do a copy-edit pass for grammar, spelling, and consistency.
Examples to fix include:
- `MacOS` vs `macOS`
- `begining`
- `neccesarry`
- `straighforward`
- inconsistent use of `You` / `your`

10. Mark cells more clearly as “run now” versus “preview only”.
Some commands execute real work, while others are wrapped in `echo`.
Add short notes so users know whether they are expected to run a cell immediately or inspect it first.

11. Explain the subject/session naming convention once.
The tutorial mixes values like `03`, `01`, and `sub-03`.
Add one short note explaining when raw IDs are used and when BIDS-style names are expected.

12. Fix or explain the multiple-session conversion loop.
The loop reads `ses` from the CSV but hardcodes `1` in the command:
`xnat_dcm2bids --output-dir ./ --config ./code/config.json "$xnatid" "$sub" 1`

Either replace `1` with the parsed session value or explain why session `1` is intentionally fixed.

13. Document the expected structure of `list.csv`.
Several loop examples assume a specific column order:
`xnatid, patient, date, sub, ses, ...`

Show the expected columns once so users understand what the loop is parsing.

14. Rename or reorganize the `lobi_scripts` subsection for clarity.
The current `3.1 lobi_scripts` section is more of a workflow note than a real subsection.
Consider renaming it to something like:
`Managing local pipeline scripts`
or merging it into the MRIQC/fMRIPrep section.

15. Clarify whether copied scripts should be run with `bash` or directly.
Some examples use:
`bash {bidsdir}/code/run_mriqc.sh ...`

Others omit `bash` and call the script path directly.
Choose one style or explain why both are acceptable.

16. Explain why MRIQC is run directly but fMRIPrep is only previewed.
The notebook executes the MRIQC example, but only previews the fMRIPrep command with `echo`.
Add one sentence explaining that fMRIPrep is intentionally shown as a preview because it is heavier and slower.

17. Make loop examples consistent with single-subject examples.
If the recommended pattern is `bash {bidsdir}/code/run_fmriprep_min.sh ...`, use that same style in the `while` loop and GNU Parallel examples too.

18. Review notebook outputs and remove stale or distracting output.
Some saved outputs are useful, but some are leftovers from older runs and may confuse readers.
Decide whether to:
- clear outputs entirely
- or keep only outputs that help explain expected behavior

19. Expand the explanation of what `lobi_scripts install` and `lobi_scripts update` do.
Users would benefit from one more sentence about when to use each command and whether rerunning them is safe.

20. Add a transition into the “Preinstalled software” and “Loading software” sections.
The tutorial shifts abruptly from MRI pipelines to general software usage.
One short paragraph would help explain why these sections are included and when users will need them.

21. Replace the final FAQ placeholder with a direct reference.
Instead of `# FAQ moved to FAQ.md`, add a short note pointing users explicitly to `FAQ.md` or link it directly if notebook rendering supports it.

22. Add a short “happy path” summary near the top.
Summarize the recommended sequence in one compact checklist:
- connect to XNAT
- download `list.csv`
- prepare the BIDS directory
- create or link `config.json`
- run conversion
- copy local scripts
- run MRIQC or fMRIPrep

## Main message to preserve across the tutorial

- The notebook should be easy to follow for users switching between Jupyter and Terminal.
- Paths, section names, and command styles should stay consistent.
- Examples should clearly distinguish between preview commands and commands that actually run work.
- Project-specific files should live in the BIDS project directory, not in shared repositories.
