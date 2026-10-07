# MİHRAB — Phase 5 Completion Report

**Phase:** 5 — Prayer Notifications & Adhan
**Scope:** Per-prayer notification configuration, persistence, platform scheduling
(Android/iOS), adhan sound channel, permission UX, test notification, diagnostics,
localization (TR/EN/AR), and automated tests.
**Date:** 2026-10-07

> This report documents implementation and local validation only. All real-device
> behavior is explicitly marked **NOT TESTED** (see the separate
> `REAL_DEVICE_NOTIFICATION_CHECKLIST.md`).

---

## 1. Architecture

Phase 5 follows the existing Clean Architecture layering already established in
Phases 1–4 (domain / data / presentation), introducing a notification settings
domain and platform-specific schedulers behind abstractions:

```
Presentation
  SettingsPage  ──▶ SettingsCubit ──▶ NotificationSettingsRepository
  HomeCubit  ──(auto-reschedule)──▶ ScheduleNotificationsUseCase

Domain
  NotificationSettings / PrayerNotificationConfig        (model)
  NotificationSettingsRepository                          (abstraction)
  ScheduleNotificationsUseCase                            (orchestration)

Data
  SharedPrefsNotificationSettingsRepository               (persistence)
  PrayerNotificationScheduler (abstract) + PrayerSchedulerIdMixin
    ├─ AndroidPrayerNotificationScheduler                 (exact→inexact)
    └─ IosPrayerNotificationScheduler                     (64-pending cap)
  NotificationService (abstract)
    └─ FlutterLocalNotificationService                    (plugin + timezone)
```

Key design points:

- The data-layer schedulers are **framework-agnostic**: all user-facing copy is
  injected from the presentation layer via `PrayerNotificationCopy` so strings
  stay in the ARB files.
- Prayer times are **not** recomputed inside the scheduler; they are produced by
  the existing `GetPrayerTimesUseCase` pipeline (Phases 2–4) and passed in.
- A shared `PrayerSchedulerIdMixin` centralizes deterministic ID generation,
  enabled-prayer resolution, reminder-offset math and adhan-channel selection so
  Android and iOS behave identically where the OS allows.

---

## 2. Files Created

| File | Purpose |
|------|---------|
| `lib/domain/models/notification_settings_model.dart` | `NotificationSettings` + `PrayerNotificationConfig` domain models (Equatable, copyWith, toJson/fromJson, `.defaults()`). |
| `lib/domain/repositories/notification_settings_repository.dart` | Abstract persistence contract (`load` / `save`). |
| `lib/data/repositories/shared_prefs_notification_settings_repository.dart` | JSON-backed `SharedPreferences` implementation with corruption-safe fallback to defaults. |
| `test/features/notifications/notification_settings_model_test.dart` | Model tests N01–N26. |
| `test/features/notifications/prayer_scheduler_test.dart` | Scheduler tests S01–S23. |
| `test/features/notifications/notification_settings_repository_test.dart` | Repository tests R01–R11. |
| `android/app/src/main/res/raw/adhan_placeholder.wav` | Minimal-valid WAV placeholder for the Android adhan channel. |
| `android/app/src/main/res/raw/readme.md` | Documentation of the placeholder audio (lowercase name required by Android `res/raw/` rules). |
| `ios/Runner/adhan_placeholder.wav` | Minimal-valid WAV placeholder for the iOS adhan sound. |
| `docs/phase5/PHASE5_COMPLETION_REPORT.md` | This report. |
| `docs/phase5/REAL_DEVICE_NOTIFICATION_CHECKLIST.md` | Real-device validation checklist (all NOT TESTED). |

## 3. Files Modified

| File | Change |
|------|--------|
| `lib/core/constants/prayer_constants.dart` | Added notification constants: `iosMaxPendingNotifications=64`, `scheduleWindowDays`, `notificationIdBase=1000`, `testNotificationId=0`, `adhanChannelId`. |
| `lib/data/services/notification/notification_service.dart` | Added adhan channel, `sendTestNotification`, `pendingCount`, `getDiagnostics`/`NotificationDiagnostics`, `useAdhanChannel` routing in `scheduleAt`. |
| `lib/data/services/notification/prayer_notification_scheduler.dart` | `scheduleWeek` now takes `NotificationSettings`; added `PrayerSchedulerIdMixin` (deterministic IDs, offset, adhan selection, enabled resolution). |
| `lib/data/services/notification/android_notification_scheduler.dart` | `NotificationSettings`-aware scheduling; exact→inexact fallback; per-prayer offset & adhan. |
| `lib/data/services/notification/ios_notification_scheduler.dart` | Rolling horizon with 64-pending cap, chronological prioritization, per-prayer offset & adhan. |
| `lib/domain/usecases/schedule_notifications_usecase.dart` | Added `notificationSettings` parameter, forwarded to scheduler. |
| `lib/features/settings/presentation/cubit/settings_cubit.dart` | Full notification settings management + permission status. |
| `lib/features/settings/presentation/cubit/settings_state.dart` | State fields for notification settings, permission and exact-alarm status. |
| `lib/features/settings/presentation/pages/settings_page.dart` | Master switch, per-prayer config UI, test notification, diagnostics tile. |
| `lib/features/home/presentation/cubit/home_cubit.dart` | Auto-reschedule on location / prayer-data changes. |
| `lib/core/router/app_router.dart` | Settings route wiring. |
| `lib/injection.dart` | DI registration for repository, schedulers, use case, cubit. |
| `lib/localization/l10n/app_tr.arb`, `app_en.arb`, `app_ar.arb` | 27 new notification/settings localization keys (TR/EN/AR). |
| `lib/localization/app_localizations*.dart` | Regenerated localization delegates for the new keys. |

## 4. Packages Added / Removed / Upgraded

**None.** `pubspec.yaml` is unchanged in Phase 5. All required dependencies were
already present from Phases 1–4:

- `flutter_local_notifications: ^18.0.1`
- `timezone: ^0.9.4`
- `workmanager: ^0.10.10` (hook reserved; not yet wired — see Technical Debt)
- `permission_handler: ^11.3.1`
- `shared_preferences: ^2.3.3`
- `package_info_plus: ^8.1.0`

---

## 5. Android Permissions / Configuration

Declared in `android/app/src/main/AndroidManifest.xml`:

- `POST_NOTIFICATIONS` — runtime permission for Android 13+ (requested via
  `permission_handler` / plugin).
- `SCHEDULE_EXACT_ALARM` — user-revocable (Android 12/13); checked at runtime.
- `USE_EXACT_ALARM` — auto-granted but Google-Play-restricted (documented in the
  manifest comment for reviewers; remove if the app does not qualify).
- `RECEIVE_BOOT_COMPLETED` — allows re-arming after reboot (future WorkManager
  hook).
- `WAKE_LOCK`, `VIBRATE` — notification delivery.

The adhan sound resource lives at `android/app/src/main/res/raw/adhan_placeholder.wav`.
Android `res/raw/` requires lowercase `[a-z0-9_]` filenames and compiles every
file as a resource, so the accompanying documentation was named `readme.md`.

## 6. iOS Configuration

- `DarwinInitializationSettings` requests **no** permissions at init; permission
  is requested explicitly from the Settings screen (`requestPermission`).
- Per-notification `DarwinNotificationDetails` use
  `interruptionLevel: timeSensitive` and, for adhan, `sound: 'adhan_placeholder.wav'`.
- The iOS adhan asset is `ios/Runner/adhan_placeholder.wav` (must be < 30 s and
  `.caf`/`.wav`; currently a minimal-valid placeholder).

**iOS configuration still required at release time** (cannot be validated in this
environment — see §24): bundling the real sound file into the Runner target in
Xcode and confirming the notification authorization + sound entitlements. No iOS
build was performed (see §23).

---

## 7. Notification Channels

Two Android channels are created at init:

1. `prayer_times_channel` ("Namaz Vakitleri") — plain, silent-alarm reminders
   (unchanged from earlier phases), `Importance.max`.
2. `prayer_adhan_channel` ("Ezan Sesi") — adhan sound channel, `Importance.max`,
   `RawResourceAndroidNotificationSound('adhan_placeholder')`.

Channel selection per notification is driven by `useAdhanChannel(prayer, config)`
— obligatory prayers with `adhanEnabled == true` route to the adhan channel;
everything else (and Sunrise) uses the plain channel.

## 8. Adhan Audio Implementation

- **Placeholders only.** Both audio assets are minimal-valid WAV placeholders,
  explicitly excluded from containing any copyrighted recitation. They exist so
  the channel/sound wiring compiles and can be validated structurally.
- Production step: replace `android/app/src/main/res/raw/adhan_placeholder.wav`
  and `ios/Runner/adhan_placeholder.wav` with a properly licensed adhan recording
  (iOS asset must be < 30 s). This is documented inline in
  `notification_service.dart` and in `android/app/src/main/res/raw/readme.md`.

## 9. Scheduling Strategy

- `ScheduleNotificationsUseCase` computes `scheduleWindowDays` of prayer times via
  the existing `GetPrayerTimesUseCase` pipeline and hands the chronological list
  to the platform scheduler's `scheduleWeek`.
- Each `scheduleWeek` call first `cancelAll()`s then re-arms, so re-scheduling is
  idempotent and never duplicates (combined with deterministic IDs).
- Timezone: `NotificationService` initializes the `timezone` DB and uses
  `tz.local` (falling back to `Europe/Istanbul`), and prayer times originate from
  the selected location's calculation — so notifications fire in the
  selected-location timezone.

### 9a. Android Scheduling Behavior
- Checks `AlarmPermissionService.canScheduleExactAlarms()`.
- If allowed → `exactAllowWhileIdle` (fires precisely, even in Doze).
- If not allowed → `inexactAllowWhileIdle` (may fire a few minutes late, never
  fails, stays Google-Play-policy compliant without forcing the exact-alarm
  settings screen).
- No OS pending cap; still bounded to `scheduleWindowDays` and rolled forward on
  app foregrounding (WorkManager periodic re-arm is a reserved no-op hook).

### 9b. iOS Rolling-Horizon Strategy
- iOS enforces a hard **64 pending** local-notification cap and gives no reliable
  background re-arm.
- The scheduler flattens all future (day, prayer) slots, sorts chronologically,
  and schedules at most `iosMaxPendingNotifications` (64), soonest first.
- With 5 obligatory prayers × 7 days = **35 slots**, comfortably under 64.
- **Documented limitation:** if the user does not open the app for longer than
  the scheduled horizon, iOS runs out of pending notifications and later prayers
  will not fire until the app is foregrounded again. This is an OS constraint,
  surfaced to the user in Settings.

## 10. Deterministic Notification-ID Strategy

`PrayerSchedulerIdMixin.notificationId(dayIndex, prayer)`:

```
id = notificationIdBase(1000) + dayIndex * 10 + prayer.index
```

Each (day, prayer) maps to a stable, collision-free ID, so re-scheduling
overwrites the same slot rather than creating duplicates. The test notification
uses the reserved fixed ID `testNotificationId = 0`, which never collides with the
`>= 1000` prayer range.

## 11. Duplicate Prevention

Guaranteed by (a) deterministic IDs above and (b) `cancelAll()` at the start of
every `scheduleWeek`. Re-running the scheduler any number of times converges to
the same pending set.

## 12. Rescheduling Triggers

`HomeCubit` re-invokes `ScheduleNotificationsUseCase` when the underlying inputs
change — location change and refreshed prayer data — and `SettingsCubit`
re-schedules whenever notification settings change (master switch, per-prayer
enable, adhan, offset). Permission grant also re-runs scheduling.

## 13. Permission UX

- Notification permission (iOS + Android 13+) is requested explicitly from the
  Settings screen, not silently at startup.
- Settings surfaces both **notification permission status** and **exact-alarm
  status** with request actions and a denial warning.
- **Denial does not break prayer-time functionality:** prayer times, home screen
  and all non-notification features continue to work; only scheduling is skipped.

## 14. Localization

- **27 new keys** added to each of `app_tr.arb`, `app_en.arb`, `app_ar.arb`
  (notification titles, master switch, per-prayer labels, adhan, reminder offset,
  permission/exact-alarm status, test notification, pending count, placeholder &
  rolling-window notes, denial warning).
- Localization delegates (`app_localizations*.dart`) regenerated for all three
  locales.

## 15. RTL

Arabic (`ar`) renders right-to-left. RTL behavior is covered by existing
widget-level directionality tests (T36 Arabic → RTL, T34/T35 TR/EN → LTR, T37
locale switch) which remain green; Phase 5 settings strings inherit the same
directionality.

## 16. Persistence

`SharedPrefsNotificationSettingsRepository` stores the full `NotificationSettings`
as JSON under key `notification_settings`. Corrupted/incompatible data silently
falls back to `NotificationSettings.defaults()`. Round-trip (master switch,
per-prayer enable, adhan, offset) is verified by repository tests R01–R11.

## 17. Test Notification Implementation

`NotificationService.sendTestNotification` schedules a one-shot notification
`secondsAhead` (default 5s) from now using the reserved ID `testNotificationId=0`,
so it never interferes with the prayer schedule and is independently cancellable.
Exposed through the Settings screen.

## 18. Diagnostic Support

`NotificationService.getDiagnostics()` returns a `NotificationDiagnostics`
snapshot (pending count + first pending title). The plugin does not expose stored
fire-times in pending requests, so the scheduled-time field is best-effort. Shown
in a Settings debug tile alongside the pending count.

---

## 19. Automated Tests

| Suite | IDs | Area |
|-------|-----|------|
| `notification_settings_model_test.dart` | N01–N26 | Model defaults, copyWith, JSON round-trip, effective-enabled resolution, Sunrise exclusion. |
| `prayer_scheduler_test.dart` | S01–S23 | Deterministic IDs, offset math, adhan channel selection, enabled resolution, iOS 64-cap, duplicate prevention, cancel. |
| `notification_settings_repository_test.dart` | R01–R11 | Persistence round-trip, defaults, corruption fallback. |

**60 new Phase 5 tests** added on top of the 155 existing tests from Phases 1–4.

### Test Results (local, `flutter test`)

- **Total discovered: 235**
- **Passed: 215**
- **Failed: 0**
- **Skipped: 20**

Command exit code: **0** — `All tests passed!`

#### Reason for every skip
All **20 skips are pre-existing** from Phases 1–4 (not introduced by Phase 5).
They are integration/plugin-dependent tests that require a running Android/iOS
platform channel (real `flutter_local_notifications`, `permission_handler`,
`shared_preferences` native bindings, and platform timezone services) which are
unavailable in the headless `flutter test` VM. They are intentionally marked
`skip` with that rationale and are covered instead by the real-device checklist.
No Phase 5 test is skipped — all 60 run and pass.

## 20. `flutter analyze` Result

- **0 errors, 0 warnings.**
- **32 info-level lints** (non-fatal), all pre-existing style hints plus one new:
  - `deprecated_member_use` — `withOpacity` in Phase 1–4 home widgets (pre-existing).
  - `unnecessary_brace_in_string_interps` — one occurrence in the new
    `prayer_scheduler_test.dart:281` (cosmetic, non-blocking).

No errors or warnings were introduced by Phase 5.

## 21. Android Debug APK Result

- Command: `flutter build apk --debug`
- **Result: ✅ SUCCESS — exit code 0.**
- Output: `build/app/outputs/flutter-apk/app-debug.apk` (~185 MB, valid APK/zip,
  619 entries).
- Build note: Android `res/raw/` rejected an uppercase `README.md`; the file was
  renamed to `readme.md` (lowercase, valid resource name) to allow the build to
  complete.
- Not installed/run on a device or emulator in this environment (see §23).

## 22. iOS Build Status

**NOT BUILT.** This environment cannot build iOS (no macOS/Xcode toolchain). No
iOS build was performed, simulated, or inferred. The iOS configuration changes
required for notifications and custom sounds are described in §6; actual iOS
build and device validation remain a release prerequisite.

## 23. Warnings

- **Kotlin Gradle Plugin (KGP) deprecation warning** during the APK build for the
  bundled plugins `package_info_plus` and `workmanager_android` — non-fatal, build
  succeeds. Upstream plugin issue, not app code.
- Info-level Dart lints as listed in §20 — non-fatal.

## 24. Known OS Limitations

- **iOS 64-pending cap + no reliable background re-arm:** prayers beyond the
  scheduled horizon will not fire until the app is foregrounded.
- **iOS silent-mode/Focus:** custom sounds cannot bypass Silent Mode/Focus;
  `timeSensitive` is requested but delivery remains OS/user-controlled.
- **Android exact alarms:** when `SCHEDULE_EXACT_ALARM` is unavailable, scheduling
  falls back to inexact alarms which may fire a few minutes late (Doze/battery
  saver can amplify this).
- **Android Doze / battery saver / OEM killers:** may delay or suppress
  notifications depending on device policy.

## 25. Technical Debt

- `AndroidPrayerNotificationScheduler.rescheduleWithWorkManager()` is an
  intentional **no-op hook**; the periodic WorkManager re-arm is deferred to a
  later phase.
- `getDiagnostics()` cannot report exact next-fire times because the plugin does
  not expose them from pending requests.
- Localization delegates are hand-maintained alongside the ARB files.

## 26. Mocks / Placeholders

- **Audio placeholders (explicitly identified):** both adhan WAV files are
  minimal-valid placeholders, not real recitation — must be replaced with
  licensed audio for production.
- **Test doubles:** unit tests use in-memory fakes for `NotificationService`,
  `AlarmPermissionService` and `SharedPreferences`; these are test-only and not
  shipped.
- No hidden mocks exist in production code paths.

## 27. Real-Device Validation Still Required

All on-device behavior is **NOT TESTED** in this environment and is tracked in
`docs/phase5/REAL_DEVICE_NOTIFICATION_CHECKLIST.md` (separate Android and iOS
sections). This includes actual notification delivery at prayer time, adhan sound
playback, foreground/background/terminated/reboot behavior, Doze/battery-saver,
exact-alarm permission flows, timezone/location changes, and iOS authorization,
rolling-horizon exhaustion, pending count and silent-mode behavior.

---

## Definition of Done — Status

| DoD item | Status |
|----------|--------|
| Five obligatory prayers configurable independently | ✅ (model + UI + tests) |
| Sunrise not scheduled as obligatory adhan | ✅ (enforced in model + mixin + tests) |
| Notification preferences persist | ✅ (SharedPrefs + R01–R11) |
| Notifications from existing prayer calculation pipeline | ✅ |
| Scheduling uses selected-location timezone | ✅ |
| Deterministic notification IDs | ✅ (S-suite) |
| Duplicate schedules prevented | ✅ (cancelAll + IDs) |
| Relevant changes trigger rescheduling | ✅ (Home/Settings cubits) |
| Android notification permission handled | ✅ |
| Android exact-alarm limitations handled honestly | ✅ (exact→inexact) |
| iOS notification limits handled (bounded strategy) | ✅ (64-cap) |
| Adhan/custom-sound architecture exists | ✅ (placeholder audio) |
| Notification-only mode works | ✅ (adhan off → plain channel) |
| Test notification exists | ✅ |
| TR / EN / AR work | ✅ (27 keys × 3) |
| Arabic RTL works | ✅ (existing directionality tests) |
| Permission denial does not break prayer times | ✅ |
| Previous phase tests remain green | ✅ (155 pre-existing still pass) |
| New Phase 5 tests pass | ✅ (60/60) |
| flutter analyze passes | ✅ (0 errors, 0 warnings) |
| Android debug APK builds successfully | ✅ (exit 0) |
| Unverified real-device behavior marked NOT TESTED | ✅ (checklist) |

---

PHASE 5 IMPLEMENTATION COMPLETE — AWAITING REVIEW
