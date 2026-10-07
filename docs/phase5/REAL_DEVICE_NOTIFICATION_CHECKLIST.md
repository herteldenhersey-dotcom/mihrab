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

---

## Phase 5.1 Güncellemesi — Gerçek Cihaz Test Notları

**Tarih:** 2026-10-07

### Timezone Doğruluğu — Kritik Test
Phase 5.1'in en önemli değişikliği timezone doğruluğudur. Gerçek cihazda test edilmesi GEREKİR:

**Senaryo:**
1. Uygulamada konum olarak **İstanbul** seç (Europe/Istanbul)
2. Cihazı **farklı bir timezone'a** al (örn. UTC, London, New York)
3. Namaz vakti bildiriminin **İstanbul wall-clock saatinde** çalıp çalmadığını kontrol et
4. Beklenen: Bildirim İstanbul saatiyle çalar, cihaz timezone'uyla değil

**Phase 5 öncesinde bu test başarısız olurdu** — bildirim cihaz timezone'unda çalırdı.  
**Phase 5.1 sonrasında** `tz.TZDateTime(Europe/Istanbul, y, m, d, h, min, s)` kullanıldığı için doğru saatte çalmalıdır.

### Scoped Cancel Doğrulaması
1. Ayarlar → Test Bildirimi gönder (ID=0)
2. Hemen akabinde Bildirim Ayarlarını kaydet (yeniden planlama tetiklenir)
3. Test bildiriminin **silinmediğini** ve 5 saniye içinde çaldığını doğrula
4. Phase 5.1 öncesinde `cancelAll()` test bildirimini de siliyordu

### iOS adhan_placeholder.wav Kontrolü
- `adhan_placeholder.wav` artık `ios/Runner.xcodeproj/project.pbxproj`'a eklendi
- iOS build'de ses dosyasının bundle'a dahil edildiğini doğrula:
  ```
  Xcode → Runner → Build Phases → Copy Bundle Resources → adhan_placeholder.wav ✓
  ```
- Ezan bildirimi çaldığında özel sesin sistem varsayılanı yerine kullanıldığını test et

### Hatırlatma
- iOS tam uzunlukta ezan: **MÜMKÜN DEĞİL** (30 saniyelik limit). Belgelendi.
- Android kanal ses değiştirme: **MÜMKÜN DEĞİL** (kanal bir kez oluşturulunca). Belgelendi.
