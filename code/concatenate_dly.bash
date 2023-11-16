#!/usr/bin/env bash

mkdir -p data/temp

tar Oxvzf data/ghcnd_all.tar.gz | grep "PRCP" | split -l 500000 -d -a 2 - "data/temp/PRCP_chunk_" 
gzip data/temp/PRCP_chunk_*

code/read_split_dly_files.R

rm -rf data/temp

### extract tar files, run through grep that takes any line that contains "PRCP" (precipitation)then compress and store in directory

### tar Oxvzf practice.tar.gz > practice.output # practice output is intermediate file we do not want
### gzip -f practice.output