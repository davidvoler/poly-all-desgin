import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class AnnotatedPage extends StatelessWidget {
  const AnnotatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhoneBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar — close + progress + tune
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.close,
                      tooltip: 'Close',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: PolyProgressBar(value: 0.3, height: 8)),
                    const SizedBox(width: 10),
                    const Text(
                      '3 / 10',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    RoundIconButton(
                      icon: Icons.tune,
                      tooltip: 'Settings',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Back / Question label / Skip
                _QuizNav(
                  questionLabel: 'Question 3',
                  onBack: () {},
                  onSkip: () {},
                ),
                const SizedBox(height: 14),

                Center(
                  child: Text(
                    '— Read & tap the highlighted words —',
                    style: PolyText.sectionLabel(),
                  ),
                ),
                const SizedBox(height: 12),

                // Reading panel
                GlassCard(
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                  child: Column(
                    children: [
                      const _AnnotatedSentence(),
                      const SizedBox(height: 10),
                      Text(
                        '"I am studying Japanese."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Annotation card — white surface, "tail" pointing up
                const _AnnoCard(),
                const SizedBox(height: 12),

                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Tap any  ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: PolyColors.orange300,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: PolyColors.orange300.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextSpan(
                        text: '  word to learn its meaning & sound.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                CtaButton(
                  label: 'Continue',
                  trailingIcon: Icons.arrow_forward,
                  onTap: () => Navigator.pushReplacementNamed(context, '/quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnotatedSentence extends StatelessWidget {
  const _AnnotatedSentence();

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -0.24,
      height: 1.5,
      shadows: [Shadow(blurRadius: 18, color: Colors.black54, offset: Offset(0, 4))],
    );

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'わたしは', style: baseStyle),
          // Active annotation — solid orange pill
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _AnnoChip(text: '日本語', active: true),
          ),
          const TextSpan(text: 'を', style: baseStyle),
          // Hint annotation — soft orange tint
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _AnnoChip(text: 'べんきょう', active: false),
          ),
          const TextSpan(text: 'しています。', style: baseStyle),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _AnnoChip extends StatelessWidget {
  final String text;
  final bool active;
  const _AnnoChip({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? PolyColors.orange300
            : PolyColors.orange300.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(7),
        boxShadow: active
            ? [
                BoxShadow(
                    color: PolyColors.orange300.withValues(alpha: 0.35),
                    offset: const Offset(0, 4),
                    blurRadius: 14),
              ]
            : null,
        border: active
            ? null
            : Border(
                bottom: BorderSide(color: PolyColors.orange300, width: 2),
              ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.24,
          color: active ? PolyColors.annoActiveText : Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

class _AnnoCard extends StatelessWidget {
  const _AnnoCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Pointer triangle
        const Positioned(
          top: -7,
          child: _CardTail(),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                offset: const Offset(0, 12),
                blurRadius: 28,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NOUN · にほんご',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.26,
                  color: PolyColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '日本語',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.22,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'にほんご',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'nihongo',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'The Japanese language. Lit. "Japan-language" — used to refer to the spoken/written language itself.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _PillButton(
                    label: 'Play',
                    icon: Icons.volume_up,
                    primary: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _PillButton(
                    label: 'Examples',
                    icon: Icons.menu_book,
                    onTap: () {},
                  ),
                  const Spacer(),
                  Icon(Icons.bookmark_border,
                      size: 20, color: Colors.grey.shade500),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardTail extends StatelessWidget {
  const _CardTail();
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.7853981633974483, // π/4
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.icon,
    this.primary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : const Color(0xFF424242);
    final bg = primary ? PolyColors.brandPrimary : Colors.white;
    final border = primary ? PolyColors.brandPrimary : const Color(0xFFE0E0E0);
    return Material(
      color: bg,
      borderRadius: PolyRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: PolyRadii.pill,
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reused small nav strip — duplicated here to keep the file self-contained.
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
              label: 'Back', leading: Icons.arrow_back, onTap: onBack),
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
              label: 'Skip', trailing: Icons.arrow_forward, onTap: onSkip),
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
      color: Colors.white.withValues(alpha: 0.08),
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
                Icon(leading, size: 16, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                Icon(trailing, size: 16, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
