import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Device-level reading-comfort preferences for the quiz page. These are
/// local-only (no server round-trip) — they tune how the current device
/// renders the quiz, not the user's profile.
class QuizSettings {
  final QuizTextSize sentenceSize;
  final QuizTextSize optionSize;
  final bool autoPlayAudio;
  const QuizSettings({
    this.sentenceSize = QuizTextSize.medium,
    this.optionSize = QuizTextSize.medium,
    this.autoPlayAudio = false,
  });

  QuizSettings copyWith({
    QuizTextSize? sentenceSize,
    QuizTextSize? optionSize,
    bool? autoPlayAudio,
  }) =>
      QuizSettings(
        sentenceSize: sentenceSize ?? this.sentenceSize,
        optionSize: optionSize ?? this.optionSize,
        autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
      );
}

class QuizSettingsNotifier extends Notifier<QuizSettings> {
  static const _kSentence = 'quiz.sentenceSize';
  static const _kOption = 'quiz.optionSize';
  static const _kAutoPlay = 'quiz.autoPlayAudio';

  @override
  QuizSettings build() {
    // Kick off the async load; until it resolves the UI shows defaults.
    _load();
    return const QuizSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    QuizTextSize size(String key) {
      final i = prefs.getInt(key);
      return (i != null && i >= 0 && i < QuizTextSize.values.length)
          ? QuizTextSize.values[i]
          : QuizTextSize.medium;
    }

    state = QuizSettings(
      sentenceSize: size(_kSentence),
      optionSize: size(_kOption),
      autoPlayAudio: prefs.getBool(_kAutoPlay) ?? false,
    );
  }

  Future<void> setSentenceSize(QuizTextSize v) async {
    state = state.copyWith(sentenceSize: v);
    (await SharedPreferences.getInstance()).setInt(_kSentence, v.index);
  }

  Future<void> setOptionSize(QuizTextSize v) async {
    state = state.copyWith(optionSize: v);
    (await SharedPreferences.getInstance()).setInt(_kOption, v.index);
  }

  Future<void> setAutoPlayAudio(bool v) async {
    state = state.copyWith(autoPlayAudio: v);
    (await SharedPreferences.getInstance()).setBool(_kAutoPlay, v);
  }
}

final quizSettingsProvider =
    NotifierProvider<QuizSettingsNotifier, QuizSettings>(
        QuizSettingsNotifier.new);
