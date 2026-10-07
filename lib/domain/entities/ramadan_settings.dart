import 'package:equatable/equatable.dart';

/// User-configurable Ramadan preferences (persisted locally, spec §12).
class RamadanSettings extends Equatable {
  /// Sahur (pre-dawn) reminder enabled.
  final bool sahurEnabled;

  /// Minutes BEFORE Imsak to fire the Sahur reminder (15/30/45/60).
  final int sahurOffsetMinutes;

  /// Iftar reminder enabled.
  final bool iftarEnabled;

  /// Minutes BEFORE Iftar to fire the reminder (0/5/10/15/30; 0 = at Iftar).
  final int iftarOffsetMinutes;

  /// Hijri date adjustment in days (-3..+3, spec §3).
  final int hijriAdjustment;

  /// Whether the Ramadan card is shown on the Home screen.
  final bool cardVisible;

  const RamadanSettings({
    this.sahurEnabled = true,
    this.sahurOffsetMinutes = 30,
    this.iftarEnabled = true,
    this.iftarOffsetMinutes = 15,
    this.hijriAdjustment = 0,
    this.cardVisible = true,
  });

  static const RamadanSettings defaults = RamadanSettings();

  /// Allowed Sahur offsets (minutes before Imsak). Model is extensible.
  static const List<int> sahurOffsetOptions = [15, 30, 45, 60];

  /// Allowed Iftar offsets (minutes before Iftar; 0 = at Iftar).
  static const List<int> iftarOffsetOptions = [0, 5, 10, 15, 30];

  RamadanSettings copyWith({
    bool? sahurEnabled,
    int? sahurOffsetMinutes,
    bool? iftarEnabled,
    int? iftarOffsetMinutes,
    int? hijriAdjustment,
    bool? cardVisible,
  }) {
    return RamadanSettings(
      sahurEnabled: sahurEnabled ?? this.sahurEnabled,
      sahurOffsetMinutes: sahurOffsetMinutes ?? this.sahurOffsetMinutes,
      iftarEnabled: iftarEnabled ?? this.iftarEnabled,
      iftarOffsetMinutes: iftarOffsetMinutes ?? this.iftarOffsetMinutes,
      hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
      cardVisible: cardVisible ?? this.cardVisible,
    );
  }

  Map<String, dynamic> toJson() => {
        'sahurEnabled': sahurEnabled,
        'sahurOffsetMinutes': sahurOffsetMinutes,
        'iftarEnabled': iftarEnabled,
        'iftarOffsetMinutes': iftarOffsetMinutes,
        'hijriAdjustment': hijriAdjustment,
        'cardVisible': cardVisible,
      };

  factory RamadanSettings.fromJson(Map<String, dynamic> json) => RamadanSettings(
        sahurEnabled: json['sahurEnabled'] as bool? ?? true,
        sahurOffsetMinutes: (json['sahurOffsetMinutes'] as num?)?.toInt() ?? 30,
        iftarEnabled: json['iftarEnabled'] as bool? ?? true,
        iftarOffsetMinutes: (json['iftarOffsetMinutes'] as num?)?.toInt() ?? 15,
        hijriAdjustment: (json['hijriAdjustment'] as num?)?.toInt() ?? 0,
        cardVisible: json['cardVisible'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
        sahurEnabled,
        sahurOffsetMinutes,
        iftarEnabled,
        iftarOffsetMinutes,
        hijriAdjustment,
        cardVisible,
      ];
}
