# TubeQuiz Architecture

## Overview

TubeQuiz is an Android-only Flutter application that acts as a "Music Quiz Master" for YouTube Music. It uses Android's MediaSession API (accessed via Notification Listener Service) to monitor and control YouTube Music playback.

## Layer Architecture

### Presentation Layer
- **Screens**: Dashboard screen with quiz controls
- **Widgets**: Reusable UI components (StatusCard, SnippetDurationSlider, PlaylistCard)
- **Providers**: ChangeNotifier-based state management via Provider

### Business Logic Layer
- **QuizEngine**: Core orchestrator that implements the quiz loop
- **FuzzyMatchService**: String matching for track comparison
- **CsvImportService**: CSV file parsing and playlist import

### Platform Layer
- **MediaControlService**: Flutter platform channel bridge to native Android code
- **TtsService**: Text-to-Speech wrapper using flutter_tts
- **MainActivity.kt**: Native Android code for MediaSession control
- **MediaNotificationListenerService.kt**: Android NotificationListenerService for reading YouTube Music metadata

## Data Flow

```
YouTube Music App
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
    ├── TtsService (announcements)
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

4. **Custom Fuzzy Matching**: Implements Levenshtein distance and token-based matching for robust track comparison, handling common metadata differences (feat., parenthetical text, etc.).

5. **Polling-based Detection**: Uses periodic polling (2-second interval) to check for track changes, which is reliable and battery-efficient.
