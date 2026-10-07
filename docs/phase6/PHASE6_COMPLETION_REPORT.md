# Phase 6 — Ramadan Experience, Sahur & Iftar — Completion Report

## 1. Scope delivered
Phase 6 adds a complete, offline-capable Ramadan experience to MİHRAB:

- **Hijri (Islamic) calendar service** — pure Dart tabular/arithmetic calendar, no network.
- **Ramadan domain layer** — entities, repository interface, and 4 use cases.
- **Data layer** — repository implementation (SharedPreferences-backed settings) and a dedicated Ramadan notification scheduler.
- **Presentation** — `RamadanCubit` + sealed state, a live countdown engine, a Home card, and a settings page.
- **Localization** — 30 Ramadan keys added across TR / EN / AR.
- **Tests** — 52 new tests in `test/features/ramadan/`.

## 2. Files added
| Layer | File |
|---|---|
| Hijri | `lib/data/services/hijri/hijri_calendar_service.dart` |
| Entities | `lib/domain/entities/ramadan_info.dart`, `ramadan_settings.dart`, `ramadan_notification_schedule.dart` |
| Repo interface | `lib/domain/repositories/ramadan_repository.dart` |
| Use cases | `lib/domain/usecases/get_ramadan_info_usecase.dart`, `get_ramadan_settings_usecase.dart`, `save_ramadan_settings_usecase.dart`, `schedule_ramadan_notifications_usecase.dart` |
| Repo impl | `lib/data/repositories/ramadan_repository_impl.dart` |
| Scheduler | `lib/data/services/ramadan/ramadan_notification_scheduler.dart` |
| Cubit/state | `lib/features/ramadan/presentation/cubit/ramadan_cubit.dart`, `ramadan_state.dart`, `ramadan_countdown_service.dart` |
| Widgets | `lib/features/ramadan/presentation/widgets/ramadan_card.dart`, `ramadan_countdown.dart` |
| Page | `lib/features/ramadan/presentation/pages/ramadan_page.dart` (rewritten from placeholder) |
| Tests | `test/features/ramadan/{hijri_calendar,countdown,notification_scheduler,schedule_usecase,repository_settings,localization}_test.dart` |
| Docs | `docs/phase6/REAL_DEVICE_RAMADAN_CHECKLIST.md`, this report |

## 3. Files modified
- `lib/injection.dart` — DI registration for the Hijri service, Ramadan repository, scheduler, 4 use cases and `RamadanCubit`.
- `lib/features/home/presentation/pages/home_page.dart` — inserts the self-contained `RamadanCard` after the next-prayer hero card.
- `lib/localization/l10n/app_{tr,en,ar}.arb` + `lib/localization/app_localizations*.dart` — 30 Ramadan keys (hand-maintained localization).

## 4. Hijri calendar design & accuracy
- Algorithm: **tabular (arithmetic) Islamic calendar**, civil epoch (JDN 1948440 = 1 Muharram 1 AH), 30-year cycle leap set `{2,5,7,10,13,16,18,21,24,26,29}`.
- Supports **29 or 30-day** Ramadan (month length computed, never hardcoded).
- Validated anchors (algorithm output ↔ official Diyanet Turkey start of Ramadan):
  - 1 Ramadan 1445 → **11 Mar 2024** ✔
  - 1 Ramadan 1446 → **1 Mar 2025** ✔
  - 1 Ramadan 1447 → **18 Feb 2026** ✔
- **Estimate disclaimer:** algorithmic dates can differ from official moon-sighting announcements by ±1–2 days; the UI always labels dates as estimates and never as officially confirmed. A user-configurable **Hijri adjustment (−3..+3 days)** lets users align with the local official announcement.
- Independent of the legacy `core/utils/date_utils.dart` Hijri helper (unchanged, still used by its own tests).

## 5. Imsak / Iftar — reuse of existing calculation
No prayer-time math is duplicated. `Imsak = Fajr` and `Iftar = Maghrib`, both obtained from the existing `GetPrayerTimesUseCase`. Offsets already applied inside that use case are respected.

## 6. Countdown engine
`RamadanCountdownService` is a pure, clock-based engine with three phases
(`beforeImsak` → `fasting` → `afterIftar`). It recomputes from a supplied `now`
each tick (1 s timer in the cubit), so it never drifts and survives
pause/resume by simple recomputation. It never returns a negative duration and
formats as `HH:mm:ss`.

## 7. Notification ID ownership (CRITICAL — zero collisions)
| Owner | ID range |
|---|---|
| Test notification | `0` |
| Prayer schedule | `1000–1065` |
| **Ramadan schedule** | **`2000–2099`** |

- Formula: `2000 + dayIndex × 2 + typeOffset` (Sahur = 0, Iftar = 1).
- 7-day horizon → 14 ids used (`2000–2013`); the 2000–2099 band leaves headroom.
- Cancellation is **always scoped** via `NotificationService.cancelIds(ramadanScheduleIds())` — **`cancelAll()` is never called** from the Ramadan feature, so prayer and test notifications are never collaterally removed. Enforced by tests R33, R37, R42, R43.

## 8. Notification behaviour
- Sahur fires at `Imsak − sahurOffset` (15/30/45/60 min); Iftar at `Maghrib − iftarOffset` (0/5/10/15/30 min, 0 = at Iftar).
- Offsets crossing midnight are handled by plain `DateTime` subtraction (test R31).
- Past events are filtered when a reference `now` is supplied (test R30).
- Ramadan reminders use the **ordinary reminder channel**, never the adhan sound channel (test R35).
- All reminders are scheduled against the **selected location's IANA timezone** (`locationTzId`), never the device timezone (tests R36, R41).
- When both reminders are disabled, the use case performs a scoped cancel and schedules nothing (test R42).

## 9. iOS 64 pending-notification capacity audit
- Prayer worst case: `scheduleWindowDays (7) × 5 obligatory = 35`.
- Ramadan worst case: `horizonDays (7) × 2 = 14`.
- **Total: 49 ≤ 64** iOS cap. Verified by test R38. Headroom remains for the test notification and future categories.

## 10. Timezone handling
`RamadanCubit` mirrors `HomeCubit`'s timezone resolution: it prefers the saved
location's IANA id, then country-code resolution, then coordinate resolution,
then the cached zone. All "now"/day computations use that zone.

## 11. Localization
30 Ramadan keys added to TR / EN / AR (ARB + abstract + 3 impl files). Parity
and non-blank/ Arabic-script guards are covered by tests R49–R52 and the
existing `test/localization/arb_keys_test.dart` (full key-set parity).

## 12. Test results
- **New Ramadan tests:** 52 / 52 passing (`test/features/ramadan/`).
  - R01–R11 Hijri calendar · R12–R18 countdown · R19–R38 notification scheduler
    (IDs, scoped cancel, offsets, midnight, iOS cap) · R39–R44 schedule use case ·
    R45–R48 repository/settings persistence · R49–R52 localization.
- **Full suite:** see "Validation" below — no regressions to the Phase 5.1 baseline.
- **Static analysis:** `flutter analyze lib` → 0 errors, 0 warnings (only pre-existing
  `withOpacity` deprecation infos and a few `prefer_initializing_formals` infos).

## 13. Validation performed in this environment
- `flutter pub get` — OK.
- `flutter analyze lib` — 0 errors / 0 warnings (info-level lints only).
- `flutter test test/features/ramadan/` — 52/52 pass.
- `flutter test` (full) — results recorded at commit time (no regressions; prior
  Diyanet-validation skips remain skipped by design).

## 14. NOT done / NOT tested (explicit)
- **iOS build: NOT BUILT.** This environment cannot build or run iOS; iOS behaviour is unverified.
- **Real-device behaviour: NOT TESTED** — all device items are tracked in `REAL_DEVICE_RAMADAN_CHECKLIST.md`.
- Actual OS notification delivery, reboot re-scheduling, and exact-alarm permission flows are not exercised by unit tests.
- Phase 7 work has **not** been started.

## 15. Follow-ups / recommendations
- Wire a reschedule trigger on Ramadan settings-save and on location/method change into the live notification pipeline on a real device, then tick the checklist.
- Consider surfacing the Ramadan settings entry from the main Settings screen (currently reachable via the Home card and the `ramadan` route).
- Re-validate Hijri anchors against each year's official Diyanet announcement and expose the adjustment prominently.
