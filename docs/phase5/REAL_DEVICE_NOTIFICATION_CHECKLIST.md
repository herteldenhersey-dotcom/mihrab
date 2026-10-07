# MİHRAB — Phase 5 Real-Device Notification Checklist

This checklist tracks **on-device** validation of Phase 5 (Prayer Notifications &
Adhan). None of these items can be verified in the headless build/test
environment, so **every item is marked `☐ NOT TESTED`**. An item may only be
changed to PASS/FAIL after it has actually been exercised on a physical device
(or supported emulator/simulator) and the observed behavior recorded.

**Legend:** `☐ NOT TESTED` · `☑ PASS` · `☒ FAIL`

> Reminder: the adhan sound assets are minimal-valid **placeholders**. Audio
> playback items validate wiring, not final recitation. Replace with licensed
> audio before release sign-off.

---

## Android

### Permissions & Install
- ☐ NOT TESTED — Fresh install: first notification permission flow appears as expected
- ☐ NOT TESTED — Android 13+ runtime `POST_NOTIFICATIONS` permission prompt and grant
- ☐ NOT TESTED — Exact-alarm permission available: `SCHEDULE_EXACT_ALARM` granted → exact scheduling used
- ☐ NOT TESTED — Exact-alarm permission unavailable/revoked: graceful fallback to inexact alarms
- ☐ NOT TESTED — Permission denial does NOT break prayer-time display or other features

### Delivery
- ☐ NOT TESTED — Notification fires at the scheduled prayer time
- ☐ NOT TESTED — Adhan/custom sound plays on the adhan channel when enabled
- ☐ NOT TESTED — Notification-only mode (adhan off) uses the plain channel, no adhan sound
- ☐ NOT TESTED — Reminder offset (fire N minutes before prayer time) delivers at the offset time

### App / Device States
- ☐ NOT TESTED — App in foreground: notification delivered
- ☐ NOT TESTED — App in background: notification delivered
- ☐ NOT TESTED — App terminated (swiped away): notification delivered
- ☐ NOT TESTED — Screen locked: notification delivered and visible
- ☐ NOT TESTED — After device reboot: schedule re-armed / notifications still fire
- ☐ NOT TESTED — Battery saver enabled: delivery behavior observed and acceptable
- ☐ NOT TESTED — Doze mode: delivery behavior observed and acceptable

### Rescheduling Triggers
- ☐ NOT TESTED — Location change triggers reschedule with correct new times
- ☐ NOT TESTED — Timezone change triggers reschedule with correct local times
- ☐ NOT TESTED — Manual prayer offset change triggers reschedule
- ☐ NOT TESTED — Notification settings change (master/per-prayer/adhan) triggers reschedule

### Test & Diagnostics
- ☐ NOT TESTED — Test notification fires a few seconds after being triggered
- ☐ NOT TESTED — Diagnostics pending count reflects the actual scheduled notifications

---

## iOS

> iOS could NOT be built in this environment (no macOS/Xcode toolchain). All iOS
> items below are pending a real macOS build + device/simulator run. The real
> adhan sound file must also be bundled into the Runner target in Xcode.

### Authorization & Sound
- ☐ NOT TESTED — Notification authorization flow (alert/badge/sound) requested and granted
- ☐ NOT TESTED — Custom adhan sound plays when enabled (< 30 s asset bundled in Runner)

### App / Device States
- ☐ NOT TESTED — App in foreground: notification presented
- ☐ NOT TESTED — App in background: notification delivered
- ☐ NOT TESTED — App terminated: notification delivered
- ☐ NOT TESTED — Device locked: notification delivered and visible

### Rolling Horizon & Limits
- ☐ NOT TESTED — Pending-notification count stays within the 64 OS cap
- ☐ NOT TESTED — Rolling horizon re-arms on app foreground (window rolls forward)
- ☐ NOT TESTED — Behavior when app unopened beyond the horizon (later prayers do not fire — OS limitation confirmed)

### Rescheduling Triggers
- ☐ NOT TESTED — Location change triggers reschedule with correct new times
- ☐ NOT TESTED — Timezone change triggers reschedule with correct local times
- ☐ NOT TESTED — Settings change (master/per-prayer/adhan/offset) triggers reschedule

### Test & Silent Mode
- ☐ NOT TESTED — Test notification fires a few seconds after being triggered
- ☐ NOT TESTED — Silent-mode / Focus behavior observed (timeSensitive requested; delivery OS/user-controlled)
