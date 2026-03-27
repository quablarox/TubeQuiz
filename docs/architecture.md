# TubeQuiz Architecture

## Overview

TubeQuiz is an Android-only Flutter application that acts as a "Music Quiz Master" for YouTube Music and Amazon Music. It uses Android's MediaSession API (accessed via Notification Listener Service) to monitor and control music playback.

## Layer Architecture

### Presentation Layer
- **Screens**: Dashboard screen with service toggle, settings, and stats
- **Widgets**: Reusable UI components (StatusCard, SnippetDurationSlider, PlaylistCard, AnnounceSettingsCard)
- **Providers**: ChangeNotifier-based state management via Provider

### Business Logic Layer
- **QuizEngine**: Core orchestrator that implements both passive tracking and the quiz loop
- **FuzzyMatchService**: Multi-factor string matching (Levenshtein + Jaccard + contains) for track comparison
- **CsvImportService**: CSV file parsing and playlist import
- **TtsService**: Text-to-Speech wrapper with bracket-noise cleaning (strips Explicit, Remix, feat., etc.)

### Platform Layer
- **MediaControlService**: Flutter platform channel bridge to native Android code
- **MainActivity.kt**: Native Android code for MediaSession control and audio ducking
- **MediaNotificationListenerService.kt**: Android NotificationListenerService for reading music-app metadata

## Data Flow

```
YouTube Music / Amazon Music
    │
    ▼
NotificationListenerService (Android)
    │
    ▼
MediaSession API (Android)
    │
    ▼
Platform Channel (MethodChannel/EventChannel)
    │
    ▼
MediaControlService (Dart)
    │
    ▼
QuizEngine (Dart)
    ├── FuzzyMatchService (track matching)
    ├── TtsService (announcements with bracket-noise filter)
    └── MediaControlService (seek/skip commands)
    │
    ▼
QuizProvider (state management)
    │
    ▼
Dashboard UI (Flutter widgets)
```

## Key Design Decisions

1. **NotificationListenerService over Accessibility**: Uses Android's NotificationListenerService to read media metadata, which is less invasive than Accessibility Service.

2. **MediaSession API for Control**: Uses Android's MediaSessionManager to find YouTube Music's active session and send transport controls (play, pause, seek, skip).

3. **Provider for State Management**: Simple ChangeNotifier + Provider pattern is sufficient for this app's complexity level.

4. **Custom Fuzzy Matching**: Implements Levenshtein distance, Jaccard token similarity, and contains-checks for robust track comparison, handling common metadata differences (feat., parenthetical text, etc.).

5. **Polling-based Detection**: Uses periodic polling (2-second interval) to check for track changes, which is reliable and battery-efficient.

6. **TTS Title Cleaning**: Bracket noise words (Explicit, Remix, Live, feat., Remastered, Official Video, etc.) are stripped from titles before TTS reads them aloud, so the announcement sounds natural.

7. **Debug/Release ID Separation**: Debug builds use a `.debug` application-ID suffix so they can be installed side-by-side with release builds without triggering Android's conflicting-installation error.
