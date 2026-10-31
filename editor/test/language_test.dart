import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/courses/data/language.dart';

void main() {
  test('parses a language and labels it with its native name', () {
    final spanish = Language.fromJson({
      'code': 'es',
      'name': 'Spanish',
      'native_name': 'Español',
      'weight': 3,
    });

    expect(spanish.code, 'es');
    expect(spanish.label, 'Spanish (Español)');
    expect(const Language(code: 'en', name: 'English').label, 'English');
  });
}
