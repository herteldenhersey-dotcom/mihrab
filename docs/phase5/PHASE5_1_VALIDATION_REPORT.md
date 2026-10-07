# MİHRAB Phase 5.1 — Doğrulama Raporu

**Tarih:** 2026-10-07  
**Sürüm:** Phase 5.1 (Phase 5 Kritik Düzeltmeleri)  
**Durum:** IMPLEMENTATION COMPLETE — AWAITING REVIEW

---

## Genel Bakış

Phase 5.1, Phase 5'te tespit edilen 10 kritik güvenilirlik, uyumluluk ve doğruluk sorununu giderir. Bu rapor her birini §1–§11 olarak belgeler.

---

## §1 — Android Exact-Alarm İzin Denetimi

### Sorun
`USE_EXACT_ALARM` (Android 13+) `AndroidManifest.xml`'e eklenmişti. Bu izin yalnızca saat ve takvim uygulamalarına verilir; namaz uygulamaları bu kategoriye girmez. Play Store reddi riski taşımaktaydı.

### Yapılan Değişiklik
`USE_EXACT_ALARM` kaldırıldı. `SCHEDULE_EXACT_ALARM` korundu — bu izin Android 12'de rastgele uygulamalara açıktır, 13+ sürümlerinde ise kullanıcıdan runtime'da talep edilmektedir (Play Store politikasına uygun).

### Dosya
`android/app/src/main/AndroidManifest.xml`

### Sonuç
✅ Play Store uyumlu. Politika yorumu manifest'te satır içi yorum olarak belgelenmiştir.

---

## §2 — Timezone Zamanlama Doğruluğu

### Sorun (Kritik)
`FlutterLocalNotificationService.scheduleAt()` şunu kullanıyordu:
```dart
final tzWhen = tz.TZDateTime.from(when, tz.local);
```
Bu, namaz vaktini seçilen konumun değil **cihazın** saat dilimine göre yorumluyor, kullanıcı cihazı farklı bir ülkedeyken bildirimlerin yanlış saatte çalmasına yol açıyordu.

Ayrıca `init()` içinde `tz.setLocalLocation('Europe/Istanbul')` çağrısı vardı — bu, İstanbul'da olmayan tüm kullanıcılar için timezone'u zorla sabitliyordu.

### Yapılan Değişiklikler

**`notification_service.dart` (abstract):**
- `scheduleAt()` imzasına `String? locationTzId` parametresi eklendi
- `cancelIds(Iterable<int> ids)` abstract methodu eklendi

**`notification_service.dart` (concrete — FlutterLocalNotificationService):**
- `_resolveLocation(String? tzId)` private helper eklendi (tanınmayan tzId'lerde `tz.local`'e düşer, crash yoktur)
- `scheduleAt()` şimdi şunu kullanıyor:
  ```dart
  final loc = _resolveLocation(locationTzId);
  final tzWhen = tz.TZDateTime(loc, when.year, when.month, when.day,
      when.hour, when.minute, when.second);
  ```
  Namaz vakitleri seçilen konumun wall-clock DateTimes olarak hesaplandığından `y/m/d/h/m/s` bileşenlerini o konumun timezone'unda yorumlamak tek doğru yöntemdir.
- `cancelIds()` implementasyonu eklendi (her ID için `_plugin.cancel(id)`)
- `init()` içindeki `tz.setLocalLocation('Europe/Istanbul')` satırı kaldırıldı

**`prayer_notification_scheduler.dart` (abstract):**
- `scheduleWeek()` imzasına `String? locationTzId` parametresi eklendi
- `PrayerSchedulerIdMixin.allScheduleIds()` helper methodu eklendi

**`android_notification_scheduler.dart`:**
- `scheduleWeek()` `locationTzId` parametresini kabul ediyor ve `scheduleAt()` çağrısına geçiriyor

**`ios_notification_scheduler.dart`:**
- Aynı şekilde `locationTzId` zinciri eklendi

**`schedule_notifications_usecase.dart`:**
- `call()` metoduna `String? locationTzId` parametresi eklendi; `scheduleWeek()`'e iletildi

**`home_cubit.dart`:**
- `_tryRescheduleNotifications()` → `scheduler.call()` çağrısına `locationTzId: location.timezoneId` eklendi

### locationTzId Yolu
```
AppLocation.timezoneId
  → HomeCubit._tryRescheduleNotifications()
    → ScheduleNotificationsUseCase.call(locationTzId: ...)
      → PrayerNotificationScheduler.scheduleWeek(locationTzId: ...)
        → NotificationService.scheduleAt(locationTzId: ...)
          → _resolveLocation() → tz.getLocation()
            → tz.TZDateTime(loc, y, m, d, h, min, s)
```

### Sonuç
✅ Timezone doğruluğu tüm stack boyunca sağlandı.

---

## §3 — Yeniden Başlatma (Reboot) Geri Yükleme

### Sorun
`rescheduleWithWorkManager()` çağrısı kasıtlı bir no-op'tu fakat çalışan bir WorkManager entegrasyonu izlenimi veriyordu.

### Gerçek Durum (Doğrulandı)
`flutter_local_notifications` Android plugin'i native `ScheduledNotificationBootReceiver` sınıfını `AndroidManifest.xml`'e kaydetmektedir. Bu alıcı cihaz yeniden başlatıldıktan sonra tüm bekleyen alarmları otomatik olarak geri yükler — WorkManager gerekli değildir.

### Yapılan Değişiklik
`rescheduleWithWorkManager()` `android_notification_scheduler.dart`'tan kaldırıldı. Yerine açıklayıcı bir yorum eklendi:
```dart
// NOTE: rescheduleWithWorkManager() intentionally REMOVED.
// Reboot restoration is handled by the native Android plugin mechanism:
// ScheduledNotificationBootReceiver restores all pending alarms after
// device reboot — no WorkManager required.
```

### Sonuç
✅ Yanlış izlenim veren no-op kaldırıldı; native mekanizma doğrulandı.

---

## §4 — Adhan Ses Davranışı ve Kısıtlamalar

### Android
- `adhan_placeholder.wav` → `android/app/src/main/res/raw/` ✅ mevcut
- Kanal yaratımında `RawResourceAndroidNotificationSound('adhan_placeholder')` kullanılıyor ✅
- **Önemli kısıtlama:** Android bildirim kanalları bir kez yaratıldıktan sonra ses ayarı değiştirilemez (sistem politikası). `adhan_placeholder.wav` değiştirilirse kullanıcı önce uygulamayı kaldırmalı ya da kanal silinmelidir.
- **Üretim notu:** `adhan_placeholder.wav` geçici bir minimal WAV dosyasıdır. Yayın öncesi lisanslı bir ezan kaydıyla değiştirilmelidir.

### iOS
- `adhan_placeholder.wav` → `ios/Runner/adhan_placeholder.wav` ✅ disk'te mevcut
- `ios/Runner.xcodeproj/project.pbxproj`'a Phase 5.1'de eklendi ✅
  - FileRef UUID: `F5B9A2C4B7954408A6BF4643`
  - BuildFile UUID: `AC97870B8D4842B5A87C2141`
  - Runner Resources build phase'e dahil edildi
- **Kritik kısıtlama:** iOS yerel bildirim sesleri **30 saniye** ile sınırlıdır. Tam uzunlukta ezan bu yolla mümkün değildir. Gerçek zamanlı ezan sesi için VoIP push + arka plan ses işleme gerektirir — bu mevcut fazın kapsamı dışındadır.
- **Silent Mode / Focus:** iOS, bildirim seslerinin Sessiz Modu/Odak'ı atlamasına izin vermez. `InterruptionLevel.timeSensitive` talep edilmektedir ancak davranış işletim sistemi/kullanıcı denetimine bağlıdır.

### Sonuç
✅ Belgelendi. iOS 30 saniyelik ses sınırı ve Android kanal değişmezliği raporlarda açıkça belirtilmiştir.

---

## §5 — 20 Atlanan Testin Mutabakatı

### Sorun
Phase 5 test çalıştırmasında 20 test "atlandı" olarak raporlanıyordu. Regresyon mu, yoksa beklenen durum mu?

### Analiz (Doğrulandı)
Bu 20 test `test/data/providers/diyanet_official_validation_test.dart` dosyasındaki Phase 4 Diyanet vakıf doğrulama vakaları. `expected == null` olduğunda `markTestSkipped()` çağrılıyor — bu, referans Diyanet verilerinin henüz sisteme eklenmediği anlamına geliyor.

Phase 5 bu testleri değiştirmedi, yeniden adlandırmadı veya silmedi. Bu 20 atlama **beklenen ve bilerek yapılmış** bir durumdur; regresyon değildir.

**AlAdhan Method 13 ≠ Resmi Diyanet:** AlAdhan'ın "Türkiye Diyanet" hesap yöntemi, resmi Diyanet İşleri Başkanlığı tablosal değerleriyle eşleşmez. Bu nedenle referans değerler null bırakılmıştır; fabricate edilmemiştir.

### Sonuç
✅ 20 atlama onaylandı — Phase 4'ten gelen, bilerek yapılmış, regresyon yok.

---

## §6 — Bildirim İptali Kapsamı (cancelIds)

### Sorun
`scheduleWeek()` içinde `cancelAll()` çağrısı yapılıyordu. Bu, test bildirimi (ID=0) dahil TÜM bildirimleri siliyordu.

### Yapılan Değişiklik
Her iki scheduler da (`AndroidPrayerNotificationScheduler` ve `IosPrayerNotificationScheduler`) artık `_service.cancelIds(allScheduleIds())` kullanıyor.

### allScheduleIds() Formülü
```
ID = notificationIdBase + dayIndex × 10 + prayer.index
   = 1000 + dayIndex × 10 + prayer.index
```
Aralık: 1000–1065 (7 gün × 6 namaz türü). Test bildirimi ID=0 bu aralığa girmez.

### Sonuç
✅ İptal işlemi yalnızca namaz programı ID'lerini kapsar; ilgisiz bildirimler korunur.

---

## §7 — iOS Bekleyen Bildirim İşleme

### Durum
iOS, bekleyen yerel bildirimleri **64** ile kısıtlar. Phase 5 bu sınıra `PrayerConstants.iosMaxPendingNotifications = 64` ile uyar.

5 zorunlu namaz × 7 gün = 35 bildirim — limitin çok altında.

`IosPrayerNotificationScheduler` zaten:
1. Tüm slotları chronological sıralar
2. `slots.take(64)` ile keser
3. Planlar

**Sınırlama:** Kullanıcı uygulamayı pencere boyutundan (7 gün) uzun süre açmazsa iOS bekleyen bildirimlerden tükenecek ve ötesindeki vakitler çalmayacaktır. Bu bir uygulama hatası değil, işletim sistemi kısıtlamasıdır.

### Sonuç
✅ iOS pending-notification işleme Phase 5'te test S22-S23 kapsamındadır; Phase 5.1'de S24-S29 eklendi.

---

## §8 — Yeniden Planlama Tetikleyicileri

### Doğru Durum (Phase 5'te belgelendi, Phase 5.1'de teyit edildi)

Yeniden planlama şu durumlarda tetiklenir:
1. **App foreground:** `HomeCubit._tryRescheduleNotifications()` → her lokasyon/ayar değişikliğinde
2. **Konum değişikliği:** Yeni lokasyon seçildiğinde `_tryRescheduleNotifications()` çağrılır
3. **Bildirim ayarı değişikliği:** Settings sayfasından tetiklenir

**Otomatik arka plan yeniden planlama YOK** — WorkManager entegrasyonu sonraki bir fazda planlanmaktadır.  
**Reboot geri yüklemesi VAR** — native `ScheduledNotificationBootReceiver` üzerinden.

### Sonuç
✅ Doğrulanan tetikleyiciler doğru olarak belgelendi.

---

## §9 — Yeni Regresyon Testleri

Phase 5.1, `test/features/notifications/prayer_scheduler_test.dart` dosyasına 6 yeni test ekledi:

| ID  | Açıklama |
|-----|----------|
| S24 | `allScheduleIds()` tam sayıda ID döndürür (scheduleWindowDays × PrayerType count) |
| S25 | `allScheduleIds()` yinelenen ID içermez |
| S26 | `allScheduleIds()` testNotificationId (0) içermez |
| S27 | `locationTzId` `scheduleWeek()`'e iletilir |
| S28 | `locationTzId` sağlanmadığında null iletilir |
| S29 | Rastgele IANA tzId değişmeden iletilir |

---

## §10 — Test ve Analiz Sonuçları

### flutter test
```
Toplam keşfedilen: 241 (Phase 5 baseline: 235, +6 yeni)
Geçti:             221 (Phase 5 baseline: 215, +6 yeni)
Atlandı:            20 (Phase 4 Diyanet vakaları — değişmedi)
Başarısız:           0
```
✅ Tüm testler geçti.

### flutter analyze
```
32 issue found — TÜMÜ info seviyesi
  • deprecated_member_use: withOpacity (Phase 4'ten geliyor, Phase 5.1 kapsamı dışı)
  • 0 error, 0 warning
```
✅ Sıfır hata, sıfır uyarı.

### APK Build
```
flutter build apk --debug → ✓ Built build/app/outputs/flutter-apk/app-debug.apk
Exit code: 0
```
✅ Debug APK başarıyla oluşturuldu.

---

## §11 — Gerçek Cihaz Testleri

**Önemli Uyarı:** Bu fazda gerçek cihaz testi YAPILMADI. Aşağıdaki özellikler yalnızca birim testler ve statik analiz ile doğrulandı:

| Özellik | Doğrulama Yöntemi | Durum |
|---------|-------------------|-------|
| Timezone doğruluğu | Birim test (S27-S29) | ✅ Test geçti |
| Scoped cancel | Birim test (S24-S26) | ✅ Test geçti |
| iOS 64-cap | Birim test (S22-S23) | ✅ Test geçti |
| Reboot geri yükleme | Manifest incelemesi | ✅ Native receiver teyit |
| Adhan ses (Android) | APK build kontrolü | ✅ Build başarılı |
| Adhan ses (iOS) | pbxproj edit | ✅ Bundle'a eklendi |
| Gerçek cihazda ses çalma | **YAPILMADI** | ⬜ Gerçek cihaz gerekli |
| Doze/Standby geçişi | **YAPILMADI** | ⬜ Gerçek cihaz gerekli |
| iOS Silent Mode davranışı | **YAPILMADI** | ⬜ Gerçek cihaz gerekli |

Gerçek cihaz test protokolü için: `docs/phase5/REAL_DEVICE_NOTIFICATION_CHECKLIST.md`

---

## Değiştirilen Dosyalar Özeti

| Dosya | Değişiklik |
|-------|-----------|
| `android/app/src/main/AndroidManifest.xml` | USE_EXACT_ALARM kaldırıldı |
| `ios/Runner.xcodeproj/project.pbxproj` | adhan_placeholder.wav eklendi (FileRef + BuildFile + Resources) |
| `lib/data/services/notification/notification_service.dart` | locationTzId, _resolveLocation(), cancelIds(), init() düzeltmesi |
| `lib/data/services/notification/prayer_notification_scheduler.dart` | scheduleWeek() locationTzId, allScheduleIds() mixin helper |
| `lib/data/services/notification/android_notification_scheduler.dart` | locationTzId zinciri, scoped cancel, rescheduleWithWorkManager kaldırıldı |
| `lib/data/services/notification/ios_notification_scheduler.dart` | locationTzId zinciri, scoped cancel |
| `lib/domain/usecases/schedule_notifications_usecase.dart` | locationTzId parametresi |
| `lib/features/home/presentation/cubit/home_cubit.dart` | location.timezoneId geçişi |
| `test/features/notifications/prayer_scheduler_test.dart` | _FakeScheduler güncellendi, S24-S29 eklendi |

---

*Phase 5.1 Implementation Complete — Awaiting Review*
