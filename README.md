# Immutable5

An Islamic companion app built with Flutter that helps Muslims with daily prayers, Quran reading, and learning.

## Features

### Prayer Times
- Automatic prayer time calculation based on your location
- Real-time countdown to the next prayer
- Support for multiple calculation methods (University of Islamic Sciences, etc.)
- Madhab selection (Shafi, Hanafi, Maliki, Hanbali)
- **Home screen widget** - View prayer times without opening the app (Android & iOS)
  - Customizable themes (Light, Dark, Green Accent, Blue Accent)
  - Multiple layouts (Compact, Detailed, Minimal)
  - Live preview of widget appearance
- Prayer notifications with scheduled reminders
- Prayer tracking with completion statistics and streaks

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

### Daily Duas Collection
- 20+ curated authentic duas with categories
- Arabic text with transliteration and English translation
- Category filtering (Morning, Evening, Travel, Masjid, etc.)
- Bookmark/favorite functionality
- Copy to clipboard feature
- Color-coded categories for easy navigation

### Inspirational Quotes
- Daily inspirational quotes
- Filter quotes by topic
- Smooth animations and beautiful card design

### Customization
- AMOLED dark theme for battery saving
- Light theme option
- Localization support (multiple languages)
- Configurable prayer calculation methods
- Widget theme and layout customization

### Performance & Battery
- Advanced caching system with 5MB limit
- LRU (Least Recently Used) cache eviction
- Battery saver mode for extended battery life
- Network request throttling
- Automatic cleanup of expired cache
- Cache statistics and manual clearing

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
- `home_widget` - Home screen widgets for Android and iOS
- `flutter_local_notifications` - Prayer time notifications
- `flutter_qiblah` - Qibla compass functionality
- `permission_handler` - Runtime permissions handling
- `timezone` - Timezone support for notifications
- `intl` - Internationalization and date formatting

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
  │   ├── prayer/              # Prayer times calculation
  │   ├── prayer_tracking/     # Prayer completion tracking
  │   ├── notifications/       # Prayer notifications service
  │   ├── widget/              # Home screen widget service
  │   ├── qibla/               # Qibla compass
  │   ├── quotes/              # Inspirational quotes
  │   ├── quran/               # Quran reader
  │   ├── calendar/            # Calendar view
  │   ├── hajj/                # Hajj information
  │   ├── common_words/        # Arabic words learning
  │   └── settings/            # App settings
  └── main.dart                # App entry point
android/
  └── app/src/main/
      ├── res/
      │   ├── layout/
      │   │   └── prayer_times_widget.xml
      │   └── xml/
      │       └── prayer_times_widget_info.xml
      └── kotlin/com/example/immutable5/
          └── PrayerTimesWidgetProvider.kt
ios/
  └── PrayerTimesWidget/
      ├── PrayerTimesWidget.swift
      └── Info.plist
assets/
  ├── quotes.csv           # Quote database
  ├── quran.txt            # Quran text
  └── common_words.csv     # Common words database
```

## Production Configuration

### Android Application ID

Before publishing to the Google Play Store, update the application ID in `android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    applicationId = "com.yourcompany.immutable5"  // Change from com.example.immutable5
    // ...
}
```

### Android Release Signing

For production releases, set up proper signing credentials:

1. Generate a keystore file:
```bash
keytool -genkey -v -keystore ~/immutable5-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias immutable5
```

2. Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=immutable5
storeFile=<path-to-keystore>/immutable5-release-key.jks
```

3. Update `android/app/build.gradle.kts` to use the signing configuration (replace the current debug signing).

**Important**: Never commit `key.properties` or your keystore to version control. Add them to `.gitignore`.

### Hajj Page Images

The Hajj guide currently uses placeholder images. To add actual images:

1. Add image assets to `assets/hajj/` directory
2. Update `pubspec.yaml` to include the new assets:
```yaml
assets:
  - assets/hajj/
```
3. Modify `lib/features/hajj/hajj_page.dart` to display the images instead of placeholders

## Home Screen Widget Setup

The app includes a home screen widget that displays prayer times directly on your device's home screen.

### Android Widget

The Android widget is automatically configured and ready to use:

1. Long-press on your home screen
2. Select "Widgets"
3. Find "Immutable5" or "Prayer Times"
4. Drag the widget to your home screen
5. The widget will automatically update with your prayer times

The widget updates every 30 minutes and shows:
- Next prayer name and time with countdown
- All 5 daily prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha)
- Last update timestamp

### iOS Widget

The iOS widget requires additional setup in Xcode:

1. Open the project in Xcode: `open ios/Runner.xcworkspace`
2. Add a new Widget Extension target:
   - File → New → Target
   - Select "Widget Extension"
   - Name it "PrayerTimesWidget"
   - Uncheck "Include Configuration Intent"
3. Copy the widget code from `ios/PrayerTimesWidget/PrayerTimesWidget.swift`
4. Add App Group capability:
   - Select your app target → Signing & Capabilities
   - Add "App Groups" capability
   - Create group: `group.immutable5.prayertimes`
   - Repeat for the widget extension target
5. Build and run the app

To add the widget on iOS:
1. Long-press on home screen
2. Tap the "+" button in the top corner
3. Search for "Immutable5" or "Prayer Times"
4. Select widget size (Medium or Large)
5. Add to home screen

**Note**: iOS widgets update based on the system's widget timeline policy, typically every 15-30 minutes.

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
