# MİHRAB — Faz 3 Gerçek Cihaz Test Kontrol Listesi

Bu belge, Faz 3 konum özelliğinin **gerçek Android/iOS cihazda** (veya emülatörde) yapılması gereken
manuel testlerini listeler. Spec Bölüm 23 gereğidir.

> **ÖNEMLİ AYRIM**
> - **AUTOMATED TESTED** = bu ortamda otomatik testlerle doğrulandı (fake'lerle, gerçek donanım olmadan).
> - **REQUIRES REAL DEVICE VALIDATION** = gerçek cihaz/emülatör gerektirir; bu ortamda test EDİLMEDİ.
>
> Aşağıdaki cihaza özgü davranışların hiçbiri "test edildi" diye sunulmuyor.

---

## Durum Özeti

| Kapsam | Durum |
|---|---|
| Cubit izin/GPS durum eşlemesi (fake repo) | AUTOMATED TESTED |
| Elle arama mantığı, dedup, koordinat filtresi (fake repo) | AUTOMATED TESTED |
| Konum & onboarding kalıcılığı (gerçek Hive) | AUTOMATED TESTED |
| Namaz motoru entegrasyonu (gerçek provider) | AUTOMATED TESTED |
| Yerelleştirme paritesi + RTL widget testi | AUTOMATED TESTED |
| Gerçek OS izin diyalogları | REQUIRES REAL DEVICE VALIDATION |
| Gerçek GPS ile konum tespiti | REQUIRES REAL DEVICE VALIDATION |
| Konum servisi aç/kapa davranışı | REQUIRES REAL DEVICE VALIDATION |
| Görsel RTL / ekran görüntüleri | REQUIRES REAL DEVICE VALIDATION |
| Uçak modu / ağsız geocoding | REQUIRES REAL DEVICE VALIDATION |

---

## Manuel Test Adımları (REQUIRES REAL DEVICE VALIDATION)

- [ ] **Temiz kurulum (fresh install):** uygulama ilk kez kurulur, onboarding Dil → Konum akışı başlar.
- [ ] **Konuma izin ver (allow):** "Konumumu Kullan" → native diyalog → İzin Ver → koordinat + adres çözülür, "Devam" aktifleşir.
- [ ] **Konumu reddet (deny):** izin reddedilir → yerelleştirilmiş "izin reddedildi" durumu + "Tekrar Dene"; uygulama kilitlenmez, elle seçim çalışır.
- [ ] **Kalıcı reddet (deny permanently, Android/iOS):** kalıcı ret → "Ayarları Aç" butonu OS ayarlarını açar.
- [ ] **Konum servisleri kapalı (GPS disabled):** GPS kapalıyken "Konumumu Kullan" → "servisler kapalı" durumu + "Konum ayarlarını aç".
- [ ] **GPS'i aç ve tekrar dene:** ayarlardan GPS açılır, geri dönülür, "Tekrar Dene" → başarı.
- [ ] **Otomatik konum başarısı (automatic success):** gerçek GPS ile geçerli koordinat + (varsa) adres.
- [ ] **Elle konum seçimi (manual selection):** şehir adı yazılır → gerçek sonuçlar → seçim → konum kaydedilir.
- [ ] **Uygulama yeniden başlatma (restart):** uygulama kapatılıp açılır → kayıtlı konum korunur.
- [ ] **Konum kalıcılığı (persistence):** onboarding sonrası konum, sonraki oturumlarda mevcuttur.
- [ ] **Arapça RTL:** dil Arapça yapılır → konum ekranı sağdan sola düzgün hizalanır (görsel doğrulama).
- [ ] **Dil değiştirme:** TR ↔ EN ↔ AR geçişinde tüm konum metinleri doğru çevrilir, layout bozulmaz.
- [ ] **Uçak modu / ağsız:** ağ yokken elle arama → yerelleştirilmiş hata + "Tekrar Dene"; uygulama çökmez.
- [ ] **Reverse-geocoding başarısızlığı/fallback:** adres çözülemediğinde koordinatlar yine de kullanılır ("koordinatlar kullanılıyor" notu), kurulum tamamlanır.

---

## Ekran Görüntüleri (REQUIRES REAL DEVICE VALIDATION)

Spec'in istediği aşağıdaki ekran görüntüleri **çalışan uygulama/emülatör gerektirir** ve bu ortamda
emülatör bulunmadığından **üretilmedi** (sahte ekran görüntüsü eklenmedi):

- [ ] Türkçe konum ekranı
- [ ] İngilizce konum ekranı
- [ ] Arapça RTL konum ekranı
- [ ] Elle konum seçimi
- [ ] İzin reddi durumu

Emülatör/cihaz sağlandığında `flutter run` ile üretilebilir.
