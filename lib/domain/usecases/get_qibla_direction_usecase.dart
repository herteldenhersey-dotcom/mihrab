import '../providers/prayer_time_provider.dart';

/// Returns the qibla bearing (degrees clockwise from true north) for a point.
class GetQiblaDirectionUseCase {
  final PrayerTimeProvider _provider;

  GetQiblaDirectionUseCase(this._provider);

  double call({required double latitude, required double longitude}) {
    return _provider.getQiblaDirection(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
