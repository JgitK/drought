import { defineConfig } from 'vite'
import { copyFileSync, mkdirSync } from 'fs'
import { join } from 'path'

export default defineConfig({
  base: process.env.NODE_ENV === 'production' ? '/drought/' : '/',  // GitHub Pages base path in production only
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    emptyOutDir: true,
  },
  server: {
    port: 3000,
    open: false
  },
  plugins: [{
    name: 'copy-data',
    closeBundle() {
      // Copy data directory to dist
      mkdirSync('dist/data', { recursive: true })
      try {
        copyFileSync('data/drought_data.geojson', 'dist/data/drought_data.geojson')
      } catch (err) {
        console.warn('Warning: Could not copy drought_data.geojson')
      }
    }
  }]
})
