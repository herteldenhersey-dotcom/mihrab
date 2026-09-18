import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  /// "HH:mm" (24h) — the standard prayer-time display format.
  String get hhmm => DateFormat('HH:mm').format(this);

  /// "HH:mm:ss".
  String get hhmmss => DateFormat('HH:mm:ss').format(this);

  /// Localized long date, e.g. "18 Eylül 2026" for [locale] "tr".
  String longDate(String locale) => DateFormat.yMMMMd(locale).format(this);

  /// Weekday name, e.g. "Cuma".
  String weekdayName(String locale) => DateFormat.EEEE(locale).format(this);

  DateTime get dateOnly => DateTime(year, month, day);

  bool get isFriday => weekday == DateTime.friday;
}
