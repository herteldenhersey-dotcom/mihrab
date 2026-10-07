# Phase 6 — Real-Device Ramadan Verification Checklist

> **Status legend:** `[ ]` NOT TESTED · `[x]` verified on device
>
> Every item below is **NOT TESTED** in this environment — this sandbox has no
> physical device, no Google Play Services, and cannot build/run iOS. These
> steps must be performed manually on real Android and iOS hardware before the
> Ramadan feature is shipped.

## 1. Hijri calendar accuracy
- [ ] On device, open the app on the official Diyanet first day of Ramadan and confirm the card shows **Day 1**.
- [ ] Confirm the day counter increments at the local civil midnight of the **selected location** (not device midnight) across a day boundary.
- [ ] Verify the estimated first/last dates match (or are within the documented ±1–2 day estimate window of) the official Diyanet announcement.
- [ ] Apply a Hijri adjustment of +1/-1 in settings and confirm the day counter and Imsak/Iftar day shift accordingly.
- [ ] Confirm the "estimate / not official" disclaimer is visible wherever dates are shown.

## 2. Imsak / Iftar times
- [ ] Imsak equals the app's Fajr time for the same day and location.
- [ ] Iftar equals the app's Maghrib time for the same day and location.
- [ ] Change the calculation method/location and confirm Imsak/Iftar update consistently with the prayer screen.

## 3. Countdown engine
- [ ] Before Imsak: countdown targets Imsak and decrements each second.
- [ ] Between Imsak and Iftar: countdown targets Iftar.
- [ ] After Iftar: countdown targets tomorrow's Imsak.
- [ ] Lock the phone for several minutes, reopen — countdown shows the correct value (clock-based, no drift).
- [ ] Cross Imsak and Iftar boundaries while watching — the phase flips without showing a negative value.

## 4. Sahur / Iftar notifications (Android)
- [ ] Enable Sahur reminder; confirm it fires at `Imsak − offset` for the selected location timezone.
- [ ] Enable Iftar reminder; confirm it fires at `Maghrib − offset` (offset 0 fires exactly at Iftar).
- [ ] Change offsets (15/30/45/60 for Sahur; 0/5/10/15/30 for Iftar) and confirm the fire time changes.
- [ ] Confirm reminders use the **ordinary reminder channel**, NOT the adhan sound channel.
- [ ] Toggle a reminder off and confirm the corresponding pending notification is removed (and the other category stays).
- [ ] Exact alarm permission: with permission denied, confirm reminders still schedule (inexact) and the app does not crash.
- [ ] Reboot the device and confirm reminders are re-scheduled (or re-scheduled on next app open).

## 5. Sahur / Iftar notifications (iOS)
- [ ] Enable both reminders and confirm both fire at the correct times.
- [ ] Confirm total pending notifications (prayer + Ramadan) never exceeds the iOS 64 cap (see capacity audit in completion report).
- [ ] Confirm prayer-time notifications are NOT dropped when Ramadan reminders are added.

## 6. Notification ID isolation (CRITICAL)
- [ ] Schedule prayer + Ramadan reminders, then disable Ramadan reminders; confirm prayer notifications are **untouched** (scoped cancel, never `cancelAll`).
- [ ] Fire a test notification (id 0) and confirm it never collides with a Ramadan reminder.
- [ ] Inspect pending notifications; confirm all Ramadan ids are within **2000–2099**.

## 7. Timezone correctness
- [ ] Set a location in a timezone different from the device; confirm Imsak/Iftar, countdown and reminder fire-times all use the **selected location** timezone.
- [ ] Travel/change device timezone without changing the selected location; confirm Ramadan times do not shift.

## 8. Home card & settings UI
- [ ] Ramadan card appears on Home during Ramadan with day/Imsak/Iftar/countdown.
- [ ] Outside Ramadan the card shows the next-Ramadan estimate with disclaimer.
- [ ] Hiding the card in settings removes it from Home.
- [ ] All strings render correctly in TR, EN, and AR (AR right-to-left).

## 9. 29 vs 30-day Ramadan
- [ ] Confirm the card's `totalDays` reflects 29 or 30 for the current Hijri year (never hardcoded 30).
- [ ] At the end of a 29-day Ramadan, confirm the counter does not show a non-existent day 30.

## 10. Regression
- [ ] Prayer times, Qibla, mosques, notifications and settings all continue to work unchanged.
