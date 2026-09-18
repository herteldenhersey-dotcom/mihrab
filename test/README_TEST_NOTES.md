# Test Notları (Phase 1)

Bu dizin Phase 1 için birim testlerini içerir. Kod üretimi (codegen) kullanılmadığı
için tüm sahte (fake) sınıflar elle yazılmıştır — `mockito`/`build_runner` yoktur.

## Test kapsamı

| Test dosyası | Kapsam |
|---|---|
| `data/providers/adhan_prayer_time_provider_test.dart` | **Diyanet doğruluk testi** — İstanbul 2024-03-15, `adhan` çıktısı Diyanet referansı ile ±2 dk toleransında karşılaştırılır; `ManualOffsets` düzeltme mekanizması doğrulanır; madhab (Hanefi/Şafii) ve kıble yönü kontrolleri. |
| `core/utils/prayer_time_utils_test.dart` | Sonraki namaz, mevcut namaz, geri sayım ve İşa sonrası (gece yarısı) uç durumları. |
| `core/utils/date_utils_test.dart` | Gün sınırları, Hicri dönüşüm (Kuveyti algoritması) ve Ramazan tespiti. |
| `domain/usecases/get_prayer_times_usecase_test.dart` | Ayarların provider'a iletilmesi ve manuel dakika offset'lerinin uygulanması. |
| `domain/usecases/get_next_prayer_usecase_test.dart` | Sonraki namaz use-case'i, İşa sonrası yarın Fajr hesabı dahil. |

## Diyanet referans değerleri

İstanbul (41.0082, 28.9784), 15 Mart 2024, Europe/Istanbul (UTC+3, DST yok):

```
İmsak 05:44 · Güneş 07:08 · Öğle 13:18 · İkindi 16:37 · Akşam 19:18 · Yatsı 20:37
```

Kaynak: AlAdhan API `method=13` ("Diyanet İşleri Başkanlığı, Turkey"):
`https://api.aladhan.com/v1/timings/15-03-2024?latitude=41.0082&longitude=28.9784&method=13`

`adhan` paketinin `CalculationMethod.turkey` çıktısı bu referansa ±2 dk içinde
uyum sağlar. Resmî Diyanet basılı takviminde kalan küçük sistematik sapmalar,
kullanıcı başına ayarlanabilir `ManualOffsets` (dakika bazlı) ile giderilir.

## Zaman dilimi notu

`adhan` paketi anları UTC hesaplar ve yerel `DateTime` olarak sunar. CI genelde
UTC, gerçek cihaz ise UTC+3 çalışır. Test ortamdan bağımsız olsun diye sonuçlar
`toUtc()` ile normalize edilip sabit +3 saat Türkiye offset'i eklenerek İstanbul
duvar saatine çevrilir.
