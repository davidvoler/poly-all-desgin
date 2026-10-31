import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../util/error_text.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';
import 'ai_courses_page.dart' show kAiLevels;

/// Full-page "create a video course" form — the video-course counterpart of
/// create_ai_course_page.dart. Collects lang / to_lang / level / title +
/// the generation options, POSTs to
/// /api/v1/generate_poc_new/create_video_course, then drops the editor
/// straight into the new course's video workspace. Videos themselves are
/// added afterward from the workspace — a course can hold more than one.
class CreateVideoCoursePage extends ConsumerStatefulWidget {
  const CreateVideoCoursePage({super.key});

  @override
  ConsumerState<CreateVideoCoursePage> createState() =>
      _CreateVideoCoursePageState();
}

class _CreateVideoCoursePageState extends ConsumerState<CreateVideoCoursePage> {
  final _title = TextEditingController();
  final _lang = TextEditingController(text: 'Japanese');
  final _toLang = TextEditingController(text: 'Hebrew');
  String _level = 'A1';

  // Generation options — persisted onto course_simple.course.metadata by
  // POST /api/v1/generate_poc_new/create_video_course. Seeded with the same
  // defaults as the server-side VideoCourseOption.
  VideoCourseOptions _options = const VideoCourseOptions();

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
      final courseId = await ref.read(dashboardApiProvider).createVideoCourse(
            lang: _lang.text.trim(),
            toLang: _toLang.text.trim(),
            level: _level,
            title: _title.text.trim(),
            options: _options,
          );
      if (!mounted) return;
      ref.invalidate(editorCoursesProvider);
      if (courseId != null) {
        Navigator.pushReplacementNamed(context, '/video-course/$courseId');
      } else {
        _leave();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = apiErrorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'New video course',
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
                const Text('Create a video course', style: DashText.h2),
                const SizedBox(height: 4),
                Text(
                  "Just the basics — you'll add one or more videos once you're "
                  "inside the course.",
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
                  hint: 'e.g. Japanese from a Travel Vlog',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 6),
                VideoCourseOptionsEditor(
                  options: _options,
                  onChanged: (o) => setState(() => _options = o),
                  initiallyExpanded: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  SelectableText('Could not create the course — $_error',
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
