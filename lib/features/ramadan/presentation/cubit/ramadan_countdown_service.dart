/// The fasting phase the countdown is currently targeting (spec §11).
enum RamadanCountdownPhase {
  /// Before Imsak → counting down to Imsak (start of fast).
  beforeImsak,

  /// Between Imsak and Iftar → counting down to Iftar (end of fast).
  fasting,

  /// After Iftar → counting down to tomorrow's Imsak.
  afterIftar,
}

/// Result of a countdown computation.
class RamadanCountdown {
  final RamadanCountdownPhase phase;
  final Duration remaining;

  /// The absolute target instant the countdown is running toward.
  final DateTime target;

  const RamadanCountdown({
    required this.phase,
    required this.remaining,
    required this.target,
  });
}

/// Pure countdown engine for Ramadan (spec §11).
///
/// Clock-based (computes from a supplied `now`, never decrements a stored
/// counter) so there is no drift and app pause/resume is handled by simply
/// recomputing. Never returns a negative [Duration].
class RamadanCountdownService {
  const RamadanCountdownService();

  /// Computes the countdown given [now], today's [imsak]/[iftar] and the next
  /// day's [tomorrowImsak] (all expressed in the selected location's wall
  /// clock). All inputs must be comparable `DateTime`s in the same frame.
  RamadanCountdown compute({
    required DateTime now,
    required DateTime imsak,
    required DateTime iftar,
    required DateTime tomorrowImsak,
  }) {
    if (now.isBefore(imsak)) {
      return RamadanCountdown(
        phase: RamadanCountdownPhase.beforeImsak,
        remaining: _nonNegative(imsak.difference(now)),
        target: imsak,
      );
    }
    if (now.isBefore(iftar)) {
      return RamadanCountdown(
        phase: RamadanCountdownPhase.fasting,
        remaining: _nonNegative(iftar.difference(now)),
        target: iftar,
      );
    }
    return RamadanCountdown(
      phase: RamadanCountdownPhase.afterIftar,
      remaining: _nonNegative(tomorrowImsak.difference(now)),
      target: tomorrowImsak,
    );
  }

  Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

  /// Formats a [Duration] as HH:mm:ss (clamped at 0).
  static String format(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    final h = safe.inHours.toString().padLeft(2, '0');
    final m = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final s = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
