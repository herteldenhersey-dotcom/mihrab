import 'package:equatable/equatable.dart';

import 'exceptions.dart';

/// Domain-level, presentation-safe error type.
///
/// Sealed so the UI can exhaustively switch on failure kinds and show
/// localized messages. Repositories convert [AppException]s into [Failure]s.
sealed class Failure extends Equatable {
  /// A developer-facing message. UI should map [code] to a localized string.
  final String message;

  /// Stable machine code used for localization lookup / analytics.
  final String code;

  const Failure(this.message, this.code);

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error'])
      : super(message, 'network');
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'Request timed out'])
      : super(message, 'timeout');
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([String message = 'Rate limited'])
      : super(message, 'rate_limit');
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error'])
      : super(message, 'server');
}

class ParseFailure extends Failure {
  const ParseFailure([String message = 'Parse error'])
      : super(message, 'parse');
}

class LocationFailure extends Failure {
  const LocationFailure([String message = 'Location unavailable'])
      : super(message, 'location');
}

class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Permission denied'])
      : super(message, 'permission');
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error'])
      : super(message, 'cache');
}

class SensorFailure extends Failure {
  const SensorFailure([String message = 'Sensor unavailable'])
      : super(message, 'sensor');
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Unknown error'])
      : super(message, 'unknown');
}

/// Maps a caught [AppException]/error into a presentation-safe [Failure].
Failure mapExceptionToFailure(Object error) {
  return switch (error) {
    NetworkException() => NetworkFailure(error.message),
    TimeoutAppException() => TimeoutFailure(error.message),
    RateLimitException() => RateLimitFailure(error.message),
    ServerException() => ServerFailure(error.message),
    ParseException() => ParseFailure(error.message),
    LocationException() => LocationFailure(error.message),
    PermissionException() => PermissionFailure(error.message),
    CacheException() => CacheFailure(error.message),
    SensorException() => SensorFailure(error.message),
    Failure() => error,
    _ => UnknownFailure(error.toString()),
  };
}
