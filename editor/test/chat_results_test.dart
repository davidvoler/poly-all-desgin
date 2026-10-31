import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/chat/widgets/chat_results.dart';

void main() {
  testWidgets('shows a list of records as a table and other values as lines', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatResults(
            results: {
              'words_translations': [
                {'word': 'ciao', 'translation': 'hello / hi'},
                {'word': 'grazie', 'translation': 'thank you'},
              ],
              'saved': 2,
            },
          ),
        ),
      ),
    );

    expect(find.text('WORDS TRANSLATIONS (2)'), findsOneWidget);
    expect(find.text('Word'), findsOneWidget);
    expect(find.text('Translation'), findsOneWidget);
    expect(find.text('ciao'), findsOneWidget);
    expect(find.text('thank you'), findsOneWidget);
    expect(find.text('Saved: 2'), findsOneWidget);
  });
}
