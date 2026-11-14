# EGM Technical Design Document: Sakina Architectural & Code Review Fix Plan

**Document Path:** `docs/designs/fix-plan.md`  
**Target Branch:** `fix/antigravity-review`  
**Repository:** `https://github.com/almhtrf111312/Sakina`  
**Framework:** Elephant & Goldfish Model (EGM)  
**Coordinator (Elephant):** Agent 1  
**Audit Status:** **ACCEPTED BY GOLDFISH REVIEW** (Post-modifications incorporated)

---

## 1. Executive Summary & Context

The **Sakina (سكينة)** application is a lightweight, offline-first Islamic prayer times, adhan, azkar, Qibla compass, and lock-screen live wallpaper application built with Flutter and native Android (Kotlin).

This document serves as the comprehensive, actionable technical blueprint for remediating architectural defects, thread synchronization hazards, configuration discrepancies, and code deprecations across the codebase.

Execution strictly abides by the non-negotiable operational boundaries:
* **Code-level remediation and static analysis only:** No live emulation, manual testing, `flutter run`, or local `flutter build`. Verification is executed through static analysis (`flutter analyze`) and automated cloud CI (`GitHub Actions`).
* **Clean file partition across workers:** No two worker agents touch the same file.
* **Goldfish review before execution:** Implementation begins only after isolated Goldfish validation.

---

## 2. Brainstorming Analysis & Architectural Multi-Lens Findings

### Lens A: System Performance & Main-Thread Integrity
* **Finding:** Android receivers (`BootReceiver`, `TimeChangeReceiver`) execute on the system main thread. Synchronous I/O or JSON deserialization within `onReceive()` risks Application Not Responding (ANR) warnings under device startup stress. Simply spawning an untracked `Thread` allows the Android runtime to kill the process before background execution finishes.
* **Resolution:** Wrap background execution in `val pendingResult = goAsync()` and `Thread { try { ... } finally { pendingResult.finish() } }.start()`. This guarantees process survival without blocking the system main thread.

### Lens B: State Consistency & Dual Settings Discrepancy
* **Finding:** Two competing settings models exist: `domain/models/settings_model.dart` (`SettingsModel`, unpersisted in `main.dart`) and `data/settings/settings_repository.dart` (`AppSettings`, persisted in `SharedPreferences` and used throughout all feature screens). Changes made in `SettingsScreen` do not reflect in `SakinaApp`'s root theme and localization.
* **Resolution:** Unify the application root in `lib/main.dart` onto `appSettingsProvider` from `settings_repository.dart`. Theme (`day`, `night`, `amoled`), locale (`ar`, `en`, `tr`), and background decorations will dynamically react and persist immediately. In `domain/models/settings_model.dart`, export `AppThemeMode` from `settings_repository.dart` and mark `SettingsModel` as `@Deprecated` to prevent breaking imports.

### Lens C: Astronomical Formula Calibration & Model Alignment
* **Finding:** 
  1. Calculation method enums in `prayer_calculator.dart` (`ummAlQura`, `diyanet`) differed from `domain/models/prayer_time_model.dart` (`makkah`, `turkey`), which is an orphaned model.
  2. Numerical stability in `_hourAngle` must assert `cosH` clamping to `[-1.0, 1.0]` for extreme latitudes.
  3. Cache key serialization in `prayer_repository.dart` must incorporate coordinates, calculation method, madhab, highLatitudeRule, and prayer adjustments to guarantee cache invalidation upon any setting change.
* **Resolution:** Standardize astronomical method naming across calculators and UI, enforce `cosH` clamping in `_hourAngle`, and add all prayer configuration parameters to `_metaKey()`.

### Lens D: Android OS Boundaries & Security Policies
* **Finding:** 
  1. Android strictly prevents third-party applications from directly drawing into vendor-proprietary Always-On Display (AOD) firmware.
  2. `AlarmReceiver` in `AndroidManifest.xml` carried an erroneous `android:permission="android.permission.RECEIVE_BOOT_COMPLETED"`, causing permission denials when internal intents were dispatched.
  3. `AdhanForegroundService` requires exact foreground service types (`mediaPlayback|specialUse`) and strict receiver unregistration.
* **Resolution:** Remove the erroneous permission attribute from `AlarmReceiver`, confirm `RECEIVER_NOT_EXPORTED` flags on all internal dynamic broadcast receivers, and document the OS boundary in code and settings documentation: Sakina provides a Lock Screen Live Wallpaper + Full-Screen Adhan Intent.

### Lens E: CI/CD, Build Reproducibility & Signing Architecture
* **Finding:**
  1. The release build in GitHub Actions relies on a dynamically generated debug keystore, preventing in-place APK updates on physical user devices.
  2. Analysis options include deprecated lint rules (`avoid_returning_null_for_future`, `iterable_contains_unrelated_type`, `list_remove_unrelated_type`) generating warnings on Dart 3.3+.
  3. `pubspec.yaml` contains unused dependencies (`path_provider`).
* **Resolution:** Clean `analysis_options.yaml`, remove unused dependencies, enforce single `Sakina.apk` output on `ubuntu-24.04`, and implement conditional release signing via Gradle `key.properties` (with clean fallback to `debug` if absent) and GitHub Secrets (`KEYSTORE_BASE64`).

---

## 3. Strict Worker Agent Partition & Responsibilities

```
                               ┌────────────────────────┐
                               │   Agent 1: Elephant    │
                               │   (Coordinator/Arch)   │
                               └───────────┬────────────┘
         ┌───────────────┬─────────────────┼─────────────────┬───────────────┐
         ▼               ▼                 ▼                 ▼               ▼
   ┌───────────┐   ┌───────────┐     ┌───────────┐     ┌───────────┐   ┌───────────┐
   │  Agent 2  │   │  Agent 3  │     │  Agent 4  │     │  Agent 5  │   │  Agent 6  │
   │  Prayer & │   │ Alarms &  │     │ UI, State │     │ Wallpaper │   │  CI, Build│
   │ Location  │   │  Kotlin   │     │ & Dart    │     │   & AOD   │   │  & Deps   │
   └───────────┘   └───────────┘     └───────────┘     └───────────┘   └───────────┘
```

### Worker 2: Prayer Times & Location
* **Assigned Files:**
  * `lib/data/prayer/prayer_calculator.dart`
  * `lib/data/prayer/prayer_repository.dart`
  * `lib/data/location/location_service.dart`
  * `lib/core/utils/date_utils.dart`
  * `lib/core/utils/qibla_calculator.dart`
  * `lib/domain/models/prayer_time_model.dart`
* **Deliverables:**
  * Clamp `cosH` in `_hourAngle` between -1.0 and 1.0 to eliminate high-latitude NaN hazards.
  * Harmonize CalculationMethod enum names (`ummAlQura` standard) in `domain/models/prayer_time_model.dart`.
  * Ensure cache key `_metaKey()` in `prayer_repository.dart` incorporates method, madhab, highLatitudeRule, and adjustments.
  * Validate location fallbacks when GPS permissions are withheld.

### Worker 3: Alarms & Native Android (Kotlin)
* **Assigned Files:**
  * `android/app/src/main/kotlin/com/sakina/app/alarm/AlarmScheduler.kt`
  * `android/app/src/main/kotlin/com/sakina/app/alarm/AdhanReceiver.kt`
  * `android/app/src/main/kotlin/com/sakina/app/alarm/AlarmReceiver.kt`
  * `android/app/src/main/kotlin/com/sakina/app/alarm/BootReceiver.kt`
  * `android/app/src/main/kotlin/com/sakina/app/alarm/TimeChangeReceiver.kt`
  * `android/app/src/main/kotlin/com/sakina/app/service/AdhanForegroundService.kt`
  * `android/app/src/main/kotlin/com/sakina/app/bridge/AlarmBridgePlugin.kt`
  * `android/app/src/main/AndroidManifest.xml`
  * `lib/core/utils/alarm_bridge.dart`
  * `lib/data/notifications/prayer_alarm_sync.dart`
* **Deliverables:**
  * Remove erroneous `android:permission="android.permission.RECEIVE_BOOT_COMPLETED"` on `AlarmReceiver` in `AndroidManifest.xml`.
  * In `BootReceiver.kt` and `TimeChangeReceiver.kt`, wrap background scheduling in `val pendingResult = goAsync()` and `Thread { try { ... } finally { pendingResult.finish() } }.start()`.
  * Offload `cancelAllAlarms()` in `AlarmBridgePlugin.kt` to a worker thread with main thread handler callback.
  * Validate payload keys (`prayerTimes`, `soundId`, `notificationType`) between Dart and Kotlin.

### Worker 4: UI, Navigation & Unified Settings State Management (Dart)
* **Assigned Files:**
  * `lib/main.dart`
  * `lib/data/settings/settings_repository.dart`
  * `lib/domain/models/settings_model.dart`
  * `lib/features/home/home_screen.dart`
  * `lib/features/settings/settings_screen.dart`
  * `lib/features/azkar/azkar_screen.dart`
  * `lib/features/qibla/qibla_screen.dart`
  * `lib/features/tasbih/tasbih_screen.dart`
* **Deliverables:**
  * Refactor `lib/main.dart` to watch `appSettingsProvider` directly.
  * Map `AppThemeMode` (night, day, amoled, systemAuto) cleanly to Flutter `ThemeMode`.
  * In `domain/models/settings_model.dart`, export `AppThemeMode` from `settings_repository.dart` and mark `SettingsModel` and `SettingsNotifier` with `@Deprecated`.
  * Audit buttons, listeners, and dispose calls across all feature screens.

### Worker 5: Lock Screen Live Wallpaper & AOD
* **Assigned Files:**
  * `android/app/src/main/kotlin/com/sakina/app/aod/SakinaWallpaperService.kt`
  * `android/app/src/main/kotlin/com/sakina/app/aod/AodActivity.kt`
  * `android/app/src/main/kotlin/com/sakina/app/bridge/AodBridgePlugin.kt`
  * `android/app/src/main/res/xml/wallpaper.xml`
  * `lib/features/aod/aod_settings_screen.dart`
  * `lib/features/aod/aod_preview_screen.dart`
* **Deliverables:**
  * Reconcile `aod_settings_screen.dart` controls to persist changes via `appSettingsProvider` (using `settingsNotifierProvider`).
  * Verify `SakinaWallpaperService` parses multi-day `schedule` array and autonomously computes next prayer every minute.
  * Ensure canvas drawing lock/unlock handles exceptions cleanly without leaks.
  * Clearly document OS AOD platform restrictions in UI and code.

### Worker 6: Build, CI & Dependencies
* **Assigned Files:**
  * `.github/workflows/build_apk.yml`
  * `pubspec.yaml`
  * `analysis_options.yaml`
  * `android/build.gradle.kts`
  * `android/app/build.gradle.kts`
  * `android/settings.gradle.kts`
  * `android/app/proguard-rules.pro`
* **Deliverables:**
  * Remove deprecated linter rules (`avoid_returning_null_for_future`, `iterable_contains_unrelated_type`, `list_remove_unrelated_type`) from `analysis_options.yaml`.
  * Remove unused `path_provider` from `pubspec.yaml`.
  * In `android/app/build.gradle.kts`, implement robust conditional release signing via `key.properties` with fallback to `debug` if `key.properties` does not exist.
  * In `.github/workflows/build_apk.yml`, add conditional base64 keystore decode step when secrets are present.
  * Verify single APK output `Sakina.apk` uploaded as `Sakina-APK` artifact on `ubuntu-24.04`.

---

## 4. Goldfish Review Protocol & Acceptance Criteria

Three fresh-context Goldfish reviewers evaluate the changes across distinct scopes upon completion:
1. **Goldfish 1 (Dart & Architecture):** Validates reactive Riverpod state unification, memory leak prevention, and astronomical calculations.
2. **Goldfish 2 (Kotlin & Android Platform):** Validates thread safety, foreground service contracts, alarm manager permissions, and receiver lifecycles.
3. **Goldfish 3 (Build, Security & CI):** Validates Gradle dependency hygiene, ProGuard keep rules, and release signing strategy.
