import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/courses_api.dart';
import 'api/models.dart';
import 'i18n/translations.g.dart';
import 'pages/annotated_page.dart';
import 'pages/course_page.dart';
import 'pages/courses_page.dart';
import 'pages/home_page.dart';
import 'pages/quiz_page.dart';
import 'state/lang.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Pick the device locale, fall back to base (en) if unsupported.
  LocaleSettings.useDeviceLocale();
  runApp(
    ProviderScope(
      child: TranslationProvider(
        child: const _PreferenceBootstrap(child: PolyglotsApp()),
      ),
    ),
  );
}

/// Watches [preferenceProvider] once at app startup and seeds the
/// in-memory view state (`speakLangProvider`, `learningLangProvider`,
/// `uiLangProvider`, `selectedModuleIdProvider`) from whatever the
/// server returns. Uses `setSilently` so the seed itself doesn't echo
/// back to the server as a POST.
class _PreferenceBootstrap extends ConsumerWidget {
  final Widget child;
  const _PreferenceBootstrap({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Preference?>>(preferenceProvider, (prev, next) {
      next.whenData((pref) {
        if (pref == null) return;
        // Server: `lang` = language being learned, `to_lang` = the
        // student's native ("I speak") language.
        if (pref.lang != null) {
          ref
              .read(learningLangProvider.notifier)
              .setSilently(Lang.byCode(pref.lang!));
        }
        if (pref.toLang != null) {
          ref
              .read(speakLangProvider.notifier)
              .setSilently(Lang.byCode(pref.toLang!));
        }
        if (pref.uiLang != null) {
          ref
              .read(uiLangProvider.notifier)
              .setSilently(Lang.byCode(pref.uiLang!));
        }
        if (pref.moduleId != null) {
          ref
              .read(selectedModuleIdProvider.notifier)
              .setSilently(pref.moduleId);
        }
      });
    });
    return child;
  }
}

/// Lets scrollables (esp. horizontal lists like the course-page module
/// strip) be dragged with a mouse/trackpad on web & desktop, where the
/// default behavior only accepts touch and ignores the wheel sideways.
class _DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class PolyglotsApp extends StatelessWidget {
  const PolyglotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polyglots',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _DragScrollBehavior(),
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
