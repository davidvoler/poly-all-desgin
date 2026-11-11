import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/courses/data/prompts_context.dart';

void main() {
  test('reads and writes the server context shape', () {
    final context = PromptsContext.fromJson({
      'context_id': 4,
      'course_id': 2,
      'module_id': 8,
      'lesson_id': 10,
      'words': <Object>[],
    });

    expect(context.moduleId, 8);
    expect(context.lessonId, 10);
    expect(context.toJson(), {'course_id': 2, 'module_id': 8, 'lesson_id': 10});
  });
}
