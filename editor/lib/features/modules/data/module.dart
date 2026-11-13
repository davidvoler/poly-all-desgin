import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

class Module {
  const Module({
    required this.id,
    required this.title,
    this.description = '',
    this.videoUrl = '',
  });

  /// Builds a module from the server's `course.module` row.
  factory Module.fromJson(Map<String, dynamic> json) => Module(
    id: json['module_id'] as int,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    videoUrl: json['video_url'] as String? ?? '',
  );

  final int id;
  final String title;
  final String description;

  /// For a video module, the YouTube URL its lessons are parts of.
  final String videoUrl;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    this.description = '',
    this.videoStart,
    this.videoEnd,
    this.exercises = const [],
  });

  /// Builds a lesson from the server's `LessonFull`, which nests the lesson
  /// row under `lesson` next to its `exercises`.
  factory Lesson.fromJson(Map<String, dynamic> json) {
    final lesson = json['lesson'] as Map<String, dynamic>? ?? json;
    return Lesson(
      id: lesson['lesson_id'] as int,
      title: lesson['title'] as String? ?? '',
      description: lesson['description'] as String? ?? '',
      videoStart: (lesson['video_start'] as num?)?.toDouble(),
      videoEnd: (lesson['video_end'] as num?)?.toDouble(),
      exercises: [
        for (final row in json['exercises'] as List? ?? const [])
          Exercise.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  final int id;
  final String title;

  /// For a video part, the part's subtitles.
  final String description;

  /// For a video part, where it starts and ends in the video, in seconds.
  final double? videoStart;
  final double? videoEnd;
  final List<Exercise> exercises;
}

class Exercise {
  const Exercise({
    this.id,
    this.courseId,
    this.moduleId,
    this.lessonId,
    this.type = '',
    this.word = '',
    this.question = '',
    this.sentence = '',
    this.answer = '',
    this.options = const [],
    this.translation = '',
    this.explanation = '',
  });

  /// Builds an exercise from the server's `course.exercise` row.
  factory Exercise.fromJson(Map<String, dynamic> json) {
    final answer = json['answer'] as String? ?? '';
    final rawOptions = json['options'];
    final options = <ExerciseOption>[];
    if (rawOptions is List) {
      for (final rawOption in rawOptions) {
        if (rawOption is Map) {
          options.add(
            ExerciseOption(
              text: '${rawOption['text']}',
              correct: rawOption['correct'] == true,
            ),
          );
        }
      }
    }
    if (options.isEmpty && answer.isNotEmpty) {
      options.add(ExerciseOption(text: answer, correct: true));
    }
    return Exercise(
      id: json['exercise_id'] as int?,
      courseId: json['course_id'] as int?,
      moduleId: json['module_id'] as int?,
      lessonId: json['lesson_id'] as int?,
      type: json['exercise_type'] as String? ?? '',
      word: json['word'] as String? ?? '',
      question: json['question'] as String? ?? '',
      sentence: json['sentence'] as String? ?? '',
      answer: answer,
      options: options,
      translation: json['sentence_alt1'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  /// The server's `Exercise` shape. Columns the editor does not show are
  /// left out, so the server keeps them empty.
  Map<String, Object?> toJson() => {
    'exercise_id': id,
    'course_id': courseId,
    'module_id': moduleId,
    'lesson_id': lessonId,
    'exercise_type': type,
    'word': word.isEmpty ? null : word,
    'question': question,
    'sentence': sentence.isEmpty ? null : sentence,
    'answer': answer,
    'options': [for (final option in options) option.toJson()],
    'sentence_alt1': translation,
    'explanation': explanation,
  };

  /// Null until the exercise is saved.
  final int? id;
  final int? courseId;
  final int? moduleId;
  final int? lessonId;
  final String type;

  /// The module word the exercise practises; marks the word used.
  final String word;
  final String question;

  /// The sentence in the learned language, which the student app shows.
  final String sentence;

  /// The correct option; for true/false, `true` or `false`.
  final String answer;

  /// Options in their saved display order.
  final List<ExerciseOption> options;

  List<String> get correctOptions => [
    for (final option in options)
      if (option.correct) option.text,
  ];

  List<String> get incorrectOptions => [
    for (final option in options)
      if (!option.correct) option.text,
  ];
  final String translation;
  final String explanation;
}

class ExerciseOption {
  const ExerciseOption({required this.text, this.correct = false});

  final String text;
  final bool correct;

  Map<String, Object?> toJson() => {'text': text, if (correct) 'correct': true};
}

/// Exercise types the editor offers, by server value.
const exerciseTypes = {
  'single_choice': 'Single choice',
  'multiple_choice': 'Multiple choice',
  'fill_in_the_blank': 'Fill in the blank',
  'true_false': 'True / false',
  'explanation': 'Explanation',
};

class ExercisesRepository {
  const ExercisesRepository(this._dio);

  final Dio _dio;

  /// Creates the exercise when it has no id yet, else updates it.
  Future<Exercise> save(Exercise exercise) async {
    final response = exercise.id == null
        ? await _dio.post<Map<String, dynamic>>(
            '/api/v1/exercises/exercise',
            data: exercise.toJson(),
          )
        : await _dio.put<Map<String, dynamic>>(
            '/api/v1/exercises/exercise',
            data: exercise.toJson(),
          );
    return Exercise.fromJson(response.data!);
  }

  Future<void> delete(int exerciseId) => _dio.delete<void>(
    '/api/v1/exercises/exercise',
    queryParameters: {'exercise_id': exerciseId},
  );
}

final exercisesRepositoryProvider = Provider<ExercisesRepository>(
  (ref) => ExercisesRepository(ref.watch(dioProvider)),
);

class Word {
  const Word({required this.text, this.used = false, this.translation = ''});

  /// Builds a word from the server's `Word` shape.
  factory Word.fromJson(Map<String, dynamic> json) => Word(
    text: json['text'] as String,
    used: json['used'] as bool? ?? false,
    translation: json['translation'] as String? ?? '',
  );

  final String text;

  /// Whether the word is already used in the course.
  final bool used;

  /// The word in the students' language; empty when unknown.
  final String translation;
}

class Sentence {
  const Sentence({
    required this.id,
    required this.text,
    this.lessonId,
    this.translation = '',
    this.used = false,
  });

  /// Builds a sentence from the server's `Sentence` shape.
  factory Sentence.fromJson(Map<String, dynamic> json) => Sentence(
    id: json['sentence_id'] as int,
    text: json['sentence'] as String? ?? '',
    lessonId: json['lesson_id'] as int?,
    translation: json['translation'] as String? ?? '',
    used: json['used'] as bool? ?? false,
  );

  final int id;
  final String text;

  /// The lesson (video part) the sentence comes from.
  final int? lessonId;
  final String translation;

  /// Whether an exercise in the module asks this sentence.
  final bool used;
}

class ModulesRepository {
  const ModulesRepository(this._dio);

  final Dio _dio;

  Future<List<Module>> fetchModules(int courseId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/modules/modules',
      queryParameters: {'course_id': courseId},
    );
    return [
      for (final row in response.data ?? const [])
        Module.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Changes a module word's translation, or removes the word.
  Future<void> updateWord({
    required int courseId,
    required int moduleId,
    required String text,
    String? translation,
    bool deleted = false,
  }) => _dio.put<void>(
    '/api/v1/words/word',
    data: {
      'course_id': courseId,
      'module_id': moduleId,
      'text': text,
      'translation': translation,
      'deleted': deleted,
    },
  );

  /// The module's lessons with their exercises.
  Future<List<Lesson>> fetchLessons(int moduleId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/modules/module/full',
      queryParameters: {'module_id': moduleId},
    );
    return [
      for (final row in response.data?['lessons'] as List? ?? const [])
        Lesson.fromJson(row as Map<String, dynamic>),
    ];
  }
}

/// The words of a module.
Future<List<Word>> _fetchWords(Dio dio, int courseId, int moduleId) async {
  final response = await dio.get<List<dynamic>>(
    '/api/v1/words/words',
    queryParameters: {'course_id': courseId, 'module_id': moduleId},
  );
  return [
    for (final row in response.data ?? const [])
      Word.fromJson(row as Map<String, dynamic>),
  ];
}

final modulesRepositoryProvider = Provider<ModulesRepository>(
  (ref) => ModulesRepository(ref.watch(dioProvider)),
);

/// Modules of a course, by course id.
final modulesProvider = FutureProvider.family<List<Module>, int>(
  (ref, courseId) =>
      ref.watch(modulesRepositoryProvider).fetchModules(courseId),
);

/// Lessons and exercises of a module, by module id.
final lessonsProvider = FutureProvider.family<List<Lesson>, int>(
  (ref, moduleId) =>
      ref.watch(modulesRepositoryProvider).fetchLessons(moduleId),
);

/// Words of a module, by course and module id.
final wordsProvider =
    FutureProvider.family<List<Word>, ({int courseId, int moduleId})>(
      (ref, key) =>
          _fetchWords(ref.watch(dioProvider), key.courseId, key.moduleId),
    );

/// The sentences of a module, such as those extracted from video parts.
final sentencesProvider =
    FutureProvider.family<List<Sentence>, ({int courseId, int moduleId})>((
      ref,
      key,
    ) async {
      final response = await ref
          .watch(dioProvider)
          .get<List<dynamic>>(
            '/api/v1/words/sentences',
            queryParameters: {
              'course_id': key.courseId,
              'module_id': key.moduleId,
            },
          );
      return [
        for (final row in response.data ?? const [])
          Sentence.fromJson(row as Map<String, dynamic>),
      ];
    });
