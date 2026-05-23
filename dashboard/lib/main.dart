import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/dashboard_api.dart';
import 'pages/courses_page.dart';
import 'pages/editors_page.dart';
import 'pages/languages_page.dart';
import 'pages/login_page.dart';
import 'pages/overview_page.dart';
import 'pages/settings_page.dart';
import 'pages/students_page.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: DashboardApp()));
}

/// Lets horizontal tables on Languages / Courses / Students be dragged
/// with a mouse on desktop & web, where the default behavior ignores
/// everything but touch.
class _DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polyglots · Schools',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _DragScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: DashColors.darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DashColors.brand,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      // Auth gate routes between login and the dashboard. Once signed
      // in, named routes navigate inside the dashboard normally.
      home: const _AuthGate(),
      routes: {
        '/courses': (_) => const _Guarded(child: CoursesPage()),
        '/languages': (_) => const _Guarded(child: LanguagesPage()),
        '/editors': (_) => const _Guarded(child: EditorsPage()),
        '/students': (_) => const _Guarded(child: StudentsPage()),
        '/settings': (_) => const _Guarded(child: SettingsPage()),
      },
    );
  }
}

/// Picks between the login page and the dashboard based on auth state.
/// The login page is rendered without scaffold chrome; the dashboard's
/// pages bring their own.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth is AuthSignedIn) return const OverviewPage();
    return const LoginPage();
  }
}

/// Wraps a named-route page so deep links can't bypass the auth gate.
/// If the user is signed out (e.g. after a sign-out) the LoginPage
/// replaces the inner page on next rebuild.
class _Guarded extends ConsumerWidget {
  final Widget child;
  const _Guarded({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth is AuthSignedIn) return child;
    return const LoginPage();
  }
}
