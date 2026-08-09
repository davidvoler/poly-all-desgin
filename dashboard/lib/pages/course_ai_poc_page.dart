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

  // /generate_course call state — [_course] holds the created course's
  // prompt/options once it comes back.
  bool _submitting = false;
  String? _submitError;
  PromptResponse? _course;

  // Follow-up option call state — [_optionLoading] is the prompt_type of
  // whichever option button is in flight, so only that button spinners.
  PromptType? _optionLoading;
  String? _optionError;
  PromptResponse? _optionResult;

  @override
  void dispose() {
    _title.dispose();
    _language.dispose();
    _studentLanguage.dispose();
    _prompt.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
      _course = null;
      _optionResult = null;
      _optionError = null;
    });
    try {
      final result = await ref.read(dashboardApiProvider).generateCourse(
            lang: _language.text.trim(),
            toLang: _studentLanguage.text.trim(),
            title: _title.text.trim(),
            prompt: _prompt.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _course = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = '$e';
      });
    }
  }

  Future<void> _runOption(PromptResponseOption option) async {
    final courseId = _course?.courseId;
    if (_optionLoading != null || courseId == null) return;
    setState(() {
      _optionLoading = option.promptType;
      _optionError = null;
      _optionResult = null;
    });
    try {
      final api = ref.read(dashboardApiProvider);
      final result = option.promptType == PromptType.getWords
          ? await api.generateWordsList(courseId: courseId)
          : await api.generateLesson(
              courseId: courseId,
              lang: _course?.lang,
              toLang: _course?.toLang,
            );
      if (!mounted) return;
      setState(() {
        _optionLoading = null;
        _optionResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optionLoading = null;
        _optionError = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final username =
        me?.name.isNotEmpty == true ? me!.name : MockData.me.name;
    return DashboardShell(
      title: 'Course AI POC',
      activeRoute: '/course-ai-poc',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                _PromptField(
                  controller: _prompt,
                  greeting: "Hi $username, let's start creating a course",
                  onChanged: _rebuild,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Could not create the course — $_submitError',
                    style: const TextStyle(fontSize: 12, color: DashColors.red400),
                  ),
                ],
                const SizedBox(height: 14),
                PrimaryButton(
                  label: _submitting ? 'Creating…' : 'Create course',
                  leading: Icons.auto_awesome_outlined,
                  onTap: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
          if (_course != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_course!.prompt, style: DashText.h2),
                  if (_course!.options.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _course!.options
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
                  if (_optionError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'That failed — $_optionError',
                      style: const TextStyle(fontSize: 12, color: DashColors.red400),
                    ),
                  ],
                  if (_optionResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DashColors.w(0.04),
                        borderRadius: DashRadii.input,
                        border: Border.all(color: DashColors.w(0.14)),
                      ),
                      child: Text(
                        _optionResult!.response.isNotEmpty
                            ? _optionResult!.response
                            : _optionResult!.prompt,
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
