#!/usr/bin/env Rscript

library(tidyverse)
library(lubridate)
library(glue)
library(jsonlite)

# Read processed precipitation data
prcp_data <- read_tsv("data/ghcnd_tidy.tsv.gz", show_col_types = FALSE)
station_data <- read_tsv("data/ghcnd_regions_years.tsv", show_col_types = FALSE)

# Calculate date range (5-day buffer for data reliability)
buffered_end <- today() - 5
buffered_start <- buffered_end - 30

# Format date range for display
start <- case_when(
    year(buffered_start) != year(buffered_end) ~ format(buffered_start, "%B %-d, %Y"),
    year(buffered_start) == year(buffered_end) ~ format(buffered_start, "%B %-d"),
    TRUE ~ NA_character_
)

end <- case_when(
    month(buffered_start) != month(buffered_end) ~ format(buffered_end, "%B %-d, %Y"),
    month(buffered_start) == month(buffered_end) ~ format(buffered_end, "%-d, %Y"),
    TRUE ~ NA_character_
)

date_range <- glue("{start} to {end}")

# Join precipitation data with station locations and calculate Z-scores
drought_data <- inner_join(prcp_data, station_data, by = "id") %>%
  filter((year != first_year & year != last_year) | year == year(buffered_end)) %>%
  group_by(latitude, longitude, year) %>%
  summarize(mean_prcp = mean(prcp), .groups = "drop") %>%
  group_by(latitude, longitude) %>%
  mutate(
    z_score = (mean_prcp - mean(mean_prcp)) / sd(mean_prcp),
    n = n(),
    mean_historical = mean(mean_prcp),
    sd_historical = sd(mean_prcp)
  ) %>%
  ungroup() %>%
  filter(n >= 50 & year == year(buffered_end)) %>%
  mutate(
    z_score_clamped = case_when(
      z_score > 2 ~ 2,
      z_score < -2 ~ -2,
      TRUE ~ z_score
    ),
    z_score_raw = z_score
  ) %>%
  select(longitude, latitude, z_score = z_score_clamped, z_score_raw,
         mean_prcp, mean_historical, sd_historical, n)

# Create GeoJSON structure
# GeoJSON requires coordinates in [longitude, latitude] order
geojson <- list(
  type = "FeatureCollection",
  metadata = list(
    date_range = as.character(date_range),
    date_start = as.character(buffered_start),
    date_end = as.character(buffered_end),
    description = "Precipitation Z-scores for the past 30 days compared to 50+ year historical average",
    source = "NOAA GHCN Daily Data",
    generated = as.character(today())
  ),
  features = pmap(
    list(
      drought_data$longitude,
      drought_data$latitude,
      drought_data$z_score,
      drought_data$z_score_raw,
      drought_data$mean_prcp,
      drought_data$mean_historical,
      drought_data$sd_historical,
      drought_data$n
    ),
    function(lon, lat, z, z_raw, current, hist_mean, hist_sd, years) {
      list(
        type = "Feature",
        geometry = list(
          type = "Point",
          coordinates = c(lon, lat)
        ),
        properties = list(
          z_score = round(z, 2),
          z_score_raw = round(z_raw, 2),
          current_prcp = round(current, 2),
          historical_mean = round(hist_mean, 2),
          historical_sd = round(hist_sd, 2),
          years_of_data = years,
          latitude = lat,
          longitude = lon
        )
      )
    }
  )
)

# Export as GeoJSON
write_json(
  geojson,
  "data/drought_data.geojson",
  pretty = TRUE,
  auto_unbox = TRUE
)

# Also create a minified version for production
write_json(
  geojson,
  "data/drought_data.min.geojson",
  auto_unbox = TRUE
)

# Print summary
cat(glue("
Exported {length(geojson$features)} weather station points
Date range: {date_range}
Output files:
  - data/drought_data.geojson (human-readable)
  - data/drought_data.min.geojson (minified)
"))
