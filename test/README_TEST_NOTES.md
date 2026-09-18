# Test Notları (Phase 1)

Bu dizin Phase 1 için birim testlerini içerir. Kod üretimi (codegen) kullanılmadığı
için tüm sahte (fake) sınıflar elle yazılmıştır — `mockito`/`build_runner` yoktur.

## Test kapsamı

| Test dosyası | Kapsam |
|---|---|
| `data/providers/adhan_prayer_time_provider_test.dart` | **AlAdhan Method 13 uyumluluk testi** — İstanbul 2024-03-15, `adhan` çıktısı AlAdhan `method=13` referansı ile ±2 dk toleransında karşılaştırılır; `ManualOffsets` düzeltme mekanizması doğrulanır; madhab (Hanefi/Şafii) ve kıble yönü kontrolleri. |
| `data/providers/diyanet_official_validation_test.dart` | **Resmî Diyanet doğrulama iskeleti (TODO)** — 5 şehir × 4 mevsim = 20 case matrisi. Resmî değerler henüz girilmediği için tüm case'ler `skipped` olarak raporlanır (değer UYDURULMAZ). Bkz. aşağıdaki teknik borç bölümü. |
| `core/utils/prayer_time_utils_test.dart` | Sonraki namaz, mevcut namaz, geri sayım ve İşa sonrası (gece yarısı) uç durumları. |
| `core/utils/date_utils_test.dart` | Gün sınırları, Hicri dönüşüm (Kuveyti algoritması) ve Ramazan tespiti. |
| `domain/usecases/get_prayer_times_usecase_test.dart` | Ayarların provider'a iletilmesi ve manuel dakika offset'lerinin uygulanması. |
| `domain/usecases/get_next_prayer_usecase_test.dart` | Sonraki namaz use-case'i, İşa sonrası yarın Fajr hesabı dahil. |

## AlAdhan Method 13 referans değerleri (resmî Diyanet DEĞİLDİR)

İstanbul (41.0082, 28.9784), 15 Mart 2024, Europe/Istanbul (UTC+3, DST yok):

```
İmsak 05:44 · Güneş 07:08 · Öğle 13:18 · İkindi 16:37 · Akşam 19:18 · Yatsı 20:37
```

Kaynak: AlAdhan API `method=13`:
`https://api.aladhan.com/v1/timings/15-03-2024?latitude=41.0082&longitude=28.9784&method=13`

> ⚠️ **Önemli:** AlAdhan `method=13` "Diyanet İşleri Başkanlığı, Turkey" olarak
> etiketlenmiş olsa da bu, üçüncü taraf bir yeniden uygulamadır — resmî ve yayınlı
> Diyanet verisi DEĞİLDİR. Bu test yalnızca *AlAdhan Method 13 uyumluluğunu*
> ölçer, Diyanet'in kendi takvimine karşı doğrulama YAPMAZ.

`adhan` paketinin `CalculationMethod.turkey` çıktısı bu referansa ±2 dk içinde
uyum sağlar. Kalan küçük sistematik sapmalar kullanıcı başına ayarlanabilir
`ManualOffsets` (dakika bazlı) ile giderilir.

## Diyanet Resmî Doğrulama — TODO (Teknik Borç)

`diyanet_official_validation_test.dart` dosyası, resmî ve doğrulanabilir Diyanet
namaz vakitlerine karşı ayrı bir doğrulama katmanıdır. Hedef kapsam:

**5 şehir × 4 mevsim = 20 doğrulama case'i**

| | Kış (15 Oca) | İlkbahar (15 Nis) | Yaz (15 Tem) | Sonbahar (15 Eki) |
|---|---|---|---|---|
| İstanbul | TODO | TODO | TODO | TODO |
| Ankara | TODO | TODO | TODO | TODO |
| Diyarbakır | TODO | TODO | TODO | TODO |
| Trabzon | TODO | TODO | TODO | TODO |
| Antalya | TODO | TODO | TODO | TODO |

**Durum:** Resmî Diyanet referans değerleri henüz toplanmadığı için her case'in
`expected` alanı `null`'dır ve **değer uydurulmamıştır**. `expected == null` olan
her case `markTestSkipped` ile `skipped` (beklemede) olarak raporlanır; böylece
suite geçmeye devam ederken eksik açıkça görünür.

**Borcu kapatmak için:** her case için
`namazvakitleri.diyanet.gov.tr` üzerinden resmî vakitleri bulun, `_ExpectedTimes`
ile (gece yarısından itibaren dakika olarak) doldurun. Case otomatik olarak
çalışıp ±2 dk toleransıyla doğrulama yapar. Sistematik bir sapma çıkarsa toleransı
gevşetmek yerine şehir başına önerilen `ManualOffsets` olarak belgeleyin.

## Feedback teslim durumu (delivery status)

`FeedbackItem` artık yanıltıcı `submitted` boolean'ı yerine
`FeedbackDeliveryStatus { pending, handoffInitiated, delivered, failed }` kullanır.
`mailto:` intent'inin açılması e-postanın gerçekten gönderildiğini KANITLAMAZ; bu
nedenle V1 en fazla `handoffInitiated` raporlayabilir. `delivered` yalnızca ileride
gerçek bir backend (REST/Firebase/Supabase) teslimi doğruladığında kullanılır.
Eski `submitted` verisi geriye dönük okunur (true → `handoffInitiated`,
false → `pending`). Bkz. `data/repositories/local_feedback_repository_test.dart`.

## Zaman dilimi notu

`adhan` paketi anları UTC hesaplar ve yerel `DateTime` olarak sunar. CI genelde
UTC, gerçek cihaz ise UTC+3 çalışır. Test ortamdan bağımsız olsun diye sonuçlar
`toUtc()` ile normalize edilip sabit +3 saat Türkiye offset'i eklenerek İstanbul
duvar saatine çevrilir.
