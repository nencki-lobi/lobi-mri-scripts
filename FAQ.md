# FAQ

1. **Where are my files?**

> All files are stored on the DRAGON storage system in Mikołajki. Whether you work in `$HOME`, `./shared_storage`, or use a dedicated network drive, your files will remain secure and available at full speed.

2. **How can I upload my own files?**

> * Use drag and drop for files below 500 MB in total. This limit also applies when moving files between folders in the browser window, so use the Terminal to move larger files internally.
> * Use `xnat_dcm2bids` and related tools to download DICOMs from XNAT.
> * Use a dedicated network drive, which can be accessed from both Neurodesk and your personal computer.

3. **Where should I store my files?**

> * The best option is to use **a dedicated network drive**. A network drive can be created upon request. See below for instructions.
> * The `$HOME` directory (1 TB) is dedicated to your personal needs. No one except you and the administrator can access or delete files stored there.
> * The `./shared_storage` directory (5 TB) is dedicated to collaboration and sharing data between users. Anyone can access or delete files stored there.

4. **I want a dedicated network drive for my research group project. How do I request it?**

> You need to submit a request via the Helpdesk. Please provide:
>
> * **Location → DRAGON**
> * Lab ID (e.g., N601, N417)
> * Name of the PI and all members
> * Project name
> * Required size (in TB)
>
> **Your disk will be accessible from Neurodesk and any other computer on the local network.**

5. **How can I access my dedicated network drive from Neurodesk?**

> To mount your dedicated network drive in Neurodesk, follow these steps:
> 1) In `$HOME`, create a file named `cifs_mounts.conf`.
> 2) In the file, add the following information:
>```
>//dragon.nencki.edu.pl/417-maestro/PROJECT,PROJECT,USERNAME@nencki.ibd, PASSWORD  
>```
> * **Do not use spaces** or any other extra characters.
> * Add an empty line at the end. The file should contain two lines in total.
> * The second `PROJECT` is the target directory in your workspace.
> 
> 3) Apply the changes: **File → Hub Control → Stop and Start**.
> 4) You should now see the new directory `PROJECT` in `$HOME`.

6. **What happens if I shut down or restart the environment?**

> Don’t worry, your data will be preserved. However, all installed programs will be removed because a fresh version of the Neurodesk environment will be loaded.

7. **How can I access an HTML report from MRIQC and fMRIPrep?**

> You can start an HTTP server in the directory containing your HTML files by running `python -m http.server 8000`. You will then be able to access the server via Jupyter's proxy at [neurodesk.nencki.edu.pl/user/YOUR_NAME/proxy/8000/](https://neurodesk.nencki.edu.pl/user/YOUR_NAME/proxy/8000/). Make sure the URL ends with a **slash**.

8. **Where can I find more information about the new tools?**

> Check out the Neurodesktop website and tutorials: [https://neurodesk.org/example-notebooks/intro.html](https://neurodesk.org/example-notebooks/intro.html)
>
> Visit our GitHub repositories:
> * [https://github.com/nencki-lobi/lobi-mri-scripts](https://github.com/nencki-lobi/lobi-mri-scripts)
> * [https://github.com/nencki-lobi/xnat_dcm2bids](https://github.com/nencki-lobi/xnat_dcm2bids)

9. What should be my backup strategy?

> Try to store your data on a dedicated network drive. If Neurodesk is unavailable, you should still be able to access your files from any other computer on the local network.
>
> Use GitHub for version control of your scripts and configurations, for example `bids-dir/code`.
>
> Consider using an additional network drive or cloud storage for important files. We recommend using RESTIC for backups on local network drives. For cloud storage, consider using GIN G-Node. See more in [Data Management (to be created)](https://intra.lobi.nencki.edu.pl/).
