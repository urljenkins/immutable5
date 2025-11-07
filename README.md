# Immutable5

An Islamic companion app built with Flutter that helps Muslims with daily prayers, Quran reading, and learning.

## Features

### Prayer Times
- Automatic prayer time calculation based on your location
- Real-time countdown to the next prayer
- Support for multiple calculation methods (University of Islamic Sciences, etc.)
- Madhab selection (Shafi, Hanafi, Maliki, Hanbali)

### Calendar
- Dual calendar display (Gregorian and Hijri dates)
- Interactive calendar with day selection
- Visual display of both calendar systems side-by-side

### Quran Reader
- Full Quran text included
- Easy navigation and reading interface

### Hajj Guide
- Information and guidance for Hajj pilgrimage

### Common Arabic Words
- Learn commonly used Arabic words
- Useful for learning Islamic terminology

### Inspirational Quotes
- Daily inspirational quotes
- Filter quotes by topic
- Smooth animations and beautiful card design

### Customization
- AMOLED dark theme for battery saving
- Light theme option
- Localization support (multiple languages)
- Configurable prayer calculation methods

## Technical Details

### Platform Support
- Android
- iOS
- Web
- Windows
- macOS
- Linux

### Dependencies
- `geolocator` - Location services for prayer time calculation
- `table_calendar` - Calendar widget
- `hijri` - Hijri calendar conversion
- `shared_preferences` - Local data storage
- `http` - Network requests
- `csv` - Quote and word data parsing

## Getting Started

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Dart 3.7.2 or higher

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd immutable5
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Location Permissions

The app requires location permissions to calculate accurate prayer times based on your geographical position. Make sure to grant location access when prompted.

## Project Structure

```
lib/
  ├── features/
  │   ├── prayer/          # Prayer times calculation
  │   ├── quotes/          # Inspirational quotes
  │   ├── quran/           # Quran reader
  │   ├── calendar/        # Calendar view
  │   ├── hajj/            # Hajj information
  │   ├── common_words/    # Arabic words learning
  │   └── settings/        # App settings
  └── main.dart            # App entry point
assets/
  ├── quotes.csv           # Quote database
  ├── quran.txt            # Quran text
  └── common_words.csv     # Common words database
```

## Configuration

Access the Settings page to customize:
- Prayer calculation method
- Madhab (school of Islamic jurisprudence)
- Theme (AMOLED dark or light)
- Language preferences

## License

This project is licensed under the terms specified in the LICENSE file.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
