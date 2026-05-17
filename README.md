# JellyAmp

A Spotify-style Jellyfin music client built with Flutter. Works on Android, iOS, Windows, macOS, and Linux.

## Features

- Browse albums, artists, and playlists
- Full-screen player with album art, progress scrubber, shuffle and repeat
- Synced lyrics (requires `.lrc` sidecar files on your Jellyfin server)
- Offline downloads — download songs and play without a server connection
- Playback reporting back to Jellyfin (scrobbling / resume position)
- Dynamic colour theming from album art
- Search across songs and albums

## Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.0+
- A running [Jellyfin](https://jellyfin.org/) server with music

### Install & run

```bash
flutter pub get

# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Build release

```bash
# Android APK
flutter build apk --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## Platform notes

| Platform | Playback | Downloads | Media keys |
|----------|----------|-----------|------------|
| Android  | ✅        | ✅         | ✅ (system) |
| iOS      | ✅        | ✅         | ✅ (system) |
| Windows  | ✅        | ✅         | ❌          |
| macOS    | ✅        | ✅         | ❌          |
| Linux    | ✅        | ✅         | ❌          |

> **Windows / Linux note:** System media controls (lock screen, media keys) are not supported as `audio_service` only targets mobile. The app plays audio fine in the background — the window just needs to remain open.

> **HTTP servers:** The Android manifest has `usesCleartextTraffic="true"` so plain `http://` Jellyfin servers work. On iOS you may need to add an `NSAppTransportSecurity` exception in `ios/Runner/Info.plist` for your server's IP.

> **Lyrics:** Jellyfin serves lyrics from `.lrc` files placed alongside audio files. The app will show a "No lyrics available" message if none exist for a track.

## Project structure

```
lib/
  main.dart
  theme.dart
  models/         jellyfin_models.dart
  providers/      auth_provider, library_provider, player_provider
  services/       jellyfin_api, db_service, download_service
  screens/        home, search, library, downloads, album, artist, playlist, player
  widgets/        album_card, song_tile, mini_player, lyrics_view
```
