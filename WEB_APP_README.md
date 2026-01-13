# Interactive Drought Map - Development Guide

## Overview

The drought monitoring system now includes an **interactive web application** built with modern web technologies. Users can explore precipitation data dynamically with zoom, pan, location search, and detailed station information.

## Tech Stack

- **Vite** - Fast build tool and dev server
- **Leaflet.js** - Interactive mapping library
- **Vanilla JavaScript** - No heavy frameworks, just fast performance
- **OpenStreetMap** - Free base map tiles (CartoDB Dark theme)
- **Nominatim API** - Free geocoding for location search

## Quick Start

### Development Mode

```bash
# Install dependencies (first time only)
npm install

# Start dev server
npm run dev
```

Then open http://localhost:3000/drought/ in your browser.

### Production Build

```bash
# Build for production
npm run build

# Preview production build locally
npm run preview
```

Output goes to `dist/` directory.

## Features

### 1. Interactive Map
- Pan and zoom to explore any region
- Dark theme matching the original design
- Responsive on mobile and desktop

### 2. Location Search
- Search for any city/location (e.g., "Los Angeles", "Tokyo", "London")
- Auto-complete suggestions from OpenStreetMap
- Automatically flies to location and shows nearest weather station

### 3. Station Details
- Click any point to see detailed precipitation statistics
- Z-score with color-coded severity
- Current vs. historical average comparison
- Number of years of data available
- Exact coordinates

### 4. Visual Design
- Z-score color gradient (red = dry, white = normal, blue = wet)
- Hover effects for better interactivity
- Clean, minimal interface
- Matches original dark theme aesthetic

## Data Flow

```
NOAA GHCN Data
    ↓
R Processing (read_split_dly_files.R)
    ↓
GeoJSON Export (export_geojson.R)
    ↓
data/drought_data.geojson
    ↓
Vite Build (copies to dist/data/)
    ↓
Interactive Web App (Leaflet.js)
```

## File Structure

```
/home/user/drought/
├── src/
│   ├── main.js           # App logic, map, search
│   └── style.css         # Styling
├── index.html            # Entry point
├── vite.config.js        # Build configuration
├── package.json          # Dependencies
├── data/
│   └── drought_data.geojson  # Exported data
└── dist/                 # Production build output
    ├── index.html
    ├── assets/           # Bundled JS/CSS
    └── data/             # GeoJSON data
```

## Snakemake Integration

The web app is integrated into the Snakemake workflow:

```bash
# Run full pipeline (downloads data, processes, builds web app)
snakemake --cores 1

# Build just the web app (if data exists)
snakemake dist/index.html --cores 1
```

### New Snakemake Rules:

1. **export_geojson** - Converts processed data to GeoJSON format
2. **build_webapp** - Runs Vite build to create production bundle

## Deployment

### GitHub Pages

1. Build the app: `npm run build`
2. The `dist/` folder contains everything needed
3. Configure GitHub Pages to serve from the `dist/` folder (or copy contents to root)
4. Update `base` in `vite.config.js` if using a different path

### Custom Server

Simply copy the `dist/` folder to your web server. It's 100% static files, no backend required.

## Development Tips

### Hot Reload
Changes to JS/CSS automatically reload in the browser during dev mode.

### Testing with Real Data
When you run the full Snakemake pipeline with real NOAA data:
1. `code/export_geojson.R` will generate real GeoJSON
2. Rebuild with `npm run build`
3. The app will show actual weather station data

### Sample Data
The current `data/drought_data.geojson` contains sample data for development. Look for the `is_sample: true` flag in the metadata.

## Performance

- **Bundle size**: ~155KB JS (45KB gzipped)
- **Load time**: <1 second on fast connections
- **Data size**: Varies based on number of stations (typically 1-5MB GeoJSON)

## Browser Support

- Chrome/Edge (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)
- Mobile browsers (iOS Safari, Chrome Android)

## Future Enhancements

See the main analysis for three strategic improvement plans:
- Plan A: Climate Researcher Platform
- Plan B: Public Awareness Portal (current direction)
- Plan C: Real-Time Agricultural Tool
