import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/course.dart';
import '../data/language.dart';

/// Asks for a new course's details, or edits [course]'s when given.
/// Pops the course to save, or null when cancelled.
class CreateCourseDialog extends ConsumerStatefulWidget {
  const CreateCourseDialog({this.course, super.key});

  /// The course to edit; null creates a new one.
  final Course? course;

  @override
  ConsumerState<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends ConsumerState<CreateCourseDialog> {
  late final course = widget.course;
  late final titleController = TextEditingController(text: course?.title);
  late final descriptionController = TextEditingController(
    text: course?.description,
  );
  late final guidanceController = TextEditingController(
    text: course?.guidance,
  );

  static const levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  /// ISO codes of the picked languages.
  late String learningLanguage = _orDefault(course?.lang, 'es');
  late String studentLanguage = _orDefault(course?.toLang, 'en');
  late String level = levels.contains(course?.level) ? course!.level : 'A1';
  late bool diacritics = course?.diacritics ?? false;

  static String _orDefault(String? value, String fallback) =>
      value == null || value.isEmpty ? fallback : value;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    guidanceController.dispose();
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
        id: course?.id,
        status: course?.status ?? 'draft',
        description: descriptionController.text.trim(),
        title: title,
        learningLanguage: _name(learningLanguage),
        studentLanguage: _name(studentLanguage),
        level: level,
        monogram: learningLanguage.toUpperCase(),
        lang: learningLanguage,
        toLang: studentLanguage,
        guidance: guidanceController.text.trim(),
        diacritics: diacritics,
        options: course?.options ?? const {},
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course == null ? 'Create a course' : 'Edit course',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17252D),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          course == null
                              ? 'Set the foundation before you start authoring.'
                              : 'Change the course details.',
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
              TextField(
                controller: descriptionController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_rounded),
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
                values: levels,
                onChanged: (value) => setState(() => level = value!),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: diacritics,
                onChanged: (value) => setState(() => diacritics = value),
                title: const Text('Diacritics (vowel marks)'),
                subtitle: const Text(
                  'Also keep each sentence with diacritics, such as Arabic '
                  'harakat or Hebrew niqqud. The plain sentence is always kept.',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: guidanceController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Course guidance for the AI',
                  hintText:
                      'For example: Literary course, prepare the student for '
                      'reading books. Or: Everyday spoken sentences.',
                  helperText: 'Added to every AI request for this course.',
                  helperMaxLines: 2,
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                ),
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
                    icon: Icon(
                      course == null
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(course == null ? 'Continue' : 'Save'),
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
