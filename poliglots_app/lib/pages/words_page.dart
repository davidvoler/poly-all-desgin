import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
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
                                  for (final w in words)
                                    _WordChip(label: w),
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

/// Read-only glass tag-pill. Mirrors the quiz page's answer chip look,
/// minus the selection/feedback states. [AutoText] keeps RTL scripts
/// (Arabic/Hebrew) rendering correctly inside the LTR layout.
class _WordChip extends StatelessWidget {
  final String label;
  const _WordChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
