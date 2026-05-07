import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n/translations.g.dart';
import 'pages/annotated_page.dart';
import 'pages/course_page.dart';
import 'pages/courses_page.dart';
import 'pages/home_page.dart';
import 'pages/quiz_page.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Pick the device locale, fall back to base (en) if unsupported.
  LocaleSettings.useDeviceLocale();
  runApp(
    ProviderScope(
      child: TranslationProvider(child: const PolyglotsApp()),
    ),
  );
}

class PolyglotsApp extends StatelessWidget {
  const PolyglotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polyglots',
      debugShowCheckedModeBanner: false,
      // Keep MaterialApp's locale in sync with slang's so MaterialLocalizations,
      // WidgetsLocalizations, etc. follow the same language.
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: PolyColors.brandPrimary,
        scaffoldBackgroundColor: PolyColors.darkBg,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PolyColors.brandPrimary,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/courses': (context) => const CoursesPage(),
        '/course': (context) => const CoursePage(),
        '/quiz': (context) => const QuizPage(),
        '/annotated': (context) => const AnnotatedPage(),
      },
    );
  }
}
