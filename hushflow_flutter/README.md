# Hushflow Flutter App

Cross-platform Flutter application for the Hushflow email subscription manager.

## Features

- 📧 **Gmail Sign-in** - OAuth2 authentication with Google
- 📊 **Prioritized Inbox** - ML-ranked email feed
- 🤖 **AI Summaries** - GPT-powered newsletter digests
- 🎧 **Audio Briefings** - Text-to-speech playback
- 🗣️ **Voice Commands** - Natural language control
- 🧹 **Batch Cleanup** - One-tap unsubscribe from multiple senders

## Getting Started

### Prerequisites

- Flutter SDK >= 3.10.0
- Running Hushflow server (see `../hushflow_server`)

### Setup

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build for release
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
```

## Project Structure

```
hushflow_flutter/
├── lib/
│   ├── main.dart           # App entry point
│   ├── app/                # App configuration
│   ├── features/           # Feature modules
│   │   ├── auth/           # Authentication
│   │   ├── inbox/          # Email listing
│   │   ├── summary/        # AI summaries
│   │   └── settings/       # User preferences
│   ├── shared/             # Shared widgets/utils
│   └── providers/          # Riverpod providers
├── assets/                 # Images, fonts, etc.
└── test/                   # Unit and widget tests
```

## State Management

Uses [Riverpod](https://riverpod.dev/) for state management with:
- `AsyncNotifier` for async operations
- `FutureProvider` for API calls
- `StateNotifier` for complex state

## Theming

Uses [FlexColorScheme](https://pub.dev/packages/flex_color_scheme) for Material 3 theming with light/dark mode support.
