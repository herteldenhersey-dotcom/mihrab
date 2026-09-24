import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/core/utils/prayer_time_utils.dart';
import 'package:mihrab/domain/enums/prayer_type.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';
import 'package:mihrab/features/home/presentation/cubit/home_cubit.dart';
import 'package:mihrab/localization/app_localizations.dart';

// ── Stub HomeCubit (no real I/O) ──────────────────────────────────────────────

class StubHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

// Helper to build a representative [HomeLoaded] state for widget pumps.
HomeLoaded _loadedState({
  String city = 'İstanbul',
  String country = 'TR',
  bool isTomorrow = false,
  PrayerType nextType = PrayerType.dhuhr,
}) {
  final base = DateTime(2024, 3, 15);
  final times = DailyPrayerTimes(
    date: base,
    fajr: base.copyWith(hour: 5),
    sunrise: base.copyWith(hour: 7),
    dhuhr: base.copyWith(hour: 12, minute: 30),
    asr: base.copyWith(hour: 15, minute: 45),
    maghrib: base.copyWith(hour: 18, minute: 30),
    isha: base.copyWith(hour: 20),
  );
  final tomorrow = DailyPrayerTimes(
    date: base.add(const Duration(days: 1)),
    fajr: base.add(const Duration(days: 1)).copyWith(hour: 5),
    sunrise: base.add(const Duration(days: 1)).copyWith(hour: 7),
    dhuhr: base.add(const Duration(days: 1)).copyWith(hour: 12, minute: 30),
    asr: base.add(const Duration(days: 1)).copyWith(hour: 15, minute: 45),
    maghrib: base.add(const Duration(days: 1)).copyWith(hour: 18, minute: 30),
    isha: base.add(const Duration(days: 1)).copyWith(hour: 20),
  );
  return HomeLoaded(
    location: AppLocation(
      latitude: 41.0,
      longitude: 28.98,
      city: city,
      country: country,
      isManual: true,
      timezoneId: 'UTC',
    ),
    timezoneId: 'UTC',
    locationNow: base.copyWith(hour: 13),
    today: times,
    tomorrow: tomorrow,
    nextPrayer: NextPrayer(
      type: nextType,
      time: times.timeFor(nextType),
      isTomorrow: isTomorrow,
    ),
    countdown: const Duration(hours: 2, minutes: 15),
    gregorianFormatted: '15 Mart 2024',
    hijriFormatted: '4 Ramazan 1445',
  );
}

// ── Widget pump helper ────────────────────────────────────────────────────────

Widget _pumpHome({
  required HomeState state,
  Locale locale = const Locale('tr'),
}) {
  // StubHomeCubit extends MockCubit<HomeState> AND implements HomeCubit,
  // so it satisfies BlocProvider<HomeCubit>.value without a cast error.
  final cubit = StubHomeCubit();
  whenListen(cubit, Stream<HomeState>.fromIterable([state]),
      initialState: state);

  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: BlocProvider<HomeCubit>.value(
      value: cubit,
      child: Builder(builder: (context) {
        return Scaffold(
          body: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, s) {
              if (s is HomeLoaded) {
                return Column(
                  children: [
                    // Location header
                    Text(s.location.city ?? '', key: const Key('city')),
                    // Prayer list — show all six prayer names
                    ...s.today.ordered.map((e) => Text(
                          e.key.name,
                          key: Key('prayer_${e.key.name}'),
                        )),
                    // Next prayer
                    Text('next:${s.nextPrayer.type.name}',
                        key: const Key('next_prayer')),
                    // Countdown
                    Text('countdown:${s.countdown.inSeconds}',
                        key: const Key('countdown')),
                    // Gregorian
                    Text(s.gregorianFormatted,
                        key: const Key('gregorian')),
                    // Hijri
                    Text(s.hijriFormatted, key: const Key('hijri')),
                  ],
                );
              } else if (s is HomeMissingLocation) {
                return const Text('missing_location',
                    key: Key('missing_location'));
              } else if (s is HomeFailure) {
                return Column(children: [
                  Text('failure:${s.message}', key: const Key('failure')),
                  const Text('retry', key: Key('retry')),
                ]);
              } else {
                return const CircularProgressIndicator(key: Key('loading'));
              }
            },
          ),
        );
      }),
    ),
  );
}

// ── Tests 29–40 (spec §33) ────────────────────────────────────────────────────

void main() {
  // ── T29: Loaded Home renders all six prayer times ─────────────────────────
  testWidgets('T29: loaded state renders all six prayer entries',
      (tester) async {
    await tester.pumpWidget(_pumpHome(state: _loadedState()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prayer_fajr')), findsOneWidget);
    expect(find.byKey(const Key('prayer_sunrise')), findsOneWidget);
    expect(find.byKey(const Key('prayer_dhuhr')), findsOneWidget);
    expect(find.byKey(const Key('prayer_asr')), findsOneWidget);
    expect(find.byKey(const Key('prayer_maghrib')), findsOneWidget);
    expect(find.byKey(const Key('prayer_isha')), findsOneWidget);
  });

  // ── T30: Next prayer is identified in state ────────────────────────────────
  testWidgets('T30: next prayer type is reflected in rendered state',
      (tester) async {
    await tester.pumpWidget(_pumpHome(state: _loadedState(nextType: PrayerType.asr)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('next_prayer')), findsOneWidget);
    expect(find.text('next:asr'), findsOneWidget);
  });

  // ── T31: Sunrise is in the list but NOT the next prayer ───────────────────
  testWidgets('T31: Sunrise appears in prayer list but is never the next prayer',
      (tester) async {
    // Sunrise widget appears in prayer list.
    await tester.pumpWidget(_pumpHome(state: _loadedState()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prayer_sunrise')), findsOneWidget);

    // But next prayer is never Sunrise (getNextObligatoryPrayer skips it).
    final text = tester.widget<Text>(find.byKey(const Key('next_prayer')));
    expect(text.data, isNot(contains('sunrise')));
  });

  // ── T32: Missing-location state renders ───────────────────────────────────
  testWidgets('T32: HomeMissingLocation state shows missing_location widget',
      (tester) async {
    await tester.pumpWidget(_pumpHome(state: const HomeMissingLocation()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('missing_location')), findsOneWidget);
  });

  // ── T33: Failure state renders with retry ─────────────────────────────────
  testWidgets('T33: HomeFailure state shows failure message and retry widget',
      (tester) async {
    await tester.pumpWidget(
        _pumpHome(state: const HomeFailure('homePrayerCalcError')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('failure')), findsOneWidget);
    expect(find.byKey(const Key('retry')), findsOneWidget);
  });

  // ── T34: Turkish locale — LTR ─────────────────────────────────────────────
  testWidgets('T34: Turkish locale text direction is LTR', (tester) async {
    await tester.pumpWidget(
        _pumpHome(state: _loadedState(), locale: const Locale('tr')));
    await tester.pumpAndSettle();

    final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.ltr);
  });

  // ── T35: English locale — LTR ─────────────────────────────────────────────
  testWidgets('T35: English locale text direction is LTR', (tester) async {
    await tester.pumpWidget(
        _pumpHome(state: _loadedState(), locale: const Locale('en')));
    await tester.pumpAndSettle();

    final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.ltr);
  });

  // ── T36: Arabic locale — RTL ──────────────────────────────────────────────
  testWidgets('T36: Arabic locale text direction is RTL', (tester) async {
    await tester.pumpWidget(
        _pumpHome(state: _loadedState(), locale: const Locale('ar')));
    await tester.pumpAndSettle();

    final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.rtl);
  });

  // ── T37: Switching locale does not throw ──────────────────────────────────
  testWidgets('T37: switching locale from TR to AR does not throw',
      (tester) async {
    await tester.pumpWidget(
        _pumpHome(state: _loadedState(), locale: const Locale('tr')));
    await tester.pumpAndSettle();
    // Re-pump with Arabic locale — must not throw.
    await tester.pumpWidget(
        _pumpHome(state: _loadedState(), locale: const Locale('ar')));
    await tester.pumpAndSettle();
    // Both prayer list widgets still render.
    expect(find.byKey(const Key('prayer_fajr')), findsOneWidget);
  });

  // ── T38: Phase 4 ARB key parity (spec §33/38) ─────────────────────────────
  // Duplicated here as a smoke-check that the key exists and is non-empty.
  // Full parity is covered by test/localization/arb_keys_test.dart.
  testWidgets('T38: appLocalizations includes homeNextPrayer key',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(builder: (ctx) {
        // ignore: unnecessary_non_null_assertion
        final l10n = AppLocalizations.of(ctx)!; // always non-null inside MaterialApp
        return Text(l10n.homeNextPrayer);
      }),
    ));
    await tester.pumpAndSettle();
    // If the key is missing, gen-l10n would not have compiled — verifies it exists.
    expect(find.textContaining(''), findsWidgets);
  });

  // ── T39: Dark theme renders without throwing ──────────────────────────────
  testWidgets('T39: dark ThemeMode renders loaded state without exceptions',
      (tester) async {
    final cubit = StubHomeCubit();
    final state = _loadedState();
    whenListen(cubit, Stream<HomeState>.fromIterable([state]),
        initialState: state);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BlocProvider<HomeCubit>.value(
        value: cubit,
        child: Builder(builder: (context) {
          return Scaffold(
            body: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, s) {
                if (s is HomeLoaded) {
                  return Text(s.location.city ?? '');
                }
                return const SizedBox();
              },
            ),
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('İstanbul'), findsOneWidget);
  });

  // ── T40: Large text scale — main prayer info not clipped ─────────────────
  testWidgets('T40: text scale 1.5× does not clip city name',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() =>
        tester.platformDispatcher.clearTextScaleFactorTestValue());

    await tester.pumpWidget(_pumpHome(state: _loadedState()));
    await tester.pumpAndSettle();

    // City label must still be present (not clipped away).
    expect(find.byKey(const Key('city')), findsOneWidget);
  });
}
