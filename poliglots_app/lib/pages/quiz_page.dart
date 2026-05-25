import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
import '../api/models.dart';
import '../score.dart';
import '../state/lang.dart';
import '../theme.dart';
import '../widgets/auto_text.dart';
import '../widgets/common.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _exerciseIndex = 0;
  // Per-question state, keyed by exercise index, so navigating Back/Skip
  // restores a previously answered question with its feedback intact.
  // Set semantics for both modes: single-correct exercises (simple/read)
  // replace the set on tap; `recognize` toggles, since multiple options
  // are correct.
  final Map<int, Set<int>> _selectedByIndex = {};
  // Indices the user has pressed "Check answer" on (feedback revealed).
  final Set<int> _checkedIndices = {};
  // How many times the user tapped an option for each exercise — each
  // change of mind counts (click A then B → 2 attempts).
  final Map<int, int> _attemptsByIndex = {};
  // When each exercise was first shown — used to derive answer_delay_ms.
  final Map<int, DateTime> _shownAtByIndex = {};
  // Local mirror of the server's score for each checked exercise, so the
  // question card can render a small icon (good / medium / wrong) without
  // a round-trip. Same formula as the server (see lib/score.dart).
  final Map<int, double> _scoreByIndex = {};
  // Set once the user advances past the last exercise — swaps the quiz
  // body for the completion screen.
  bool _finished = false;
  // Computed once at completion (in _completeLesson) and reused on every
  // rebuild of the _QuizComplete screen.
  _LessonSummary? _summary;
  // Achievements unlocked by this lesson (server-derived). Populated
  // asynchronously after _completeLesson POSTs the lesson result; null
  // while in-flight so the UI can show a tiny loading hint.
  List<Achievement>? _newAchievements;

  final AudioPlayer _audio = AudioPlayer();

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioPath) async {
    final url = audioUrl(audioPath);
    if (url == null) return;
    await _audio.stop();
    await _audio.play(UrlSource(url));
  }

  void _restartLesson() {
    setState(() {
      _exerciseIndex = 0;
      _finished = false;
      _summary = null;
      _newAchievements = null;
      _selectedByIndex.clear();
      _checkedIndices.clear();
      _attemptsByIndex.clear();
      _shownAtByIndex.clear();
      _scoreByIndex.clear();
    });
  }

  /// Fired once, when the user reveals feedback for an exercise. POSTs
  /// the attempt and returns the locally-computed score so the caller
  /// can display it without waiting for the round-trip.
  double _submitResult(Exercise ex, Set<int> selected, int? lessonId,
      int attempts, int answerDelayMs) {
    final correctIdx = <int>{
      for (var k = 0; k < ex.options.length; k++)
        if (ex.options[k].correct) k,
    };
    final chosenCorrect =
        selected.where(correctIdx.contains).length;
    final incorrectCount =
        selected.where((i) => !correctIdx.contains(i)).length;
    final correctRatio =
        correctIdx.isEmpty ? 0.0 : chosenCorrect / correctIdx.length;
    final isCorrect =
        chosenCorrect == correctIdx.length && incorrectCount == 0;
    final pref = ref.read(preferenceProvider).value;
    ref.read(coursesRepositoryProvider).saveResults(
          Results(
            userId: kCurrentUserId,
            lang: pref?.lang ?? '',
            courseId: pref?.courseId,
            moduleId: pref?.moduleId,
            lessonId: lessonId,
            exerciseId: ex.id,
            sentenceId: ex.sentenceId,
            word1: ex.word1,
            word2: ex.word2,
            word3: ex.word3,
            answerDelayMs: '$answerDelayMs',
            attempts: attempts,
            correct: isCorrect,
            correctRatio: correctRatio,
            incorrectCount: incorrectCount,
          ),
        );
    return calculateScore(
      correctRatio: correctRatio,
      incorrectCount: incorrectCount,
      attempts: attempts,
    );
  }

  /// Aggregate the per-exercise state we accumulated during the quiz
  /// into one [_LessonSummary]. Pure read of the maps — no mutation.
  _LessonSummary _buildSummary(List<Exercise> exercises) {
    var correct = 0;
    var wrong = 0;
    for (var k = 0; k < exercises.length; k++) {
      if (!_checkedIndices.contains(k)) continue;
      final s = _scoreByIndex[k] ?? 0;
      if (s > 0) {
        correct++;
      } else {
        wrong++;
      }
    }
    final skipped = exercises.length - _checkedIndices.length;
    final totalScore =
        _scoreByIndex.values.fold<double>(0, (a, b) => a + b);
    // Unique words across all exercises, first-encountered order.
    final seenWords = <String>{};
    final words = <String>[];
    for (final ex in exercises) {
      for (final w in [ex.word1, ex.word2, ex.word3]) {
        final t = w.trim();
        if (t.isNotEmpty && seenWords.add(t)) {
          words.add(t);
        }
      }
    }
    return _LessonSummary(
      correct: correct,
      wrong: wrong,
      skipped: skipped,
      totalScore: totalScore,
      totalCount: exercises.length,
      words: words,
    );
  }

  /// Fires once when the user reaches the end of the quiz. Builds the
  /// summary, flips into the completion screen, POSTs the lesson result
  /// (only in lesson mode — practice modes have no lesson id), then
  /// asks the server whether the user just unlocked any achievements
  /// and surfaces them on the completion screen.
  Future<void> _completeLesson(List<Exercise> exercises, int? lessonId) async {
    final summary = _buildSummary(exercises);
    setState(() {
      _finished = true;
      _summary = summary;
      _newAchievements = null;
    });
    if (lessonId == null) return;
    final pref = ref.read(preferenceProvider).value;
    final repo = ref.read(coursesRepositoryProvider);
    await repo.saveLessonCompleted(
      lang: pref?.lang ?? '',
      courseId: pref?.courseId,
      moduleId: pref?.moduleId,
      lessonId: lessonId,
      score: summary.totalScore,
      correctCount: summary.correct,
      wrongCount: summary.wrong,
      skippedCount: summary.skipped,
    );
    // After the lesson is recorded, ask the server to scan for badges
    // the user has just earned. courseId is required by the endpoint —
    // skip the check (and the celebration) when we don't have one yet.
    final courseId = pref?.courseId;
    final lang = pref?.lang;
    if (courseId == null || lang == null || lang.isEmpty) return;
    try {
      final unlocked = await repo.checkNewAchievements(
        courseId: courseId,
        lang: lang,
      );
      if (!mounted) return;
      setState(() => _newAchievements = unlocked);
      if (unlocked.isNotEmpty) {
        // Refresh the cached achievement list so other surfaces see the
        // new entries the next time they read the provider.
        ref.invalidate(achievementsProvider);
      }
    } catch (_) {
      // Network or server hiccup — keep the completion screen usable
      // and just don't show the celebration card.
      if (!mounted) return;
      setState(() => _newAchievements = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Route arg is one of: an int lesson id (lesson mode), a PracticeKind
    // (practice mode launched from the home stats), or a List<String> of
    // words (practice narrowed to a hand-picked subset, launched from the
    // Words page).
    final arg = ModalRoute.of(context)?.settings.arguments;
    final practice = arg is PracticeKind ? arg : null;
    final lessonId = arg is int ? arg : null;
    final selectedWords = arg is List<String> ? arg : null;

    final AsyncValue<List<Exercise>> exercisesAsync;
    if (selectedWords != null) {
      final prefLang =
          ref.watch(preferenceProvider.select((p) => p.value?.lang));
      final learning = ref.watch(learningLangProvider);
      exercisesAsync = ref.watch(practiceByWordsProvider(
        PracticeByWordsKey(
          lang: prefLang ?? learning.code,
          words: selectedWords,
        ),
      ));
    } else if (practice != null) {
      exercisesAsync = ref.watch(practiceExercisesProvider(practice));
    } else {
      exercisesAsync = ref.watch(exercisesProvider(lessonId ?? 1));
    }

    // Nav-bar title: practice mode label, else the current lesson's
    // title resolved from the module's lessons (falls back to "Lesson").
    final String pageTitle;
    if (selectedWords != null) {
      pageTitle = 'Practicing ${selectedWords.length} selected words';
    } else if (practice != null) {
      pageTitle = practice.title;
    } else {
      final moduleId =
          ref.watch(preferenceProvider.select((p) => p.value?.moduleId));
      final lessons = moduleId == null
          ? const <Lesson>[]
          : (ref.watch(lessonsProvider(moduleId)).value ?? const <Lesson>[]);
      final li = lessons.indexWhere((l) => l.id == lessonId);
      pageTitle = (li != -1 && lessons[li].title.isNotEmpty)
          ? lessons[li].title
          : 'Lesson';
    }

    return Scaffold(
      body: PhoneBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: exercisesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (err, _) => Center(
                child: Text(
                  "Couldn't load exercises\n$err",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Text(
                      practice != null
                          ? 'Nothing to practice right now'
                          : 'No exercises in this lesson',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }
                if (_finished) {
                  return _QuizComplete(
                    lessonId: lessonId,
                    practice: practice,
                    onRepeat: _restartLesson,
                    summary: _summary!,
                    newAchievements: _newAchievements,
                  );
                }
                final idx = _exerciseIndex.clamp(0, exercises.length - 1);
                final ex = exercises[idx];
                final multi = ex.exerciseType == 'recognize';
                final selected = _selectedByIndex[idx] ?? const <int>{};
                final checked = _checkedIndices.contains(idx);
                // Start the answer timer the first time this exercise
                // is shown (and not yet answered).
                if (!checked) {
                  _shownAtByIndex.putIfAbsent(idx, DateTime.now);
                }
                return _QuizBody(
                  index: idx,
                  total: exercises.length,
                  score: _scoreByIndex[idx],
                  exercise: ex,
                  title: pageTitle,
                  selected: selected,
                  checked: checked,
                  onSelect: checked
                      ? null
                      : (i) => setState(() {
                            final cur = {...selected};
                            if (multi) {
                              if (cur.contains(i)) {
                                cur.remove(i);
                              } else {
                                cur.add(i);
                              }
                            } else {
                              cur
                                ..clear()
                                ..add(i);
                            }
                            _selectedByIndex[idx] = cur;
                            _attemptsByIndex[idx] =
                                (_attemptsByIndex[idx] ?? 0) + 1;
                          }),
                  onPrimary: () {
                    if (!checked) {
                      final shownAt = _shownAtByIndex[idx];
                      final delayMs = shownAt == null
                          ? 0
                          : DateTime.now().difference(shownAt).inMilliseconds;
                      final score = _submitResult(ex, selected, lessonId,
                          _attemptsByIndex[idx] ?? 0, delayMs);
                      setState(() {
                        _checkedIndices.add(idx);
                        _scoreByIndex[idx] = score;
                      });
                    } else if (idx + 1 < exercises.length) {
                      setState(() => _exerciseIndex = idx + 1);
                    } else {
                      _completeLesson(exercises, lessonId);
                    }
                  },
                  onSkip: () {
                    if (idx + 1 < exercises.length) {
                      setState(() => _exerciseIndex = idx + 1);
                    } else {
                      _completeLesson(exercises, lessonId);
                    }
                  },
                  onBack: idx > 0
                      ? () => setState(() => _exerciseIndex = idx - 1)
                      : null,
                  onPlayAudio: ex.audio.isEmpty
                      ? null
                      : () => _playAudio(ex.audio),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Per-quiz summary computed at finish time and shown on the
/// _QuizComplete screen.
class _LessonSummary {
  final int correct;
  final int wrong;
  final int skipped;
  final double totalScore;
  final int totalCount;
  final List<String> words;
  const _LessonSummary({
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.totalScore,
    required this.totalCount,
    required this.words,
  });
}

/// Shown after the last exercise. "Next Lesson" jumps to the following
/// lesson in the current module (resolved via [preferenceProvider]'s
/// `moduleId` + [lessonsProvider]); falls back to popping back to the
/// course page when this is the module's last lesson.
class _QuizComplete extends ConsumerWidget {
  final int? lessonId;
  final PracticeKind? practice;
  final VoidCallback onRepeat;
  final _LessonSummary summary;
  // Null while the server check is still in flight (only meaningful in
  // lesson mode). Empty list means "checked, nothing new". Non-empty
  // means a celebration card is shown above the score breakdown.
  final List<Achievement>? newAchievements;
  const _QuizComplete({
    required this.lessonId,
    required this.practice,
    required this.onRepeat,
    required this.summary,
    required this.newAchievements,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Practice mode: no lesson chain — just finish or drill again.
    if (practice != null) {
      return _CompleteScaffold(
        heading: '${practice!.title} — done!',
        subtitle: 'Nice work — keep the streak going.',
        primaryLabel: 'Back home',
        onPrimary: () => Navigator.maybePop(context),
        repeatLabel: 'Practice again',
        onRepeat: onRepeat,
        summary: summary,
        newAchievements: null,
      );
    }

    final moduleId =
        ref.watch(preferenceProvider.select((p) => p.value?.moduleId));
    final lessons = moduleId == null
        ? const <Lesson>[]
        : (ref.watch(lessonsProvider(moduleId)).value ?? const <Lesson>[]);

    final i = lessons.indexWhere((l) => l.id == lessonId);
    final Lesson? current = i != -1 ? lessons[i] : null;
    final Lesson? next =
        (i != -1 && i + 1 < lessons.length) ? lessons[i + 1] : null;

    String name(Lesson? l) =>
        (l != null && l.title.isNotEmpty) ? l.title : 'this lesson';

    return _CompleteScaffold(
      heading: 'Lesson ${name(current)} completed',
      subtitle: next != null
          ? 'Nice work — ready for the next one?'
          : "You've finished the last lesson in this module.",
      primaryLabel:
          next != null ? 'Continue to ${name(next)}' : 'Back to course',
      onPrimary: () {
        if (next != null) {
          ref.read(preferenceProvider.notifier).save(lessonId: next.id);
          Navigator.pushReplacementNamed(context, '/quiz',
              arguments: next.id);
        } else {
          Navigator.maybePop(context);
        }
      },
      repeatLabel: 'Repeat lesson',
      onRepeat: onRepeat,
      summary: summary,
      newAchievements: newAchievements,
    );
  }
}

/// Shared completion layout for both lesson- and practice-finished
/// states. Middle scrolls; close button on top and CTA pair at the
/// bottom stay pinned.
class _CompleteScaffold extends StatelessWidget {
  final String heading;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String repeatLabel;
  final VoidCallback onRepeat;
  final _LessonSummary summary;
  // Forwarded from _QuizComplete. Null = check still in flight (or not
  // applicable in practice mode). Empty = nothing new to celebrate.
  final List<Achievement>? newAchievements;
  const _CompleteScaffold({
    required this.heading,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.repeatLabel,
    required this.onRepeat,
    required this.summary,
    required this.newAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            RoundIconButton(
              icon: Icons.close,
              tooltip: 'Close',
              onTap: () => Navigator.maybePop(context),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(
                  child: Icon(Icons.celebration,
                      size: 64, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // New achievements unlocked by finishing this lesson —
                // shown only when the server returned a non-empty list.
                if (newAchievements != null && newAchievements!.isNotEmpty) ...[
                  _NewAchievementsCard(achievements: newAchievements!),
                  const SizedBox(height: 12),
                ],

                // Final score
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Text(
                        '${summary.totalScore.toStringAsFixed(1)} / ${summary.totalCount}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('FINAL SCORE',
                          style: PolyText.sectionLabel(
                              color: PolyColors.white(0.6))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Correct / wrong / skipped breakdown
                GlassCard(
                  child: Row(
                    children: [
                      _SummaryStat(
                        icon: Icons.celebration,
                        color: PolyColors.green500,
                        value: summary.correct,
                        label: 'Correct',
                      ),
                      const _SummaryDivider(),
                      _SummaryStat(
                        icon: Icons.refresh,
                        color: PolyColors.red400,
                        value: summary.wrong,
                        label: 'Wrong',
                      ),
                      const _SummaryDivider(),
                      _SummaryStat(
                        icon: Icons.skip_next,
                        color: PolyColors.white(0.6),
                        value: summary.skipped,
                        label: 'Skipped',
                      ),
                    ],
                  ),
                ),

                // Words in this lesson (dedup, first-encountered order)
                if (summary.words.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      'WORDS IN THIS LESSON',
                      style: PolyText.sectionLabel(
                          color: PolyColors.white(0.55)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final w in summary.words)
                        _SummaryWordChip(label: w),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        CtaButton(
          label: primaryLabel,
          trailingIcon: Icons.arrow_forward,
          onTap: onPrimary,
        ),
        const SizedBox(height: 10),
        _SecondaryButton(
          label: repeatLabel,
          icon: Icons.refresh,
          onTap: onRepeat,
        ),
      ],
    );
  }
}

/// One tier of the lesson-end summary card — icon + count + small label.
class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  const _SummaryStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.36,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.08,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}

/// Celebration card shown above the score breakdown on the lesson-
/// completion screen when `check_new_achievements` returned anything.
/// Lists each unlocked badge with its icon, headline, and the count
/// (e.g. "10 words learned").
class _NewAchievementsCard extends StatelessWidget {
  final List<Achievement> achievements;
  const _NewAchievementsCard({required this.achievements});

  static String _headline(AchievementType t) {
    switch (t) {
      case AchievementType.lessonsCompleted:
        return 'Lessons milestone';
      case AchievementType.wordsLearned:
        return 'Vocabulary milestone';
      case AchievementType.unknown:
        return 'Achievement unlocked';
    }
  }

  static String _detail(Achievement a) {
    switch (a.type) {
      case AchievementType.lessonsCompleted:
        return '${a.countElements} lessons completed';
      case AchievementType.wordsLearned:
        return '${a.countElements} words learned';
      case AchievementType.unknown:
        return 'Keep it up!';
    }
  }

  static IconData _icon(AchievementType t) {
    switch (t) {
      case AchievementType.lessonsCompleted:
        return Icons.menu_book;
      case AchievementType.wordsLearned:
        return Icons.translate;
      case AchievementType.unknown:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: PolyColors.orange300, size: 20),
              const SizedBox(width: 8),
              Text(
                achievements.length == 1
                    ? 'NEW ACHIEVEMENT'
                    : 'NEW ACHIEVEMENTS',
                style: PolyText.sectionLabel(color: PolyColors.orange300),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < achievements.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PolyColors.orange300.withValues(alpha: 0.18),
                    border: Border.all(
                        color: PolyColors.orange300.withValues(alpha: 0.55)),
                  ),
                  child: Icon(_icon(achievements[i].type),
                      color: PolyColors.orange300, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline(achievements[i].type),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _detail(achievements[i]),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pill chip for a single word in the lesson-summary "Words in this
/// lesson" wrap. Same visual language as the Words page chip.
class _SummaryWordChip extends StatelessWidget {
  final String label;
  const _SummaryWordChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: PolyRadii.pill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: AutoText(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Translucent glass pill — secondary action paired with [CtaButton].
class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: PolyRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: PolyRadii.pill,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.26,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizBody extends StatelessWidget {
  final int index;
  final int total;
  final Exercise exercise;
  // Page title shown in the nav bar (lesson title or practice mode).
  final String title;
  final Set<int> selected;
  final bool checked;
  // Local score for the answered exercise; null until the user checks.
  // Mirrors the server's calculate_score formula via lib/score.dart so
  // we can render feedback without waiting for the POST round-trip.
  final double? score;
  // Null while the user hasn't answered yet (or after Check, when tiles
  // are locked); set once Check or Continue can fire.
  final ValueChanged<int>? onSelect;
  final VoidCallback onPrimary;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;
  final VoidCallback? onPlayAudio;

  const _QuizBody({
    required this.index,
    required this.total,
    required this.exercise,
    required this.title,
    required this.selected,
    required this.checked,
    required this.score,
    required this.onSelect,
    required this.onPrimary,
    required this.onSkip,
    required this.onBack,
    required this.onPlayAudio,
  });

  /// Per-option visual state once the answer is revealed: every correct
  /// option turns green, a wrong pick turns red, the rest stay neutral.
  _TileFeedback _feedbackFor(int i) {
    if (!checked) return _TileFeedback.none;
    if (exercise.options[i].correct) return _TileFeedback.correct;
    if (selected.contains(i)) return _TileFeedback.wrong;
    return _TileFeedback.none;
  }

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (index + 1) / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top — close + progress + lives
        Row(
          children: [
            RoundIconButton(
              icon: Icons.close,
              tooltip: 'Close',
              onTap: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 12),
            Expanded(child: PolyProgressBar(value: progress, height: 8)),
            const SizedBox(width: 10),
            Text(
              '${index + 1} / $total',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.44,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite, size: 14, color: PolyColors.red400),
                SizedBox(width: 4),
                Text(
                  '3',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        _QuizNav(
          title: title,
          onBack: index > 0 ? onBack : null,
          onSkip: onSkip,
        ),
        const SizedBox(height: 14),

        Center(
          child: Text('— Translate this sentence —',
              style: PolyText.sectionLabel()),
        ),
        const SizedBox(height: 12),

        GlassCard(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              AutoText(
                exercise.sentence,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                  height: 1.2,
                  shadows: [
                    Shadow(
                        blurRadius: 18,
                        color: Colors.black54,
                        offset: Offset(0, 4)),
                  ],
                ),
              ),
              if (exercise.exerciseType.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  exercise.exerciseType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AudioButton(onTap: onPlayAudio),
                  if (checked && score != null) ...[
                    const SizedBox(width: 12),
                    _ScoreIcon(score: score!),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Expanded(
          child: exercise.exerciseType == 'recognize'
              // Tag-style chips that wrap to the next line; no A/B/C.
              ? SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < exercise.options.length; i++)
                        _AnswerChip(
                          label: exercise.options[i].text,
                          selected: selected.contains(i),
                          feedback: _feedbackFor(i),
                          onTap: onSelect == null ? null : () => onSelect!(i),
                        ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: exercise.options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _AnswerTile(
                    letter: String.fromCharCode(65 + i),
                    label: exercise.options[i].text,
                    selected: selected.contains(i),
                    feedback: _feedbackFor(i),
                    onTap: onSelect == null ? null : () => onSelect!(i),
                  ),
                ),
        ),

        const SizedBox(height: 14),
        CtaButton(
          label: checked ? 'Continue' : 'Check answer',
          trailingIcon: Icons.arrow_forward,
          onTap: (checked || selected.isNotEmpty) ? onPrimary : null,
        ),
      ],
    );
  }
}

class _QuizNav extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  const _QuizNav({required this.title, this.onBack, this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: PolyRadii.pill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          _QnavButton(
            label: 'Back',
            leading: Icons.arrow_back,
            onTap: onBack,
          ),
          Expanded(
            child: Center(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
          _QnavButton(
            label: 'Skip',
            trailing: Icons.arrow_forward,
            onTap: onSkip,
          ),
        ],
      ),
    );
  }
}

class _QnavButton extends StatelessWidget {
  final String label;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onTap;
  const _QnavButton({required this.label, this.leading, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: onTap == null ? 0.04 : 0.08),
      borderRadius: PolyRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: PolyRadii.pill,
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading,
                    size: 16,
                    color: Colors.white.withValues(alpha: onTap == null ? 0.35 : 1)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: onTap == null ? 0.35 : 1),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                Icon(trailing,
                    size: 16,
                    color: Colors.white.withValues(alpha: onTap == null ? 0.35 : 1)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _AudioButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.10 : 0.04),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(Icons.volume_up,
              size: 17,
              color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.35)),
        ),
      ),
    );
  }
}

enum _TileFeedback { none, correct, wrong }

/// Tag/pill option used for `recognize` exercises — wraps to the next
/// line, no A/B/C badge. Shares the selection/feedback colour language
/// with [_AnswerTile].
class _AnswerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final _TileFeedback feedback;
  final VoidCallback? onTap;
  const _AnswerChip({
    required this.label,
    required this.selected,
    required this.feedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = feedback == _TileFeedback.correct;
    final isWrong = feedback == _TileFeedback.wrong;
    final accent = isCorrect
        ? PolyColors.green500
        : isWrong
            ? PolyColors.red400
            : null;
    final fillAlpha = accent != null ? 0.22 : (selected ? 0.18 : 0.06);
    final borderColor =
        accent ?? Colors.white.withValues(alpha: selected ? 0.45 : 0.16);

    return Material(
      color: accent != null
          ? accent.withValues(alpha: fillAlpha)
          : Colors.white.withValues(alpha: fillAlpha),
      borderRadius: PolyRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: PolyRadii.pill,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (accent != null) ...[
                Icon(isCorrect ? Icons.check : Icons.close,
                    size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              AutoText(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final String letter;
  final String label;
  final bool selected;
  final _TileFeedback feedback;
  final VoidCallback? onTap;
  const _AnswerTile({
    required this.letter,
    required this.label,
    required this.selected,
    required this.feedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = feedback == _TileFeedback.correct;
    final isWrong = feedback == _TileFeedback.wrong;
    final accent = isCorrect
        ? PolyColors.green500
        : isWrong
            ? PolyColors.red400
            : null;

    final fillAlpha = accent != null ? 0.22 : (selected ? 0.18 : 0.06);
    final borderColor = accent ?? Colors.white.withValues(alpha: selected ? 0.45 : 0.14);

    return Material(
      color: accent != null
          ? accent.withValues(alpha: fillAlpha)
          : Colors.white.withValues(alpha: fillAlpha),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: selected && accent == null
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        offset: const Offset(0, 6),
                        blurRadius: 18),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent ??
                      (selected ? Colors.white : Colors.white.withValues(alpha: 0.10)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent ??
                        (selected ? Colors.white : Colors.white.withValues(alpha: 0.20)),
                  ),
                ),
                child: accent != null
                    ? Icon(
                        isCorrect ? Icons.check : Icons.close,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        letter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? PolyColors.brandPrimary
                              : Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoText(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-tier feedback glyph for the per-question score (see lib/score.dart).
/// Good (≥0.9) → celebration in green; medium (>0 and <0.9) → thumbs-up in
/// orange; wrong (≤0) → refresh in red ("try this one again", framed forward
/// rather than as a verdict). The score function currently produces only
/// the good/wrong tiers, but the medium branch is here so future scoring
/// tweaks don't silently fall through.
class _ScoreIcon extends StatelessWidget {
  final double score;
  const _ScoreIcon({required this.score});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    if (score >= 0.9) {
      icon = Icons.celebration;
      color = PolyColors.green500;
    } else if (score > 0) {
      icon = Icons.thumb_up;
      color = PolyColors.orange300;
    } else {
      icon = Icons.refresh;
      color = PolyColors.red400;
    }
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }
}
