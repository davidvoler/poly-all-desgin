import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

/// "My courses" for the Create-with-AI copilot — a Flutter port of
/// plan/design_experiments/create_with_ai_poc/index.html. Every course the
/// signed-in editor owns (same GET /api/v1/edit/course/courses as the
/// regular Courses page), with the AI-copilot progress stats as badges,
/// plus a bare-bones create form (lang/to_lang/level/title — no prompt).
class AiCoursesPage extends ConsumerStatefulWidget {
  const AiCoursesPage({super.key});

  @override
  ConsumerState<AiCoursesPage> createState() => _AiCoursesPageState();
}

class _AiCoursesPageState extends ConsumerState<AiCoursesPage> {
  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(editorCoursesProvider(const CoursesFilter()));

    return DashboardShell(
      title: 'Create with AI',
      activeRoute: '/ai-courses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My courses', style: DashText.h1),
                    const SizedBox(height: 4),
                    Text(
                      "Courses you've been building with the AI copilot. Pick one up where you left off, or start a new one.",
                      style: DashText.subtitle,
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                label: 'New course',
                leading: Icons.add,
                onTap: _openCreateDialog,
              ),
            ],
          ),
          const SizedBox(height: 22),
          coursesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Could not load courses — $e',
                  style: TextStyle(color: DashColors.red400, fontSize: 13)),
            ),
            data: (courses) => _CourseGrid(courses: courses),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final courseId = await showDialog<int>(
      context: context,
      builder: (_) => const _CreateAiCourseDialog(),
    );
    if (courseId == null || !mounted) return;
    ref.invalidate(editorCoursesProvider);
    Navigator.pushNamed(context, '/ai-course', arguments: courseId);
  }
}

class _CourseGrid extends StatelessWidget {
  final List<EditorCourse> courses;
  const _CourseGrid({required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 28, color: DashColors.w(0.4)),
            const SizedBox(height: 10),
            Text("No courses yet — create one to start.",
                style: TextStyle(color: DashColors.w(0.6), fontSize: 13)),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final c in courses) _CourseCard(course: c),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final EditorCourse course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final progress = _progressLabel(course);
    return SizedBox(
      width: 280,
      child: InkWell(
        borderRadius: DashRadii.card,
        onTap: () => Navigator.pushNamed(context, '/ai-course', arguments: course.courseId),
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${flagFor(course.lang)}${flagFor(course.toLang)}',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 10),
              Text(course.title,
                  style: DashText.h2, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${course.lang} → ${course.toLang}',
                  style: TextStyle(fontSize: 12, color: DashColors.w(0.55))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(label: course.level ?? 'A1', kind: PillKind.white),
                  Text(progress, style: TextStyle(fontSize: 11, color: DashColors.w(0.55))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _progressLabel(EditorCourse c) {
    final words = c.wordCount ?? 0;
    if (words == 0) return 'Not started';
    final lessons = c.lessonCount ?? 0;
    final ready = c.readyLessonCount ?? 0;
    final lessonWord = lessons == 1 ? 'lesson' : 'lessons';
    final readySuffix = ready > 0 ? ' ($ready ready)' : '';
    return '$words words · $lessons $lessonWord$readySuffix';
  }
}

/// Learning-language flag emoji, purely decorative — falls back to a
/// globe for anything not in the curated set (mirrors LANG_INFO in
/// create_with_ai_poc/assets/store.js).
String flagFor(String lang) {
  const flags = {
    'japanese': '🇯🇵',
    'hebrew': '🇮🇱',
    'spanish': '🇪🇸',
    'french': '🇫🇷',
    'italian': '🇮🇹',
    'arabic': '🇸🇦',
    'german': '🇩🇪',
    'english': '🇬🇧',
    'korean': '🇰🇷',
    'portuguese': '🇵🇹',
  };
  return flags[lang.trim().toLowerCase()] ?? '🌐';
}

const kAiLanguageSuggestions = [
  'Japanese', 'Hebrew', 'Spanish', 'French', 'Italian', 'Arabic', 'German',
  'English', 'Korean', 'Portuguese',
];
const kAiLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];

class _CreateAiCourseDialog extends ConsumerStatefulWidget {
  const _CreateAiCourseDialog();

  @override
  ConsumerState<_CreateAiCourseDialog> createState() => _CreateAiCourseDialogState();
}

class _CreateAiCourseDialogState extends ConsumerState<_CreateAiCourseDialog> {
  final _title = TextEditingController();
  final _lang = TextEditingController(text: 'Japanese');
  final _toLang = TextEditingController(text: 'Hebrew');
  String _level = 'A1';

  // Generation options — persisted onto course_simple.course.metadata by
  // POST /api/v1/generate_poc_new/create_course. Seeded with the same
  // defaults as the server-side CourseOption.
  CourseOptions _options = const CourseOptions();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _lang.dispose();
    _toLang.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final courseId = await ref.read(dashboardApiProvider).createAiCourse(
            lang: _lang.text.trim(),
            toLang: _toLang.text.trim(),
            level: _level,
            title: _title.text.trim(),
            options: _options,
          );
      if (!mounted) return;
      Navigator.of(context).pop(courseId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: viewport.height * 0.9,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create a course',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                "Just the basics — the AI copilot helps with everything else once you're inside.",
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LanguageField(
                              controller: _lang,
                              label: 'Learning language',
                              hint: 'Japanese',
                              onChanged: () => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LanguageField(
                              controller: _toLang,
                              label: 'Student language',
                              hint: 'Hebrew',
                              onChanged: () => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('LEVEL', style: DashText.sectionLabel(size: 10)),
                      const SizedBox(height: 6),
                      Segment(
                        options: kAiLevels,
                        selected: _level,
                        onSelect: (v) => setState(() => _level = v),
                      ),
                      const SizedBox(height: 14),
                      CourseField(
                        controller: _title,
                        label: 'Course title (optional)',
                        hint: 'e.g. Japanese for Hebrew Speakers',
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 6),
                      CourseOptionsEditor(
                        options: _options,
                        onChanged: (o) => setState(() => _options = o),
                        initiallyExpanded: true,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text('Could not create the course — $_error',
                            style: TextStyle(
                                fontSize: 12, color: DashColors.red400)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GhostButton(
                    label: 'Cancel',
                    onTap: _submitting ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    label: _submitting ? 'Creating…' : 'Create course',
                    onTap: _submitting ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
