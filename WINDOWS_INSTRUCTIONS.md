# Windows Instructions - Interactive Drought Map

## Step 1: Download the File

**The file you need is:**
```
drought-interactive-map.zip
```

**Where to find it:**
- It's located at: `/home/user/drought/drought-interactive-map.zip`
- You're currently working in a container/remote environment
- Look for a **"Download" button** or **file browser** in your interface
- Download `drought-interactive-map.zip` to your Windows machine (e.g., Downloads folder)

**If you're using:**
- **VS Code**: Right-click the file → Download
- **Claude Code Web**: There should be a download option in the file explorer
- **Terminal/SSH**: Use `scp` or your file transfer tool

---

## Step 2: Extract the Zip File (Windows)

**Super Easy - No special software needed!**

1. **Find the downloaded file** in your Downloads folder (or wherever you saved it)

2. **Right-click** on `drought-interactive-map.zip`

3. **Click "Extract All..."**

4. **Choose where to extract** (or just click "Extract" to use the default location)

5. **Done!** You'll now have a folder called `drought-interactive-map` (or just `dist`)

---

## Step 3: Run the Map (3 Options for Windows)

### **Option A: Just Double-Click (Easiest - Try This First!)**

1. Open the extracted `dist` folder
2. Find the file named `index.html`
3. **Double-click** `index.html`
4. It should open in your default browser (Chrome, Edge, Firefox, etc.)

**If you see the map but no colored dots:**
- This is a security restriction with local files
- Use Option B instead

---

### **Option B: Python Web Server (Recommended)**

**Check if you have Python:**
1. Press `Win + R` (opens Run dialog)
2. Type `cmd` and press Enter
3. Type: `python --version`
4. If you see a version number, you have Python! Continue below.
5. If not, download from: https://www.python.org/downloads/

**Run the server:**

1. **Open Command Prompt:**
   - Press `Win + R`
   - Type `cmd` and press Enter

2. **Navigate to the extracted folder:**
   ```cmd
   cd Downloads\drought-interactive-map\dist
   ```

   (Adjust the path if you extracted somewhere else)

3. **Start the server:**
   ```cmd
   python -m http.server 8080
   ```

4. **Open your browser and go to:**
   ```
   http://localhost:8080/
   ```

5. **Done!** The map should now work perfectly.

6. **To stop the server:** Press `Ctrl + C` in the Command Prompt

---

### **Option C: Use a Browser Extension (Alternative)**

If Python doesn't work, install a simple web server extension:

**For Chrome/Edge:**
1. Install "Web Server for Chrome" extension
2. Point it to the `dist` folder
3. Click the URL it provides

---

## Step 4: Test the Map

Once it's open, try these:

✅ **Search:** Type "New York" in the search box at the top
✅ **Click:** Click any colored dot to see weather details
✅ **Zoom:** Use mouse wheel to zoom in/out
✅ **Pan:** Click and drag to move around

**Colors mean:**
- 🔴 **Red/Orange** = Drier than normal
- ⚪ **White** = Normal precipitation
- 🔵 **Blue** = Wetter than normal

---

## Troubleshooting

### "I can't find the file to download"

The file is at: `/home/user/drought/drought-interactive-map.zip`

If you're using Claude Code, look for:
- File explorer panel on the left
- Right-click the file → Download

### "Extract All is grayed out"

- Make sure you right-clicked the `.zip` file itself
- Try downloading the file again

### "Python is not recognized"

You don't have Python installed. Either:
- Use **Option A** (double-click index.html)
- Or install Python from https://www.python.org/downloads/
  - Make sure to check "Add Python to PATH" during installation!

### "The map shows but no colored dots"

This means local files are blocked. Use **Option B** (Python server) instead.

### "Can't navigate to the folder in Command Prompt"

Your exact path might be different. Try:
```cmd
cd %USERPROFILE%\Downloads\drought-interactive-map\dist
```

Or use File Explorer:
1. Open the `dist` folder
2. Click in the address bar at the top
3. Type `cmd` and press Enter
4. This opens Command Prompt already in that folder!
5. Then just type: `python -m http.server 8080`

---

## Quick Summary

**Easiest Path:**
1. Download `drought-interactive-map.zip`
2. Right-click → Extract All
3. Open `dist` folder
4. Double-click `index.html`

**If that doesn't fully work:**
1. Extract the zip
2. Open Command Prompt in the `dist` folder
3. Run: `python -m http.server 8080`
4. Open browser to: http://localhost:8080/

---

## Still Stuck?

Let me know:
- Which step you're on
- What error message you see (take a screenshot!)
- Did you get Python working?

I can create a different package or walk you through it step-by-step!
