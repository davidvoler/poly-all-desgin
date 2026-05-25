// Smoke test — verifies the app boots and the home page renders.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poliglots_app/i18n/translations.g.dart';
import 'package:poliglots_app/main.dart';

void main() {
  testWidgets('Home page renders English strings', (WidgetTester tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(child: const PolyglotsApp()),
      ),
    );
    await tester.pump();

    expect(find.text('POLYGLOTS'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    expect(find.text('Practice Now'), findsOneWidget);
  });

  testWidgets('Home page renders Italian strings', (WidgetTester tester) async {
    LocaleSettings.setLocaleSync(AppLocale.it);
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(child: const PolyglotsApp()),
      ),
    );
    await tester.pump();

    expect(find.text('POLYGLOTS'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    expect(find.text('Esercitati ora'), findsOneWidget);
    expect(find.text('Serie di 5 giorni'), findsOneWidget);
  });

  testWidgets('Home page renders Hebrew strings', (WidgetTester tester) async {
    LocaleSettings.setLocaleSync(AppLocale.he);
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(child: const PolyglotsApp()),
      ),
    );
    await tester.pump();

    expect(find.text('POLYGLOTS'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    expect(find.text('תרגל עכשיו'), findsOneWidget);
    expect(find.text('רצף של 5 ימים'), findsOneWidget);
  });
}
