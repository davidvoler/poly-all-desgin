import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/modules/data/module.dart';
import 'package:editor/features/modules/widgets/part_video.dart';

void main() {
  test('parses a module lesson with its exercises from the server', () {
    final lesson = Lesson.fromJson({
      'lesson': {'lesson_id': 7, 'module_id': 3, 'title': 'Greetings'},
      'exercises': [
        {
          'exercise_id': 1,
          'exercise_type': 'single_choice',
          'question': 'Hola?',
        },
      ],
    });

    expect(lesson.id, 7);
    expect(lesson.title, 'Greetings');
    expect(lesson.exercises.single.type, 'single_choice');
    expect(lesson.exercises.single.question, 'Hola?');
  });

  test('parses a module sentence from the server', () {
    final sentence = Sentence.fromJson({
      'sentence_id': 11,
      'lesson_id': 38,
      'sentence': 'Il sole è caldo.',
      'translation': 'The sun is hot.',
      'used': true,
    });

    expect(sentence.id, 11);
    expect(sentence.lessonId, 38);
    expect(sentence.text, 'Il sole è caldo.');
    expect(sentence.translation, 'The sun is hot.');
    expect(sentence.used, isTrue);
  });

  test('reads a video part\'s times and its module\'s video', () {
    final lesson = Lesson.fromJson({
      'lesson': {
        'lesson_id': 38,
        'title': 'Part 1 (0:02-2:03)',
        'video_start': 2,
        'video_end': 123.5,
      },
      'exercises': <Object>[],
    });
    final module = Module.fromJson({
      'module_id': 26,
      'title': 'Dolomites',
      'video_url': 'https://www.youtube.com/watch?v=9N99wz9xtJE&t=145s',
    });

    expect(lesson.videoStart, 2.0);
    expect(lesson.videoEnd, 123.5);
    expect(PartVideo.videoId(module.videoUrl), '9N99wz9xtJE');
    expect(PartVideo.videoId(''), isNull);
  });
}
