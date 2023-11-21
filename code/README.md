11/4/23
Created bash scripts for getting data from NOAA via wget 

11/5/23
Created snakemake file to automate file download with dependencies acct'd for

11/7/23
Used "archive" package to extract tar, files; ghcnd_all is too big to decompress, would take 17 days.

11/13/23
Used "O" operator in tar extract program to extract and concatenate files from tarball, now using split to lower RAM usage

11/21/23
Trying to use r-showtext but does not seem to be available for download in my channel. Weird. Can only install locally in R console.