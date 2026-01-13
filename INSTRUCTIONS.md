# How to Run the Interactive Drought Map on Your Machine

## 📦 What You Have

The `drought-interactive-map.tar.gz` file contains everything you need to run the interactive map.

---

## 🚀 Quick Start (3 Methods)

### **Method 1: Simple Double-Click (Easiest)**

1. **Extract the archive:**
   ```bash
   tar -xzf drought-interactive-map.tar.gz
   ```

2. **Open in browser:**
   - Navigate to the `dist/` folder
   - Double-click `index.html`
   - It should open in your default browser

**Note:** Some browsers block loading local files for security. If the map doesn't show data, use Method 2 or 3 instead.

---

### **Method 2: Python HTTP Server (Recommended)**

Works on Mac, Linux, and Windows (with Python installed).

1. **Extract the archive:**
   ```bash
   tar -xzf drought-interactive-map.tar.gz
   cd dist
   ```

2. **Start a local server:**

   **Python 3:**
   ```bash
   python3 -m http.server 8080
   ```

   **Python 2:**
   ```bash
   python -m SimpleHTTPServer 8080
   ```

3. **Open your browser:**
   ```
   http://localhost:8080/
   ```

4. **Done!** The interactive map should now be fully functional.

5. **To stop:** Press `Ctrl+C` in the terminal

---

### **Method 3: Node.js HTTP Server (If you have Node)**

1. **Extract the archive:**
   ```bash
   tar -xzf drought-interactive-map.tar.gz
   cd dist
   ```

2. **Install http-server globally (one time only):**
   ```bash
   npm install -g http-server
   ```

3. **Start the server:**
   ```bash
   http-server -p 8080
   ```

4. **Open your browser:**
   ```
   http://localhost:8080/
   ```

---

## 🎯 What You Should See

When you open the map, you should see:

- **Interactive world map** with a dark background
- **Colored dots** representing weather stations
  - 🔴 Red = Drier than normal
  - ⚪ White = Normal precipitation
  - 🔵 Blue = Wetter than normal
- **Search box** at the top
- **Legend** in the bottom-left corner

### **Try These Features:**

1. **Pan & Zoom:**
   - Click and drag to pan
   - Scroll to zoom in/out

2. **Search for a location:**
   - Type "Los Angeles" or "Tokyo" in the search box
   - Click on a suggestion
   - Watch the map fly to that location

3. **View station details:**
   - Click any colored dot
   - See Z-score, current precipitation, historical average

4. **Mobile test:**
   - Resize your browser window
   - Everything should adapt responsively

---

## 🐛 Troubleshooting

### **Problem: Map shows but no colored dots appear**

**Solution:** The data file didn't load. This happens when opening `index.html` directly.
- Use Method 2 (Python HTTP Server) instead

### **Problem: "localhost refused to connect"**

**Check:**
1. Did you start the server? (See Method 2 or 3)
2. Is port 8080 already in use? Try a different port:
   ```bash
   python3 -m http.server 9000
   ```
   Then open: http://localhost:9000/

### **Problem: Search doesn't work**

**Reason:** Search requires internet connection (uses OpenStreetMap geocoding API)
- Make sure you're connected to the internet
- The map itself works offline, just search won't

### **Problem: Map tiles don't load**

**Reason:** Map tiles come from the internet (CartoDB/OpenStreetMap)
- Make sure you're connected to the internet
- If behind a corporate firewall, tiles might be blocked

---

## 📁 File Structure

```
dist/
├── index.html              # Main HTML file
├── assets/
│   ├── index-*.js          # JavaScript bundle
│   └── index-*.css         # Styles
└── data/
    └── drought_data.geojson  # Weather station data
```

All files are self-contained. No installation needed!

---

## 🌐 Deploy to GitHub Pages (Optional)

Want to put this online?

1. **Copy everything in `dist/` to your GitHub repo root** (or a `docs/` folder)

2. **Go to your repo settings:**
   - Settings → Pages
   - Source: Select your branch
   - Folder: Select root or `/docs`
   - Save

3. **Wait 1-2 minutes**, then visit:
   ```
   https://yourusername.github.io/drought/
   ```

---

## 💡 Next Steps

Once you have it running:

1. **Test all features** - search, click, zoom
2. **Share feedback** - what would make it better?
3. **Pick the next feature** to add:
   - Time-series graphs
   - Animated time-lapse
   - Data export
   - Your idea?

---

## 📊 Technical Details

**Built with:**
- Vite (build tool)
- Leaflet.js (mapping)
- Vanilla JavaScript (no frameworks)
- OpenStreetMap tiles
- NOAA GHCN climate data

**Performance:**
- Total size: ~180KB (including all assets)
- Load time: <1 second on fast connection
- Works offline (except map tiles and search)

**Browser support:**
- Chrome/Edge (latest 2 versions) ✅
- Firefox (latest 2 versions) ✅
- Safari (latest 2 versions) ✅
- Mobile browsers ✅

---

## ❓ Need Help?

If something doesn't work, let me know:
- What method did you try?
- What error message did you see?
- What browser are you using?

I can help troubleshoot or create a different package format!
