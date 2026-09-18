/// Low-level exceptions thrown by data sources.
///
/// These are caught in the repository layer and converted into [Failure]s
/// (see `failures.dart`) before crossing into the domain/presentation layers.
library;

/// Base class for all app-specific exceptions.
sealed class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

/// Network transport failure (no connection, DNS, socket, etc.).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// The request timed out.
class TimeoutAppException extends AppException {
  const TimeoutAppException(super.message, {super.cause});
}

/// The remote endpoint rate-limited us (HTTP 429) or returned 5xx.
class RateLimitException extends AppException {
  final int? statusCode;
  const RateLimitException(super.message, {this.statusCode, super.cause});
}

/// The server responded but the payload could not be parsed.
class ParseException extends AppException {
  const ParseException(super.message, {super.cause});
}

/// A generic server error (non-2xx that is not a rate limit).
class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode, super.cause});
}

/// Location services disabled or permission denied.
class LocationException extends AppException {
  const LocationException(super.message, {super.cause});
}

/// Local cache/storage failure (Hive/SharedPreferences).
class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

/// A required OS permission was denied.
class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}

/// Device sensor (e.g. compass) unavailable.
class SensorException extends AppException {
  const SensorException(super.message, {super.cause});
}
