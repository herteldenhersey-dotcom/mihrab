import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/enums/language_code.dart';
import 'package:mihrab/domain/repositories/settings_repository.dart';
import 'package:mihrab/localization/app_localizations.dart';
import 'package:mihrab/localization/cubit/locale_cubit.dart';

/// Minimal in-memory settings fake (mirrors the one in locale_cubit_test).
class FakeSettingsRepository implements SettingsRepository {
  LanguageCode? _storedLanguage;
  FakeSettingsRepository({LanguageCode? initialLanguage})
      : _storedLanguage = initialLanguage;

  @override
  Future<LanguageCode?> getStoredLanguage() async => _storedLanguage;
  @override
  Future<LanguageCode> getLanguage() async => _storedLanguage ?? LanguageCode.tr;
  @override
  Future<void> saveLanguage(LanguageCode language) async =>
      _storedLanguage = language;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used in test');
}

/// Test harness reproducing app.dart's localization + reactive-locale wiring,
/// but with a plain [MaterialApp] home so we can read the resolved
/// [Directionality] the framework derives from `MaterialApp.locale`.
class _Harness extends StatelessWidget {
  const _Harness({required this.localeCubit});
  final LocaleCubit localeCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleCubit>.value(
      value: localeCubit,
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales:
                LanguageCode.values.map((c) => c.locale).toList(),
            home: Builder(
              builder: (context) => Directionality(
                // Re-reading the ambient direction the WidgetsApp installed.
                textDirection: Directionality.of(context),
                child: Text(
                  AppLocalizations.of(context).onboardingLanguageTitle,
                  key: const Key('title'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

TextDirection _ambientDirection(WidgetTester tester) {
  final element = tester.element(find.byKey(const Key('title')));
  return Directionality.of(element);
}

void main() {
  Future<LocaleCubit> loadedCubit(
    WidgetTester tester, {
    required LanguageCode initial,
  }) async {
    final cubit = LocaleCubit(
      FakeSettingsRepository(initialLanguage: initial),
      deviceLocaleProvider: () => const Locale('en'),
    );
    await cubit.load();
    return cubit;
  }

  testWidgets('Arabic renders right-to-left', (tester) async {
    final cubit = await loadedCubit(tester, initial: LanguageCode.ar);
    await tester.pumpWidget(_Harness(localeCubit: cubit));
    await tester.pumpAndSettle();

    expect(_ambientDirection(tester), TextDirection.rtl);
    // And the Arabic string is actually rendered.
    expect(find.text('اختر لغتك'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('Turkish renders left-to-right', (tester) async {
    final cubit = await loadedCubit(tester, initial: LanguageCode.tr);
    await tester.pumpWidget(_Harness(localeCubit: cubit));
    await tester.pumpAndSettle();

    expect(_ambientDirection(tester), TextDirection.ltr);
    await cubit.close();
  });

  testWidgets('English renders left-to-right', (tester) async {
    final cubit = await loadedCubit(tester, initial: LanguageCode.en);
    await tester.pumpWidget(_Harness(localeCubit: cubit));
    await tester.pumpAndSettle();

    expect(_ambientDirection(tester), TextDirection.ltr);
    await cubit.close();
  });

  testWidgets('runtime switch TR → AR flips LTR to RTL without restart',
      (tester) async {
    final cubit = await loadedCubit(tester, initial: LanguageCode.tr);
    await tester.pumpWidget(_Harness(localeCubit: cubit));
    await tester.pumpAndSettle();
    expect(_ambientDirection(tester), TextDirection.ltr);

    await cubit.changeLocale(LanguageCode.ar);
    await tester.pumpAndSettle();

    expect(_ambientDirection(tester), TextDirection.rtl);
    expect(find.text('اختر لغتك'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('runtime switch AR → EN restores RTL to LTR',
      (tester) async {
    final cubit = await loadedCubit(tester, initial: LanguageCode.ar);
    await tester.pumpWidget(_Harness(localeCubit: cubit));
    await tester.pumpAndSettle();
    expect(_ambientDirection(tester), TextDirection.rtl);

    await cubit.changeLocale(LanguageCode.en);
    await tester.pumpAndSettle();

    expect(_ambientDirection(tester), TextDirection.ltr);
    expect(find.text('Choose your language'), findsOneWidget);
    await cubit.close();
  });
}
