import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/courses/data/course.dart';

void main() {
  test('parses a course row from the server', () {
    final course = Course.fromJson({
      'course_id': 1,
      'school': 'local',
      'user_id': 1,
      'lang': 'it',
      'to_lang': 'en',
      'level': 'a1',
      'title': 'Basic Italian',
      'description': 'Itailian for complete beginners',
      'deleted': false,
      'status': 'draft',
      'course_options': null,
    });

    expect(course.id, 1);
    expect(course.title, 'Basic Italian');
    expect(course.learningLanguage, 'Italian');
    expect(course.studentLanguage, 'English');
    expect(course.level, 'A1');
    expect(course.monogram, 'IT');
  });
}
