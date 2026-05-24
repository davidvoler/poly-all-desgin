import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/dashboard_api.dart';
import 'config/app_config.dart';
import 'pages/course_detail_page.dart';
import 'pages/courses_page.dart';
import 'pages/create_school_page.dart';
import 'pages/editors_page.dart';
import 'pages/languages_page.dart';
import 'pages/login_page.dart';
import 'pages/overview_page.dart';
import 'pages/settings_page.dart';
import 'pages/students_page.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
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

/// Skips Material's default page transition for every platform so
/// switching between sidebar sections (Overview → Courses, etc.) is
/// instant — the dashboard already shares its chrome across pages, so
/// the default fade/zoom reads as flicker.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
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
        // Kill the per-platform page transition — the dashboard shares
        // its chrome across pages, so the default fade/zoom reads as
        // flicker when switching sidebar sections.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionsBuilder(),
            TargetPlatform.iOS: _NoTransitionsBuilder(),
            TargetPlatform.linux: _NoTransitionsBuilder(),
            TargetPlatform.macOS: _NoTransitionsBuilder(),
            TargetPlatform.windows: _NoTransitionsBuilder(),
            TargetPlatform.fuchsia: _NoTransitionsBuilder(),
          },
        ),
      ),
      // Auth gate routes between login and the dashboard. Once signed
      // in, named routes navigate inside the dashboard normally.
      home: const _AuthGate(),
      routes: {
        // Onboarding wizard — intentionally NOT wrapped in _Guarded
        // since the whole point is to run before the user has any
        // school to sign into.
        '/create-school': (_) => const CreateSchoolPage(),
        '/courses': (_) => const _Guarded(child: CoursesPage()),
        '/course': (_) => const _Guarded(child: CourseDetailPage()),
        '/languages': (_) => const _Guarded(child: LanguagesPage()),
        '/editors': (_) =>
            const _Guarded(adminOnly: true, child: EditorsPage()),
        '/students': (_) => const _Guarded(child: StudentsPage()),
        '/settings': (_) =>
            const _Guarded(adminOnly: true, child: SettingsPage()),
      },
    );
  }
}

/// Picks between the login page and the dashboard based on auth state.
/// While AuthRestoring (cold-boot lookup of the cached session) we
/// show the gradient background only so we don't flash the login form
/// before deciding where the user belongs.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth is AuthRestoring) {
      return Container(decoration: kDashBackground);
    }
    if (auth is AuthSignedIn) return const OverviewPage();
    return const LoginPage();
  }
}

/// Wraps a named-route page so deep links can't bypass the auth gate.
/// If the user is signed out (e.g. after a sign-out) the LoginPage
/// replaces the inner page on next rebuild. When `adminOnly` is set,
/// non-admin signed-in users see [_AdminOnlyDenied] instead of the
/// inner page — mirrors the sidebar's filtered nav so deep links
/// don't expose pages we hide.
class _Guarded extends ConsumerWidget {
  final Widget child;
  final bool adminOnly;
  const _Guarded({required this.child, this.adminOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthSignedIn) return const LoginPage();
    if (adminOnly && !auth.info.isAdmin) {
      return const _AdminOnlyDenied();
    }
    return child;
  }
}

/// Empty state shown when a non-admin user lands on /editors or
/// /settings via a deep link or bookmark. We don't bounce to the
/// previous route because the user may have arrived cold (e.g. from
/// a typed URL), so a friendly explanation + sign-out is gentler.
class _AdminOnlyDenied extends ConsumerWidget {
  const _AdminOnlyDenied();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: kDashBackground,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Admins only',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This page is restricted to school admins. '
                    'Ask an admin to grant you access, or head back to the dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed('/'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('Back to dashboard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
