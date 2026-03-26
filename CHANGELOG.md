# Changelog

All notable changes to TubeQuiz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Audio ducking mode setting: off, first/last only, or all announcements
- Release signing configuration for consistent APK updates
- Versioned CI build artifacts (APK names include version number)
- Pull request template enforcing structured commit messages
- This changelog

### Changed
- TTS announcement text simplified from "Next song: X by Y" to "X by Y"

## [1.0.0] - 2026-03-26

### Added
- Passive mode: always-on tracking with TTS announcements
- Quiz mode: playlist filtering, snippet playback, seeking, and skipping
- Announcement timing: beginning, end, both, or repeating interval
- Snippet duration control (5–60 seconds)
- Full song mode
- Random start position (capped at 1:30)
- CSV playlist import with fuzzy matching
- Audio ducking during TTS announcements
- NotificationListenerService for YouTube Music metadata
- Foreground service support
