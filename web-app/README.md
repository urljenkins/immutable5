# Immutable5 Web App

A modern web application for Islamic prayer times, Qibla direction, and daily duas. Built with React and Vite.

## Features

### 🕌 Prayer Times
- Real-time prayer times based on your location
- Automatic location detection using Geolocation API
- Live countdown to next prayer
- All 5 daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha)
- Additional times (Sunrise, Sunset, Midnight)
- Visual indicators for current/next prayer
- Responsive grid layout

### 🧭 Qibla Compass
- Interactive compass showing direction to Mecca
- Real-time device orientation support
- Qibla angle calculation
- Compass offset display
- Works on mobile devices with compass sensor
- Fallback for devices without compass support

### 📿 Daily Duas Collection
- 8+ authentic duas with categories
- Arabic text with transliteration and English translation
- Category filtering (Morning, Evening, Travel, etc.)
- Bookmark favorite duas
- Copy to clipboard functionality
- Color-coded categories
- Beautiful card-based UI

## Technology Stack

- **React 18** - UI library
- **Vite** - Build tool and dev server
- **Axios** - HTTP client for API calls
- **Aladhan API** - Prayer times calculation
- **Vanilla CSS** - Styling with CSS custom properties
- **Geolocation API** - Location detection
- **Device Orientation API** - Compass functionality

## Getting Started

### Prerequisites
- Node.js 16+ and npm

### Installation

1. Navigate to the web-app directory:
```bash
cd web-app
```

2. Install dependencies:
```bash
npm install
```

3. Start development server:
```bash
npm run dev
```

The app will open at `http://localhost:3000`

### Build for Production

```bash
npm run build
```

The production build will be in the `dist` folder.

### Preview Production Build

```bash
npm run preview
```

## Project Structure

```
web-app/
├── src/
│   ├── components/
│   │   ├── Navigation.jsx         # Navigation bar
│   │   ├── PrayerTimes.jsx        # Prayer times component
│   │   ├── QiblaCompass.jsx       # Qibla compass
│   │   └── DuasCollection.jsx     # Duas collection
│   ├── services/
│   │   └── prayerTimesService.js  # API integration
│   ├── utils/
│   │   ├── location.js            # Geolocation utilities
│   │   └── qibla.js               # Qibla calculations
│   ├── styles/
│   │   ├── index.css              # Global styles
│   │   └── App.css                # App-specific styles
│   ├── App.jsx                    # Main app component
│   └── main.jsx                   # Entry point
├── index.html
├── package.json
├── vite.config.js
└── README.md
```

## Features in Detail

### Prayer Times
- Uses Aladhan API for accurate prayer time calculation
- Method 2 (University of Islamic Sciences, Karachi)
- Real-time countdown timer with hours, minutes, seconds
- Automatic next prayer detection
- Emoji icons for each prayer
- Highlighted card for upcoming prayer
- Caching support for offline functionality

### Qibla Compass
- Calculates Qibla direction using Haversine formula
- Kaaba coordinates: 21.4225°N, 39.8262°E
- Device orientation support for real-time compass
- Displays Qibla angle, offset, and compass heading
- Animated compass rotation
- Visual instructions for users
- iOS permission handling for device orientation

### Duas Collection
- Organized by category (Morning, Evening, Before/After Eating, Travel, Difficulty, Gratitude, Protection)
- RTL (right-to-left) support for Arabic text
- Italicized transliteration in highlighted boxes
- Bookmark functionality with local state
- Copy entire dua (Arabic + Transliteration + Translation)
- Color-coded category badges
- Responsive card layout

## Browser Support

- Modern browsers with ES6+ support
- Geolocation API required for location detection
- Device Orientation API optional for compass feature
- LocalStorage for caching

## API Reference

### Aladhan API
- **Base URL**: `https://api.aladhan.com/v1`
- **Endpoint**: `/timings/{timestamp}`
- **Parameters**:
  - `latitude`: User's latitude
  - `longitude`: User's longitude
  - `method`: Calculation method (default: 2)

## License

This project is part of the Immutable5 Islamic app suite.

## Contributing

Contributions welcome! Please feel free to submit issues and pull requests.

## Acknowledgments

- Prayer times provided by [Aladhan API](https://aladhan.com/prayer-times-api)
- Compass calculations based on Haversine formula
- Duas sourced from authentic Islamic texts
