import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
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
                onTap: () => Navigator.pushNamed(context, '/ai-course-new'),
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

class _CourseCard extends ConsumerStatefulWidget {
  final EditorCourse course;
  const _CourseCard({required this.course});

  @override
  ConsumerState<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends ConsumerState<_CourseCard> {
  bool _busy = false;

  EditorCourse get course => widget.course;

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteCourseDialog(title: course.title),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(dashboardApiProvider).deleteCourse(course.courseId);
      if (!mounted) return;
      ref.invalidate(editorCoursesProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Deleted "${course.title}"'),
          duration: const Duration(milliseconds: 1600),
        ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Could not delete — $e'),
          backgroundColor: DashColors.red400,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressLabel(course);
    return SizedBox(
      width: 280,
      child: Stack(
        children: [
          InkWell(
            borderRadius: DashRadii.card,
            onTap: _busy
                ? null
                : () => Navigator.pushNamed(context, '/ai-course', arguments: course.courseId),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Opacity(
                opacity: _busy ? 0.4 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${flagFor(course.lang)}${flagFor(course.toLang)}',
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: Text(course.title,
                          style: DashText.h2, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 4),
                    Text('${languageName(course.lang)} → ${languageName(course.toLang)}',
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
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    tooltip: 'Delete course',
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline, color: DashColors.w(0.5)),
                    onPressed: _confirmDelete,
                  ),
          ),
        ],
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

class _DeleteCourseDialog extends StatelessWidget {
  final String title;
  const _DeleteCourseDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Delete course?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                '"$title" and all of its modules, lessons and exercises will be '
                'permanently removed. This can\'t be undone.',
                style: TextStyle(fontSize: 13, color: DashColors.w(0.65), height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GhostButton(label: 'Cancel', onTap: () => Navigator.pop(context, false)),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    label: 'Delete',
                    leading: Icons.delete_outline,
                    onTap: () => Navigator.pop(context, true),
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

/// Learning-language flag emoji, purely decorative — falls back to a
/// globe for anything not in the curated set. Accepts an ISO code ("ar",
/// how `Course.lang` is stored) or a display name ("Arabic").
String flagFor(String lang) {
  const flags = {
    'ja': '🇯🇵',
    'he': '🇮🇱',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'it': '🇮🇹',
    'ar': '🇸🇦',
    'de': '🇩🇪',
    'en': '🇬🇧',
    'ko': '🇰🇷',
    'pt': '🇵🇹',
  };
  return flags[languageCode(lang)] ?? '🌐';
}

const kAiLanguageSuggestions = [
  'Japanese', 'Hebrew', 'Spanish', 'French', 'Italian', 'Arabic', 'German',
  'English', 'Korean', 'Portuguese',
];
const kAiLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];
