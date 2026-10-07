import 'package:equatable/equatable.dart';

/// The kind of Ramadan reminder a scheduled notification represents.
enum RamadanReminderType {
  /// Sahur reminder — fires BEFORE Imsak (pre-dawn meal).
  sahur,

  /// Iftar reminder — fires at/before Maghrib (breaking the fast).
  iftar,
}

/// A single resolved Ramadan reminder instant, ready to hand to the scheduler.
///
/// [id] is the deterministic notification id in the Ramadan range (2000–2099).
/// [fireTime] is the civil wall-clock instant in the SELECTED LOCATION's
/// timezone (components are reinterpreted in that IANA zone by the service).
class RamadanNotificationSchedule extends Equatable {
  final int id;
  final RamadanReminderType type;

  /// The civil day index within the scheduling horizon (0-based).
  final int dayIndex;

  /// The underlying prayer event time (Imsak/Fajr for sahur, Maghrib for iftar).
  final DateTime eventTime;

  /// The actual notification fire time (eventTime minus the configured offset).
  final DateTime fireTime;

  const RamadanNotificationSchedule({
    required this.id,
    required this.type,
    required this.dayIndex,
    required this.eventTime,
    required this.fireTime,
  });

  @override
  List<Object?> get props => [id, type, dayIndex, eventTime, fireTime];
}
