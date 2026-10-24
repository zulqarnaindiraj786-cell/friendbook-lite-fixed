# FriendBook Lite

A lightweight social app built with Flutter, featuring AdMob banner ads.

## Features

- Home feed with posts from friends
- Friends list with online status
- Profile screen
- Google AdMob banner ads

## Getting Started

1. Install Flutter SDK (>= 3.10.0)
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to launch the app on a device or emulator

## AdMob Configuration

This app uses Google Mobile Ads with the following IDs:

- **App ID:** `ca-app-pub-3387480177023669~5696528190`
- **Banner Ad Unit ID:** `ca-app-pub-3387480177023669/2691090902`

The App ID is configured in `android/app/src/main/AndroidManifest.xml`.

## Build APK

```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                  # App entry point with AdMob initialization
├── models/
│   └── friend.dart            # Data models and sample data
├── screens/
│   ├── home_screen.dart       # Home feed
│   ├── friends_screen.dart    # Friends list
│   └── profile_screen.dart    # User profile
└── services/
    └── admob_service.dart     # AdMob banner ad management

android/
├── app/
│   ├── build.gradle           # App-level Gradle config (minSdk 21, targetSdk 34)
│   └── src/main/
│       ├── AndroidManifest.xml  # AdMob App ID + INTERNET permission
│       └── kotlin/...           # MainActivity
├── build.gradle               # Project-level Gradle config
├── settings.gradle            # Gradle settings
└── gradle.properties          # Gradle JVM args
```

## Requirements

- Flutter >= 3.10.0
- Dart >= 3.0.0
- Android minSdk 21, targetSdk 34
