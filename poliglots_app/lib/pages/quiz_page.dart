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
  // Set semantics for both modes: single-correct exercises (simple/read)
  // replace the set on tap; `recognize` toggles, since multiple options
  // are correct.
  Set<int> _selected = {};
  // Two-phase primary action: false → "Check answer" (reveals feedback),
  // true → "Continue" (advances to the next exercise).
  bool _checked = false;

  void _resetForNext() {
    _selected = {};
    _checked = false;
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
                final idx = _exerciseIndex.clamp(0, exercises.length - 1);
                final ex = exercises[idx];
                final multi = ex.exerciseType == 'recognize';
                return _QuizBody(
                  index: idx,
                  total: exercises.length,
                  exercise: ex,
                  selected: _selected,
                  checked: _checked,
                  onSelect: _checked
                      ? null
                      : (i) => setState(() {
                            if (multi) {
                              if (_selected.contains(i)) {
                                _selected = {..._selected}..remove(i);
                              } else {
                                _selected = {..._selected, i};
                              }
                            } else {
                              _selected = {i};
                            }
                          }),
                  onPrimary: () {
                    if (!_checked) {
                      setState(() => _checked = true);
                    } else {
                      setState(() {
                        if (idx + 1 < exercises.length) {
                          _exerciseIndex = idx + 1;
                        }
                        _resetForNext();
                      });
                    }
                  },
                  onSkip: idx < exercises.length - 1
                      ? () {
                          setState(() {
                            _exerciseIndex = idx + 1;
                            _resetForNext();
                          });
                        }
                      : null,
                  onBack: idx > 0
                      ? () {
                          setState(() {
                            _exerciseIndex = idx - 1;
                            _resetForNext();
                          });
                        }
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
