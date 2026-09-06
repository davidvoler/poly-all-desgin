import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';
import 'ai_courses_page.dart' show kAiLevels;

/// Full-page "create a course" form for the Create-with-AI copilot (was a
/// dialog on the Courses page). Collects lang / to_lang / level / title +
/// the generation options, POSTs to
/// /api/v1/generate_poc_new/create_course, then drops the editor straight
/// into the new course's workspace. Languages are sent to the server as
/// ISO codes ("ar"), not display names.
class CreateAiCoursePage extends ConsumerStatefulWidget {
  const CreateAiCoursePage({super.key});

  @override
  ConsumerState<CreateAiCoursePage> createState() => _CreateAiCoursePageState();
}

class _CreateAiCoursePageState extends ConsumerState<CreateAiCoursePage> {
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

  void _leave() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/ai-courses');
    }
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
      ref.invalidate(editorCoursesProvider);
      if (courseId != null) {
        Navigator.pushReplacementNamed(context, '/ai-course/$courseId');
      } else {
        _leave();
      }
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
    return DashboardShell(
      title: 'New course',
      activeRoute: '/ai-courses',
      topbarTrailing: [
        GhostButton(
          label: 'Back to courses',
          leading: Icons.arrow_back,
          onTap: _submitting ? null : _leave,
        ),
      ],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Create a course', style: DashText.h2),
                const SizedBox(height: 4),
                Text(
                  "Just the basics — the AI copilot helps with everything else "
                  "once you're inside.",
                  style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
                ),
                const SizedBox(height: 20),
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
                  const SizedBox(height: 12),
                  Text('Could not create the course — $_error',
                      style: TextStyle(fontSize: 12, color: DashColors.red400)),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GhostButton(
                      label: 'Cancel',
                      onTap: _submitting ? null : _leave,
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
      ),
    );
  }
}
