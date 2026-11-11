import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/auth/data/auth.dart';
import 'package:editor/features/chat/data/ai_models.dart';
import 'package:editor/features/chat/data/chat_responder.dart';
import 'package:editor/features/chat/data/prompt_router_responder.dart';
import 'package:editor/features/courses/data/course.dart';
import 'package:editor/features/courses/data/courses_repository.dart';
import 'package:editor/features/courses/data/language.dart';
import 'package:editor/main.dart';

import 'fake_auth.dart';

Widget buildApp(FakeAuthNotifier auth) => ProviderScope(
  overrides: [
    authProvider.overrideWith(() => auth),
    coursesProvider.overrideWith((ref) async => sampleCourses),
    languagesProvider.overrideWith((ref) async => builtInLanguages),
    aiProvidersProvider.overrideWith((ref) async => const []),
    responderFactoryProvider.overrideWithValue(
      (course) => ChatResponder(course: course),
    ),
  ],
  child: const CourseEditorApp(),
);

void main() {
  Future<void> useDesktopSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('signed out, the editor shows only the login', (tester) async {
    await useDesktopSize(tester);
    await tester.pumpWidget(buildApp(FakeAuthNotifier(const AuthSignedOut())));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Course assistant'), findsNothing);
  });

  testWidgets('a wrong password shows the server error', (tester) async {
    await useDesktopSize(tester);
    await tester.pumpWidget(buildApp(FakeAuthNotifier(const AuthSignedOut())));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'demo@local.dev',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.text('Course assistant'), findsNothing);
  });

  testWidgets('signing in opens the chat; signing out returns to the login', (
    tester,
  ) async {
    await useDesktopSize(tester);
    final auth = FakeAuthNotifier(const AuthSignedOut());
    await tester.pumpWidget(buildApp(auth));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'demo@local.dev',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'changeme',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Course assistant'), findsOneWidget);
    expect(find.text('demo@local.dev'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOuts, 1);
    expect(find.text('Course assistant'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('an ended session returns to the login with its reason', (
    tester,
  ) async {
    await useDesktopSize(tester);
    final auth = FakeAuthNotifier();
    await tester.pumpWidget(buildApp(auth));
    await tester.pumpAndSettle();
    expect(find.text('Course assistant'), findsOneWidget);

    auth.sessionEnded('The session is invalid or has expired. Sign in again.');
    await tester.pumpAndSettle();

    expect(
      find.text('The session is invalid or has expired. Sign in again.'),
      findsOneWidget,
    );
  });
}
