import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/navigation_rail_panel.dart';
import '../../chat/data/prompt_router_responder.dart';
import '../../chat/widgets/chat_panel.dart';
import '../../modules/data/module.dart';
import '../../modules/pages/module_editing_page.dart';
import '../../modules/widgets/exercise_dialog.dart';
import '../../modules/widgets/lesson_preview.dart';
import '../../modules/widgets/part_video.dart';
import '../data/course.dart';
import '../data/prompts_context.dart';

class CourseAuthoringPage extends ConsumerWidget {
  const CourseAuthoringPage({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const NavigationRailPanel(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ChatPanel(
                          responder: ref.watch(responderFactoryProvider)(
                            course,
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Color(0xFFE4E0D9)),
                      Expanded(child: CourseDataPane(course: course)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 42),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E0D9))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to courses',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 16),
          const Text(
            'Courses',
            style: TextStyle(color: Color(0xFF8A979A), fontSize: 13),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFB2B9B8),
            ),
          ),
          Text(
            course.title,
            style: const TextStyle(
              color: Color(0xFF17252D),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.visibility_outlined, size: 17),
            label: const Text('Preview'),
          ),
        ],
      ),
    );
  }
}

class CourseDataPane extends ConsumerStatefulWidget {
  const CourseDataPane({required this.course, super.key});

  final Course course;

  @override
  ConsumerState<CourseDataPane> createState() => _CourseDataPaneState();
}

class _CourseDataPaneState extends ConsumerState<CourseDataPane> {
  Course get course => widget.course;

  /// Whether the current lesson was closed by tapping it.
  bool lessonClosed = false;

  /// Whether the current module was closed by tapping it.
  bool moduleClosed = false;

  /// Tapping the open module closes it; tapping a closed one opens it and
  /// makes it current.
  void _toggleModule(int courseId, int moduleId, bool isOpen, bool isCurrent) {
    setState(() {
      moduleClosed = isOpen;
      // Another module opens with its current lesson showing.
      if (!isCurrent) lessonClosed = false;
    });
    if (!isOpen) _select(courseId, moduleId);
  }

  /// Tapping the open lesson closes it; tapping a closed one opens it and
  /// makes it current.
  void _toggleLesson(int courseId, int moduleId, Lesson lesson, bool isOpen) {
    setState(() => lessonClosed = isOpen);
    if (!isOpen) _select(courseId, moduleId, lesson.id);
  }

  /// Makes the module, and the lesson when given, the course's current
  /// context.
  Future<void> _select(int courseId, int moduleId, [int lessonId = 0]) async {
    try {
      await ref
          .read(courseContextProvider(courseId).notifier)
          .select(moduleId: moduleId, lessonId: lessonId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the context.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17252D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.learningLanguage} for ${course.studentLanguage}  ·  ${course.level}',
            style: const TextStyle(color: Color(0xFF748087), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CourseFact(label: 'Learning', value: course.learningLanguage),
              _CourseFact(
                label: 'Students speak',
                value: course.studentLanguage,
              ),
              _CourseFact(label: 'Level', value: course.level),
              _CourseFact(label: 'Lessons', value: '${course.lessons}'),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: Color(0xFF17252D),
                    unselectedLabelColor: Color(0xFF8A979A),
                    indicatorColor: Color(0xFF2B7771),
                    tabs: [
                      Tab(text: 'Modules'),
                      Tab(text: 'Words'),
                      Tab(text: 'Sentences'),
                      Tab(text: 'Preview'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildModules(),
                        _buildWords(),
                        _buildSentences(),
                        _buildPreview(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The context's module when the course has it, else the first module.
  static int _currentModuleId(List<Module> modules, PromptsContext? current) =>
      modules.any((m) => m.id == current?.moduleId)
      ? current!.moduleId
      : modules.first.id;

  /// The current module and the course context, once both are loaded.
  ({int courseId, Module module, PromptsContext? context})? _current() {
    final id = course.id;
    if (id == null) return null;
    final courseContext = ref.watch(courseContextProvider(id));
    final modules = ref.watch(modulesProvider(id)).value;
    if (courseContext.isLoading || modules == null || modules.isEmpty) {
      return null;
    }
    final moduleId = _currentModuleId(modules, courseContext.value);
    return (
      courseId: id,
      module: modules.firstWhere((m) => m.id == moduleId),
      context: courseContext.value,
    );
  }

  /// The current lesson as a student meets it.
  Widget _buildPreview() {
    if (course.id == null) {
      return const _NoWords('Save the course to preview its lessons.');
    }
    final current = _current();
    if (current == null) {
      return ref.watch(modulesProvider(course.id!)).value?.isEmpty ?? false
          ? const _NoWords('Add a module to preview its lessons.')
          : const Center(child: CircularProgressIndicator());
    }
    final module = current.module;
    return ref
        .watch(lessonsProvider(module.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load the lesson.\n$error')),
          data: (lessons) {
            if (lessons.isEmpty) {
              return const _NoWords('This module has no lessons yet.');
            }
            // The context's lesson, else the module's first.
            final lesson = lessons.firstWhere(
              (lesson) => lesson.id == current.context?.lessonId,
              orElse: () => lessons.first,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${module.title.isEmpty ? 'Untitled module' : module.title}'
                  '  ·  ${lesson.title.isEmpty ? 'Untitled lesson' : lesson.title}',
                  style: const TextStyle(
                    color: Color(0xFF748087),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LessonPreview(
                    // Starts over when the lesson or its exercises change.
                    key: ObjectKey(lesson),
                    lesson: lesson,
                    videoUrl: module.videoUrl,
                  ),
                ),
              ],
            );
          },
        );
  }

  Widget _buildSentences() {
    if (course.id == null) {
      return const _NoWords('Save the course to add sentences.');
    }
    final current = _current();
    if (current == null) {
      return ref.watch(modulesProvider(course.id!)).value?.isEmpty ?? false
          ? const _NoWords('Add a module to add sentences.')
          : const Center(child: CircularProgressIndicator());
    }
    final module = current.module;
    final key = (courseId: current.courseId, moduleId: module.id);
    // Lesson titles label the groups, e.g. a video's parts.
    final lessons = ref.watch(lessonsProvider(module.id)).value ?? const [];
    return ref
        .watch(sentencesProvider(key))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load the sentences.\n$error'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(sentencesProvider(key)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (sentences) => sentences.isEmpty
              ? const _NoWords(
                  'No sentences in this module yet. '
                  'Extract them from a video part.',
                )
              : _SentenceList(
                  moduleTitle: module.title.isEmpty
                      ? 'Untitled module'
                      : module.title,
                  sentences: sentences,
                  lessonTitles: {
                    for (final lesson in lessons) lesson.id: lesson.title,
                  },
                ),
        );
  }

  Widget _buildWords() {
    final id = course.id;
    if (id == null) return const _NoWords('Save the course to add words.');
    final courseContext = ref.watch(courseContextProvider(id));
    if (courseContext.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final modules = ref.watch(modulesProvider(id)).value;
    if (modules == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (modules.isEmpty) return const _NoWords('Add a module to add words.');
    final moduleId = _currentModuleId(modules, courseContext.value);
    final module = modules.firstWhere((m) => m.id == moduleId);
    final key = (courseId: id, moduleId: moduleId);
    return ref
        .watch(wordsProvider(key))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load the words.\n$error'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(wordsProvider(key)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (words) => words.isEmpty
              ? const _NoWords('No words in this module yet.')
              : _WordList(
                  courseId: id,
                  moduleId: moduleId,
                  moduleTitle: module.title.isEmpty
                      ? 'Untitled module'
                      : module.title,
                  words: words,
                ),
        );
  }

  Widget _buildModules() {
    final id = course.id;
    if (id == null) return _EmptyModules(course: course);
    // Loading the context can create the first module and lesson, so the
    // modules are fetched only once it is there.
    final courseContext = ref.watch(courseContextProvider(id));
    if (courseContext.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final current = courseContext.value;
    return ref
        .watch(modulesProvider(id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load the modules.\n$error'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(modulesProvider(id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (modules) {
            if (modules.isEmpty) return _EmptyModules(course: course);
            final currentModuleId = _currentModuleId(modules, current);
            return ListView.separated(
              itemCount: modules.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final module = modules[index];
                return _ModuleCard(
                  courseId: id,
                  module: module,
                  isCurrent: module.id == currentModuleId,
                  isOpen: module.id == currentModuleId && !moduleClosed,
                  currentLessonId: current?.lessonId ?? 0,
                  lessonClosed: lessonClosed,
                  onTap: () => _toggleModule(
                    id,
                    module.id,
                    module.id == currentModuleId && !moduleClosed,
                    module.id == currentModuleId,
                  ),
                  onLessonTap: (lesson, isOpen) =>
                      _toggleLesson(id, module.id, lesson, isOpen),
                );
              },
            );
          },
        );
  }
}

class _ModuleCard extends ConsumerWidget {
  const _ModuleCard({
    required this.courseId,
    required this.module,
    required this.isCurrent,
    required this.isOpen,
    required this.currentLessonId,
    required this.onTap,
    required this.onLessonTap,
    this.lessonClosed = false,
  });

  final int courseId;
  final Module module;
  final bool isCurrent;

  /// Whether the card shows its lessons.
  final bool isOpen;
  final int currentLessonId;
  final VoidCallback onTap;

  /// Called with the tapped lesson and whether it is open.
  final void Function(Lesson lesson, bool isOpen) onLessonTap;

  /// Whether the current lesson is closed.
  final bool lessonClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrent ? const Color(0xFF2B7771) : const Color(0xFFE4E0D9),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: onTap,
            leading: Icon(
              isOpen ? Icons.folder_open_rounded : Icons.folder_outlined,
              color: const Color(0xFF2B7771),
            ),
            title: Text(
              module.title.isEmpty ? 'Untitled module' : module.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF17252D),
              ),
            ),
            subtitle: module.description.isEmpty
                ? null
                : Text(
                    module.description,
                    style: const TextStyle(color: Color(0xFF748087)),
                  ),
          ),
          if (isOpen) _buildLessons(ref),
        ],
      ),
    );
  }

  /// The lessons; the context's lesson (else the first) opens with its
  /// exercises.
  Widget _buildLessonList(List<Lesson> lessons) {
    final current = lessons.any((l) => l.id == currentLessonId)
        ? currentLessonId
        : lessons.first.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final lesson in lessons) ...[
          _LessonRow(
            lesson: lesson,
            isCurrent: lesson.id == current,
            onTap: () =>
                onLessonTap(lesson, lesson.id == current && !lessonClosed),
          ),
          if (lesson.id == current && !lessonClosed)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 0, 6),
              child: _LessonExercises(
                courseId: courseId,
                module: module,
                lesson: lesson,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildLessons(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ref
          .watch(lessonsProvider(module.id))
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Could not load the lessons.\n$error'),
            data: (lessons) => lessons.isEmpty
                ? const Text(
                    'No lessons yet.',
                    style: TextStyle(color: Color(0xFF748087), fontSize: 13),
                  )
                : _buildLessonList(lessons),
          ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.isCurrent,
    required this.onTap,
  });

  final Lesson lesson;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFFE3EAE5) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 17,
                    color: Color(0xFFB86F46),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lesson.title.isEmpty ? 'Untitled lesson' : lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF17252D),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${lesson.exercises.length} exercises',
                    style: const TextStyle(
                      color: Color(0xFF8A979A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The exercises of a lesson, with adding, editing and deleting.
class _LessonExercises extends ConsumerWidget {
  const _LessonExercises({
    required this.courseId,
    required this.module,
    required this.lesson,
  });

  final int courseId;
  final Module module;
  final Lesson lesson;

  /// Opens the exercise form and saves the result.
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final words =
        ref
            .read(wordsProvider((courseId: courseId, moduleId: module.id)))
            .value ??
        const <Word>[];
    final edited = await showDialog<Exercise>(
      context: context,
      builder: (_) => ExerciseDialog(exercise: exercise, words: words),
    );
    if (edited == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(exercisesRepositoryProvider).save(edited),
      'save',
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text(
          exercise.question.isEmpty ? 'This exercise' : exercise.question,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(exercisesRepositoryProvider).delete(exercise.id!),
      'delete',
    );
  }

  /// Runs a change and reloads the lessons and words, since saving or
  /// deleting an exercise changes which words are used.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<Object?> Function() change,
    String verb,
  ) async {
    try {
      await change();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not $verb the exercise.\n$error')),
      );
      return;
    }
    ref.invalidate(lessonsProvider(module.id));
    ref.invalidate(wordsProvider((courseId: courseId, moduleId: module.id)));
    ref.invalidate(
      sentencesProvider((courseId: courseId, moduleId: module.id)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = lesson.exercises;
    final videoStart = lesson.videoStart;
    final showVideo =
        videoStart != null && PartVideo.videoId(module.videoUrl) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showVideo) ...[
          PartVideo(
            // A new player for each part.
            key: ValueKey(lesson.id),
            videoUrl: module.videoUrl,
            start: videoStart,
            end: lesson.videoEnd,
          ),
          const SizedBox(height: 12),
        ],
        if (lesson.description.isNotEmpty) ...[
          _PartText(text: lesson.description),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                exercises.isEmpty
                    ? 'No exercises in this lesson yet.'
                    : '${exercises.length} exercises',
                style: const TextStyle(color: Color(0xFF748087), fontSize: 13),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _edit(
                context,
                ref,
                Exercise(
                  courseId: courseId,
                  moduleId: module.id,
                  lessonId: lesson.id,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add exercise'),
            ),
          ],
        ),
        for (final exercise in exercises) ...[
          const SizedBox(height: 10),
          _ExerciseCard(
            exercise: exercise,
            onEdit: () => _edit(context, ref, exercise),
            onDelete: () => _delete(context, ref, exercise),
          ),
        ],
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: Color(0xFF748087), fontSize: 13);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E0D9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    exerciseTypes[exercise.type] ?? exercise.type,
                    if (exercise.word.isNotEmpty) exercise.word,
                  ].join('  ·  ').toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF9AA4A6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                if (exercise.question.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    exercise.question,
                    style: const TextStyle(
                      color: Color(0xFF17252D),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                if (exercise.type == 'explanation')
                  Text(
                    exercise.explanation,
                    style: const TextStyle(
                      color: Color(0xFF17252D),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  )
                else if (exercise.type == 'true_false')
                  Text(
                    exercise.answer.toLowerCase() == 'false' ? 'False' : 'True',
                    style: const TextStyle(
                      color: Color(0xFF2B7771),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  // Correct options in bold, then the wrong ones.
                  Text.rich(
                    TextSpan(
                      children: [
                        for (final option in exercise.correctOptions)
                          TextSpan(
                            text: '$option   ',
                            style: const TextStyle(
                              color: Color(0xFF2B7771),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        for (final option in exercise.incorrectOptions)
                          TextSpan(text: '$option   '),
                      ],
                    ),
                    style: muted,
                  ),
                if (exercise.translation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(exercise.translation, style: muted),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit exercise',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'Delete exercise',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

/// A module's sentences grouped by lesson, marking those used in exercises.
class _SentenceList extends StatelessWidget {
  const _SentenceList({
    required this.moduleTitle,
    required this.sentences,
    required this.lessonTitles,
  });

  final String moduleTitle;
  final List<Sentence> sentences;
  final Map<int, String> lessonTitles;

  @override
  Widget build(BuildContext context) {
    final used = sentences.where((s) => s.used).length;
    // Header rows where the lesson changes; sentences arrive in lesson order.
    final rows = <Widget>[];
    int? lessonId;
    for (final (index, sentence) in sentences.indexed) {
      if (index == 0 || sentence.lessonId != lessonId) {
        lessonId = sentence.lessonId;
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 16, bottom: 8),
            child: Text(
              (lessonTitles[lessonId] ?? 'Other sentences').toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9AA4A6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }
      rows.add(_SentenceRow(sentence: sentence));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$moduleTitle  ·  ${sentences.length} sentences, $used used',
          style: const TextStyle(color: Color(0xFF748087), fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(child: ListView(children: rows)),
      ],
    );
  }
}

class _SentenceRow extends StatelessWidget {
  const _SentenceRow({required this.sentence});

  final Sentence sentence;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: sentence.used ? const Color(0xFFE3EAE5) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sentence.used
                ? const Color(0xFF2B7771)
                : const Color(0xFFE4E0D9),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message: sentence.used ? 'Used in an exercise' : 'Not used yet',
              child: Icon(
                sentence.used
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 17,
                color: sentence.used
                    ? const Color(0xFF2B7771)
                    : const Color(0xFFB2B9B8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    sentence.text,
                    style: const TextStyle(
                      color: Color(0xFF17252D),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (sentence.translation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    SelectableText(
                      sentence.translation,
                      style: const TextStyle(
                        color: Color(0xFF748087),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A video part's subtitles, collapsed to a few lines until expanded.
class _PartText extends StatefulWidget {
  const _PartText({required this.text});

  final String text;

  @override
  State<_PartText> createState() => _PartTextState();
}

class _PartTextState extends State<_PartText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => expanded = !expanded),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF8F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4E0D9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: expanded ? null : 3,
              overflow: expanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF17252D),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              expanded ? 'Show less' : 'Show the whole part',
              style: const TextStyle(
                color: Color(0xFF2B7771),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The module's words; tapping one edits its translation or removes it.
class _WordList extends ConsumerWidget {
  const _WordList({
    required this.courseId,
    required this.moduleId,
    required this.moduleTitle,
    required this.words,
  });

  final int courseId;
  final int moduleId;
  final String moduleTitle;
  final List<Word> words;

  Future<void> _edit(BuildContext context, WidgetRef ref, Word word) async {
    final change = await showDialog<_WordChange>(
      context: context,
      builder: (_) => _WordDialog(word: word),
    );
    if (change == null || !context.mounted) return;
    try {
      await ref
          .read(modulesRepositoryProvider)
          .updateWord(
            courseId: courseId,
            moduleId: moduleId,
            text: word.text,
            translation: change.translation,
            deleted: change.remove,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change the word.\n$error')),
      );
      return;
    }
    ref.invalidate(wordsProvider((courseId: courseId, moduleId: moduleId)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final used = words.where((word) => word.used).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$moduleTitle  ·  ${words.length} words, $used used',
          style: const TextStyle(color: Color(0xFF748087), fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final word in words)
                  _WordChip(word: word, onTap: () => _edit(context, ref, word)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// What the word dialog asks for: a new translation, or removing the word.
class _WordChange {
  const _WordChange({this.translation, this.remove = false});

  final String? translation;
  final bool remove;
}

class _WordDialog extends StatefulWidget {
  const _WordDialog({required this.word});

  final Word word;

  @override
  State<_WordDialog> createState() => _WordDialogState();
}

class _WordDialogState extends State<_WordDialog> {
  late final translation = TextEditingController(text: widget.word.translation);

  @override
  void dispose() {
    translation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.word.text),
      content: TextField(
        controller: translation,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Translation'),
        onSubmitted: (value) =>
            Navigator.of(context).pop(_WordChange(translation: value.trim())),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const _WordChange(remove: true)),
          child: const Text('Remove word'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(_WordChange(translation: translation.text.trim())),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.onTap});

  final Word word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: word.used
          ? 'Already used · tap to edit'
          : 'Not used yet · tap to edit',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: word.used ? const Color(0xFFE3EAE5) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: word.used
                  ? const Color(0xFF2B7771)
                  : const Color(0xFFE4E0D9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (word.used) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Color(0xFF2B7771),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                word.text,
                style: const TextStyle(color: Color(0xFF17252D), fontSize: 14),
              ),
              if (word.translation.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  word.translation,
                  style: const TextStyle(
                    color: Color(0xFF8A979A),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoWords extends StatelessWidget {
  const _NoWords(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      style: const TextStyle(color: Color(0xFF748087), fontSize: 14),
    ),
  );
}

class _EmptyModules extends StatelessWidget {
  const _EmptyModules({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E0D9)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE3EAE5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.layers_outlined,
                size: 29,
                color: Color(0xFF2B7771),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your course is ready to take shape',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF17252D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask the assistant, or add your first module yourself.',
              style: TextStyle(color: Color(0xFF748087), fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ModuleEditingPage(
                    course: course,
                    moduleTitle: 'Module 1',
                  ),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add first module'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseFact extends StatelessWidget {
  const _CourseFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E0D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A979A), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17252D),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
