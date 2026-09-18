import 'package:equatable/equatable.dart';

import '../enums/asr_calculation_method.dart';
import '../enums/prayer_calculation_method.dart';
import 'prayer_times_model.dart';

/// The full set of parameters that determine how prayer times are computed.
///
/// Persisted in settings. Combines the calculation method, the Asr madhab and
/// the per-prayer manual minute offsets used to reconcile with the official
/// Diyanet timetable.
class CalculationSettings extends Equatable {
  final PrayerCalculationMethod method;
  final AsrCalculationMethod asrMethod;
  final ManualOffsets offsets;

  const CalculationSettings({
    this.method = PrayerCalculationMethod.diyanet,
    this.asrMethod = AsrCalculationMethod.standard,
    this.offsets = ManualOffsets.zero,
  });

  /// Sensible default for Turkey: Diyanet method + standard Asr.
  static const CalculationSettings turkeyDefault = CalculationSettings();

  CalculationSettings copyWith({
    PrayerCalculationMethod? method,
    AsrCalculationMethod? asrMethod,
    ManualOffsets? offsets,
  }) {
    return CalculationSettings(
      method: method ?? this.method,
      asrMethod: asrMethod ?? this.asrMethod,
      offsets: offsets ?? this.offsets,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method.key,
        'asrMethod': asrMethod.key,
        'offsets': offsets.toJson(),
      };

  factory CalculationSettings.fromJson(Map<String, dynamic> json) =>
      CalculationSettings(
        method:
            PrayerCalculationMethod.fromKey(json['method'] as String? ?? ''),
        asrMethod:
            AsrCalculationMethod.fromKey(json['asrMethod'] as String? ?? ''),
        offsets: json['offsets'] is Map<String, dynamic>
            ? ManualOffsets.fromJson(json['offsets'] as Map<String, dynamic>)
            : ManualOffsets.zero,
      );

  @override
  List<Object?> get props => [method, asrMethod, offsets];
}
