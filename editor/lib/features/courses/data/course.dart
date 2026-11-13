import 'package:flutter/material.dart';

class Course {
  const Course({
    this.id,
    required this.title,
    required this.learningLanguage,
    required this.studentLanguage,
    required this.level,
    this.lessons = 0,
    this.color = const Color(0xFFE7A37A),
    this.monogram = 'CO',
    this.description = '',
    this.status = 'draft',
    this.lang = '',
    this.toLang = '',
    this.guidance = '',
    this.options = const {},
  });

  /// Builds a course from the server's `course.course` row. Languages are
  /// named from [languageNames] (by ISO code) when given.
  factory Course.fromJson(
    Map<String, dynamic> json, {
    Map<String, String> languageNames = const {},
  }) {
    final lang = (json['lang'] as String? ?? '').toLowerCase();
    final toLang = (json['to_lang'] as String? ?? '').toLowerCase();
    final options = json['course_options'] is Map
        ? Map<String, Object?>.from(json['course_options'] as Map)
        : const <String, Object?>{};
    return Course(
      id: json['course_id'] as int?,
      title: json['title'] as String? ?? '',
      learningLanguage: languageNames[lang] ?? languageName(lang),
      studentLanguage: languageNames[toLang] ?? languageName(toLang),
      level: (json['level'] as String? ?? '').toUpperCase(),
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      color: _languageColors[lang] ?? const Color(0xFFD9C9A8),
      monogram: lang.toUpperCase(),
      lang: lang,
      toLang: toLang,
      guidance: options['extra_system_prompt'] as String? ?? '',
      options: options,
    );
  }

  /// The server's `Course` shape.
  Map<String, Object?> toJson() => {
    'course_id': id,
    'lang': lang,
    'to_lang': toLang,
    'level': level.toLowerCase(),
    'title': title,
    'description': description,
    'status': status,
    // Keeps the other saved options; the guidance is added to the course's AI prompts.
    'course_options': {
      ...options,
      'extra_system_prompt': guidance.isEmpty ? null : guidance,
    },
  };

  final int? id;
  final String title;
  final String learningLanguage;
  final String studentLanguage;
  final String level;
  final int lessons;
  final Color color;
  final String monogram;
  final String description;
  final String status;

  /// ISO codes of the learning and student languages.
  final String lang;
  final String toLang;

  /// The author's guidance for the AI, such as "Literary course: prepare the
  /// student for reading books". Saved as course_options.extra_system_prompt.
  final String guidance;

  /// The course's saved course_options, kept when the course is saved.
  final Map<String, Object?> options;
}

const _languageNames = {
  'en': 'English',
  'es': 'Spanish',
  'de': 'German',
  'fr': 'French',
  'it': 'Italian',
  'ja': 'Japanese',
};

const _languageColors = {
  'es': Color(0xFFE7A37A),
  'de': Color(0xFF9BC3B2),
  'fr': Color(0xFFA7B9DB),
  'it': Color(0xFFC9B6DE),
  'ja': Color(0xFFE0A0AA),
};

/// Display name for an ISO language code, falling back to the code itself.
String languageName(String code) => _languageNames[code] ?? code.toUpperCase();

const sampleCourses = [
  Course(
    title: 'Everyday Spanish',
    learningLanguage: 'Spanish',
    studentLanguage: 'English',
    level: 'A1',
    lessons: 18,
    color: Color(0xFFE7A37A),
    monogram: 'ES',
  ),
  Course(
    title: 'German for Curious Minds',
    learningLanguage: 'German',
    studentLanguage: 'English',
    level: 'A2',
    lessons: 12,
    color: Color(0xFF9BC3B2),
    monogram: 'DE',
  ),
  Course(
    title: 'French in Context',
    learningLanguage: 'French',
    studentLanguage: 'English',
    level: 'B1',
    lessons: 24,
    color: Color(0xFFA7B9DB),
    monogram: 'FR',
  ),
  Course(
    title: 'Japanese Foundations',
    learningLanguage: 'Japanese',
    studentLanguage: 'English',
    level: 'A1',
    lessons: 9,
    color: Color(0xFFE0A0AA),
    monogram: '日',
  ),
];
