import '../../../domain/entities/ramadan_info.dart';

/// Pure-Dart Hijri (Islamic) calendar conversion based on the tabular
/// (arithmetic) Islamic calendar algorithm with civil epoch.
///
/// Design notes:
/// - No network required (fully offline, spec §14).
/// - Supports a user-configurable [adjustment] in days (-3..+3) that shifts the
///   civil (Gregorian) date BEFORE conversion. A positive adjustment means the
///   Hijri date advances (i.e. the Hijri day number increases), matching the
///   common "the moon was sighted a day earlier/later than the tabular value"
///   correction (spec §3).
/// - IMPORTANT: Algorithmic dates can differ from official Diyanet / Umm
///   al-Qura announcements. These results are an ESTIMATE and must never be
///   presented as officially confirmed (spec §3).
/// - Timezone handling: the caller passes a [DateTime] already expressed as the
///   civil wall-clock date of the SELECTED LOCATION (not the device). Only the
///   y/m/d components are used, so the service is timezone-agnostic as long as
///   the caller supplies the correct local civil date.
class HijriCalendarService {
  const HijriCalendarService();

  /// Islamic month index for Ramadan (1-based).
  static const int ramadanMonth = 9;

  /// Clamps an adjustment into the supported range (-3..+3).
  static int clampAdjustment(int adjustment) {
    if (adjustment < -3) return -3;
    if (adjustment > 3) return 3;
    return adjustment;
  }

  /// Converts a civil [date] (local wall-clock date of the selected location)
  /// to a Hijri date, applying [adjustment] (days) first.
  HijriDate toHijri(DateTime date, {int adjustment = 0}) {
    final adj = clampAdjustment(adjustment);
    // Normalise to midnight and apply the day adjustment on the civil date.
    final civil = DateTime(date.year, date.month, date.day)
        .add(Duration(days: adj));
    final jdn = _gregorianToJdn(civil.year, civil.month, civil.day);
    return _jdnToHijri(jdn);
  }

  /// Length (29 or 30 days) of the Hijri [month] in [year] per the tabular
  /// algorithm. Odd months have 30 days; even months 29 — except month 12
  /// which has 30 days in a leap year.
  int monthLength(int year, int month) {
    if (month % 2 == 1) return 30;
    if (month == 12 && _isHijriLeapYear(year)) return 30;
    return 29;
  }

  /// Whether [date] (with [adjustment]) falls in Ramadan (Hijri month 9).
  bool isRamadan(DateTime date, {int adjustment = 0}) =>
      toHijri(date, adjustment: adjustment).month == ramadanMonth;

  /// Builds a full [RamadanInfo] describing the Ramadan state for [date].
  ///
  /// Computes the civil first/last day of the Ramadan that contains (or, when
  /// outside Ramadan, the NEXT upcoming) [date]. Supports 29/30-day Ramadan and
  /// Gregorian month/year boundary crossings because it works purely in JDN
  /// space.
  RamadanInfo ramadanInfo(DateTime date, {int adjustment = 0}) {
    final adj = clampAdjustment(adjustment);
    final hijri = toHijri(date, adjustment: adj);

    if (hijri.month == ramadanMonth) {
      final first = _hijriFirstDayCivil(hijri.year, adj);
      final total = monthLength(hijri.year, ramadanMonth);
      final last = first.add(Duration(days: total - 1));
      return RamadanInfo(
        isRamadan: true,
        dayNumber: hijri.day,
        totalDays: total,
        hijriDate: hijri,
        hijriYear: hijri.year,
        hijriMonth: hijri.month,
        firstDay: first,
        lastDay: last,
      );
    }

    // Outside Ramadan → find the next upcoming Ramadan (estimate).
    final nextYear = (hijri.month < ramadanMonth) ? hijri.year : hijri.year + 1;
    final first = _hijriFirstDayCivil(nextYear, adj);
    final total = monthLength(nextYear, ramadanMonth);
    final last = first.add(Duration(days: total - 1));
    return RamadanInfo(
      isRamadan: false,
      dayNumber: 0,
      totalDays: total,
      hijriDate: hijri,
      hijriYear: nextYear,
      hijriMonth: ramadanMonth,
      firstDay: first,
      lastDay: last,
    );
  }

  // ── internal ────────────────────────────────────────────────────────────

  /// Civil (Gregorian) date of day 1 of Ramadan in Hijri [hYear].
  /// Returns the date WITHOUT the adjustment folded in, so that comparing it
  /// against an adjusted "today" stays consistent: we invert the adjustment so
  /// the returned civil date aligns with un-adjusted civil input.
  DateTime _hijriFirstDayCivil(int hYear, int adjustment) {
    final jdn = _hijriToJdn(hYear, ramadanMonth, 1);
    final civil = _jdnToGregorian(jdn);
    // Subtract the adjustment so callers comparing against un-adjusted civil
    // dates see the same shift applied consistently.
    return DateTime(civil.year, civil.month, civil.day)
        .subtract(Duration(days: adjustment));
  }

  bool _isHijriLeapYear(int year) {
    // 11 leap years in a 30-year cycle (Kuwaiti/civil set).
    final y = year % 30;
    const leaps = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29};
    return leaps.contains(y < 0 ? y + 30 : y);
  }

  // Civil tabular Islamic epoch: JDN 1948440 = 1 Muharram 1 AH (July 16, 622).
  static const int _islamicEpoch = 1948440;

  int _hijriToJdn(int year, int month, int day) {
    return day +
        ((29.5 * (month - 1)).ceil()) +
        (year - 1) * 354 +
        ((3 + 11 * year) ~/ 30) +
        _islamicEpoch -
        1;
  }

  HijriDate _jdnToHijri(int jdn) {
    final days = jdn - _islamicEpoch;
    int year = ((30 * days + 10646) ~/ 10631);
    if (year < 1) year = 1;
    int firstOfYear = _hijriToJdn(year, 1, 1);
    // Correct boundary rounding.
    while (jdn < firstOfYear) {
      year -= 1;
      firstOfYear = _hijriToJdn(year, 1, 1);
    }
    while (jdn >= _hijriToJdn(year + 1, 1, 1)) {
      year += 1;
    }
    int month = 1;
    while (month < 12 && jdn >= _hijriToJdn(year, month + 1, 1)) {
      month += 1;
    }
    final day = jdn - _hijriToJdn(year, month, 1) + 1;
    return HijriDate(year: year, month: month, day: day);
  }

  int _gregorianToJdn(int y, int m, int d) {
    final a = (14 - m) ~/ 12;
    final yy = y + 4800 - a;
    final mm = m + 12 * a - 3;
    return d +
        ((153 * mm + 2) ~/ 5) +
        365 * yy +
        (yy ~/ 4) -
        (yy ~/ 100) +
        (yy ~/ 400) -
        32045;
  }

  DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final dd = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * dd) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + dd - 4800 + (m ~/ 10);
    return DateTime(year, month, day);
  }
}
