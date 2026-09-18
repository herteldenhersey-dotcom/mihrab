import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/enums/language_code.dart';
import '../../domain/repositories/settings_repository.dart';

part 'locale_state.dart';

/// Owns the app's active language and drives `MaterialApp.locale`.
///
/// Responsibilities (per Phase 2 spec):
/// * load the stored locale from [SettingsRepository];
/// * on a fresh install (nothing stored), detect the device locale and pick a
///   supported language, falling back to English when unsupported;
/// * change the locale at runtime (no app restart) and persist the choice;
/// * expose the current [Locale] to the widget tree.
///
/// Persistence lives here (not in widgets), keeping the UI declarative.
class LocaleCubit extends Cubit<LocaleState> {
  final SettingsRepository _settings;

  /// Injectable for tests; defaults to the platform's current locale.
  final Locale Function() deviceLocaleProvider;

  LocaleCubit(
    this._settings, {
    Locale Function()? deviceLocaleProvider,
  })  : deviceLocaleProvider =
            deviceLocaleProvider ?? _platformLocale,
        super(const LocaleState.initial());

  static Locale _platformLocale() =>
      PlatformDispatcher.instance.locale;

  /// Loads the persisted language, or derives one from the device locale on a
  /// fresh install. Always emits a resolved, loaded state.
  Future<void> load() async {
    final stored = await _settings.getStoredLanguage();
    if (stored != null) {
      emit(LocaleState.loaded(stored, persisted: true));
      return;
    }
    final detected = LanguageCode.fromDeviceLocale(deviceLocaleProvider());
    // Do NOT persist the auto-detected choice — the user hasn't chosen yet, so
    // a later device-language change can still influence a still-fresh install.
    emit(LocaleState.loaded(detected, persisted: false));
  }

  /// Changes the active language at runtime and persists it. Safe to call from
  /// the language onboarding step; the UI updates immediately.
  Future<void> changeLocale(LanguageCode language) async {
    if (state.language == language && state.persisted) return;
    emit(LocaleState.loaded(language, persisted: true));
    await _settings.saveLanguage(language);
  }
}
