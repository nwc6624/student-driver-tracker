# Student Driver Tracker

A Flutter app for students and instructors to keep track of supervised driving hours.

## Key Features

- **Driver Profiles** – create multiple student drivers, each with required driving-hour goals.
- **Session Logging** – add driving sessions in minutes, including date, location & notes.
- **Live Totals** – profile shows total hours first (rounded) and minutes; turns green when the requirement is met.
- **Completion Dialog** – congratulates the driver when they reach their goal and shows summary stats.
- **Editing / Deletion**
  - Delete individual sessions.
  - Delete an entire driver profile from the ••• menu.
  - Handle orphaned profiles gracefully with *Return Home* & *Delete Profile* options.
- **Dark / Light Theme Toggle** – remembers preference via `SharedPreferences`.
- **Offline Persistence** – local storage powered by Hive; data survives restarts.

## Getting Started

1. **Prerequisites**
   - Flutter 3.x (stable channel)
   - Dart SDK (bundled with Flutter)
   - Android Studio / Xcode for emulators or real devices

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate Hive adapters** (already checked in, but run after model changes):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run**
```bash
flutter run -d <device-id>
```

## Project Structure

- `lib/models/` – Hive data models (`driver.dart`, `driving_session.dart`).
- `lib/screens/` – UI pages (home, create driver, profile, add session, about).
- `lib/providers/` – Riverpod state management (theme provider).
- `lib/utils/` – helpers (PDF export, permissions, etc.).
- `lib/adapters/` – custom Hive adapters (e.g., `duration_adapter.dart`).

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](LICENSE)
