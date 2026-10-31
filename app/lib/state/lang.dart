import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
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

  /// Look up a [Lang] from its ISO-style code (e.g. "en", "ja"). Falls
  /// back to [Lang.english] for unknown codes — server contracts may
  /// drift, and we'd rather render *something* than crash.
  static Lang byCode(String code) =>
      values.firstWhere((l) => l.code == code, orElse: () => english);
}

/// The chrome language — what the app's UI is rendered in. Independent
/// of [speakLangProvider] so a user can speak English natively but read
/// the app in Italian, or vice versa.
///
/// Setting this is the *one* place that flips slang's locale; if no
/// translation bundle exists for the chosen language the UI falls back
/// to English (slang's `fallback_strategy: base_locale`).
class UiLangNotifier extends Notifier<Lang> {
  @override
  Lang build() {
    // Mirror whatever slang resolved on startup (useDeviceLocale or fallback)
    final code = LocaleSettings.currentLocale.languageCode;
    return Lang.values.firstWhere(
      (l) => l.code == code,
      orElse: () => Lang.english,
    );
  }

  void set(Lang lang) {
    _apply(lang);
    ref.read(preferenceProvider.notifier).save(uiLang: lang.code);
  }

  /// Seed from server preferences without echoing back a POST.
  void setSilently(Lang lang) => _apply(lang);

  void _apply(Lang lang) {
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

final uiLangProvider =
    NotifierProvider<UiLangNotifier, Lang>(UiLangNotifier.new);

/// The user's source ("I speak") language — a profile fact, used to scope
/// course catalogs and to label the medallion's flag-pair on home. Has
/// no side effect on the UI locale.
class SpeakLangNotifier extends Notifier<Lang> {
  @override
  Lang build() => Lang.english;

  void set(Lang lang) {
    state = lang;
    // "I speak" is the student's native language → server's `to_lang`.
    ref.read(preferenceProvider.notifier).save(toLang: lang.code);
  }

  /// Seed from server preferences without echoing back a POST.
  void setSilently(Lang lang) => state = lang;
}

final speakLangProvider =
    NotifierProvider<SpeakLangNotifier, Lang>(SpeakLangNotifier.new);

/// The user's target ("Learning") language — the *content* they're
/// studying. Independent of UI and speak.
class LearningLangNotifier extends Notifier<Lang> {
  @override
  Lang build() => Lang.japanese;

  void set(Lang lang) {
    state = lang;
    // "Learning" is the language being studied → server's `lang`.
    ref.read(preferenceProvider.notifier).save(lang: lang.code);
  }

  /// Seed from server preferences without echoing back a POST.
  void setSilently(Lang lang) => state = lang;
}

final learningLangProvider =
    NotifierProvider<LearningLangNotifier, Lang>(LearningLangNotifier.new);
