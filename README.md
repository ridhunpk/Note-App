# Note App

A Flutter-based note-taking application with offline storage, sync support, and a clean app architecture.

## Overview

This repository contains a Flutter app for creating, editing, and synchronizing notes. The app uses local storage, a BLoC architecture, and connectivity checks to provide a reliable note experience across mobile and desktop platforms.

## Key Features

- Create, edit, and delete notes
- Local persistence with Hive
- Sync support for remote note storage
- Connectivity detection for online/offline behavior
- Modular architecture with clear separation of responsibilities

## Getting Started

### Prerequisites

- Flutter SDK installed
- Dart SDK installed (comes with Flutter)
- A supported platform toolchain for Android, iOS, Windows, Linux, or macOS

### Run the app

1. Open the project in your IDE
2. Fetch dependencies:

```bash
flutter pub get
```

3. Run on your target device:

```bash
flutter run
```

## Project Structure

```text
Note-App/
├── android/                 # Android project files
├── ios/                     # iOS project files
├── linux/                   # Linux desktop project files
├── macos/                   # macOS desktop project files
├── web/                     # Web build files
├── windows/                 # Windows desktop project files
├── assets/                  # App assets and icons
├── lib/                     # Main Dart source files
│   ├── app.dart             # App setup and routing
│   ├── main.dart            # Entry point
│   ├── bloc/                # BLoC state management
│   │   ├── notes/           # Note-related BLoCs
│   │   └── sync/            # Sync-related BLoCs
│   ├── core/                # Shared constants and configuration
│   ├── data/                # Data models and repository interfaces
│   │   ├── local/           # Local persistence implementation
│   │   └── remote/          # Remote API / sync implementation
│   ├── models/              # Domain model classes
│   ├── presentation/        # UI pages and widgets
│   ├── services/            # App services (connectivity, sync, conflict handling)
│   └── repositories/        # Repository implementations
├── pubspec.yaml             # Flutter package configuration
├── analysis_options.yaml    # Dart analysis rules
└── README.md                # Project documentation
```

## Important Files

- `lib/main.dart` — Application entry point
- `lib/app.dart` — App configuration, theme, routes, and initialization
- `lib/services/` — Connectivity, sync, and conflict services
- `lib/bloc/` — State management for notes and sync operations
- `pubspec.yaml` — Dependencies and Flutter metadata

## Notes

- The app uses `hive` for local storage and `dio` for remote HTTP requests.
- `flutter_bloc` and `equatable` are used for predictable state management.
- `flutter_launcher_icons` is configured for generating app icons.

## Contributing

Contributions are welcome. Open an issue or submit a pull request with improvements.

## License

This project is private and not configured for publication. Update `pubspec.yaml` and include a license file if you plan to share it publicly.
