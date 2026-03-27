# TubeQuiz – Music Quiz Master

A Flutter Android companion app that turns YouTube Music (and Amazon Music) into an automated "Guess the Song" quiz. It runs alongside your music app, listens for track changes, and announces each song via Text-to-Speech — optionally playing only a short snippet before skipping to the next track.

## Features

### Two Operating Modes

| Mode | What it does |
|------|-------------|
| **Passive Tracking** | Always-on: detects every new song and reads the title aloud via TTS. No playback control. |
| **Quiz Mode** | Full quiz loop: filters tracks against a CSV playlist, plays a configurable snippet, then auto-skips. |

### Announcement & TTS

- **Flexible timing** — announce at the start, end, both, or on a repeating interval
- **Audio ducking** — four modes: *Off*, *First/Last only*, *All announcements*, or *Pause music*
- **Smart title cleaning** — automatically strips bracket noise like *(Explicit)*, *(Remix)*, *[Official Video]*, *(feat. …)*, *(Remastered 2024)* etc. before reading aloud

### Playback Control (Quiz Mode)

- **Snippet duration** — adjustable from 5 to 60 seconds
- **Full song mode** — let the entire track play instead of a snippet
- **Random start** — jump to a random position (capped at 1:30) for variety

### Playlist & Matching

- **CSV import** — load a playlist file (`YouTube_ID, Artist, Title`)
- **Fuzzy matching** — case-insensitive, Levenshtein + token-based scoring handles metadata differences like extra whitespace, "feat." tags, or "(Official Video)" suffixes
- **Without a playlist** every track is quizzed

### Supported Music Apps

- YouTube Music
- Amazon Music

### Other

- **Foreground service** — keeps running while the screen is off
- **Settings persistence** — all preferences are saved automatically and applied to the next track
- **Material Design 3** — clean, modern single-screen UI

## Architecture

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── track.dart                 # Track data model (CSV row)
│   ├── playlist.dart              # Playlist container model
│   └── quiz_state.dart            # Quiz state machine & enums
├── services/
│   ├── csv_import_service.dart    # CSV file picker and parser
│   ├── fuzzy_match_service.dart   # Fuzzy string matching engine
│   ├── media_control_service.dart # Platform channel to Android MediaSession
│   ├── tts_service.dart           # Text-to-Speech wrapper with title cleaning
│   └── quiz_engine.dart           # Core quiz / passive-tracking orchestrator
├── providers/
│   └── quiz_provider.dart         # State management (ChangeNotifier + Provider)
├── screens/
│   └── dashboard_screen.dart      # Main dashboard UI
└── widgets/
    ├── status_card.dart           # Live status & statistics
    ├── snippet_duration_slider.dart # Duration / playback settings
    ├── playlist_card.dart         # Playlist info and import controls
    └── announce_settings_card.dart # Timing & ducking controls
```

## Quiz Loop

1. **Detect & Match** — reads the current track's metadata via Android's NotificationListenerService and (in quiz mode) checks it against the imported CSV playlist using fuzzy matching.
2. **Quiz Action** (match found or no playlist loaded):
   - Announce via TTS: *"[Title] by [Artist]"* (bracket noise removed)
   - Seek to a random position (if enabled)
   - Play for the configured snippet duration (or full song)
   - Auto-skip to the next track
3. **Skip Action** (playlist loaded but no match): skip immediately.

## Setup

### Prerequisites

- Flutter SDK ≥ 3.2.0
- Android SDK with API 26+ (Android 8.0 Oreo)
- Java 17

### Installation

```bash
# Install dependencies
flutter pub get

# Run in debug mode (uses .debug app-ID suffix — won't conflict with release)
flutter run

# Build release APK
flutter build apk --release
```

### Required Permissions

The app requires **Notification Listener** permission to read music-app metadata. A banner on the dashboard will guide you to the system settings if permission is missing.

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## CSV Format

```csv
YouTube_ID,Artist,Title
dQw4w9WgXcQ,Rick Astley,Never Gonna Give You Up
9bZkp7q19f0,PSY,Gangnam Style
```

Header rows are detected and skipped automatically.

## License

This project is provided as-is for educational and personal use.