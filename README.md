# MİHRAB

MİHRAB — namaz vakitleri, kıble, yakındaki camiler, Ramazan ve Cuma yardımcısı
sunan bir İslami ibadet asistanı (Flutter mobil uygulaması).

> **Durum:** Phase 1 tamamlandı — temiz mimari (clean architecture) iskeleti,
> tüm soyutlamalar/arayüzler, yerelleştirme (tr/en/ar), namaz vakti motoru,
> bildirim stratejisi ve birim testleri. Ekranlar Phase 1'de yer tutucudur;
> canlı veri bağlama Phase 2'de gelir.

---

## Öne çıkanlar

- **Namaz vakti doğruluğu birinci öncelik.** Offline `adhan` motoru Diyanet
  yöntemine (`CalculationMethod.turkey`) eşlenir; kalan sistematik sapmalar
  kullanıcı başına ayarlanabilir **dakika bazlı offset** (`ManualOffsets`) ile
  giderilir. İstanbul 2024-03-15 için Diyanet referansıyla **±2 dk** karşılaştıran
  otomatik test mevcuttur (`test/data/providers/adhan_prayer_time_provider_test.dart`).
- **Değiştirilebilir vakit sağlayıcısı.** `PrayerTimeProvider` soyutlaması,
  ileride online bir Diyanet API'sine geçişi domain/presentation katmanlarına
  dokunmadan mümkün kılar.
- **iOS 64 bildirim limiti** ve **Android 12+ kesin alarm (exact alarm)** izinleri
  gözetilir; izin reddedilirse güvenli **inexact** geri dönüş devreye girer.
- **Overpass** cami arama: çift uç nokta (endpoint), yeniden deneme + geri çekilme
  (backoff), zaman aşımı ve 429 yönetimi, Hive önbelleği (24 saat TTL) ve sağlayıcı
  soyutlaması.
- **Geri bildirim** yerel Hive kuyruğu + `mailto` yedeği; `FeedbackRepository`
  soyutlaması korunur (Firebase/REST stub'ları hazır).

---

## Mimari (clean architecture)

```
lib/
├── core/            # Ortak altyapı: tema, sabitler, hatalar, ağ, yardımcılar, router
│   ├── constants/   # Kabe koordinatları, Overpass uçları, namaz sabitleri
│   ├── errors/      # sealed AppException + Failure eşlemesi
│   ├── network/     # DioClient, ConnectivityService
│   ├── router/      # AppRoutes + GoRouter (alt gezinme shell'i)
│   ├── theme/       # Material 3 açık/koyu tema
│   └── utils/       # Namaz/tarih/konum yardımcıları (Hicri dönüşüm dahil)
├── domain/          # Saf iş kuralları (Flutter'a bağımsız)
│   ├── enums/       # PrayerType, hesaplama yöntemi, dil, geri bildirim kategorisi
│   ├── models/      # DailyPrayerTimes, ManualOffsets, CalculationSettings, ...
│   ├── providers/   # PrayerTimeProvider (soyut)
│   ├── repositories/# Mosque/Feedback/Location/Settings (soyut)
│   └── usecases/    # GetPrayerTimes, GetNextPrayer, ScheduleNotifications, ...
├── data/            # Somut implementasyonlar
│   ├── providers/   # AdhanPrayerTimeProvider
│   ├── datasources/ # Overpass (remote), Hive + SharedPreferences (local)
│   ├── repositories/# Overpass/GooglePlaces, Local/Firebase/REST feedback, ...
│   └── services/    # Bildirim (iOS/Android zamanlayıcılar), konum, pusula
├── features/        # Sunum katmanı (Cubit + sayfalar), özellik başına
├── localization/    # ARB dosyaları (tr/en/ar) + üretilen AppLocalizations
├── app.dart         # MaterialApp.router (tema + yerelleştirme + router)
├── injection.dart   # get_it ile manuel DI (codegen yok)
└── main.dart        # Başlangıç: dotenv → DI → bildirim → runApp
```

Katman kuralı: `presentation → domain ← data`. Domain katmanı hiçbir Flutter/
paket detayına bağlı değildir.

---

## Kurulum

Gereksinimler: Flutter (stable, Dart 3.13+), Android SDK ve/veya Xcode.

```bash
# 1) Bağımlılıklar
flutter pub get

# 2) Ortam dosyası (gizli değerler) — .env sürüm kontrolüne EKLENMEZ
cp .env.example .env
#   .env içine gerçek değerleri yazın:
#     GOOGLE_MAPS_API_KEY=...   (Phase 2+ harita için, opsiyonel)
#     FEEDBACK_EMAIL=...        (geri bildirim mailto yedeği)

# 3) Yerelleştirme kodu (gerekirse yeniden üret)
flutter gen-l10n

# 4) Çalıştır
flutter run

# 5) Statik analiz ve testler
flutter analyze
flutter test
```

> **Not:** `.env` bir asset olarak paketlenir. Depoyu klonladıktan sonra derleme
> öncesi mutlaka `cp .env.example .env` yapın; aksi halde asset eksik olur.
> `main.dart` `.env` yokluğuna toleranslıdır (uygulama çökmez) ama build için
> dosyanın var olması gerekir.

---

## Ortam değişkenleri (`.env`)

| Anahtar | Açıklama | Zorunlu |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | Google harita/yer servisleri (Phase 2+) | Hayır (Phase 1) |
| `FEEDBACK_EMAIL` | Geri bildirim `mailto` yedeği için alıcı | Hayır (varsayılan gömülü) |

---

## Namaz vakti doğruluğu & Diyanet uyumu

- Varsayılan yöntem **Diyanet** (`CalculationMethod.turkey`: Fajr 18°, Isha 17°
  + yöntem düzeltmeleri). Asr için Şafii/Hanefi seçilebilir.
- Küçük sistematik sapmalar `CalculationSettings.offsets` (`ManualOffsets`,
  dakika bazlı) ile kullanıcı tarafında düzeltilebilir. Offset'ler ham hesaptan
  **sonra** use-case katmanında uygulanır (`DailyPrayerTimes.applyOffsets`).
- Doğrulama: İstanbul (41.0082, 28.9784), 15 Mart 2024 için motor çıktısı Diyanet
  referansına (`İmsak 05:44 · Güneş 07:08 · Öğle 13:18 · İkindi 16:37 · Akşam 19:18 · Yatsı 20:37`)
  ±2 dk içinde uyar. Ayrıntı: `test/README_TEST_NOTES.md`.

---

## Bildirim stratejisi (gerçek platform limitleri)

**iOS**
- iOS aynı anda **en fazla 64 bekleyen yerel bildirime** izin verir. Bu yüzden
  `IosPrayerNotificationScheduler` yalnızca bir **kayan pencere** (varsayılan 7 gün)
  için vakitleri sıralayıp ilk 64 slotu planlar; uygulama her açılışında yeniden
  doldurur.
- iOS'ta arka planda keyfi kod çalıştırılamaz; bu nedenle vakitler **önceden
  planlanmış yerel bildirimler** olarak kurulur (sunucu push'u yok).

**Android**
- Android 12+ (API 31) dakika hassasiyetli bildirim için **kesin alarm** izni
  ister (`SCHEDULE_EXACT_ALARM`). `AndroidPrayerNotificationScheduler` çalışma
  anında `canScheduleExactNotifications()` kontrol eder; izin yoksa
  `AndroidScheduleMode.inexactAllowWhileIdle` ile **güvenli geri dönüş** yapar.
- `USE_EXACT_ALARM` (Android 13+) manifesttedir; Google Play bunu yalnızca çekirdek
  işlevi alarm/hatırlatıcı/takvim olan uygulamalara açar. Namaz vakti uygulaması
  bu kapsama girer; Play incelemesi itiraz ederse `USE_EXACT_ALARM` kaldırılıp
  yukarıdaki inexact geri dönüşe güvenilebilir (kod hazır).
- Yeniden başlatma sonrası yeniden planlama için `RECEIVE_BOOT_COMPLETED` +
  `flutter_local_notifications` boot receiver'ları tanımlıdır.

---

## Teknik kararlar

- **Kod üretimi (codegen) kullanılmadı.** Dart 3.13 üzerinde
  `hive_generator`/`injectable_generator`/`build_runner` zinciri bozuk `macros`
  paketine bağımlı olduğundan bunlar çıkarıldı. Yerine **elle yazılmış Hive
  TypeAdapter'lar**, **elle get_it kaydı** ve **elle yazılmış test fake'leri**
  kullanıldı. Ayrıntılar `pubspec.yaml` içindeki açıklamalarda.
- Bağımlılık enjeksiyonu: `get_it` (manuel), yönlendirme: `go_router`
  (`StatefulShellRoute.indexedStack` ile kalıcı alt gezinme), durum yönetimi:
  `flutter_bloc` (Cubit).

---

## Faz durumu

| Faz | Kapsam | Durum |
|---|---|---|
| **Phase 1** | Mimari iskelet, tüm soyutlamalar, yerelleştirme, vakit motoru, bildirim stratejisi, testler | ✅ Tamamlandı |
| Phase 2 | Canlı veri bağlama (namaz vakitleri, kıble pusulası, cami haritası), ayarlar UI | ⏳ Planlandı |
| Phase 3 | Ramazan/Cuma özellikleri, bildirim ince ayarı, cilalama | ⏳ Planlandı |

---

## Not

`com.mihrab.app` şimdilik geliştirme (dev) kimliğidir; yayın öncesi kesin paket
kimliği belirlenecektir.
