import 'package:flutter_compass/flutter_compass.dart';

import '../../../core/errors/exceptions.dart';

/// Wraps `flutter_compass` to expose the device magnetic heading.
///
/// Qibla direction (bearing to the Kaaba) is computed separately via the
/// [PrayerTimeProvider]; the UI rotates the arrow by
/// (qiblaBearing - deviceHeading).
class CompassService {
  /// Stream of device heading in degrees (0..360, magnetic north).
  ///
  /// Emits an error ([SensorException]) if the device has no compass sensor.
  Stream<double> headingStream() {
    final events = FlutterCompass.events;
    if (events == null) {
      throw const SensorException('Bu cihazda pusula sensörü yok');
    }
    return events
        .where((e) => e.heading != null)
        .map((e) => e.heading!);
  }

  /// Whether the device exposes a compass sensor.
  bool get hasCompass => FlutterCompass.events != null;
}
