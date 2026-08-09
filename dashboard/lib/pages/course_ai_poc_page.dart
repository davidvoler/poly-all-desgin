import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../data/mock.dart';
import '../theme.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

/// "Course AI POC" — a stripped-down proof-of-concept for the "Create with
/// AI" idea (see plan/doc/CREATE_COURSE_WITH_AI.md). Just the bare minimum:
/// course name, learning language, student language, and a prompt input.
/// No structure/exercise-mix/enrichment options, no generated-prompt preview
/// — those live on the full CreateCoursePage once the POC proves out.
class CourseAiPocPage extends ConsumerStatefulWidget {
  const CourseAiPocPage({super.key});

  @override
  ConsumerState<CourseAiPocPage> createState() => _CourseAiPocPageState();
}

class _CourseAiPocPageState extends ConsumerState<CourseAiPocPage> {
  final _title = TextEditingController();
  final _language = TextEditingController(text: 'Japanese');
  final _studentLanguage = TextEditingController(text: 'Hebrew');
  final _prompt = TextEditingController();

  // The created course — set once by /generate_course and kept for the
  // rest of the session. Its course_id/lang/to_lang back every later
  // lesson/words call instead of the (now-locked) form fields, and its
  // title/options never change after creation.
  bool _submitting = false;
  String? _submitError;
  PromptResponse? _course;

  // Latest result shown below the course card — from a follow-up prompt
  // or one of the quick-option buttons. [_optionLoading] is the
  // prompt_type of whichever option button is in flight, so only that
  // button spinners (the main prompt box uses [_submitting] instead).
  PromptType? _optionLoading;
  String? _lastError;
  PromptResponse? _lastResult;

  @override
  void dispose() {
    _title.dispose();
    _language.dispose();
    _studentLanguage.dispose();
    _prompt.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// Before a course exists, submits the Basics form to /generate_course.
  /// Once [_course] is set, every later submit reuses its course_id/lang/
  /// to_lang and calls /generate_lesson instead — the prompt box never
  /// re-creates the course.
  Future<void> _submit() async {
    if (_submitting) return;
    final course = _course;
    setState(() {
      _submitting = true;
      _submitError = null;
      _lastError = null;
    });
    try {
      final api = ref.read(dashboardApiProvider);
      if (course == null) {
        final result = await api.generateCourse(
          lang: _language.text.trim(),
          toLang: _studentLanguage.text.trim(),
          title: _title.text.trim(),
          prompt: _prompt.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _course = result;
          _title.text = result.title; // reflect the server-confirmed title
          _prompt.clear();
        });
      } else {
        final result = await api.generateLesson(
          courseId: course.courseId!,
          lang: course.lang,
          toLang: course.toLang,
          prompt: _prompt.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _lastResult = result;
          _prompt.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = '$e';
      });
    }
  }

  Future<void> _runOption(PromptResponseOption option) async {
    final course = _course;
    if (_optionLoading != null || course?.courseId == null) return;
    final courseId = course!.courseId!;
    setState(() {
      _optionLoading = option.promptType;
      _lastError = null;
      _lastResult = null;
    });
    try {
      final api = ref.read(dashboardApiProvider);
      final result = option.promptType == PromptType.getWords
          ? await api.generateWordsList(courseId: courseId)
          : await api.generateLesson(
              courseId: courseId,
              lang: course.lang,
              toLang: course.toLang,
            );
      if (!mounted) return;
      setState(() {
        _optionLoading = null;
        _lastResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optionLoading = null;
        _lastError = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final username =
        me?.name.isNotEmpty == true ? me!.name : MockData.me.name;
    final course = _course;
    return DashboardShell(
      title: course != null && course.title.isNotEmpty
          ? course.title
          : 'Course AI POC',
      activeRoute: '/course-ai-poc',
      showTopbarDefaults: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (course == null) ...[
                  const GroupLabel('Basics'),
                  const SizedBox(height: 12),
                  CourseField(
                    controller: _title,
                    label: 'Course title',
                    hint: 'e.g. Japanese for Hebrew Speakers',
                    onChanged: _rebuild,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LanguageField(
                          controller: _language,
                          label: 'Learning language',
                          hint: 'Japanese or ja',
                          onChanged: _rebuild,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LanguageField(
                          controller: _studentLanguage,
                          label: 'Student language',
                          hint: 'Hebrew or he',
                          onChanged: _rebuild,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // The course is locked in once created — title/lang/
                  // to_lang stay exactly as the server confirmed them and
                  // back every later call instead of editable fields.
                  const GroupLabel('Course'),
                  const SizedBox(height: 8),
                  Text(course.title, style: DashText.h2),
                  const SizedBox(height: 4),
                  Text(
                    '${course.lang ?? '—'} → ${course.toLang ?? '—'}',
                    style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
                  ),
                  const SizedBox(height: 16),
                ],
                _PromptField(
                  controller: _prompt,
                  greeting: course == null
                      ? "Hi $username, let's start creating a course"
                      : "What's next for '${course.title}'?",
                  onChanged: _rebuild,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    course == null
                        ? 'Could not create the course — $_submitError'
                        : 'Could not create the lesson — $_submitError',
                    style: const TextStyle(fontSize: 12, color: DashColors.red400),
                  ),
                ],
                const SizedBox(height: 14),
                PrimaryButton(
                  label: _submitting
                      ? (course == null ? 'Creating…' : 'Sending…')
                      : (course == null ? 'Create course' : 'Create lesson'),
                  leading: Icons.auto_awesome_outlined,
                  onTap: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
          if (course != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.prompt, style: DashText.h2),
                  if (course.options.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: course.options
                          .map((o) => GhostButton(
                                label: _optionLoading == o.promptType
                                    ? '${o.title}…'
                                    : o.title,
                                leading: o.promptType == PromptType.getWords
                                    ? Icons.list_alt_outlined
                                    : Icons.menu_book_outlined,
                                onTap: _optionLoading == null
                                    ? () => _runOption(o)
                                    : null,
                              ))
                          .toList(),
                    ),
                  ],
                  if (_lastError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'That failed — $_lastError',
                      style: const TextStyle(fontSize: 12, color: DashColors.red400),
                    ),
                  ],
                  if (_lastResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DashColors.w(0.04),
                        borderRadius: DashRadii.input,
                        border: Border.all(color: DashColors.w(0.14)),
                      ),
                      child: Text(
                        _lastResult!.response.isNotEmpty
                            ? _lastResult!.response
                            : _lastResult!.prompt,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The prompt input — a friendly greeting in place of the plain "Prompt"
/// label, above an otherwise ordinary [CourseField]-styled text box.
class _PromptField extends StatelessWidget {
  final TextEditingController controller;
  final String greeting;
  final VoidCallback onChanged;
  const _PromptField({
    required this.controller,
    required this.greeting,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting, style: DashText.h2),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Describe the course you want the AI to create…',
            hintStyle: TextStyle(fontSize: 13, color: DashColors.w(0.35)),
            filled: true,
            fillColor: DashColors.w(0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide: BorderSide(color: DashColors.w(0.14)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide: BorderSide(color: DashColors.w(0.14)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide:
                  BorderSide(color: DashColors.brand.withValues(alpha: 0.55)),
            ),
          ),
        ),
      ],
    );
  }
}
