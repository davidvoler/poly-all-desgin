import 'package:flutter/material.dart';
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/chat/data/chat_responder.dart';
import 'package:editor/features/chat/data/prompt_router_responder.dart';
import 'package:editor/features/courses/data/course.dart';
import 'package:editor/features/courses/data/courses_repository.dart';
import 'package:editor/features/courses/data/language.dart';
import 'package:editor/main.dart';

// Serve the sample courses and canned replies instead of calling the server.
Widget buildApp() => ProviderScope(
  overrides: [
    coursesProvider.overrideWith((ref) async => sampleCourses),
    languagesProvider.overrideWith((ref) async => builtInLanguages),
    responderFactoryProvider.overrideWithValue(
      (course) => ChatResponder(course: course),
    ),
  ],
  child: const CourseEditorApp(),
);

// The spinner animates until the reply arrives, so advance past the
// simulated latency before settling.
Future<void> waitForReply(WidgetTester tester) async {
  await tester.pump(ChatResponder.responseDelay);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on the chat and switches pages from the left menu', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Course assistant'), findsOneWidget);
    expect(find.text('Everyday Spanish'), findsNWidgets(2));

    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    expect(find.text('Your courses'), findsOneWidget);
    expect(find.text('Add course'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Course assistant'), findsOneWidget);
  });

  testWidgets('opens course setup and enters authoring', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add course'));
    await tester.pumpAndSettle();
    expect(find.text('Create a course'), findsOneWidget);
    expect(find.text('Learning language'), findsOneWidget);
    expect(find.text('Student language'), findsOneWidget);
    expect(find.text('Course title'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Italian for Travel');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Italian for Travel'), findsNWidgets(2));
    expect(find.text('Your course is ready to take shape'), findsOneWidget);
    expect(find.text('Course assistant'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'create a module');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    expect(find.text('create a module'), findsOneWidget);
    expect(find.text('Thinking…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await waitForReply(tester);
    expect(find.text('Thinking…'), findsNothing);
    expect(
      find.textContaining('Give it a name, or start from a topic'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Show debug data'));
    await tester.pumpAndSettle();
    expect(find.text('Debug data'), findsOneWidget);
    expect(find.textContaining('"matched_rule": "module"'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    // Picking an option sends it and the reply offers the next options.
    await tester.tap(find.widgetWithText(ActionChip, 'Greetings'));
    await waitForReply(tester);
    expect(find.textContaining('"Greetings" vocabulary'), findsOneWidget);
    expect(
      find.widgetWithText(ActionChip, 'Basic list (10 words)'),
      findsOneWidget,
    );

    // An option that needs input asks for a value before it is sent.
    await tester.enterText(find.byType(TextField), 'create a module');
    await tester.tap(find.byTooltip('Send message'));
    await waitForReply(tester);
    await tester.tap(find.widgetWithText(ActionChip, 'Name the module').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Module name'),
      'At the café',
    );
    await tester.tap(find.byTooltip('Submit Module name'));
    await waitForReply(tester);
    expect(find.text('Name the module: At the café'), findsOneWidget);
    expect(
      find.textContaining('Module "At the café" is ready to set up'),
      findsOneWidget,
    );

    await tester.tap(find.text('Add first module'));
    await tester.pumpAndSettle();

    expect(find.text('MODULE OUTLINE'), findsOneWidget);
    expect(find.text('AI provider'), findsOneWidget);
    expect(find.text('Module generation'), findsOneWidget);
    expect(find.text('muse-glimmer'), findsOneWidget);
    expect(
      find.text('Describe the lessons or exercises you need...'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField),
      'ordering coffee in Spanish',
    );
    await tester.tap(find.byTooltip('Send prompt'));
    await tester.pump();
    expect(find.text('ordering coffee in Spanish'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
