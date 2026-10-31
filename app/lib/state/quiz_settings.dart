import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/courses_api.dart';

/// Three-step size scale shared by the quiz's sentence and option text.
/// `scale` multiplies each widget's base font size.
enum QuizTextSize {
  small(label: 'Small', scale: 0.85),
  medium(label: 'Medium', scale: 1.0),
  large(label: 'Large', scale: 1.3);

  final String label;
  final double scale;
  const QuizTextSize({required this.label, required this.scale});
}

/// Which reading a Japanese learner wants rendered above the sentence as
/// ruby text. `none` = no ruby. Each non-none mode maps to a key in the
/// exercise's `ruby_text` map (note the content's `romanji` spelling), and —
/// as a legacy fallback — to a sentence-alt slot (hiragana=alt1, romaji=alt2,
/// katakana=alt3). See [Exercise.rubyText] and the alt fields.
enum RubyMode {
  none(label: 'Off', altSlot: 0, rubyKey: ''),
  hiragana(label: 'Hiragana', altSlot: 1, rubyKey: 'hiragana'),
  romaji(label: 'Romaji', altSlot: 2, rubyKey: 'romanji'),
  katakana(label: 'Katakana', altSlot: 3, rubyKey: 'katakana');

  final String label;
  final int altSlot;
  final String rubyKey;
  const RubyMode({
    required this.label,
    required this.altSlot,
    required this.rubyKey,
  });
}

/// Quiz display preferences for the current device/user. Persisted locally
/// (SharedPreferences) and mirrored to the server `preference.quiz_settings`
/// jsonb so they follow the user across devices.
class QuizSettings {
  final QuizTextSize sentenceSize;
  final QuizTextSize optionSize;
  final bool autoPlayAudio;
  // 0 = original sentence; 1/2/3 = sentence_alt1/2/3. The control only
  // offers slots the current exercise actually has.
  final int textAlternativeSlot;
  final RubyMode rubyMode;
  final bool showAnnotations;

  const QuizSettings({
    this.sentenceSize = QuizTextSize.medium,
    this.optionSize = QuizTextSize.medium,
    this.autoPlayAudio = false,
    this.textAlternativeSlot = 0,
    this.rubyMode = RubyMode.none,
    this.showAnnotations = false,
  });

  QuizSettings copyWith({
    QuizTextSize? sentenceSize,
    QuizTextSize? optionSize,
    bool? autoPlayAudio,
    int? textAlternativeSlot,
    RubyMode? rubyMode,
    bool? showAnnotations,
  }) =>
      QuizSettings(
        sentenceSize: sentenceSize ?? this.sentenceSize,
        optionSize: optionSize ?? this.optionSize,
        autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
        textAlternativeSlot: textAlternativeSlot ?? this.textAlternativeSlot,
        rubyMode: rubyMode ?? this.rubyMode,
        showAnnotations: showAnnotations ?? this.showAnnotations,
      );

  Map<String, dynamic> toJson() => {
        'sentenceSize': sentenceSize.index,
        'optionSize': optionSize.index,
        'autoPlayAudio': autoPlayAudio,
        'textAlternativeSlot': textAlternativeSlot,
        'rubyMode': rubyMode.index,
        'showAnnotations': showAnnotations,
      };

  factory QuizSettings.fromJson(Map<String, dynamic> j) {
    T at<T>(List<T> values, Object? i, T fallback) =>
        (i is int && i >= 0 && i < values.length) ? values[i] : fallback;
    return QuizSettings(
      sentenceSize: at(QuizTextSize.values, j['sentenceSize'], QuizTextSize.medium),
      optionSize: at(QuizTextSize.values, j['optionSize'], QuizTextSize.medium),
      autoPlayAudio: j['autoPlayAudio'] == true,
      textAlternativeSlot:
          (j['textAlternativeSlot'] is int) ? j['textAlternativeSlot'] as int : 0,
      rubyMode: at(RubyMode.values, j['rubyMode'], RubyMode.none),
      showAnnotations: j['showAnnotations'] == true,
    );
  }
}

class QuizSettingsNotifier extends Notifier<QuizSettings> {
  static const _kJson = 'quiz.settings_json';

  @override
  QuizSettings build() {
    _load();
    return const QuizSettings();
  }

  Future<void> _load() async {
    // Server preference (cross-device) wins when present.
    final serverQs = ref.read(preferenceProvider).value?.quizSettings;
    if (serverQs != null) {
      state = QuizSettings.fromJson(serverQs);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kJson);
    if (raw != null) {
      try {
        state = QuizSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return;
      } catch (_) {
        // Corrupt blob — fall through to defaults.
      }
    }
    // Legacy per-field keys from the first cut of this notifier.
    final s = prefs.getInt('quiz.sentenceSize');
    final o = prefs.getInt('quiz.optionSize');
    final a = prefs.getBool('quiz.autoPlayAudio');
    if (s != null || o != null || a != null) {
      state = QuizSettings(
        sentenceSize: (s != null && s >= 0 && s < QuizTextSize.values.length)
            ? QuizTextSize.values[s]
            : QuizTextSize.medium,
        optionSize: (o != null && o >= 0 && o < QuizTextSize.values.length)
            ? QuizTextSize.values[o]
            : QuizTextSize.medium,
        autoPlayAudio: a ?? false,
      );
    }
  }

  Future<void> _persist() async {
    final json = state.toJson();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kJson, jsonEncode(json));
    // Mirror to the server preference (best-effort — local copy is the
    // authoritative fallback if the user is offline / signed out).
    try {
      await ref.read(preferenceProvider.notifier).save(quizSettings: json);
    } catch (_) {}
  }

  void _set(QuizSettings next) {
    state = next;
    _persist();
  }

  void setSentenceSize(QuizTextSize v) => _set(state.copyWith(sentenceSize: v));
  void setOptionSize(QuizTextSize v) => _set(state.copyWith(optionSize: v));
  void setAutoPlayAudio(bool v) => _set(state.copyWith(autoPlayAudio: v));
  void setTextAlternativeSlot(int v) =>
      _set(state.copyWith(textAlternativeSlot: v));
  void setRubyMode(RubyMode v) => _set(state.copyWith(rubyMode: v));
  void setShowAnnotations(bool v) => _set(state.copyWith(showAnnotations: v));
}

final quizSettingsProvider =
    NotifierProvider<QuizSettingsNotifier, QuizSettings>(
        QuizSettingsNotifier.new);
