import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/modules/data/module.dart';
import 'package:editor/features/modules/widgets/lesson_preview.dart';

const lesson = Lesson(
  id: 1,
  title: 'Lesson 1',
  exercises: [
    Exercise(
      id: 1,
      type: 'single_choice',
      question: 'Il sole è caldo.',
      answer: 'The sun is hot.',
      correctOptions: ['The sun is hot.'],
      incorrectOptions: ['The moon is full.', 'The sun is cold.'],
    ),
    Exercise(
      id: 2,
      type: 'multiple_choice',
      question: 'Which are greetings?',
      answer: 'ciao',
      correctOptions: ['ciao', 'salve'],
      incorrectOptions: ['pane'],
    ),
    Exercise(
      id: 3,
      type: 'true_false',
      question: 'Pane means bread.',
      answer: 'true',
    ),
    Exercise(id: 4, type: 'explanation', explanation: 'Ciao is informal.'),
  ],
);

void main() {
  testWidgets('plays a lesson and scores it', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LessonPreview(lesson: lesson)),
      ),
    );

    // Single choice: a wrong pick is checked at once and the answer shown.
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Il sole è caldo.'), findsOneWidget);
    await tester.tap(find.text('The sun is cold.'));
    await tester.pump();
    expect(find.text('Not quite.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    // No second chance once checked.
    await tester.tap(find.text('The sun is hot.'));
    await tester.pump();
    expect(find.text('Not quite.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    // Multiple choice: pick several, then check.
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.tap(find.text('ciao'));
    await tester.tap(find.text('salve'));
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    // True/false.
    await tester.tap(find.text('True'));
    await tester.pump();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    // Explanation: read, then finish.
    expect(find.text('Ciao is informal.'), findsOneWidget);
    await tester.tap(find.text('Finish'));
    await tester.pump();

    // Explanations are not scored.
    expect(find.text('2 of 3 correct'), findsOneWidget);
    await tester.tap(find.text('Start again'));
    await tester.pump();
    expect(find.text('1 / 4'), findsOneWidget);
  });

  testWidgets('says so when the lesson has no exercises', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LessonPreview(lesson: Lesson(id: 2, title: 'Empty')),
        ),
      ),
    );
    expect(
      find.text('This lesson has no exercises to preview yet.'),
      findsOneWidget,
    );
  });
}
