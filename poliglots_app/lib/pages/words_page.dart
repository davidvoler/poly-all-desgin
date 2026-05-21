import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
import '../api/models.dart';
import '../state/lang.dart';
import '../theme.dart';
import '../widgets/auto_text.dart';
import '../widgets/common.dart';

/// Scrollable gallery of every word the user has encountered so far in
/// the language they're learning. Words render as glass tag-pills that
/// wrap to the next line. Data: [wordsListProvider].
class WordsPage extends ConsumerWidget {
  const WordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsListProvider);
    final learning = ref.watch(learningLangProvider);

    return Scaffold(
      body: PhoneBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar — back + title + balancing spacer.
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: TitleBlock(
                          overline: 'Your vocabulary',
                          title: 'Words learned',
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 18),

                Expanded(
                  child: wordsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        "Couldn't load words\n$err",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    data: (words) {
                      if (words.isEmpty) {
                        return Center(
                          child: Text(
                            'No words yet — start practicing\nto build your vocabulary.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Text(
                              '${words.length} ${learning.native} words',
                              style: PolyText.sectionLabel(
                                  color: PolyColors.white(0.5)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final LearnedWord w in words)
                                    _WordChip(label: w.word, score: w.score),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only glass tag-pill tinted by mastery score:
///   ≥3      → green   (well retained)
///   1.5..3  → amber   (getting there)
///   0..1.5  → orange  (still shaky)
///   <0      → red     (repeatedly missed)
/// [AutoText] keeps RTL scripts (Arabic/Hebrew) rendering correctly
/// inside the LTR layout.
class _WordChip extends StatelessWidget {
  final String label;
  final double score;
  const _WordChip({required this.label, required this.score});

  static const Color _amber = Color(0xFFFFD54F);

  Color get _color {
    if (score >= 3) return PolyColors.green500;
    if (score >= 1.5) return _amber;
    if (score >= 0) return PolyColors.orange300;
    return PolyColors.red400;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: PolyRadii.pill,
        border: Border.all(color: c.withValues(alpha: 0.55)),
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
