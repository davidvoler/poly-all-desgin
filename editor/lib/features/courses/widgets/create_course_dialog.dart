import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/course.dart';
import '../data/language.dart';

class CreateCourseDialog extends ConsumerStatefulWidget {
  const CreateCourseDialog({super.key});

  @override
  ConsumerState<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends ConsumerState<CreateCourseDialog> {
  final titleController = TextEditingController();

  /// ISO codes of the picked languages.
  String learningLanguage = 'es';
  String studentLanguage = 'en';
  String level = 'A1';

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  /// The server's languages, or the built-in ones until they load or when
  /// they cannot be loaded.
  List<Language> get languages =>
      ref.watch(languagesProvider).value ?? builtInLanguages;

  String _name(String code) => languages
      .firstWhere(
        (language) => language.code == code,
        orElse: () => Language(code: code, name: languageName(code)),
      )
      .name;

  void submit() {
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      Course(
        title: title,
        learningLanguage: _name(learningLanguage),
        studentLanguage: _name(studentLanguage),
        level: level,
        monogram: learningLanguage.toUpperCase(),
        lang: learningLanguage,
        toLang: studentLanguage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFCF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a course',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17252D),
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Set the foundation before you start authoring.',
                          style: TextStyle(
                            color: Color(0xFF748087),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Course title',
                  hintText: 'For example, Everyday Spanish',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LanguageDropdown(
                      label: 'Learning language',
                      value: learningLanguage,
                      languages: languages,
                      onChanged: (value) =>
                          setState(() => learningLanguage = value!),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: LanguageDropdown(
                      label: 'Student language',
                      value: studentLanguage,
                      languages: languages,
                      onChanged: (value) =>
                          setState(() => studentLanguage = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CourseDropdown(
                label: 'Level',
                value: level,
                values: const ['A1', 'A2', 'B1', 'B2', 'C1'],
                onChanged: (value) => setState(() => level = value!),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: submit,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Continue'),
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

class CourseDropdown extends StatelessWidget {
  const CourseDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: values
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
  );
}

/// Picks a language by its ISO code.
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({
    required this.label,
    required this.value,
    required this.languages,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final List<Language> languages;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    // Rebuilt when the server's list replaces the built-in one.
    key: ValueKey(languages.length),
    initialValue: languages.any((language) => language.code == value)
        ? value
        : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final language in languages)
        DropdownMenuItem(
          value: language.code,
          child: Text(language.label, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );
}
