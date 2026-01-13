import 'leaflet/dist/leaflet.css';
import './style.css';
import L from 'leaflet';

// Fix Leaflet default icon path issue with Vite
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

// State
let map;
let droughtLayer;
let droughtData = null;

// Initialize the map
function initMap() {
  map = L.map('map', {
    center: [20, 0],
    zoom: 2,
    minZoom: 2,
    maxZoom: 10,
    worldCopyJump: true
  });

  // Add dark base map
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
    subdomains: 'abcd',
    maxZoom: 20
  }).addTo(map);
}

// Get color based on Z-score
function getColor(zScore) {
  if (zScore <= -2) return '#ef8a62';
  if (zScore <= -1) return '#f6b894';
  if (zScore <= -0.5) return '#fad7c4';
  if (zScore <= 0.5) return '#f5f5f5';
  if (zScore <= 1) return '#c4dce8';
  if (zScore <= 2) return '#8bc3dc';
  return '#67a9cf';
}

// Get status text based on Z-score
function getStatus(zScore) {
  if (zScore <= -2) return 'Much Drier than Normal';
  if (zScore <= -1) return 'Drier than Normal';
  if (zScore <= -0.5) return 'Slightly Drier';
  if (zScore <= 0.5) return 'Near Normal';
  if (zScore <= 1) return 'Slightly Wetter';
  if (zScore <= 2) return 'Wetter than Normal';
  return 'Much Wetter than Normal';
}

// Get badge class based on Z-score
function getBadgeClass(zScore) {
  if (zScore < -0.5) return 'dry';
  if (zScore > 0.5) return 'wet';
  return 'normal';
}

// Create popup content
function createPopupContent(properties) {
  const { z_score, z_score_raw, current_prcp, historical_mean, years_of_data, latitude, longitude } = properties;

  const status = getStatus(z_score);
  const badgeClass = getBadgeClass(z_score);

  return `
    <div class="popup-header">
      <h3>${status}</h3>
      <div class="coordinates">${latitude.toFixed(2)}°, ${longitude.toFixed(2)}°</div>
    </div>
    <div class="popup-body">
      <div class="popup-stat">
        <span class="label">Z-Score:</span>
        <span class="value"><span class="z-score-badge ${badgeClass}">${z_score_raw.toFixed(2)}</span></span>
      </div>
      <div class="popup-stat">
        <span class="label">Current (30-day):</span>
        <span class="value">${current_prcp.toFixed(1)} cm</span>
      </div>
      <div class="popup-stat">
        <span class="label">Historical Average:</span>
        <span class="value">${historical_mean.toFixed(1)} cm</span>
      </div>
      <div class="popup-stat">
        <span class="label">Difference:</span>
        <span class="value">${(current_prcp - historical_mean).toFixed(1)} cm</span>
      </div>
      <div class="popup-stat">
        <span class="label">Years of Data:</span>
        <span class="value">${years_of_data} years</span>
      </div>
    </div>
  `;
}

// Load and display drought data
async function loadDroughtData() {
  try {
    const response = await fetch('/data/drought_data.geojson');
    droughtData = await response.json();

    // Update metadata
    if (droughtData.metadata) {
      document.getElementById('update-date').textContent = droughtData.metadata.date_range;

      if (droughtData.metadata.is_sample) {
        document.getElementById('update-date').innerHTML +=
          ' <span style="color: #ef8a62; font-weight: 600;">(SAMPLE DATA)</span>';
      }
    }

    // Add drought data as circle markers
    droughtLayer = L.geoJSON(droughtData, {
      pointToLayer: (feature, latlng) => {
        const zScore = feature.properties.z_score;
        return L.circleMarker(latlng, {
          radius: 8,
          fillColor: getColor(zScore),
          color: '#000',
          weight: 1,
          opacity: 0.8,
          fillOpacity: 0.7
        });
      },
      onEachFeature: (feature, layer) => {
        layer.bindPopup(createPopupContent(feature.properties), {
          maxWidth: 300
        });

        // Highlight on hover
        layer.on('mouseover', function() {
          this.setStyle({
            radius: 12,
            weight: 2,
            fillOpacity: 0.9
          });
        });

        layer.on('mouseout', function() {
          this.setStyle({
            radius: 8,
            weight: 1,
            fillOpacity: 0.7
          });
        });
      }
    }).addTo(map);

  } catch (error) {
    console.error('Error loading drought data:', error);
    document.getElementById('update-date').textContent = 'Error loading data';
  }
}

// Location search using Nominatim
let searchTimeout;
const searchInput = document.getElementById('location-search');
const searchBtn = document.getElementById('search-btn');
const searchResults = document.getElementById('search-results');

async function searchLocation(query) {
  if (!query || query.length < 3) {
    searchResults.classList.remove('active');
    return;
  }

  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/search?` +
      `format=json&q=${encodeURIComponent(query)}&limit=5`
    );
    const results = await response.json();

    displaySearchResults(results);
  } catch (error) {
    console.error('Search error:', error);
  }
}

function displaySearchResults(results) {
  if (results.length === 0) {
    searchResults.innerHTML = '<div class="search-result-item">No results found</div>';
    searchResults.classList.add('active');
    return;
  }

  searchResults.innerHTML = results.map(result => `
    <div class="search-result-item" data-lat="${result.lat}" data-lon="${result.lon}">
      <div class="result-name">${result.display_name.split(',')[0]}</div>
      <div class="result-details">${result.display_name}</div>
    </div>
  `).join('');

  searchResults.classList.add('active');

  // Add click handlers
  searchResults.querySelectorAll('.search-result-item').forEach(item => {
    item.addEventListener('click', () => {
      const lat = parseFloat(item.dataset.lat);
      const lon = parseFloat(item.dataset.lon);
      flyToLocation(lat, lon, item.querySelector('.result-name').textContent);
      searchResults.classList.remove('active');
      searchInput.value = '';
    });
  });
}

function flyToLocation(lat, lon, name) {
  map.flyTo([lat, lon], 6, {
    duration: 1.5
  });

  // Find and highlight nearest station
  if (droughtData && droughtData.features) {
    let nearestStation = null;
    let minDistance = Infinity;

    droughtData.features.forEach(feature => {
      const [fLon, fLat] = feature.geometry.coordinates;
      const distance = Math.sqrt(
        Math.pow(lat - fLat, 2) + Math.pow(lon - fLon, 2)
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestStation = feature;
      }
    });

    if (nearestStation) {
      // Open popup for nearest station after animation
      setTimeout(() => {
        droughtLayer.eachLayer(layer => {
          if (layer.feature === nearestStation) {
            layer.openPopup();
          }
        });
      }, 1600);
    }
  }
}

// Event listeners
searchInput.addEventListener('input', (e) => {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    searchLocation(e.target.value);
  }, 300);
});

searchBtn.addEventListener('click', () => {
  searchLocation(searchInput.value);
});

searchInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter') {
    searchLocation(searchInput.value);
  }
});

// Close search results when clicking outside
document.addEventListener('click', (e) => {
  if (!searchResults.contains(e.target) && e.target !== searchInput && e.target !== searchBtn) {
    searchResults.classList.remove('active');
  }
});

// Initialize app
initMap();
loadDroughtData();
