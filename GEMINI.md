# RoomReserve Mobile - Project Context

## Project Overview
**RoomReserve** is a Flutter-based mobile application designed for room reservation management. It leverages **Firebase** for backend services including authentication (Email/Password, Google Sign-In), database (Cloud Firestore), and file storage.

The application is built to be localized (multilingual) and supports Android and iOS platforms.

## Tech Stack & Architecture
*   **Framework:** Flutter (Dart)
*   **Backend:** Firebase (Auth, Firestore, Storage)
*   **State Management:** `provider` package (e.g., `LocaleProvider`) and local `setState`.
*   **Authentication:** Firebase Auth (Email & Google).
*   **Database:** Cloud Firestore.
*   **Routing:** Standard Navigator push/pop, with an `AuthGate` in `main.dart` acting as the root controller for authenticated vs. unauthenticated states.

## Key Directories & Files
*   `lib/`
    *   `main.dart`: Entry point. Initializes Firebase, sets up providers and localization, and defines the `AuthGate`.
    *   `Pages/`: Contains all UI screens.
        *   **Convention Note:** This project uses `PascalCase.dart` or `Pascal_Case.dart` for filenames in this directory (e.g., `Home_Page.dart`, `Login_Page.dart`), which deviates from the standard Dart `snake_case.dart`. **Follow this existing project convention when creating new pages.**
    *   `providers/`: Contains state providers (e.g., `locale_provider.dart`).
    *   `l10n/`: Localization files (`app_localizations.dart`).
    *   `assets/`: Images and icons.
*   `test/`: Unit and widget tests. (Currently contains basic placeholders).

## Development Conventions
*   **File Naming:**
    *   **Pages:** Use `PascalCase.dart` or `Pascal_Case.dart` (e.g., `Profile_Page.dart`).
    *   **Other files:** Use standard `snake_case.dart` (e.g., `locale_provider.dart`).
*   **Styling:** Material Design 3 (`useMaterial3: true`).
*   **Localization:** All UI strings should be retrieved via `AppLocalizations.of(context)` (e.g., `l10n.get('stringKey')`).
*   **Imports:** Prefer relative imports for project files.
    
## Build & Run Commands
*   **Run App:** `flutter run`
*   **Run Tests:** `flutter test`
*   **Analyze Code:** `flutter analyze`
*   **Get Dependencies:** `flutter pub get`
