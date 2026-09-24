import 'dart:async';

import '../../domain/models/location_model.dart';

/// A lightweight broadcast notifier that signals when the saved location
/// changes (e.g. the user selects a new location in Settings or the
/// location-onboarding step).
///
/// Phase 4 Design Decision — Reactive Location Changes:
/// ─────────────────────────────────────────────────────────────────────────
/// [SettingsRepository] is Future-based and not reactive by itself.
/// Rather than adding a global event bus or rebuilding the repository layer,
/// we introduce this thin broadcast StreamController.
///
/// Registration:  singleton in GetIt, registered after SettingsRepository.
/// Publishing:    any code that changes the saved location calls [notify].
/// Subscribing:   HomeCubit subscribes in [HomeCubit.load] and cancels in
///                [HomeCubit.close], so there are no subscriber leaks.
///
/// This avoids unnecessary global coupling — only the location-change path
/// and HomeCubit are aware of this notifier.
class LocationChangeNotifier {
  final _controller = StreamController<AppLocation>.broadcast();

  /// Emits a new location to all active subscribers.
  void notify(AppLocation location) {
    if (!_controller.isClosed) {
      _controller.add(location);
    }
  }

  /// Stream of location-change events.  HomeCubit listens to this to refresh
  /// prayer times and countdown without an app restart.
  Stream<AppLocation> get stream => _controller.stream;

  /// Must be called when the host (e.g. root widget or test teardown) disposes.
  void dispose() => _controller.close();
}
