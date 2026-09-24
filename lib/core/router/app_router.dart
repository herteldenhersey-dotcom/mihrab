import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/jummah/presentation/pages/jummah_page.dart';
import '../../features/mosques/presentation/pages/mosques_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/prayer_times/presentation/pages/prayer_times_page.dart';
import '../../features/qibla/presentation/pages/qibla_page.dart';
import '../../features/ramadan/presentation/pages/ramadan_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../injection.dart';
import '../../localization/app_localizations.dart';
import 'app_routes.dart';

/// Builds the application [GoRouter].
///
/// A [StatefulShellRoute.indexedStack] powers the persistent bottom navigation
/// bar (Home / Prayer Times / Qibla / Mosques / Settings). Each branch keeps
/// its own navigation state. Ramadan, Jummah and Feedback are pushed on top of
/// the shell as full-screen routes.
///
/// [onboardingComplete] decides the initial location: first-run users land on
/// onboarding, returning users go straight to Home.
GoRouter buildAppRouter({required bool onboardingComplete}) {
  return GoRouter(
    initialLocation: onboardingComplete ? AppRoutes.home : AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => BlocProvider<HomeCubit>(
                  create: (_) => getIt<HomeCubit>(),
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.prayerTimes,
                builder: (context, state) => const PrayerTimesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.qibla,
                builder: (context, state) => const QiblaPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mosques,
                builder: (context, state) => const MosquesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ramadan,
        builder: (context, state) => const RamadanPage(),
      ),
      GoRoute(
        path: AppRoutes.jummah,
        builder: (context, state) => const JummahPage(),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        builder: (context, state) => const FeedbackPage(),
      ),
      // Location setup — pushes user back to onboarding to re-select location.
      GoRoute(
        path: AppRoutes.locationSetup,
        builder: (context, state) => const OnboardingPage(),
      ),
    ],
  );
}

/// Scaffold hosting the [NavigationBar] for the shell branches.
class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab returns to that branch's initial route.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.access_time_outlined),
            selectedIcon: const Icon(Icons.access_time_filled),
            label: l10n.navPrayerTimes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l10n.navQibla,
          ),
          NavigationDestination(
            icon: const Icon(Icons.mosque_outlined),
            selectedIcon: const Icon(Icons.mosque),
            label: l10n.navMosques,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
