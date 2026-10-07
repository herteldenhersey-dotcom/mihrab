import 'package:equatable/equatable.dart';

/// A plain Hijri (Islamic) calendar date.
class HijriDate extends Equatable {
  final int year;
  final int month; // 1..12
  final int day; // 1..30

  const HijriDate({required this.year, required this.month, required this.day});

  @override
  List<Object?> get props => [year, month, day];

  @override
  String toString() => '$day/$month/$year H';
}

/// Immutable description of the Ramadan state for a given civil date.
///
/// When [isRamadan] is false, [firstDay]/[lastDay]/[totalDays]/[hijriYear]
/// describe the NEXT upcoming Ramadan (an ESTIMATE — never officially
/// confirmed, spec §3).
class RamadanInfo extends Equatable {
  /// Whether the reference date is currently within Ramadan.
  final bool isRamadan;

  /// 1-indexed day of Ramadan (0 when not in Ramadan).
  final int dayNumber;

  /// Total expected days of this Ramadan (29 or 30 — never hardcoded).
  final int totalDays;

  /// Full Hijri date of the reference civil date.
  final HijriDate hijriDate;

  /// Hijri year of the (current or next) Ramadan.
  final int hijriYear;

  /// Hijri month (always 9 for the relevant Ramadan).
  final int hijriMonth;

  /// Civil (Gregorian) date of the first day of Ramadan.
  final DateTime firstDay;

  /// Civil (Gregorian) date of the last day of Ramadan.
  final DateTime lastDay;

  const RamadanInfo({
    required this.isRamadan,
    required this.dayNumber,
    required this.totalDays,
    required this.hijriDate,
    required this.hijriYear,
    required this.hijriMonth,
    required this.firstDay,
    required this.lastDay,
  });

  @override
  List<Object?> get props => [
        isRamadan,
        dayNumber,
        totalDays,
        hijriDate,
        hijriYear,
        hijriMonth,
        firstDay,
        lastDay,
      ];
}
