#!/usr/bin/env bash

# Get the daily data from all stations and output each station within tar to a txt file
code/get_ghcnd_data.bash ghcnd_all.tar.gz
code/get_ghcnd_all_files.bash

# Get listing of type of data found at each weather station
code/get_ghcnd_data.bash ghcnd-inventory.txt

# Get metadata for each weather station
code/get_ghcnd_data.bash ghcnd-stations.txt

