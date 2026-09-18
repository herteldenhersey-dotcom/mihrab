# MİHRAB — Phase 3 Tamamlanma Raporu (Konum Onboarding)

> Bu rapor, spec'teki (bkz. `Uploads/user_message_2026-09-18_13-24-36.txt`, Bölüm 26)
> 30 maddelik başlıkları birebir takip eder. Faz 3 tamamlandı; **Faz 4'e otomatik geçilmedi**.
> Onay bekleniyor.

Tarih: 2026-09-18 · Branch: `main` · Repo: `herteldenhersey-dotcom/mihrab`

---

## 1. Yönetici Özeti (Executive summary)

Faz 3, onboarding akışına **üretim kalitesinde konum belirleme adımını** ekler.
Kullanıcı konumunu iki yoldan belirleyebilir:

1. **"Konumumu Kullan"** — cihaz GPS'i üzerinden tek seferlik konum tespiti (takip yok).
2. **"Elle Seç"** — uluslararası, gerçek (mock değil) metin-tabanlı konum arama.

Tasarımın merkezinde şu ilkeler var:

- **Uygulama, GPS reddedilse bile asla kullanılamaz hâle gelmez** — elle seçim her zaman açıktır.
- **Minimum izin** — yalnızca "kullanım sırasında konum" (when-in-use). Arka plan konumu/takip **yok**.
- **Açık izin durum modeli** — granted / denied / permanentlyDenied / serviceDisabled ayrı ayrı ele alınır;
  kalıcı ret → **Ayarları Aç** yönlendirmesi, servis kapalı → **Konum ayarlarını aç**.
- **Reverse-geocode başarısızlığı kurulumu bozmaz** — adres çözülemese bile koordinatlar kullanılır.
- **Katmanlı akış**: UI → Cubit → Repository → Provider. UI hiçbir zaman doğrudan Geolocator çağırmaz.
- **Elle arama gerçek** ve `LocationSearchRepository` soyutlaması arkasında; veri kaynağı kararı belgelendi.

Kod tamam, `flutter analyze` temiz, tam test paketi geçiyor (0 başarısız), Android debug APK derleniyor.
Cihaza özgü davranışlar (gerçek GPS, gerçek OS izin diyalogları, ekran görüntüleri) **otomatik test edilemez**;
bunlar Bölüm 29 ve ayrı gerçek-cihaz kontrol listesinde **REQUIRES REAL DEVICE VALIDATION** olarak işaretlidir.

---

## 2. Uygulanan Mimari (Architecture implemented)

Akış katmanlı ve tek yönlü:

```
LocationStep (UI, Widget)
   │  kullanıcı etkileşimi (buton/aramalar)
   ▼
LocationOnboardingCubit  ── state: DeviceLocationStatus + ManualSearchStatus + resolved(AppLocation?)
   │            │
   │            └────────────► LocationSearchRepository (abstract)
   │                                  └── GeocodingLocationSearchRepository (data)
   │
   ├────────────► LocationRepository (abstract)
   │                     └── GeolocatorLocationRepository (data)  ── Geolocator/geocoding platform API
   │
   └────────────► SettingsRepository (persist) ── HiveSettingsRepository
```

- **UI, platform API'lerini asla doğrudan çağırmaz.** Tüm cihaz/ağ erişimi repository soyutlamaları arkasında.
- `LocationOnboardingCubit`, çözülen `AppLocation`'ı `OnboardingCubit`'e `BlocListener` ile aynalar;
  onboarding "devam" kapısı buna bağlıdır.
- Durum modeli açıktır (aşağıda Bölüm 8). "Durum çorbası" yerine ayrık enum'lar kullanılır.

---

## 3. Oluşturulan Dosyalar (Files created)

Kaynak (lib):
- `lib/domain/enums/location_permission_status.dart` — `LocationPermissionStatus { granted, denied, permanentlyDenied, serviceDisabled }`.
- `lib/domain/models/location_search_result.dart` — `LocationSearchResult` (Equatable): koordinatlar + country/city/district/displayName, `hasValidCoordinates`, `toAppLocation()` (isManual=true).
- `lib/domain/repositories/location_search_repository.dart` — soyut `search(query, {limit=6})`.
- `lib/data/repositories/geocoding_location_search_repository.dart` — `LocationSearchRepository` implementasyonu (forward + reverse geocoding). **Veri-kaynağı kararı** dosya başındaki doküman yorumunda açıklanır.
- `lib/features/onboarding/presentation/cubit/location_onboarding_cubit.dart` — `LocationOnboardingCubit`.
- `lib/features/onboarding/presentation/cubit/location_onboarding_state.dart` — state + `DeviceLocationStatus` / `ManualSearchStatus` enum'ları.

Testler (test):
- `test/helpers/fake_settings_repository.dart` — in-memory `FakeSettingsRepository`.
- `test/features/onboarding/location_onboarding_cubit_test.dart` — izin/GPS (8) + elle seçim (7) + reset.
- `test/domain/models/location_model_test.dart` — koordinat doğrulama, displayName, JSON round-trip, `LocationSearchResult`.
- `test/data/repositories/location_persistence_test.dart` — gerçek `HiveSettingsRepository` ile kalıcılık/restart.
- `test/features/onboarding/onboarding_cubit_location_test.dart` — setLocation/clear/complete kalıcılığı.
- `test/features/onboarding/location_prayer_integration_test.dart` — elle konum → gerçek `AdhanPrayerTimeProvider`.
- `test/localization/location_keys_test.dart` — 30 konum anahtarının tr/en/ar paritesi + Arapça script kontrolü.

Dokümanlar (docs):
- `docs/phase3/PHASE3_COMPLETION_REPORT.md` (bu dosya)
- `docs/phase3/REAL_DEVICE_TEST_CHECKLIST.md`
- `docs/phase3/flutter_test.log`, `flutter_analyze.log`, `flutter_build_apk.log`

---

## 4. Değiştirilen Dosyalar (Files modified)

- `lib/domain/models/location_model.dart` — `static bool isValidCoordinate(lat,lng)` (finite + |lat|≤90 + |lng|≤180) ve `bool get hasValidCoordinates`.
- `lib/domain/repositories/location_repository.dart` — eklendi: `requestPermission()`, `openAppSettings()`, `openLocationSettings()` (mevcut metotlar korundu).
- `lib/data/repositories/geolocator_location_repository.dart` — yeni metotların implementasyonu; `getCurrentLocation` koordinat doğrulaması + `TimeoutException`→`TimeoutAppException`; tek-seferlik doğruluk politikası (LocationAccuracy.high, 15 sn, takip yok) belgelendi.
- `lib/features/onboarding/presentation/cubit/onboarding_cubit.dart` — `setLocation(AppLocation?)` (null→clearLocation); `complete()` geçerli konumu idempotent şekilde yeniden kalıcılaştırır.
- `lib/features/onboarding/presentation/cubit/onboarding_state.dart` — `location` alanı + copyWith(clearLocation) + props.
- `lib/features/onboarding/presentation/pages/location_step.dart` — stub'dan tam yeniden inşa (tüm UI durumları, RTL uyumlu).
- `lib/features/onboarding/presentation/pages/onboarding_page.dart` — `locationStepIndex=1` kapısı: konum yokken "Devam" pasif.
- `lib/injection.dart` — `LocationSearchRepository → GeocodingLocationSearchRepository` (lazySingleton) kaydı.
- `lib/localization/l10n/app_en.arb`, `app_tr.arb`, `app_ar.arb` — 30 konum anahtarı.
- `ios/Runner/Info.plist` — `NSLocationAlwaysAndWhenInUse*` ve `NSLocationAlways*` anahtarları **kaldırıldı** (yalnızca when-in-use kaldı); V1 arka-plan-yok kararı yorumla açıklandı.

---

## 5. Eklenen/Kaldırılan/Yükseltilen Paketler (Packages)

- **Eklenen paket YOK.** Faz 3, mevcut `pubspec.yaml` bağımlılıklarıyla tamamlandı:
  - `geolocator` (cihaz konumu, izin, ayar açma), `geocoding` (forward/reverse), `permission_handler` (mevcuttu), `hive` (kalıcılık), `bloc/flutter_bloc`, `equatable`, `get_it`.
- **Kaldırılan/yükseltilen paket YOK.**
- Gereksiz bağımlılık eklenmedi (spec kuralı).

---

## 6. Otomatik Konum İmplementasyonu (Automatic location)

`LocationOnboardingCubit.useMyLocation()`:
1. **Çift-tetik koruması** — zaten yükleniyorsa yeni istek yok sayılır; buton yükleme sırasında pasif.
2. `LocationRepository.requestPermission()` çağrılır → domain enum'una eşlenir.
3. Sonuç durumları ayrı ayrı işlenir:
   - `serviceDisabled` → `DeviceLocationStatus.serviceDisabled` (Konum ayarlarını aç eylemi).
   - `denied` → `permissionDenied` (Tekrar dene).
   - `permanentlyDenied` → `permissionPermanentlyDenied` (Ayarları Aç).
   - `granted` → `getCurrentLocation()` çağrılır.
4. Koordinatlar `AppLocation.isValidCoordinate` ile doğrulanır (NaN/inf/imkânsız reddedilir).
5. Reverse-geocode denenir; **başarısız olursa koordinatlar yine de kullanılır** (adres opsiyonel).
6. Geçerli `AppLocation` (isManual=false) `SettingsRepository.saveLocation` ile kalıcılaştırılır ve state'e yazılır.
7. Zaman aşımı `timeout`, diğer hatalar `failure` durumuna eşlenir; UI'da ham exception görünmez.

**Tek seferlik konum**, sürekli takip değil: `getPositionStream` kullanılmaz.

---

## 7. Elle Konum İmplementasyonu (Manual location)

`LocationSearchRepository` (soyut) + `GeocodingLocationSearchRepository` (implementasyon):

- **Veri-kaynağı kararı (belgelendi):** platform `geocoding` paketiyle **ileri (forward) geocoding**
  (`locationFromAddress`) kullanılır; sonuç koordinatları **ters (reverse) geocoding** ile zenginleştirilerek
  ülke/şehir/ilçe alanları doldurulur. Bu, kademeli (ülke→şehir→ilçe) çevrimdışı bir seçiciye tercih edildi:
  uluslararası kapsam, ek veri seti/paket yükü olmadan sağlanır. Karar ve gizlilik açıklaması
  `geocoding_location_search_repository.dart` başındaki doküman yorumunda yer alır.
- **Gerçek**, mock değil. `search(query)`:
  - Min. sorgu uzunluğu 2 karakter (altında `idle`).
  - Geçersiz koordinatlı sonuçlar filtrelenir; 2-ondalık kova ile dedup.
  - Boş sonuç → `ManualSearchStatus.empty`; ağ/zaman aşımı → `error` (işlevsel "Tekrar dene").
- `selectResult()` seçilen sonucu doğrular ve `AppLocation` (isManual=true) olarak kalıcılaştırır.

---

## 8. İzin Yönetimi (Permission handling)

- **Yerelleştirilmiş gerekçe (rationale) native diyalogdan ÖNCE** gösterilir (`_RationaleCard`).
- Açık durum modeli — `DeviceLocationStatus`: `idle, loading, success, serviceDisabled, permissionDenied, permissionPermanentlyDenied, timeout, failure`.
- Her duruma özel yerelleştirilmiş mesaj + eylem:
  - serviceDisabled → **Konum ayarlarını aç** (`openLocationSettings`).
  - permissionDenied → **Tekrar dene**.
  - permissionPermanentlyDenied → **Ayarları Aç** (`openAppSettings`).
  - timeout / failure → **Tekrar dene**.
- Her durumda **elle seçim erişilebilir kalır** → uygulama asla kilitlenmez.

---

## 9. Konum Kalıcılığı (Location persistence)

- Mevcut `AppLocation` depolaması (`SettingsRepository` / `HiveSettingsRepository`) kullanıldı; yeni depolama mekanizması eklenmedi.
- Yalnızca **geçerli koordinatlı** konumlar kaydedilir (`isValidCoordinate` kapısı).
- Test edildi (`location_persistence_test.dart`): kaydet→oku round-trip, uygulama yeniden başlatma (yeni repo örneği) sonrası hayatta kalma, GPS için `isManual=false`.

---

## 10. Onboarding Kalıcılığı (Onboarding persistence)

- `OnboardingCubit.setLocation` çözülen konumu state'e ve kalıcı depoya aynalar.
- `complete()` tamamlanma durumunu kalıcılaştırır ve geçerli konumu idempotent şekilde yeniden yazar.
- "Devam" butonu, konum adımında (`step index 1`) konum yokken pasiftir (kullanıcı adımı atlayamaz).
- Test edildi (`onboarding_cubit_location_test.dart`, `location_persistence_test.dart`).

---

## 11. Namaz Motoru Entegrasyonu (Prayer-engine integration)

- Elle seçilen konumun koordinatları, **gerçek** `AdhanPrayerTimeProvider` → `GetPrayerTimesUseCase` zincirine beslenir.
- Test edildi (`location_prayer_integration_test.dart`): 2024-03-15 İstanbul koordinatları için geçerli, **sıralı** namaz vakitleri (fajr < sunrise < dhuhr < asr < maghrib < isha) üretilir. Mock provider değil, gerçek hesaplama motoru.

---

## 12. Gizlilik Etkileri (Privacy implications)

- **Üçüncü taraf geocoder koordinat alır:** hem otomatik (reverse geocoding) hem elle (forward geocoding) yollar,
  platformun `geocoding` servisine (Android'de Google, iOS'ta Apple) koordinat/sorgu gönderir. Bu, Play Store
  **Data Safety** ve App Store gizlilik beyanında açıklanmalıdır.
- Konum **yalnızca cihazda** (Hive) saklanır; MİHRAB kendi sunucusuna konum göndermez.
- **Arka plan konumu/takip yok**; tek seferlik tespit.
- Gizlilik notu ilgili repository dosyasının doküman yorumunda da bulunur.

---

## 13. Android İzin/Yapılandırma Değişiklikleri

- `AndroidManifest.xml` yalnızca `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` içerir (doğrulandı).
- **`ACCESS_BACKGROUND_LOCATION` hiçbir yerde yok** (grep ile android/ genelinde doğrulandı).
- Yeni izin eklenmedi.

---

## 14. iOS İzin/Yapılandırma Değişiklikleri

- `ios/Runner/Info.plist`: yalnızca `NSLocationWhenInUseUsageDescription` bırakıldı.
- **Kaldırıldı:** `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription` (arka plan konumu gerektirir; V1'de gerekmez).
- Karar, plist içinde yorumla açıklandı.

---

## 15. Yerelleştirme Eklemeleri (Localization additions)

- **30 anahtar** eklendi ve tr/en/ar üçünde de mevcut (parite testi geçiyor):
  27 `location*` anahtarı + `openAppSettings`, `openLocationSettings`, `tryAgain`.
- `location_keys_test.dart` her üç dilde varlık + boş-olmama + Arapça için Arap-script içerme kontrolü yapar.

---

## 16. RTL Doğrulaması (RTL validation)

- LocationStep tamamen `AlignmentDirectional` / `EdgeInsetsDirectional` ile yazıldı (sabit left/right yok).
- Mevcut `rtl_widget_test.dart` regresyonsuz geçiyor (Arapça RTL, TR/EN LTR, runtime TR→AR / AR→EN geçişi).
- **Not:** Gerçek görsel RTL doğrulaması (ekran görüntüsü) gerçek cihaz/emülatör gerektirir — Bölüm 29.

---

## 17. Eklenen Otomatik Testler (Automated tests added)

38 yeni test eklendi (hepsi geçiyor), fake'lerle platform/ağ bağımlılığı izole edildi:
- İzin/GPS akışı: 8+ (izin verildi/reddedildi/kalıcı ret/servis kapalı/timeout/failure/çift-tetik/koordinat doğrulama).
- Elle seçim: 7 (min uzunluk, sonuçlar, boş, hata+retry, geçersiz koordinat filtresi, seçim+kalıcılık).
- Kalıcılık: 5 (round-trip, restart, onboarding tamamlanma, isManual bayrağı, geçersiz atlama).
- Model doğrulama: `location_model_test.dart`.
- Yerelleştirme paritesi: 4 (tr/en/ar + RTL).
- Namaz entegrasyonu: 1 (gerçek motor).

Testler gerçek GPS'e, gerçek OS izin diyaloglarına, canlı ağa veya kararsız public API'ye bağlı değildir (spec Bölüm 22).

---

## 18. Keşfedilen Toplam Test (Total tests discovered): **122**

(102 geçen + 20 amaçlı skip; 0 başarısız.)

## 19. Geçen (Passed): **102**

## 20. Başarısız (Failed): **0**

## 21. Atlanan (Skipped): **20**

## 22. Her Yeni Skip'in Kesin Nedeni (Exact reason for every new skip)

- **Faz 3'te YENİ skip eklenMEDİ.** Mevcut 20 skip'in tümü Faz 2'den gelen
  `test/data/providers/diyanet_official_validation_test.dart` içindeki resmî Diyanet doğrulama vakalarıdır
  (5 şehir × 4 mevsim = 20). Her biri `expected == null` olduğu için `markTestSkipped` ile atlanır:
  **otantik Diyanet referans verisi henüz sağlanmadı.** Bu, spec Bölüm 24/25'te açıkça izin verilen skip'lerdir.
  Gerçek referans değerleri girildiğinde otomatik aktifleşir. Uydurma referans değeri ÜRETİLMEDİ.

---

## 23. `flutter analyze` Sonucu

`No issues found! (ran in 4.3s)` — temiz. (Log: `docs/phase3/flutter_analyze.log`)

---

## 24. Android Debug Build Sonucu

`✓ Built build/app/outputs/flutter-apk/app-debug.apk` — başarılı (~184 MB, gitignore'da).
(Log: `docs/phase3/flutter_build_apk.log`)

Not: Build ortamında başlangıçta JDK yerine yalnızca JRE bulunuyordu (`javac` yoktu);
`openjdk-17-jdk-headless` kurulup Gradle daemon yeniden başlatıldıktan sonra build başarıyla tamamlandı.

---

## 25. Uyarılar (Warnings)

- **KGP uyarısı (beklenen, ölümcül değil):** `package_info_plus` ve `workmanager_android` eklentileri Kotlin
  Gradle Plugin uyguluyor; Flutter gelecekte Built-in Kotlin'e geçişi zorlayacak. Build başarılı; şimdilik aksiyon gerekmiyor.
- Başka analyze/derleme uyarısı yok.

---

## 26. Bilinen Sınırlamalar (Known limitations)

- Otomatik testler gerçek GPS donanımını, gerçek OS izin diyaloglarını ve görsel çıktıyı doğrulayamaz — gerçek cihaz gerekir (Bölüm 29).
- Elle arama, platform geocoder kapsamına bağlıdır (bazı küçük yerleşimler için sınırlı sonuç olabilir).
- Ekran görüntüleri üretilemedi: çalışan uygulama/emülatör bu ortamda mevcut değil (aşağıda açıklandı).

---

## 27. Teknik Borç (Technical debt)

- 20 Diyanet doğrulama vakası, otantik referans veri gelene dek skip olarak kalıyor.
- KGP eklenti bağımlılıkları ileride Built-in Kotlin'e uyumlu sürümlere yükseltilmeli.
- Elle arama için alternatif/çevrimdışı bir `LocationSearchRepository` implementasyonu ileride değerlendirilebilir (soyutlama zaten hazır).

---

## 28. Mock/Placeholder İşlevsellik (Mock/placeholder functionality)

- **Üretim kodunda mock konum verisi YOK.** Elle arama gerçek geocoding kullanır; GPS gerçek Geolocator kullanır.
- Onboarding'in diğer adımları (Dil[0], Bildirim[2], Hesaplama[3]) Faz 1 scaffold'larıdır — bunlar Faz 3 kapsamı dışıdır, değiştirilmedi.
- Testlerde fake'ler kullanıldı (FakeSettingsRepository, fake repository'ler) — bunlar yalnızca test izolasyonu içindir, üretim kodunda değil, ve açıkça test/ altında.

---

## 29. Hâlâ Gereken Gerçek-Cihaz Testleri (Real-device tests still required)

Aşağıdakiler **REQUIRES REAL DEVICE VALIDATION** — bu ortamda test EDİLMEDİ, edilmiş gibi de gösterilmiyor.
Tam liste: `docs/phase3/REAL_DEVICE_TEST_CHECKLIST.md`. Özet:
- Gerçek OS izin diyalogları (izin ver / reddet / kalıcı reddet).
- Gerçek GPS ile otomatik konum başarısı.
- Konum servisleri kapalıyken davranış ve tekrar açıp deneme.
- Uygulama yeniden başlatma sonrası konum kalıcılığı (gerçek cihazda).
- Arapça RTL'in görsel doğrulaması ve dil değiştirme.
- Uçak modu / ağsız senaryo ve reverse-geocoding başarısızlık/fallback.

**Ekran görüntüleri:** Spec'in istediği 5 ekran görüntüsü (TR/EN/AR konum ekranı, elle seçim, izin reddi durumu)
çalışan bir uygulama/emülatör gerektirir. Bu ortamda emülatör mevcut olmadığından **ekran görüntüsü üretilmedi**;
sahte ekran görüntüsü de eklenmedi. Emülatör/cihaz sağlandığında üretilebilir.

---

## 30. Önerilen Faz 4 Ön Koşulları (Suggested Phase 4 prerequisites)

- Onboarding'in kalan adımlarının (Bildirim, Hesaplama Yöntemi) üretim implementasyonu.
- Ana ekranda kayıtlı konumu okuyup namaz vakitlerini gösterme; **konum değişikliklerinin gözlemlenmesi**:
  ileride konum, `SettingsRepository` üzerinden okunur; reaktif güncelleme için ilgili Cubit `SettingsRepository`'yi
  dinlemeli (veya konum değişince ilgili state yenilenmeli). Kayıt tek kaynak olarak Hive'dadır.
- 20 Diyanet vakası için otantik referans verinin sağlanması (skip'leri kapatmak için).
- KGP eklentilerinin uyumlu sürümlere yükseltilmesi.
- Gerçek cihaz/emülatör ile Bölüm 29 kontrol listesinin çalıştırılması.

---

### Ek Not — Kalıcılık ve Ortam Uyarısı

Bu build ve tüm çıktılar bu **geçici** Abacus AI Agent VM'inde üretildi; VM boşta kalınca kapanır ve
`build/` çıktıları kalıcı değildir. Kaynak kod, testler ve raporlar git ile `main` dalına işlendi (kalıcı).
APK yeniden derlenebilir. Faz 4 onaylanana kadar hiçbir Faz 4 çalışması başlatılmadı.
