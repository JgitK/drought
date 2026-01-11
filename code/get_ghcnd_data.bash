#!/usr/bin/env bash

file=$1

# Create data directory if it doesn't exist
mkdir -p data

# Remove old file if it exists (force flag prevents errors if file doesn't exist)
rm -f data/$file

wget -P data/ https://www.ncei.noaa.gov/pub/data/ghcn/daily/$file