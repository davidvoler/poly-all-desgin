import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'course.dart';

class Language {
  const Language({required this.code, required this.name, String? nativeName})
    : nativeName = nativeName ?? name;

  /// Builds a language from the server's `Language` shape.
  factory Language.fromJson(Map<String, dynamic> json) => Language(
    code: json['code'] as String,
    name: json['name'] as String,
    nativeName: json['native_name'] as String?,
  );

  /// ISO 639-1 code.
  final String code;

  /// Name in the UI language.
  final String name;
  final String nativeName;

  /// The name, with the native name when it differs.
  String get label => nativeName == name ? name : '$name ($nativeName)';
}

/// The languages the app knows without the server.
final builtInLanguages = [
  for (final code in const ['en', 'es', 'de', 'fr', 'it', 'ja'])
    Language(code: code, name: languageName(code)),
];

class LanguagesRepository {
  const LanguagesRepository(this._dio);

  final Dio _dio;

  /// The UI is in English, so languages are named in English.
  static const uiLanguage = 'en';

  /// The most common languages, the most spoken first.
  Future<List<Language>> fetchLanguages() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/language/top-languages',
      queryParameters: {'ui_language': uiLanguage},
    );
    return [
      for (final row in response.data ?? const [])
        Language.fromJson(row as Map<String, dynamic>),
    ];
  }
}

final languagesRepositoryProvider = Provider<LanguagesRepository>(
  (ref) => LanguagesRepository(ref.watch(dioProvider)),
);

final languagesProvider = FutureProvider<List<Language>>(
  (ref) => ref.watch(languagesRepositoryProvider).fetchLanguages(),
);
