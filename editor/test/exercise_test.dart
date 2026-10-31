import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/modules/data/module.dart';
import 'package:editor/features/modules/widgets/exercise_dialog.dart';

void main() {
  test('maps options and translation to the server columns', () {
    final exercise = Exercise.fromJson({
      'exercise_id': 1,
      'lesson_id': 11,
      'exercise_type': 'single_choice',
      'word': 'ciao',
      'question': 'Ciao, come stai?',
      'answer': 'hi',
      'options': {
        'incorrect': ['thanks', 'please'],
      },
      'sentence_alt1': 'Hi, how are you?',
    });

    // Exercises without options.correct, like the AI's, have the answer as
    // their one correct option.
    expect(exercise.correctOptions, ['hi']);
    expect(exercise.incorrectOptions, ['thanks', 'please']);
    expect(exercise.toJson()['options'], {
      'correct': ['hi'],
      'incorrect': ['thanks', 'please'],
    });
    expect(exercise.toJson()['sentence_alt1'], 'Hi, how are you?');
  });

  /// Opens the form for [exercise] and returns a getter for its result.
  Future<Exercise? Function()> openForm(
    WidgetTester tester, [
    Exercise exercise = const Exercise(lessonId: 11),
  ]) async {
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Exercise? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<Exercise>(
              context: context,
              builder: (_) => ExerciseDialog(exercise: exercise),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  Future<void> pickType(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Finder optionField(int number) =>
      find.widgetWithText(TextField, 'Option $number');

  testWidgets('single choice starts with 4 options and one correct', (
    tester,
  ) async {
    final result = await openForm(tester);
    expect(find.byType(Checkbox), findsNWidgets(4));

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Add at least 2 options.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sentence'),
      'Ciao, come stai?',
    );
    await tester.enterText(optionField(1), 'hi');
    await tester.enterText(optionField(2), 'thanks');
    await tester.enterText(optionField(3), 'please');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Mark the correct option.'), findsOneWidget);

    // Checking another option unchecks the first in single choice.
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result()?.type, 'single_choice');
    expect(result()?.question, 'Ciao, come stai?');
    expect(result()?.answer, 'hi');
    expect(result()?.correctOptions, ['hi']);
    expect(result()?.incorrectOptions, ['thanks', 'please']);
  });

  testWidgets('multiple choice keeps every checked option', (tester) async {
    final result = await openForm(tester);
    await pickType(tester, 'Multiple choice');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sentence'),
      'Which are greetings?',
    );
    await tester.enterText(optionField(1), 'ciao');
    await tester.enterText(optionField(2), 'salve');
    await tester.enterText(optionField(3), 'pane');
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.tap(find.byTooltip('Remove option').last);
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(3));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result()?.correctOptions, ['ciao', 'salve']);
    expect(result()?.incorrectOptions, ['pane']);
  });

  testWidgets('fill in the blank picks one correct option for the blank', (
    tester,
  ) async {
    final result = await openForm(tester);
    await pickType(tester, 'Fill in the blank');
    expect(find.text('Use ___ for the blank'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(4));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Question'),
      'Torno a ___ stasera.',
    );
    await tester.enterText(optionField(1), 'casa');
    await tester.enterText(optionField(2), 'scuola');
    await tester.enterText(optionField(3), 'lavoro');
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    // Only one option stays correct.
    expect(
      tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .map((c) => c.value)
          .toList(),
      [false, false, true, false],
    );
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result()?.type, 'fill_in_the_blank');
    expect(result()?.question, 'Torno a ___ stasera.');
    expect(result()?.answer, 'casa');
    expect(result()?.correctOptions, ['casa']);
    expect(result()?.incorrectOptions, ['scuola', 'lavoro']);
  });

  testWidgets('true/false has a statement and a true or false answer', (
    tester,
  ) async {
    final result = await openForm(tester);
    await pickType(tester, 'True / false');
    expect(find.byType(Checkbox), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Statement'),
      'Pane means bread.',
    );
    await tester.tap(find.text('False'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result()?.type, 'true_false');
    expect(result()?.question, 'Pane means bread.');
    expect(result()?.answer, 'false');
  });

  testWidgets('explanation is one multi-line text', (tester) async {
    final result = await openForm(tester);
    await pickType(tester, 'Explanation');
    expect(find.widgetWithText(TextFormField, 'Sentence'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Explanation'),
      'Ciao is informal.\nUse buongiorno with strangers.',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result()?.type, 'explanation');
    expect(
      result()?.explanation,
      'Ciao is informal.\nUse buongiorno with strangers.',
    );
    expect(result()?.question, '');
  });

  testWidgets('editing shows the saved options with the correct ones checked', (
    tester,
  ) async {
    await openForm(
      tester,
      const Exercise(
        id: 5,
        type: 'multiple_choice',
        question: 'Which are greetings?',
        correctOptions: ['ciao', 'salve'],
        incorrectOptions: ['pane'],
      ),
    );
    final checks = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .map((c) => c.value)
        .toList();
    // Padded to 4 options.
    expect(checks, [true, true, false, false]);
    expect(find.text('Save'), findsOneWidget);
  });
}
