import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../constants/prayer_constants.dart';

/// Thin factory around [Dio] with sane defaults + a logging/retry-friendly
/// setup. Retry/backoff for Overpass is handled explicitly in the repository
/// (so it can decide between endpoints), but connect/receive timeouts and the
/// mandatory OSM User-Agent are configured here.
class DioClient {
  final Dio dio;

  DioClient._(this.dio);

  factory DioClient.create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: PrayerConstants.overpassTimeout,
        receiveTimeout: PrayerConstants.overpassTimeout,
        sendTimeout: PrayerConstants.overpassTimeout,
        headers: {
          'User-Agent': AppConstants.httpUserAgent,
          'Accept': 'application/json',
        },
        // We validate status codes ourselves to map 429/5xx precisely.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          // Pass through; repositories translate DioException → AppException.
          handler.next(e);
        },
      ),
    );

    return DioClient._(dio);
  }
}
