/// Date helpers: Hijri conversion and midnight/day-boundary utilities.
class AppDateUtils {
  AppDateUtils._();

  /// Local midnight (00:00) of the given [date].
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Local end-of-day (23:59:59.999).
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// True if both dates fall on the same calendar day (local time).
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static const List<String> _hijriMonthsTr = [
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiülahir',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce',
  ];

  /// Converts a Gregorian [date] to a Hijri (Umm al-Qura style tabular)
  /// date using the Kuwaiti algorithm. This is an approximation (±1 day)
  /// suitable for display; authoritative religious dates should defer to
  /// official announcements. Returns (year, month[1-12], day).
  static ({int year, int month, int day}) toHijri(DateTime date) {
    final d = date.day;
    final m = date.month;
    final y = date.year;

    int jd;
    if ((y > 1582) ||
        (y == 1582 && m > 10) ||
        (y == 1582 && m == 10 && d > 14)) {
      jd = ((1461 * (y + 4800 + ((m - 14) ~/ 12))) ~/ 4) +
          ((367 * (m - 2 - 12 * (((m - 14) ~/ 12)))) ~/ 12) -
          ((3 * (((y + 4900 + ((m - 14) ~/ 12)) ~/ 100))) ~/ 4) +
          d -
          32075;
    } else {
      jd = 367 * y -
          ((7 * (y + 5001 + ((m - 9) ~/ 7))) ~/ 4) +
          ((275 * m) ~/ 9) +
          d +
          1729777;
    }

    final l0 = jd - 1948440 + 10632;
    final n = (l0 - 1) ~/ 10631;
    final l1 = l0 - 10631 * n + 354;
    final j = ((10985 - l1) ~/ 5316) * ((50 * l1) ~/ 17719) +
        (l1 ~/ 5670) * ((43 * l1) ~/ 15238);
    final l2 = l1 -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l2) ~/ 709;
    final day = l2 - ((709 * month) ~/ 24);
    final year = 30 * n + j - 30;

    return (year: year, month: month, day: day);
  }

  /// Formats a Hijri date in Turkish, e.g. "15 Ramazan 1445".
  static String formatHijriTr(DateTime date) {
    final h = toHijri(date);
    final monthName = (h.month >= 1 && h.month <= 12)
        ? _hijriMonthsTr[h.month - 1]
        : '';
    return '${h.day} $monthName ${h.year}';
  }

  /// Whether the given [date] falls in Ramadan (Hijri month 9).
  static bool isRamadan(DateTime date) => toHijri(date).month == 9;
}
