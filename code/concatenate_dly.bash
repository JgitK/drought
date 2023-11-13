#!/usr/bin/env bash

### tar Oxvzf practice.tar.gz > practice.output # practice output is intermediate file we do not want
### gzip -f practice.output

tar Oxvzf data/ghcnd_all.tar.gz | grep PRCP | gzip > data/ghcnd_cat.gz

### extract tar files, run through grep that takes any line that contains "PRCP" (precipitation)then compress and store in directory