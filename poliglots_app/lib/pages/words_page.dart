import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
import '../api/models.dart';
import '../state/lang.dart';
import '../theme.dart';
import '../widgets/auto_text.dart';
import '../widgets/common.dart';

/// Scrollable gallery of every word the user has encountered so far in
/// the language they're learning. Tapping a chip toggles selection; when
/// any word is selected the primary CTA narrows the practice to just
/// those words via [practiceByWordsProvider]. Data: [wordsListProvider].
class WordsPage extends ConsumerStatefulWidget {
  const WordsPage({super.key});

  @override
  ConsumerState<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends ConsumerState<WordsPage> {
  final Set<String> _selected = {};

  void _toggle(String word) {
    setState(() {
      if (!_selected.remove(word)) _selected.add(word);
    });
  }

  void _clearSelection() => setState(_selected.clear);

  void _startPractice() {
    if (_selected.isEmpty) {
      Navigator.pushNamed(context, '/quiz',
          arguments: PracticeKind.words);
    } else {
      // Sorted so the cache key is stable regardless of pick order.
      final words = _selected.toList()..sort();
      Navigator.pushNamed(context, '/quiz', arguments: words);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsListProvider);
    final learning = ref.watch(learningLangProvider);
    final hasSelection = _selected.isNotEmpty;

    return Scaffold(
      body: PhoneBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar — back + title + clear-selection (only when picking).
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
                    hasSelection
                        ? RoundIconButton(
                            icon: Icons.close,
                            tooltip: 'Clear selection',
                            onTap: _clearSelection,
                          )
                        : const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 18),

                CtaButton(
                  label: hasSelection
                      ? 'Practice ${_selected.length} selected'
                      : 'Practice words',
                  leadingIcon: Icons.play_arrow,
                  onTap: _startPractice,
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
                              hasSelection
                                  ? '${words.length} ${learning.native} words · ${_selected.length} selected'
                                  : '${words.length} ${learning.native} words · tap to pick',
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
                                    _WordChip(
                                      label: w.word,
                                      score: w.score,
                                      selected: _selected.contains(w.word),
                                      onTap: () => _toggle(w.word),
                                    ),
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

/// Glass tag-pill tinted by mastery score, tappable to toggle a
/// selection set on the parent page:
///   ≥3      → green   (well retained)
///   1.5..3  → amber   (getting there)
///   0..1.5  → orange  (still shaky)
///   <0      → red     (repeatedly missed)
/// Selected chips swap their score-colored border for a bright white
/// ring (same width, no layout shift). [AutoText] keeps RTL scripts
/// rendering correctly inside the LTR layout.
class _WordChip extends StatelessWidget {
  final String label;
  final double score;
  final bool selected;
  final VoidCallback? onTap;
  const _WordChip({
    required this.label,
    required this.score,
    required this.selected,
    required this.onTap,
  });

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
    return Material(
      color: c.withValues(alpha: selected ? 0.32 : 0.18),
      borderRadius: PolyRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: PolyRadii.pill,
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.90)
                  : c.withValues(alpha: 0.55),
            ),
          ),
          child: AutoText(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
