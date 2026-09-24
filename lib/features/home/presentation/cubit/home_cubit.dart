import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/services/clock.dart';
import '../../../../core/services/location_change_notifier.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../../../data/repositories/coordinate_timezone_repository.dart';
import '../../../../domain/models/calculation_settings_model.dart';
import '../../../../domain/models/location_model.dart';
import '../../../../domain/models/prayer_times_model.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/repositories/timezone_repository.dart';
import '../../../../domain/usecases/get_prayer_times_usecase.dart';

part 'home_state.dart';

/// Drives the Home screen.
///
/// Responsibilities:
/// ─────────────────────────────────────────────────────────────────────────
/// 1. Load saved location & calculation settings from [SettingsRepository].
/// 2. Resolve (or restore cached) IANA timezone for the selected location.
/// 3. Calculate today's AND tomorrow's prayer times via [GetPrayerTimesUseCase].
/// 4. Determine the next *obligatory* prayer (Sunrise excluded — see
///    [PrayerTimeUtils.getNextObligatoryPrayer]).
/// 5. Run a 1-second Timer that recalculates remaining countdown from the real
///    clock on every tick (clock-based, not decrement-based → no drift).
/// 6. On prayer transition or midnight boundary, reload the full day's times.
/// 7. Subscribe to [LocationChangeNotifier] so Home refreshes without restart.
///
/// Clock abstraction:
/// [Clock] is injected so unit tests can supply a [FakeClock] and assert
/// deterministic countdown/next-prayer behaviour without depending on wall time.
///
/// Timezone:
/// Uses the `timezone` package's tzdata (bundled, no network).  The IANA ID
/// is stored in [AppLocation.timezoneId] and persisted separately via
/// [TimezoneRepository].  If resolution fails we enter [HomeFailure] with a
/// localized-key message rather than silently using the wrong timezone.
///
/// Lifecycle:
/// [onResume] must be called from [WidgetsBindingObserver.didChangeAppLifecycleState]
/// when the app returns from background so countdown is recalculated from the
/// current clock instant (not the stale paused value).
class HomeCubit extends Cubit<HomeState> {
  final SettingsRepository _settings;
  final GetPrayerTimesUseCase _getPrayerTimes;
  final TimezoneRepository _timezoneRepo;
  final LocationChangeNotifier _locationNotifier;
  final Clock _clock;

  Timer? _countdownTimer;
  StreamSubscription<AppLocation>? _locationSub;

  /// The locale string ("tr", "en", "ar") used for date formatting.
  /// Updated by [setLocale]; defaults to "tr".
  String _locale = 'tr';

  HomeCubit({
    required SettingsRepository settings,
    required GetPrayerTimesUseCase getPrayerTimes,
    required TimezoneRepository timezoneRepo,
    required LocationChangeNotifier locationNotifier,
    Clock? clock,
  })  : _settings = settings,
        _getPrayerTimes = getPrayerTimes,
        _timezoneRepo = timezoneRepo,
        _locationNotifier = locationNotifier,
        _clock = clock ?? const SystemClock(),
        super(const HomeInitial());

  // ── Public API ──────────────────────────────────────────────────────────

  /// Sets the active locale for date string formatting.
  void setLocale(String locale) {
    _locale = locale;
  }

  /// Initial load — call once when Home is entered.
  Future<void> load() async {
    _locationSub?.cancel();
    _locationSub = _locationNotifier.stream.listen((newLocation) {
      _loadForLocation(newLocation, forceTimezoneResolve: true);
    });
    emit(const HomeLoading());
    final location = await _settings.getSavedLocation();
    if (location == null || !location.hasValidCoordinates) {
      emit(const HomeMissingLocation());
      return;
    }
    await _loadForLocation(location);
  }

  /// Called when the app returns from background.
  /// Recalculates countdown from the current clock so drift is impossible.
  Future<void> onResume() async {
    final current = state;
    if (current is! HomeLoaded) return;

    final nowUtc = _clock.now();
    final locationNow = _toLocationTime(nowUtc, current.timezoneId);

    // If date changed while in background, reload everything.
    if (!AppDateUtils.isSameDay(locationNow, current.locationNow)) {
      await _loadForLocation(current.location);
      return;
    }

    // Same day — just recalculate next prayer & countdown.
    _recalculate(current, locationNow);
  }

  /// Explicit refresh (e.g. pull-to-refresh).
  Future<void> refresh() async {
    final current = state;
    if (current is HomeLoaded) {
      await _loadForLocation(current.location, forceTimezoneResolve: false);
    } else {
      await load();
    }
  }

  @override
  Future<void> close() async {
    _stopTimer();
    await _locationSub?.cancel();
    return super.close();
  }

  // ── Internal helpers ────────────────────────────────────────────────────

  Future<void> _loadForLocation(
    AppLocation location, {
    bool forceTimezoneResolve = false,
  }) async {
    _stopTimer();

    // 1. Resolve timezone -------------------------------------------------
    String? tzId = location.timezoneId;

    if (tzId == null || forceTimezoneResolve) {
      // Try to resolve from country code first (most accurate), then fallback.
      if (location.country != null && location.country!.isNotEmpty) {
        // Use `is` check so test fakes (which only implement TimezoneRepository)
        // safely fall through to the coordinate-based path without a TypeError.
        if (_timezoneRepo is CoordinateTimezoneRepository) {
          tzId = (_timezoneRepo as CoordinateTimezoneRepository)
              .resolveFromCountryCode(location.country!, location.longitude);
        }
      }
      // If still null, try pure coordinate resolve.
      tzId ??= await _timezoneRepo.resolveTimezone(
          location.latitude, location.longitude);

      // Last resort: use cached timezone.
      if (tzId == null) {
        tzId = await _timezoneRepo.getCachedTimezone();
      }

      // Cache whatever we found.
      if (tzId != null) {
        await _timezoneRepo.cacheTimezone(tzId);
      }
    }

    if (tzId == null) {
      emit(const HomeFailure('homeTimezoneUnavailable'));
      return;
    }

    // Persist the resolved timezone back to the cache.
    await _timezoneRepo.cacheTimezone(tzId);

    // 2. Determine "now" in the selected location's timezone ---------------
    final nowUtc = _clock.now();
    final locationNow = _toLocationTime(nowUtc, tzId);

    // 3. Fetch calculation settings ----------------------------------------
    CalculationSettings calcSettings;
    try {
      calcSettings = await _settings.getCalculationSettings();
    } catch (_) {
      calcSettings = CalculationSettings.turkeyDefault;
    }

    // 4. Calculate today & tomorrow prayer times ---------------------------
    final todayDate = DateTime(locationNow.year, locationNow.month, locationNow.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));

    DailyPrayerTimes today, tomorrow;
    try {
      today = await _getPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        date: todayDate,
        settings: calcSettings,
      );
      tomorrow = await _getPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        date: tomorrowDate,
        settings: calcSettings,
      );
    } catch (e) {
      emit(HomeFailure('homePrayerCalcError'));
      return;
    }

    // 5. Next obligatory prayer & countdown --------------------------------
    final nextPrayer = PrayerTimeUtils.getNextObligatoryPrayer(
      today,
      locationNow,
      tomorrow: tomorrow,
    );
    final countdown =
        PrayerTimeUtils.getCountdown(nextPrayer.time, locationNow);

    // 6. Format dates -------------------------------------------------------
    final gregorianFormatted = _formatGregorian(locationNow, _locale);
    final hijriFormatted =
        AppDateUtils.formatHijriLocalized(locationNow, _locale);

    emit(HomeLoaded(
      location: location,
      timezoneId: tzId,
      locationNow: locationNow,
      today: today,
      tomorrow: tomorrow,
      nextPrayer: nextPrayer,
      countdown: countdown,
      gregorianFormatted: gregorianFormatted,
      hijriFormatted: hijriFormatted,
    ));

    _startTimer();
  }

  void _startTimer() {
    _stopTimer();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _tick() {
    final current = state;
    if (current is! HomeLoaded) {
      _stopTimer();
      return;
    }

    final nowUtc = _clock.now();
    final locationNow = _toLocationTime(nowUtc, current.timezoneId);

    // Date boundary crossed → full reload.
    if (!AppDateUtils.isSameDay(locationNow, current.locationNow)) {
      _loadForLocation(current.location);
      return;
    }

    _recalculate(current, locationNow);
  }

  void _recalculate(HomeLoaded current, DateTime locationNow) {
    final nextPrayer = PrayerTimeUtils.getNextObligatoryPrayer(
      current.today,
      locationNow,
      tomorrow: current.tomorrow,
    );

    // Prayer transition — next prayer changed → re-emit full state.
    if (nextPrayer.type != current.nextPrayer.type ||
        nextPrayer.isTomorrow != current.nextPrayer.isTomorrow) {
      final countdown =
          PrayerTimeUtils.getCountdown(nextPrayer.time, locationNow);
      final gregorianFormatted = _formatGregorian(locationNow, _locale);
      final hijriFormatted =
          AppDateUtils.formatHijriLocalized(locationNow, _locale);

      emit(HomeLoaded(
        location: current.location,
        timezoneId: current.timezoneId,
        locationNow: locationNow,
        today: current.today,
        tomorrow: current.tomorrow,
        nextPrayer: nextPrayer,
        countdown: countdown,
        gregorianFormatted: gregorianFormatted,
        hijriFormatted: hijriFormatted,
        timezoneFromCache: current.timezoneFromCache,
      ));
      return;
    }

    // Normal tick — only countdown changes.
    final countdown =
        PrayerTimeUtils.getCountdown(nextPrayer.time, locationNow);
    emit(current.copyWithCountdown(countdown));
  }

  // ── Formatting helpers ─────────────────────────────────────────────────

  /// Converts a UTC [DateTime] to the local time in [tzId] using the bundled
  /// timezone database.  Falls back to device local if the ID is unknown.
  DateTime _toLocationTime(DateTime utcNow, String tzId) {
    try {
      final tzLocation = tz.getLocation(tzId);
      final tzDt = tz.TZDateTime.from(utcNow.toUtc(), tzLocation);
      return DateTime(tzDt.year, tzDt.month, tzDt.day,
          tzDt.hour, tzDt.minute, tzDt.second);
    } catch (_) {
      return utcNow.toLocal();
    }
  }

  String _formatGregorian(DateTime date, String locale) {
    final lang = locale.split('_').first.toLowerCase();
    try {
      // initializeDateFormatting is idempotent — safe to call repeatedly.
      initializeDateFormatting(lang);
      final fmt = DateFormat.yMMMMd(lang);
      return fmt.format(date);
    } catch (_) {
      try {
        initializeDateFormatting('tr');
        return DateFormat.yMMMMd('tr').format(date);
      } catch (_) {
        return DateFormat.yMd().format(date);
      }
    }
  }
}
