# TubeQuiz - Music Quiz Master

A Flutter Android companion app that acts as a "Music Quiz Master" for the YouTube Music app. It monitors YouTube Music playback and creates an automated "Guess the Song" / Snippet Quiz experience.

## Features

- **Quiz Mode**: Automatically monitors YouTube Music and runs a quiz loop
- **Snippet Duration Control**: Adjustable slider (5-60 seconds) for how long each song snippet plays
- **CSV Playlist Import**: Import a CSV file (YouTube_ID, Artist, Title) to filter which songs participate in the quiz
- **Fuzzy Matching**: Case-insensitive fuzzy matching to handle metadata differences
- **Text-to-Speech**: Announces each track before playing ("Next song: [Title] by [Artist]")
- **Cross-App Control**: Reads YouTube Music metadata and controls playback (seek, skip)
- **Background Service**: Runs as a foreground service while quiz mode is active
- **Material Design 3**: Clean, modern UI with dark/light theme support

## Architecture

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── track.dart               # Track data model (CSV row)
│   ├── playlist.dart            # Playlist container model
│   └── quiz_state.dart          # Quiz state machine
├── services/
│   ├── csv_import_service.dart  # CSV file picker and parser
│   ├── fuzzy_match_service.dart # Fuzzy string matching engine
│   ├── media_control_service.dart # Platform channel to Android MediaSession
│   ├── tts_service.dart         # Text-to-Speech wrapper
│   └── quiz_engine.dart         # Core quiz loop orchestrator
├── providers/
│   └── quiz_provider.dart       # State management (ChangeNotifier + Provider)
├── screens/
│   └── dashboard_screen.dart    # Main dashboard UI
└── widgets/
    ├── status_card.dart         # Quiz status display
    ├── snippet_duration_slider.dart # Duration setting slider
    └── playlist_card.dart       # Playlist info and import controls
```

## Quiz Loop Behavior

1. **Detect & Match**: Reads the current track's metadata from YouTube Music and checks against the imported CSV playlist using fuzzy matching
2. **Quiz Action** (match found OR no CSV loaded):
   - Announce via TTS: "Next song: [Title] by [Artist]"
   - Jump to a random timestamp within the track
   - Play for the user-defined snippet duration
   - Automatically skip to the next track
3. **Skip Action** (CSV loaded but no match): Skip the track immediately

## Setup

### Prerequisites

- Flutter SDK >= 3.2.0
- Android SDK with API 26+ (Android 8.0 Oreo)
- Java 17

### Installation

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

### Required Permissions

The app requires **Notification Listener** permission to read YouTube Music's playback metadata. The app will prompt you to grant this permission on first launch.

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## CSV Format

The playlist CSV file should follow this format:

```csv
YouTube_ID,Artist,Title
dQw4w9WgXcQ,Rick Astley,Never Gonna Give You Up
9bZkp7q19f0,PSY,Gangnam Style
```

## License

This project is provided as-is for educational and personal use.