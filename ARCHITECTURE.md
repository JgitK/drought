# Interactive Drought Map - Architecture & Learning Guide

## Overview

This document explains every building block of the interactive drought monitoring system, what knowledge you need, and how to build it from scratch.

---

## 🎯 **High-Level Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA PIPELINE (R)                        │
│  NOAA Raw Data → Processing → Statistics → GeoJSON Export  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │ drought_data  │
              │  .geojson     │
              └───────┬───────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  WEB APPLICATION                            │
│  HTML → CSS → JavaScript (Leaflet.js) → Interactive Map    │
└─────────────────────────────────────────────────────────────┘
```

**Two completely separate systems:**
1. **Backend/Data Pipeline**: R scripts that process climate data
2. **Frontend/Web App**: JavaScript application that displays it

They communicate through **one file**: `drought_data.geojson`

---

## 📚 **Knowledge Prerequisites**

### **Tier 1: Absolute Basics (You Need These)**
- **HTML**: Structure of web pages (tags, elements)
- **CSS**: Styling (colors, layouts, positioning)
- **JavaScript**: Programming logic (variables, functions, loops)
- **JSON**: Data format (how to structure data)

### **Tier 2: Intermediate (Helpful but Learnable)**
- **GeoJSON**: JSON format specifically for geographic data
- **REST APIs**: How to fetch data from the internet
- **DOM Manipulation**: How JavaScript changes HTML
- **Event Handlers**: Responding to clicks, typing, etc.

### **Tier 3: Advanced (Can Skip Initially)**
- **Build Tools** (Vite): Bundle/optimize code for production
- **Package Managers** (npm): Install libraries
- **Version Control** (git): Track changes
- **R Programming**: For data processing (or use any language)

---

## 🧱 **Component Breakdown**

### **Component 1: The Map Library (Leaflet.js)**

**What it is:**
- A JavaScript library that creates interactive maps
- Free, open-source, well-documented
- 38KB (tiny compared to Google Maps API)

**What you need to know:**
```javascript
// 1. Create a map
const map = L.map('map').setView([latitude, longitude], zoomLevel);

// 2. Add base tiles (the actual map imagery)
L.tileLayer('https://.../{z}/{x}/{y}.png').addTo(map);

// 3. Add markers/shapes
L.circleMarker([lat, lon], {options}).addTo(map);

// 4. Add popups
marker.bindPopup('<div>Your HTML content</div>');
```

**Learn it:**
- Official docs: https://leafletjs.com/reference.html
- Tutorial: https://leafletjs.com/examples.html
- Time to learn basics: 2-3 hours

**Why we chose it:**
- No API keys needed
- Works offline (with downloaded tiles)
- Easy to customize
- Large ecosystem of plugins

---

### **Component 2: GeoJSON Data Format**

**What it is:**
A standardized way to represent geographic features (points, lines, polygons) with properties.

**Structure:**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [-122.4, 37.8]  // [longitude, latitude]
      },
      "properties": {
        "name": "San Francisco",
        "z_score": -1.5,
        "current_prcp": 3.2
      }
    }
  ]
}
```

**Key Points:**
- **Coordinates are [longitude, latitude]** (not lat/lon!)
- Geometry types: Point, LineString, Polygon, MultiPoint, etc.
- Properties can be anything (your custom data)
- Leaflet understands GeoJSON natively

**Why this matters:**
- Industry standard for geo data
- Works with ALL mapping libraries
- Easy to generate from any programming language
- Human-readable JSON

**Learn it:**
- Spec: https://geojson.org/
- Time to understand: 30 minutes

---

### **Component 3: The Data Pipeline (R Scripts)**

**Purpose:** Transform raw NOAA climate data into usable GeoJSON

**Flow:**
```
Raw NOAA Data (.dly files)
    ↓
Extract & Filter (Bash + grep)
    ↓
Parse Fixed-Width Format (R: read_fwf)
    ↓
Calculate Statistics (R: dplyr, group_by, summarize)
    ↓
Compute Z-scores (R: mean, sd)
    ↓
Export to GeoJSON (R: jsonlite)
```

**Key R Concepts Used:**

**1. Reading Fixed-Width Files:**
```r
# NOAA data looks like:
# USC00045721195901PRCP  123  456  789...
# ID: 11 chars, Year: 4, Month: 2, Element: 4, then 31 days × 4 fields

widths <- c(11, 4, 2, 4, rep(c(5,1,1,1), 31))
read_fwf(file, fwf_widths(widths, headers))
```

**2. Data Transformation (tidyverse):**
```r
data %>%
  filter(element == "PRCP") %>%           # Only precipitation
  pivot_longer(starts_with("VALUE")) %>%  # Wide to long format
  group_by(id, year) %>%                  # Group by station & year
  summarize(total = sum(prcp))            # Calculate totals
```

**3. Z-Score Calculation:**
```r
# Z-score = (observation - mean) / standard_deviation
# Tells you how many std devs away from normal

data %>%
  group_by(latitude, longitude) %>%
  mutate(z_score = (mean_prcp - mean(mean_prcp)) / sd(mean_prcp))
```

**4. GeoJSON Export:**
```r
library(jsonlite)

geojson <- list(
  type = "FeatureCollection",
  features = pmap(data, function(lon, lat, z, ...) {
    list(
      type = "Feature",
      geometry = list(type = "Point", coordinates = c(lon, lat)),
      properties = list(z_score = z, ...)
    )
  })
)

write_json(geojson, "output.geojson")
```

**Could you use Python instead?**
Absolutely! Here's the equivalent:

```python
import pandas as pd
import json

# Read data
df = pd.read_fwf('data.txt', widths=widths)

# Calculate z-scores
df['z_score'] = (df['prcp'] - df.groupby(['lat','lon'])['prcp'].transform('mean')) / \
                 df.groupby(['lat','lon'])['prcp'].transform('std')

# Export GeoJSON
features = []
for _, row in df.iterrows():
    features.append({
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [row['lon'], row['lat']]},
        "properties": {"z_score": row['z_score']}
    })

with open('output.geojson', 'w') as f:
    json.dump({"type": "FeatureCollection", "features": features}, f)
```

**The Language Doesn't Matter:**
- Input: Raw climate data
- Output: GeoJSON file
- Use whatever you're comfortable with: R, Python, Node.js, Go, etc.

---

### **Component 4: The Web Application (JavaScript)**

**File Structure:**
```
index.html       # Structure (what elements exist)
style.css        # Appearance (how it looks)
main.js          # Behavior (what it does)
```

**index.html - The Structure:**
```html
<!DOCTYPE html>
<html>
<head>
    <!-- Load external libraries -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
</head>
<body>
    <div id="map"></div>  <!-- Map goes here -->
    <input id="search" />  <!-- Search box -->
    <script src="main.js"></script>
</body>
</html>
```

**style.css - The Appearance:**
```css
#map {
    width: 100%;
    height: 600px;
    background-color: #000;
}

.search-box {
    position: absolute;
    top: 20px;
    left: 20px;
    z-index: 1000;  /* Above the map */
}
```

**main.js - The Logic:**

**Step 1: Load the data**
```javascript
// Fetch the GeoJSON file
const response = await fetch('drought_data.geojson');
const data = await response.json();
```

**Step 2: Initialize the map**
```javascript
const map = L.map('map').setView([20, 0], 2);

// Add base tiles
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap'
}).addTo(map);
```

**Step 3: Color code based on data**
```javascript
function getColor(zScore) {
    if (zScore <= -2) return '#ef8a62';  // Red (dry)
    if (zScore <= 0) return '#f5f5f5';   // White (normal)
    return '#67a9cf';                    // Blue (wet)
}
```

**Step 4: Add data to map**
```javascript
L.geoJSON(data, {
    pointToLayer: (feature, latlng) => {
        return L.circleMarker(latlng, {
            radius: 8,
            fillColor: getColor(feature.properties.z_score),
            color: '#000',
            weight: 1,
            fillOpacity: 0.7
        });
    },
    onEachFeature: (feature, layer) => {
        layer.bindPopup(`Z-score: ${feature.properties.z_score}`);
    }
}).addTo(map);
```

**Step 5: Add search functionality**
```javascript
async function searchLocation(query) {
    // Use Nominatim (free geocoding API)
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${query}`;
    const response = await fetch(url);
    const results = await response.json();

    // Fly to first result
    if (results.length > 0) {
        const { lat, lon } = results[0];
        map.flyTo([lat, lon], 6);
    }
}

document.getElementById('search').addEventListener('input', (e) => {
    searchLocation(e.target.value);
});
```

**That's the entire application in ~50 lines of JavaScript!**

---

### **Component 5: Build System (Vite)**

**What problem does it solve?**

**Without a build system:**
```html
<!-- You have to manually include everything -->
<script src="leaflet.js"></script>
<script src="your-code.js"></script>
<link rel="stylesheet" href="style.css">
```

**With Vite:**
```javascript
// Import what you need
import L from 'leaflet';
import './style.css';

// Vite bundles it all into optimized files
```

**What Vite does:**
1. **Bundles** multiple JS files into one
2. **Minifies** code (removes whitespace, shortens names)
3. **Optimizes** images and assets
4. **Hot reload** during development (changes show instantly)
5. **Handles** modern JavaScript features (ES6+)

**Key Vite concepts:**

```javascript
// vite.config.js
export default {
  base: '/drought/',        // URL base path
  build: {
    outDir: 'dist',         // Where to put built files
  },
  server: {
    port: 3000              // Dev server port
  }
}
```

**You don't NEED Vite:**
- The `standalone.html` file works without any build system
- Vite just makes development faster and production smaller

**Alternatives:**
- Webpack (more complex, older)
- Parcel (similar to Vite)
- Rollup (lower-level)
- No bundler (just load scripts manually)

---

## 🔄 **How Data Flows Through the System**

### **Pipeline Flow:**

```
1. NOAA Server (data source)
   ↓ wget/curl (download)

2. ghcnd_all.tar.gz (compressed archive)
   ↓ tar + grep (extract & filter)

3. PRCP_chunk_*.gz (precipitation chunks)
   ↓ R: read_fwf (parse format)

4. R data.frame (in-memory table)
   ↓ dplyr (transform & aggregate)

5. Station × Year × Precipitation table
   ↓ Z-score calculation

6. Station × Z-score table
   ↓ jsonlite (export)

7. drought_data.geojson (output file)
   ↓ fetch() in browser

8. JavaScript object (in browser memory)
   ↓ Leaflet.geoJSON()

9. Interactive map on screen!
```

### **User Interaction Flow:**

```
User types "Tokyo" in search box
   ↓
JavaScript: keypress event fires
   ↓
Fetch: nominatim.openstreetmap.org/search?q=Tokyo
   ↓
API returns: [{name: "Tokyo", lat: 35.7, lon: 139.7}]
   ↓
JavaScript: map.flyTo([35.7, 139.7], 6)
   ↓
Leaflet animates map to Tokyo
   ↓
Find nearest station with data
   ↓
Open popup with Z-score info
```

---

## 🛠️ **How to Build This From Scratch**

### **Phase 1: Static Map (1-2 hours)**

**Goal:** Display a basic interactive map

```html
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
</head>
<body>
    <div id="map" style="width: 100%; height: 600px;"></div>

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        const map = L.map('map').setView([37.8, -122.4], 10);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

        // Add a marker
        L.marker([37.8, -122.4])
            .bindPopup('San Francisco')
            .addTo(map);
    </script>
</body>
</html>
```

**What you learn:**
- How Leaflet works
- How to add tiles
- How to add markers
- Basic HTML structure

---

### **Phase 2: Add Sample Data (2-3 hours)**

**Goal:** Display multiple points with colors

```javascript
// Hardcode some data first
const stations = [
    {lat: 37.8, lon: -122.4, z_score: -1.5},
    {lat: 40.7, lon: -73.9, z_score: 1.2},
    {lat: 34.0, lon: -118.2, z_score: -2.0}
];

// Color function
function getColor(z) {
    return z < -1 ? 'red' : z > 1 ? 'blue' : 'white';
}

// Add to map
stations.forEach(s => {
    L.circleMarker([s.lat, s.lon], {
        radius: 10,
        fillColor: getColor(s.z_score),
        fillOpacity: 0.7
    })
    .bindPopup(`Z-score: ${s.z_score}`)
    .addTo(map);
});
```

**What you learn:**
- JavaScript arrays and loops
- Functions
- Conditional logic
- Circle markers

---

### **Phase 3: Load Real Data (2-3 hours)**

**Goal:** Fetch data from a file instead of hardcoding

**Create a simple GeoJSON file (data.geojson):**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {"type": "Point", "coordinates": [-122.4, 37.8]},
      "properties": {"z_score": -1.5}
    }
  ]
}
```

**Load it in JavaScript:**
```javascript
async function loadData() {
    const response = await fetch('data.geojson');
    const data = await response.json();

    L.geoJSON(data, {
        pointToLayer: (feature, latlng) => {
            return L.circleMarker(latlng, {
                fillColor: getColor(feature.properties.z_score)
            });
        }
    }).addTo(map);
}

loadData();
```

**What you learn:**
- Async/await
- Fetch API
- GeoJSON format
- How Leaflet processes GeoJSON

---

### **Phase 4: Add Search (3-4 hours)**

**Goal:** Let users search for locations

```html
<input id="search" type="text" placeholder="Search...">
```

```javascript
document.getElementById('search').addEventListener('input', async (e) => {
    const query = e.target.value;
    if (query.length < 3) return;

    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${query}`;
    const response = await fetch(url);
    const results = await response.json();

    if (results[0]) {
        map.flyTo([results[0].lat, results[0].lon], 10);
    }
});
```

**What you learn:**
- Event listeners
- API calls
- Debouncing (optional: don't search on every keystroke)
- URL encoding

---

### **Phase 5: Style It (2-3 hours)**

**Goal:** Make it look professional

```css
body {
    margin: 0;
    font-family: 'Segoe UI', sans-serif;
    background: #000;
    color: #fff;
}

#map {
    height: 100vh;
}

.search-box {
    position: absolute;
    top: 20px;
    left: 20px;
    z-index: 1000;
    background: rgba(0,0,0,0.8);
    padding: 10px;
    border-radius: 8px;
}

input {
    background: #222;
    border: 1px solid #444;
    color: #fff;
    padding: 8px;
    border-radius: 4px;
}
```

**What you learn:**
- CSS positioning (absolute, relative)
- Z-index (layering)
- Flexbox/Grid (layout)
- Responsive design

---

### **Phase 6: Add Data Processing (varies)**

**Goal:** Generate the GeoJSON from real data

**Option A: Python**
```python
import pandas as pd
import json

# Read your data source
df = pd.read_csv('weather_data.csv')

# Calculate z-scores
df['z_score'] = (df['prcp'] - df.groupby('station')['prcp'].transform('mean')) / \
                 df.groupby('station')['prcp'].transform('std')

# Export
features = [{
    "type": "Feature",
    "geometry": {"type": "Point", "coordinates": [row.lon, row.lat]},
    "properties": {"z_score": row.z_score}
} for _, row in df.iterrows()]

with open('data.geojson', 'w') as f:
    json.dump({"type": "FeatureCollection", "features": features}, f)
```

**Option B: R (what we used)**
```r
library(tidyverse)
library(jsonlite)

data <- read_csv('weather_data.csv') %>%
  group_by(station) %>%
  mutate(z_score = (prcp - mean(prcp)) / sd(prcp))

geojson <- list(
  type = "FeatureCollection",
  features = pmap(data, ~list(
    type = "Feature",
    geometry = list(type = "Point", coordinates = c(..lon, ..lat)),
    properties = list(z_score = ..z_score)
  ))
)

write_json(geojson, 'data.geojson')
```

**What you learn:**
- Data processing in your language of choice
- Statistical calculations
- File I/O
- JSON generation

---

## 📊 **Key Concepts Explained**

### **1. Z-Score (Statistical Concept)**

**What it is:**
A measure of how unusual a value is compared to historical norms.

**Formula:**
```
Z = (X - μ) / σ

Where:
X = Current observation
μ = Mean of all observations
σ = Standard deviation
```

**Interpretation:**
- Z = 0: Exactly average
- Z = -1: One standard deviation below average (drier)
- Z = +2: Two standard deviations above average (wetter)
- Z < -2: Very unusual (drought conditions)
- Z > +2: Very unusual (flood conditions)

**Example:**
```
Historical precipitation: [4, 5, 6, 5, 4] cm
Mean (μ) = 4.8 cm
Std Dev (σ) = 0.84 cm

This month: 2 cm
Z-score = (2 - 4.8) / 0.84 = -3.33

Interpretation: This month is 3.3 standard deviations drier than normal!
```

---

### **2. Fixed-Width File Format**

**What it is:**
A text format where each field occupies a specific number of characters.

**Example (NOAA format):**
```
USC00045721195901PRCP  123  456  789
│          ││  ││    │    │    │
│          ││  ││    │    │    └─ Day 3 value
│          ││  ││    │    └────── Day 2 value
│          ││  ││    └─────────── Day 1 value
│          ││  │└──────────────── Element (PRCP)
│          ││  └───────────────── Month (01)
│          │└──────────────────── Year (1959)
│          └───────────────────── Station ID
└──────────────────────────────── Always 11 chars
```

**Why it's used:**
- Efficient for very large files
- No delimiters needed
- Fixed record size = fast seeking

**How to parse:**
```r
# Define widths
widths <- c(11, 4, 2, 4, 5, 5, 5)

# Read
read_fwf(file, fwf_widths(widths, col_names))
```

---

### **3. REST APIs (Web Services)**

**What it is:**
A way to request data from a server over HTTP.

**Example (Nominatim Geocoding):**

**Request:**
```
GET https://nominatim.openstreetmap.org/search?format=json&q=Tokyo
```

**Response:**
```json
[{
  "display_name": "Tokyo, Japan",
  "lat": "35.6762",
  "lon": "139.6503"
}]
```

**In JavaScript:**
```javascript
const response = await fetch('https://api.example.com/data');
const data = await response.json();
console.log(data);
```

**Key concepts:**
- **URL**: The address of the API
- **Query parameters**: ?format=json&q=Tokyo
- **HTTP methods**: GET (read), POST (create), PUT (update)
- **Response format**: Usually JSON

---

### **4. Event-Driven Programming**

**What it is:**
Code that runs in response to user actions.

**Examples:**

```javascript
// When user clicks a button
button.addEventListener('click', () => {
    alert('Clicked!');
});

// When user types
input.addEventListener('input', (event) => {
    console.log('You typed:', event.target.value);
});

// When map is dragged
map.on('moveend', () => {
    console.log('Map moved to:', map.getCenter());
});
```

**Why it matters:**
- Web apps are interactive
- You can't predict when users will click/type
- Events let you respond to user actions

---

## 🎓 **Learning Path**

### **Total Beginner → Working Map: 40-60 hours**

**Week 1: HTML/CSS/JS Basics (15-20 hours)**
- FreeCodeCamp: Responsive Web Design
- MDN Web Docs: JavaScript basics
- Build: A simple static webpage

**Week 2: JavaScript & APIs (10-15 hours)**
- Async/await
- Fetch API
- JSON
- Build: Fetch data from a public API and display it

**Week 3: Leaflet.js (10-15 hours)**
- Leaflet documentation
- Interactive examples
- Build: A map with markers

**Week 4: Data Processing (5-10 hours)**
- Pick Python or R
- Read CSV files
- Calculate statistics
- Export JSON
- Build: Process sample data into GeoJSON

**Week 5+: Integration & Polish**
- Combine everything
- Style it
- Add features
- Deploy it

---

## 🔧 **Tools You Need**

### **Essential:**
- **Text Editor**: VS Code (free, excellent)
- **Web Browser**: Chrome (has best dev tools)
- **Terminal**: For running commands

### **Nice to Have:**
- **Git**: Version control
- **Node.js**: For npm packages
- **Python/R**: For data processing

### **Free Resources:**
- **Learn HTML/CSS/JS**: freeCodeCamp.org
- **Leaflet Docs**: leafletjs.com
- **MDN Web Docs**: developer.mozilla.org
- **Stack Overflow**: When you're stuck

---

## 💡 **Common Pitfalls & Solutions**

### **1. "My map doesn't show!"**

**Likely causes:**
- Didn't set a height on the map div
- Forgot to include Leaflet CSS
- JavaScript error (check console)

**Solution:**
```css
#map { height: 600px; }  /* Must have height! */
```

### **2. "Data won't load!"**

**Likely causes:**
- CORS policy (can't load local files)
- Wrong file path
- Typo in fetch URL

**Solution:**
- Use a local server (Python: `python -m http.server`)
- Check browser console for errors
- Verify file path

### **3. "Coordinates are backwards!"**

**GeoJSON uses [longitude, latitude]**
**Leaflet uses [latitude, longitude]**

```javascript
// GeoJSON
{"coordinates": [-122.4, 37.8]}  // [lon, lat]

// Leaflet
L.marker([37.8, -122.4])  // [lat, lon]
```

### **4. "Colors don't update!"**

Make sure you're calling `setStyle()` or recreating markers:

```javascript
// Wrong
marker.options.fillColor = 'red';  // Doesn't update

// Right
marker.setStyle({fillColor: 'red'});
```

---

## 🚀 **Next Steps & Enhancements**

### **Beginner Enhancements:**
1. Add more data properties (temperature, humidity)
2. Change color schemes
3. Add a legend
4. Make it mobile-friendly

### **Intermediate Enhancements:**
1. Time-series charts (show trends over time)
2. Comparison mode (this year vs last year)
3. Custom markers (icons for different data types)
4. Export data as CSV

### **Advanced Enhancements:**
1. Animated time-lapse
2. Real-time data updates
3. Heatmap layer
4. 3D visualization
5. Machine learning predictions

---

## 📚 **Additional Resources**

**Leaflet:**
- Official docs: https://leafletjs.com/
- Plugins: https://leafletjs.com/plugins.html
- Examples: https://leafletjs.com/examples.html

**GeoJSON:**
- Specification: https://geojson.org/
- Validator: http://geojsonlint.com/

**JavaScript:**
- MDN: https://developer.mozilla.org/en-US/docs/Web/JavaScript
- JavaScript.info: https://javascript.info/

**Data Processing:**
- R for Data Science: https://r4ds.had.co.nz/
- Python Pandas: https://pandas.pydata.org/docs/

**Web Development:**
- FreeCodeCamp: https://www.freecodecamp.org/
- The Odin Project: https://www.theodinproject.com/

---

## 🎯 **Summary**

**Core Skills:**
1. HTML/CSS (structure & style)
2. JavaScript (behavior & logic)
3. Leaflet.js (mapping library)
4. GeoJSON (data format)
5. APIs (fetch data)
6. Data processing (your choice of language)

**Total Lines of Code (excluding libraries):**
- HTML: ~60 lines
- CSS: ~200 lines
- JavaScript: ~250 lines
- R/Python: ~100 lines
- **Total: ~610 lines**

**You built a production-ready web application with just 610 lines of code!**

**Key Takeaway:**
Modern web development is about **composing existing tools** (Leaflet, OpenStreetMap, Nominatim) rather than building everything from scratch. The magic is in knowing what exists and how to combine it.
