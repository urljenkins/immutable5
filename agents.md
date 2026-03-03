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
