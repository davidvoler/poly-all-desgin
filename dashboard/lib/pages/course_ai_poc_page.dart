import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
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

  @override
  void dispose() {
    _title.dispose();
    _language.dispose();
    _studentLanguage.dispose();
    _prompt.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final username =
        me?.name.isNotEmpty == true ? me!.name : MockData.me.name;
    return DashboardShell(
      title: 'Course AI POC',
      activeRoute: '/course-ai-poc',
      child: GlassCard(
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
          ],
        ),
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
