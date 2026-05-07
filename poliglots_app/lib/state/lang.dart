import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/translations.g.dart';

/// UI-language catalog for the speak/learn pickers. Native names stay in
/// their own script regardless of the UI locale (a Greek learner still
/// sees "Italiano", not "Italian"); the English label is shown as
/// secondary subtitle text in the language menu.
enum Lang {
  english(code: 'en', flag: '🇺🇸', native: 'English', englishName: 'English'),
  japanese(code: 'ja', flag: '🇯🇵', native: '日本語', englishName: 'Japanese'),
  hebrew(code: 'he', flag: '🇮🇱', native: 'עברית', englishName: 'Hebrew', rtl: true),
  arabic(code: 'ar', flag: '🇸🇦', native: 'العربية', englishName: 'Arabic', rtl: true),
  italian(code: 'it', flag: '🇮🇹', native: 'Italiano', englishName: 'Italian'),
  greek(code: 'el', flag: '🇬🇷', native: 'Ελληνικά', englishName: 'Greek');

  final String code;
  final String flag;
  final String native;
  final String englishName;
  final bool rtl;

  const Lang({
    required this.code,
    required this.flag,
    required this.native,
    required this.englishName,
    this.rtl = false,
  });
}

/// The user's source ("I speak") language. Changing this also flips the
/// app's UI locale to the matching `AppLocale` if a translation bundle
/// exists for it; otherwise the UI falls back to English.
class SpeakLangNotifier extends Notifier<Lang> {
  @override
  Lang build() => Lang.english;

  void set(Lang lang) {
    state = lang;
    final uiLocale = AppLocale.values.firstWhere(
      (l) => l.languageCode == lang.code,
      orElse: () => AppLocale.en,
    );
    if (uiLocale != LocaleSettings.currentLocale) {
      LocaleSettings.setLocaleSync(uiLocale);
    }
  }
}

final speakLangProvider =
    NotifierProvider<SpeakLangNotifier, Lang>(SpeakLangNotifier.new);

/// The user's target ("Learning") language. No locale side-effects — this
/// is purely the *content* the user is studying.
class LearningLangNotifier extends Notifier<Lang> {
  @override
  Lang build() => Lang.japanese;

  void set(Lang lang) => state = lang;
}

final learningLangProvider =
    NotifierProvider<LearningLangNotifier, Lang>(LearningLangNotifier.new);
