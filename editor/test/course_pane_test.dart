import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/courses/data/course.dart';
import 'package:editor/features/courses/data/prompts_context.dart';
import 'package:editor/features/courses/pages/course_authoring_page.dart';
import 'package:editor/features/modules/data/module.dart';

/// Serves a fixed context instead of calling the server.
class _FakeContextRepository extends ContextRepository {
  _FakeContextRepository() : super(Dio());

  @override
  Future<PromptsContext> getOrCreate(int courseId) async =>
      PromptsContext(courseId: courseId, moduleId: 1, lessonId: 11);

  @override
  Future<PromptsContext> save(PromptsContext context) async => context;
}

void main() {
  testWidgets('the module lists its lessons and opens the current one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contextRepositoryProvider.overrideWithValue(_FakeContextRepository()),
          modulesProvider.overrideWith(
            (ref, courseId) async => const [
              Module(id: 1, title: 'Greetings'),
              Module(id: 2, title: 'Numbers'),
            ],
          ),
          lessonsProvider.overrideWith(
            (ref, moduleId) async => moduleId == 2
                ? const [Lesson(id: 20, title: 'Counting')]
                : const [
                    Lesson(
                      id: 10,
                      title: 'Lesson 1',
                      exercises: [Exercise(id: 1, question: 'Hidden question')],
                    ),
                    Lesson(
                      id: 11,
                      title: 'Lesson 2',
                      exercises: [
                        Exercise(
                          id: 2,
                          type: 'single_choice',
                          question: 'Il sole è caldo.',
                          answer: 'The sun is hot.',
                          correctOptions: ['The sun is hot.'],
                          incorrectOptions: ['The moon is full.'],
                        ),
                      ],
                    ),
                  ],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CourseDataPane(
              course: Course(
                id: 7,
                title: 'Basic Italian',
                learningLanguage: 'Italian',
                studentLanguage: 'English',
                level: 'A1',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lesson'), findsNothing);
    expect(find.text('Lesson 1'), findsOneWidget);
    expect(find.text('Lesson 2'), findsOneWidget);
    // Only the context's lesson (Lesson 2) is open, with its exercises.
    expect(find.text('Il sole è caldo.'), findsOneWidget);
    expect(find.text('Hidden question'), findsNothing);
    expect(find.text('Add exercise'), findsOneWidget);
    expect(find.byTooltip('Edit exercise'), findsOneWidget);

    // Tapping the open lesson closes it, and tapping it again reopens it.
    await tester.tap(find.text('Lesson 2'));
    await tester.pumpAndSettle();
    expect(find.text('Il sole è caldo.'), findsNothing);
    expect(find.text('Add exercise'), findsNothing);
    await tester.tap(find.text('Lesson 2'));
    await tester.pumpAndSettle();
    expect(find.text('Il sole è caldo.'), findsOneWidget);

    // Tapping a closed lesson opens it instead.
    await tester.tap(find.text('Lesson 1'));
    await tester.pumpAndSettle();
    expect(find.text('Hidden question'), findsOneWidget);
    expect(find.text('Il sole è caldo.'), findsNothing);

    // Tapping the open module closes it, and tapping it again reopens it.
    await tester.tap(find.text('Greetings'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1'), findsNothing);
    await tester.tap(find.text('Greetings'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1'), findsOneWidget);

    // Tapping a closed module opens it and closes the other.
    await tester.tap(find.text('Numbers'));
    await tester.pumpAndSettle();
    expect(find.text('Counting'), findsOneWidget);
    expect(find.text('Lesson 1'), findsNothing);
  });
}
