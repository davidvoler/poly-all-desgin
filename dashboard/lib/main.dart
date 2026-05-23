import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'pages/courses_page.dart';
import 'pages/editors_page.dart';
import 'pages/languages_page.dart';
import 'pages/overview_page.dart';
import 'pages/settings_page.dart';
import 'pages/students_page.dart';
import 'theme.dart';

void main() {
  runApp(const DashboardApp());
}

/// Lets the horizontal table rows on Languages / Courses / Students be
/// dragged with a mouse on desktop & web, where the default behavior
/// ignores everything but touch.
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
      initialRoute: '/',
      routes: {
        '/': (_) => const OverviewPage(),
        '/languages': (_) => const LanguagesPage(),
        '/courses': (_) => const CoursesPage(),
        '/editors': (_) => const EditorsPage(),
        '/students': (_) => const StudentsPage(),
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
}
