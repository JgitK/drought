#!/usr/bin/env Rscript

# Create sample drought data for development
library(jsonlite)

set.seed(42)

# Create realistic sample data covering major world regions
sample_locations <- list(
  # North America
  list(lon = -122.4, lat = 37.8, name = "San Francisco", z = -1.5),
  list(lon = -118.2, lat = 34.0, name = "Los Angeles", z = -2.1),
  list(lon = -87.6, lat = 41.9, name = "Chicago", z = 0.8),
  list(lon = -73.9, lat = 40.7, name = "New York", z = 1.2),
  list(lon = -95.4, lat = 29.8, name = "Houston", z = 0.3),

  # Europe
  list(lon = -0.1, lat = 51.5, name = "London", z = 1.5),
  list(lon = 2.3, lat = 48.9, name = "Paris", z = 0.9),
  list(lon = 13.4, lat = 52.5, name = "Berlin", z = -0.5),
  list(lon = 12.5, lat = 41.9, name = "Rome", z = -1.8),
  list(lon = -3.7, lat = 40.4, name = "Madrid", z = -2.3),

  # Asia
  list(lon = 139.7, lat = 35.7, name = "Tokyo", z = 1.1),
  list(lon = 116.4, lat = 39.9, name = "Beijing", z = -1.2),
  list(lon = 121.5, lat = 31.2, name = "Shanghai", z = 0.7),
  list(lon = 77.2, lat = 28.6, name = "Delhi", z = -1.9),
  list(lon = 72.9, lat = 19.1, name = "Mumbai", z = 1.8),

  # Australia
  list(lon = 151.2, lat = -33.9, name = "Sydney", z = -1.3),
  list(lon = 144.9, lat = -37.8, name = "Melbourne", z = -0.8),

  # South America
  list(lon = -58.4, lat = -34.6, name = "Buenos Aires", z = 0.5),
  list(lon = -47.9, lat = -15.8, name = "Brasilia", z = 1.6),
  list(lon = -77.0, lat = -12.0, name = "Lima", z = -2.0),

  # Africa
  list(lon = 18.4, lat = -33.9, name = "Cape Town", z = -2.2),
  list(lon = 31.2, lat = 30.0, name = "Cairo", z = -1.1),
  list(lon = 28.0, lat = -26.2, name = "Johannesburg", z = 0.4)
)

# Add random nearby points to make it look more realistic
features <- list()

for (loc in sample_locations) {
  # Add main location
  features[[length(features) + 1]] <- list(
    type = "Feature",
    geometry = list(
      type = "Point",
      coordinates = c(loc$lon, loc$lat)
    ),
    properties = list(
      z_score = loc$z,
      z_score_raw = loc$z + rnorm(1, 0, 0.1),
      current_prcp = abs(rnorm(1, 5, 2)),
      historical_mean = abs(rnorm(1, 5, 1)),
      historical_sd = abs(rnorm(1, 1, 0.3)),
      years_of_data = sample(50:100, 1),
      latitude = loc$lat,
      longitude = loc$lon
    )
  )

  # Add 5-10 nearby points with similar Z-scores
  n_nearby <- sample(5:10, 1)
  for (i in 1:n_nearby) {
    nearby_lon <- loc$lon + rnorm(1, 0, 2)
    nearby_lat <- loc$lat + rnorm(1, 0, 1.5)
    nearby_z <- loc$z + rnorm(1, 0, 0.5)

    # Clamp Z-score to [-2, 2]
    nearby_z <- max(-2, min(2, nearby_z))

    features[[length(features) + 1]] <- list(
      type = "Feature",
      geometry = list(
        type = "Point",
        coordinates = c(nearby_lon, nearby_lat)
      ),
      properties = list(
        z_score = round(nearby_z, 2),
        z_score_raw = round(nearby_z + rnorm(1, 0, 0.1), 2),
        current_prcp = round(abs(rnorm(1, 5, 2)), 2),
        historical_mean = round(abs(rnorm(1, 5, 1)), 2),
        historical_sd = round(abs(rnorm(1, 1, 0.3)), 2),
        years_of_data = sample(50:100, 1),
        latitude = nearby_lat,
        longitude = nearby_lon
      )
    )
  }
}

# Create GeoJSON structure
geojson <- list(
  type = "FeatureCollection",
  metadata = list(
    date_range = "December 14, 2025 to January 13, 2026",
    date_start = "2025-12-14",
    date_end = "2026-01-13",
    description = "Sample precipitation Z-scores for the past 30 days (DEVELOPMENT DATA)",
    source = "NOAA GHCN Daily Data (simulated)",
    generated = as.character(Sys.Date()),
    is_sample = TRUE
  ),
  features = features
)

# Create data directory if it doesn't exist
dir.create("data", showWarnings = FALSE)

# Export as GeoJSON
write_json(
  geojson,
  "data/drought_data.geojson",
  pretty = TRUE,
  auto_unbox = TRUE
)

write_json(
  geojson,
  "data/drought_data.min.geojson",
  auto_unbox = TRUE
)

cat("Created sample GeoJSON with", length(features), "points\n")
cat("Files created:\n")
cat("  - data/drought_data.geojson\n")
cat("  - data/drought_data.min.geojson\n")
