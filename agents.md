# Agents Guide - Immutable5

This document provides essential context and guidelines for AI agents working on the **Immutable5** project.

## Project Overview
**Immutable5** is a comprehensive Islamic companion application featuring prayer times, Quran reading, Islamic calendar, and educational resources. It is built as a multi-platform solution with a **Flutter** mobile app and a **React** web app.

- **Mobile App:** Located in the root and `lib/` directory.
- **Web App:** Located in the `web-app/` directory.

## Technology Stack
### Mobile (Flutter)
- **State Management:** Currently a mix of `ValueNotifier`, `setState`, and some singleton services. (Refactoring towards a more robust solution like `GetIt` or `Provider` is ongoing).
- **Local Storage:** `shared_preferences` (general), `flutter_secure_storage` (sensitive data - planned/partial).
- **Navigation:** Standard Flutter Navigator.
- **Networking:** `http` package.
- **Key Dependencies:** `geolocator`, `table_calendar`, `hijri`, `flutter_local_notifications`, `flutter_qiblah`.

### Web (React)
- **Framework:** React 18 with Vite.
- **Styling:** CSS (Vanilla/Modern).

## Architecture & Patterns
The project follows a **Feature-Focused Modular Architecture**.

### Directory Structure
- `lib/features/`: Contains self-contained modules for each feature (e.g., `prayer`, `quran`, `settings`).
- `lib/services/`: Cross-cutting infrastructure services (e.g., `CacheManager`, `BatteryOptimizer`).
- `lib/core/`: (In progress) Shared interfaces, base classes, and core logic.
- `lib/shared/`: (In progress) Reusable UI components and utilities.

### Key Implementation Patterns
- **Singleton Services:** Most core logic is encapsulated in singleton services (e.g., `PrayerTimesService`, `NotificationService`).
- **Feature Isolation:** Keep logic related to a specific feature within its `features/` subdirectory.
- **Asset-Driven:** Much of the content (Quran, Duas, Quotes) is loaded from assets in `assets/`.

## Agent Guidelines

### 1. Code Consistency
- Follow the existing feature-modular structure.
- Avoid bloating `main.dart`. New logic should be extracted into services or feature-specific controllers/viewmodels.
- Use the `ARCHITECTURE_REVIEW.md` as a reference for known technical debt and areas for improvement.

### 2. State Management
- Prefer extracting business logic from Widgets into Services.
- When adding new state, consider if it should be persisted or if it needs to be shared across features.

### 3. Error Handling
- Do NOT swallow exceptions silently.
- Use consistent logging and provide user-facing feedback where appropriate.

### 4. Naming Conventions
- Async methods: `fetch*` (network), `load*` (local), `calculate*`.
- Predicates: `is*`, `has*`.
- Private members: Prefix with `_`.

### 5. Documentation
- Update `README.md` for new features.
- Maintain `agents.md` and other documentation artifacts as the project evolves.

## Common Workflows
- **Running Mobile (Dev):** `flutter run`
- **Building Web:** `cd web-app && npm run build`
- **Adding Assets:** Update `pubspec.yaml` and ensure files are in the `assets/` directory.

## Reference Files
- `pubspec.yaml`: Project dependencies and configuration.
- `README.md`: High-level feature overview and setup.
- `ARCHITECTURE_REVIEW.md`: Detailed analysis of current architectural state.

## Pre-Commit Checklist
Before committing changes, verify the following to avoid common build failures:

### 1. Constructor & Syntax
- **No duplicate constructor bodies** — Ensure initializer lists (`:`) and constructor bodies (`{`) are not duplicated from merge conflicts or copy-paste errors.
- **Parameter placement** — All constructor parameters must be inside the parentheses, before the initializer list.
- **Balanced brackets** — Check for unclosed strings, missing commas in multiline strings, and mismatched `{}`, `[]`, `()`.

### 2. Imports & Types
- **Import the correct model** — This project has two Hadith models:
  - `models/hadith.dart` — **Preferred**. Has typed `DisplayContext` from dua.dart.
  - `models/hadith_model.dart` — Legacy. Uses `Map<String, dynamic>?` for displayContext.
  - Always import `hadith.dart` when accessing `displayContext.timeWindows`, `.daysOfWeek`, etc.
- **Verify imports exist** — When adding a new class usage (e.g., `HadithsPage`), ensure the import is added to the file.

### 3. Localization
When using `l10n.someKey`:
- Ensure the key exists in **all** locale files:
  - `lib/l10n/app_localizations.dart` (abstract getter)
  - `lib/l10n/app_localizations_en.dart`
  - `lib/l10n/app_localizations_ar.dart`
  - `lib/l10n/app_localizations_es.dart`
  - `lib/l10n/app_localizations_fr.dart`
  - `lib/l10n/app_localizations_nl.dart`
  - `lib/l10n/app_localizations_zh.dart`

### 4. Navigation Items
- **Unique IDs** — Each `_NavItem` in `main.dart` must have a unique `id`. Duplicate IDs cause navigation bugs.
- **const correctness** — `_NavItem` can only be `const` if all its properties (including `page`) are const-constructible.

### 5. Method References
- **Check method exists** — Before calling private methods like `_determineActiveTimeWindow()`, verify the exact name. Similar methods may exist (e.g., `_determineActiveTimeWindows` plural vs singular).

### 6. Multiline Strings in Arguments
- **Use `\n` instead of actual newlines** — When passing multiline strings as arguments (e.g., to `ClipboardData(text: ...)`), use `\n` escape sequences instead of actual line breaks. Actual newlines in string literals within function calls cause parse errors.
  ```dart
  // BAD - causes parse errors
  ClipboardData(text: '${hadith.arabic}
  
  ${hadith.translationEn}')
  
  // GOOD
  ClipboardData(text: '${hadith.arabic}\n\n${hadith.translationEn}')
  ```

### 7. const Correctness
- **Don't use `const` with non-const values** — Remove `const` from widgets that reference non-const static fields like `AppColors.accent` (which is mutable via settings).

### 8. Dependency Injection (GetIt)
- **No duplicate registrations** — Each type can only be registered once in `lib/di/service_locator.dart`. Duplicate `registerLazySingleton` calls cause runtime errors.
- **Update test mocks** — When adding new required dependencies to controllers, add corresponding fakes in test files (e.g., `FakeHadithRepository`) and pass them explicitly.

### 9. Quick Validation
Run before committing:
```bash
flutter analyze
flutter test
flutter build apk --debug  # or: flutter build ios --debug
```
