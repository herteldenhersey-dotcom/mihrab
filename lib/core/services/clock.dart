/// Abstraction over system clock so HomeCubit logic can be tested
/// deterministically without relying on wall-clock time.
abstract class Clock {
  /// Returns the current instant in UTC.
  DateTime now();
}

/// Production implementation that delegates to [DateTime.now()].
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
