import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
import '../api/models.dart';
import '../theme.dart';
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
  // Set once the user advances past the last exercise — swaps the quiz
  // body for the completion screen.
  bool _finished = false;

  void _restartLesson() {
    setState(() {
      _exerciseIndex = 0;
      _finished = false;
      _selectedByIndex.clear();
      _checkedIndices.clear();
    });
  }

  /// Fired once, when the user reveals feedback for an exercise. POSTs
  /// the attempt (correct or not) so progress is tracked server-side.
  void _submitResult(Exercise ex, Set<int> selected, int lessonId) {
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
            attempts: 1,
            correct: isCorrect,
            correctRatio: correctRatio,
            incorrectCount: incorrectCount,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final lessonId = (ModalRoute.of(context)?.settings.arguments as int?) ?? 1;
    final exercisesAsync = ref.watch(exercisesProvider(lessonId));

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
                      'No exercises in this lesson',
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
                    onRepeat: _restartLesson,
                  );
                }
                final idx = _exerciseIndex.clamp(0, exercises.length - 1);
                final ex = exercises[idx];
                final multi = ex.exerciseType == 'recognize';
                final selected = _selectedByIndex[idx] ?? const <int>{};
                final checked = _checkedIndices.contains(idx);
                return _QuizBody(
                  index: idx,
                  total: exercises.length,
                  exercise: ex,
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
                          }),
                  onPrimary: () {
                    if (!checked) {
                      _submitResult(ex, selected, lessonId);
                      setState(() => _checkedIndices.add(idx));
                    } else if (idx + 1 < exercises.length) {
                      setState(() => _exerciseIndex = idx + 1);
                    } else {
                      setState(() => _finished = true);
                    }
                  },
                  onSkip: idx < exercises.length - 1
                      ? () => setState(() => _exerciseIndex = idx + 1)
                      : null,
                  onBack: idx > 0
                      ? () => setState(() => _exerciseIndex = idx - 1)
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown after the last exercise. "Next Lesson" jumps to the following
/// lesson in the current module (resolved via [preferenceProvider]'s
/// `moduleId` + [lessonsProvider]); falls back to popping back to the
/// course page when this is the module's last lesson.
class _QuizComplete extends ConsumerWidget {
  final int lessonId;
  final VoidCallback onRepeat;
  const _QuizComplete({required this.lessonId, required this.onRepeat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        const Spacer(),
        const Icon(Icons.celebration, size: 64, color: Colors.white),
        const SizedBox(height: 16),
        Text(
          'Lesson ${name(current)} completed',
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
          next != null
              ? 'Nice work — ready for the next one?'
              : "You've finished the last lesson in this module.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        CtaButton(
          label: next != null ? 'Continue to ${name(next)}' : 'Back to course',
          trailingIcon: Icons.arrow_forward,
          onTap: () {
            if (next != null) {
              ref.read(preferenceProvider.notifier).save(lessonId: next.id);
              Navigator.pushReplacementNamed(context, '/quiz',
                  arguments: next.id);
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        const SizedBox(height: 10),
        _SecondaryButton(
          label: 'Repeat lesson',
          icon: Icons.refresh,
          onTap: onRepeat,
        ),
      ],
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
  final Set<int> selected;
  final bool checked;
  // Null while the user hasn't answered yet (or after Check, when tiles
  // are locked); set once Check or Continue can fire.
  final ValueChanged<int>? onSelect;
  final VoidCallback onPrimary;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  const _QuizBody({
    required this.index,
    required this.total,
    required this.exercise,
    required this.selected,
    required this.checked,
    required this.onSelect,
    required this.onPrimary,
    required this.onSkip,
    required this.onBack,
  });

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
          questionLabel: 'Question ${index + 1}',
          onBack: index > 0 ? onBack : null,
          onSkip: index < total - 1 ? onSkip : null,
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
              Text(
                exercise.sentence,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
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
              _AudioButton(onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: exercise.options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final opt = exercise.options[i];
              _TileFeedback feedback;
              if (!checked) {
                feedback = _TileFeedback.none;
              } else if (opt.correct) {
                feedback = _TileFeedback.correct;
              } else if (selected.contains(i)) {
                feedback = _TileFeedback.wrong;
              } else {
                feedback = _TileFeedback.none;
              }
              return _AnswerTile(
                letter: String.fromCharCode(65 + i),
                label: opt.text,
                selected: selected.contains(i),
                feedback: feedback,
                onTap: onSelect == null ? null : () => onSelect!(i),
              );
            },
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
  final String questionLabel;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  const _QuizNav({required this.questionLabel, this.onBack, this.onSkip});

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
                questionLabel.toUpperCase(),
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
  final VoidCallback onTap;
  const _AudioButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
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
          child: const Icon(Icons.volume_up, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

enum _TileFeedback { none, correct, wrong }

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
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
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
