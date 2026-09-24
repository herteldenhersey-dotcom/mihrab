# MİHRAB — Phase 4 Real-Device Test Checklist

> **Separate automated tests from real-device validation.**  
> Automated: `flutter test` (155 passed, 20 skipped, 0 failed)  
> This document: manual validation on physical hardware / emulator.

---

## A. Launch & Onboarding Flow

| # | Check | Pass | Notes |
|---|---|---|---|
| A1 | Fresh install → onboarding appears | ☐ | |
| A2 | Complete onboarding → Home screen appears (no GPS re-request) | ☐ | |
| A3 | Correct saved location city shown in header | ☐ | |
| A4 | Correct country shown | ☐ | |

---

## B. Date Display

| # | Check | Pass | Notes |
|---|---|---|---|
| B1 | Gregorian date matches selected-location date (not device timezone) | ☐ | e.g. device=London 00:30, location=Tokyo: should show Tokyo's date |
| B2 | Turkish locale: Gregorian month name in Turkish | ☐ | |
| B3 | English locale: Gregorian month name in English | ☐ | |
| B4 | Arabic locale: Gregorian date in Arabic numerals / right format | ☐ | |
| B5 | Hijri date visible with disclaimer label | ☐ | |
| B6 | Hijri date plausible (±1 day of local authority) | ☐ | |

---

## C. Prayer Times

| # | Check | Pass | Notes |
|---|---|---|---|
| C1 | Six prayer times shown: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | ☐ | |
| C2 | Times match expected values for selected city | ☐ | Cross-check with diyanet.gov.tr or similar |
| C3 | Sunrise visually distinct from obligatory prayers | ☐ | Italic / secondary colour / note label |
| C4 | Current/next prayer is visually highlighted | ☐ | |

---

## D. Countdown

| # | Check | Pass | Notes |
|---|---|---|---|
| D1 | Countdown ticks visibly every second | ☐ | |
| D2 | Countdown shows correct prayer name | ☐ | |
| D3 | Between Fajr and Dhuhr: "Next" shows Dhuhr (not Sunrise) | ☐ | |
| D4 | After Isha: "Next" shows Fajr, time is tomorrow's Fajr | ☐ | |
| D5 | Countdown never goes negative | ☐ | |

---

## E. Background / Foreground Lifecycle

| # | Check | Pass | Notes |
|---|---|---|---|
| E1 | Background app for 5 min → resume: countdown continues correctly (no drift) | ☐ | |
| E2 | Background before a prayer → resume after that prayer: next prayer updated | ☐ | |
| E3 | Background before midnight → resume after midnight: tomorrow's times loaded | ☐ | |
| E4 | Background across Isha → resume: shows Fajr as next (tomorrow) | ☐ | |

---

## F. Theme

| # | Check | Pass | Notes |
|---|---|---|---|
| F1 | Light theme: readable, no contrast issues | ☐ | |
| F2 | Dark theme: readable, no contrast issues | ☐ | |
| F3 | System theme: follows OS setting in real time | ☐ | |

---

## G. Localization

| # | Check | Pass | Notes |
|---|---|---|---|
| G1 | Turkish (tr): all strings in Turkish | ☐ | |
| G2 | English (en): all strings in English | ☐ | |
| G3 | Arabic (ar): all strings in Arabic | ☐ | |
| G4 | Arabic: layout is RTL (text right-aligned, layout mirrored) | ☐ | |
| G5 | Arabic: Hijri month names render correctly in Arabic script | ☐ | |
| G6 | Switch locale at runtime → Home updates without restart | ☐ | |

---

## H. Accessibility

| # | Check | Pass | Notes |
|---|---|---|---|
| H1 | Large font (Accessibility → Font size 130–200%): city name not clipped | ☐ | |
| H2 | TalkBack (Android) / VoiceOver (iOS): countdown announced on change | ☐ | `liveRegion: true` |
| H3 | TalkBack: prayer names readable | ☐ | |

---

## I. Location Change

| # | Check | Pass | Notes |
|---|---|---|---|
| I1 | Manually change location from Settings → Home refreshes without restart | ☐ | |
| I2 | New city name shown immediately | ☐ | |
| I3 | New prayer times calculated for new city | ☐ | |
| I4 | Countdown restarts for new next prayer | ☐ | |

---

## J. Missing Location / Error States

| # | Check | Pass | Notes |
|---|---|---|---|
| J1 | Clear app data → fresh launch → no crash | ☐ | |
| J2 | Missing location state shown with localized message | ☐ | |
| J3 | "Set Location" button navigates to location setup | ☐ | |
| J4 | Failure state (force timezone failure) shows retry button | ☐ | |
| J5 | Retry button triggers reload without restart | ☐ | |

---

## K. Offline

| # | Check | Pass | Notes |
|---|---|---|---|
| K1 | Airplane mode after first successful launch → prayer times still shown | ☐ | |
| K2 | Countdown still works offline | ☐ | |
| K3 | First-ever launch in airplane mode → graceful failure state (not crash) | ☐ | |

---

## L. Device-Specific

| # | Check | Pass | Notes |
|---|---|---|---|
| L1 | Device timezone ≠ selected location timezone: Home uses selected location date | ☐ | e.g. device in UTC+0, selected city Istanbul UTC+3 |
| L2 | Physical device API 21+ (Android 5.0) | ☐ | Min SDK |
| L3 | Notch / punch-hole screens: header not obscured | ☐ | |
| L4 | Tablet layout: prayer list not excessively stretched | ☐ | |

---

## Result Summary

| Category | Checks | Passed | Failed | Blocked |
|---|---|---|---|---|
| A. Launch | 4 | | | |
| B. Date | 6 | | | |
| C. Prayer times | 4 | | | |
| D. Countdown | 5 | | | |
| E. Lifecycle | 4 | | | |
| F. Theme | 3 | | | |
| G. Localization | 6 | | | |
| H. Accessibility | 3 | | | |
| I. Location change | 4 | | | |
| J. Missing/error | 5 | | | |
| K. Offline | 3 | | | |
| L. Device | 4 | | | |
| **Total** | **51** | | | |

---

*Tester:*  
*Device:*  
*OS version:*  
*Date:*  
*App version/commit:*
