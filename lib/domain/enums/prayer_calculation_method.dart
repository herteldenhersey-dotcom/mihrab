/// Prayer-time calculation authorities supported by MİHRAB.
///
/// The concrete mapping to the underlying `adhan` package lives in
/// `AdhanPrayerTimeProvider` so the domain layer stays provider-agnostic.
enum PrayerCalculationMethod {
  /// Türkiye — Diyanet İşleri Başkanlığı (default for Turkey).
  diyanet,

  /// Muslim World League.
  mwl,

  /// Islamic Society of North America.
  isna,

  /// Egyptian General Authority of Survey.
  egypt,

  /// University of Islamic Sciences, Karachi.
  karachi,

  /// Umm al-Qura University, Makkah.
  ummAlQura,

  /// Kuwait.
  kuwait,

  /// Qatar.
  qatar,

  /// Singapore (MUIS).
  singapore,

  /// Institute of Geophysics, University of Tehran.
  tehran,

  /// North America (generic).
  northAmerica;

  String get key => name;

  static PrayerCalculationMethod fromKey(String key) =>
      PrayerCalculationMethod.values.firstWhere((e) => e.name == key,
          orElse: () => PrayerCalculationMethod.diyanet);
}
