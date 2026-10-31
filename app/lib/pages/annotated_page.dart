import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/auto_text.dart' show directionOf;
import '../widgets/common.dart';
import '../widgets/ruby_text.dart';

/// Standalone demo for the annotation / alternative-text capabilities
/// (TASKS phases 3 & 4). It runs on in-app sample data — there are no
/// server fields for furigana / diacritics / transliteration / per-word
/// translations yet — but every piece is built from reusable, data-driven
/// widgets so the live quiz can be wired up once that data exists.
class AnnotatedPage extends StatefulWidget {
  const AnnotatedPage({super.key});

  @override
  State<AnnotatedPage> createState() => _AnnotatedPageState();
}

class _AnnotatedPageState extends State<AnnotatedPage> {
  // Selected variant per text-alternative example, keyed by example title.
  final Map<String, String> _variant = {};
  // Currently-tapped annotated word in the annotated-sentence section.
  _AnnWord? _selectedWord;

  void _playWord(BuildContext context, _AnnWord w) =>
      _playLabel(context, w.text);

  void _playLabel(BuildContext context, String label) {
    // No per-word audio data in the demo — surface what *would* play. Once
    // words carry an audio URL this becomes an AudioPlayer.play(...) call.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          content: Text('🔊  $label'),
        ),
      );
  }

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
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.close,
                      tooltip: 'Close',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Annotations demo',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel('Furigana · ruby text (Japanese)'),
                        const SizedBox(height: 10),
                        _RubyDemo(),
                        const SizedBox(height: 24),

                        _SectionLabel('Text alternatives'),
                        const SizedBox(height: 10),
                        for (final ex in _variantExamples) ...[
                          _VariantCard(
                            example: ex,
                            selected: _variant[ex.title] ?? ex.variants.keys.first,
                            onSelect: (v) =>
                                setState(() => _variant[ex.title] = v),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 14),

                        _SectionLabel('Annotated sentence · tap a word'),
                        const SizedBox(height: 10),
                        _AnnotatedSentenceCard(
                          words: _annotatedSentence,
                          selected: _selectedWord,
                          onTapWord: (w) =>
                              setState(() => _selectedWord = w),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedWord != null)
                          _AnnoCard(
                            word: _selectedWord!,
                            onPlay: () => _playWord(context, _selectedWord!),
                          )
                        else
                          _Hint(),
                        const SizedBox(height: 24),

                        _SectionLabel('Annotated sentence · simple tooltip'),
                        const SizedBox(height: 10),
                        _TooltipSentenceCard(
                          words: _annotatedSentence,
                          onPlay: (w) => _playWord(context, w),
                        ),
                        const SizedBox(height: 24),

                        _SectionLabel('Furigana + annotation · tap a word'),
                        const SizedBox(height: 10),
                        _RubyTooltipCard(
                          words: _rubyAnnotatedSentence,
                          onPlay: (w) => _playLabel(context, w.base),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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

// ── Sample data ────────────────────────────────────────────────────────

/// A Japanese sentence as ruby segments (kanji + furigana). Kana segments
/// carry no reading. Long enough to demonstrate multiline wrapping.
final List<RubySegment> _rubySentence = [
  const RubySegment('私', 'わたし'),
  const RubySegment('は'),
  const RubySegment('毎日', 'まいにち'),
  const RubySegment('日本語', 'にほんご'),
  const RubySegment('を'),
  const RubySegment('勉強', 'べんきょう'),
  const RubySegment('して'),
  const RubySegment('図書館', 'としょかん'),
  const RubySegment('に'),
  const RubySegment('行', 'い'),
  const RubySegment('きます'),
  const RubySegment('。'),
];

class _VariantExample {
  final String title;
  // Ordered: the first key is the default variant.
  final Map<String, String> variants;
  final String translation;
  const _VariantExample({
    required this.title,
    required this.variants,
    required this.translation,
  });
}

const List<_VariantExample> _variantExamples = [
  _VariantExample(
    title: 'Arabic',
    variants: {
      'Plain': 'انا ادرس اللغة العربية',
      'Diacritics': 'أَنَا أَدْرُسُ اللُّغَةَ الْعَرَبِيَّةَ',
      'Transliteration': 'ʾanā ʾadrusu al-luġa al-ʿarabiyya',
    },
    translation: 'I study the Arabic language.',
  ),
  _VariantExample(
    title: 'Japanese',
    variants: {
      'Kanji': '日本語を勉強します',
      'Hiragana': 'にほんごをべんきょうします',
      'Romaji': 'nihongo o benkyō shimasu',
    },
    translation: 'I study Japanese.',
  ),
];

/// A word in an annotated sentence. [annotated] words are highlighted and
/// tappable; the rest render as plain text.
class _AnnWord {
  final String text;
  final bool annotated;
  final String? translation;
  final String? reading;
  final String? pos; // part of speech, shown as a small label
  const _AnnWord(
    this.text, {
    this.annotated = false,
    this.translation,
    this.reading,
    this.pos,
  });
}

final List<_AnnWord> _annotatedSentence = [
  const _AnnWord('わたしは'),
  const _AnnWord('日本語',
      annotated: true,
      translation: 'the Japanese language',
      reading: 'にほんご',
      pos: 'NOUN'),
  const _AnnWord('を'),
  const _AnnWord('勉強',
      annotated: true,
      translation: 'study; (to) study',
      reading: 'べんきょう',
      pos: 'NOUN / SURU-VERB'),
  const _AnnWord('しています。'),
];

/// A word in a ruby-annotated sentence: a base run with an optional reading
/// (furigana) rendered above it, plus an optional tooltip annotation.
/// [annotated] words are highlighted, tappable, and pop a tooltip with the
/// translation + a play icon; the rest render as plain ruby text.
class _RubyAnnWord {
  final String base;
  final String? reading;
  final bool annotated;
  final String? translation;
  const _RubyAnnWord(
    this.base, {
    this.reading,
    this.annotated = false,
    this.translation,
  });

  bool get hasReading => reading != null && reading!.isNotEmpty;
}

/// The same Japanese sentence as the ruby demo, but with the meaningful
/// words carrying a translation so they can be tapped for a tooltip.
final List<_RubyAnnWord> _rubyAnnotatedSentence = [
  const _RubyAnnWord('私',
      reading: 'わたし', annotated: true, translation: 'I; me'),
  const _RubyAnnWord('は'),
  const _RubyAnnWord('毎日',
      reading: 'まいにち', annotated: true, translation: 'every day'),
  const _RubyAnnWord('日本語',
      reading: 'にほんご', annotated: true, translation: 'the Japanese language'),
  const _RubyAnnWord('を'),
  const _RubyAnnWord('勉強',
      reading: 'べんきょう', annotated: true, translation: 'study'),
  const _RubyAnnWord('して'),
  const _RubyAnnWord('図書館',
      reading: 'としょかん', annotated: true, translation: 'library'),
  const _RubyAnnWord('に'),
  const _RubyAnnWord('行', reading: 'い', annotated: true, translation: 'to go'),
  const _RubyAnnWord('きます'),
  const _RubyAnnWord('。'),
];

// ── Section widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: PolyText.sectionLabel());
}

class _RubyDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          RubyText(
            _rubySentence,
            textAlign: TextAlign.center,
            spacing: 1,
            runSpacing: 10,
            baseStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
              shadows: [
                Shadow(blurRadius: 18, color: Colors.black54, offset: Offset(0, 4)),
              ],
            ),
            rubyStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: PolyColors.orange300,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"Every day I study Japanese and go to the library."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: PolyColors.white(0.65),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final _VariantExample example;
  final String selected;
  final ValueChanged<String> onSelect;
  const _VariantCard({
    required this.example,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final text = example.variants[selected] ?? '';
    final rtl = directionOf(text) == TextDirection.rtl;
    return GlassCard(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(example.title.toUpperCase(),
                  style: PolyText.sectionLabel(color: PolyColors.white(0.5))),
            ],
          ),
          const SizedBox(height: 10),
          // The sentence in the selected variant.
          SizedBox(
            width: double.infinity,
            child: Text(
              text,
              textAlign: rtl ? TextAlign.right : TextAlign.left,
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            example.translation,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: PolyColors.white(0.6),
            ),
          ),
          const SizedBox(height: 12),
          // Variant toggle.
          Row(
            children: [
              for (final v in example.variants.keys) ...[
                if (v != example.variants.keys.first) const SizedBox(width: 8),
                Expanded(
                  child: _VariantSegment(
                    label: v,
                    selected: v == selected,
                    onTap: () => onSelect(v),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _VariantSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _VariantSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PolyColors.brandPrimary.withValues(alpha: 0.30)
          : PolyColors.white(0.06),
      borderRadius: PolyRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: PolyRadii.pill,
            border: Border.all(
              color: selected ? PolyColors.brandPrimary : PolyColors.white(0.16),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: selected ? 1 : 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnotatedSentenceCard extends StatelessWidget {
  final List<_AnnWord> words;
  final _AnnWord? selected;
  final ValueChanged<_AnnWord> onTapWord;
  const _AnnotatedSentenceCard({
    required this.words,
    required this.selected,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final w in words)
            w.annotated
                ? _AnnChip(
                    word: w,
                    active: identical(w, selected),
                    onTap: () => onTapWord(w),
                  )
                : Text(
                    w.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.5,
                      shadows: [
                        Shadow(
                            blurRadius: 18,
                            color: Colors.black54,
                            offset: Offset(0, 4)),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }
}

/// Highlighted, tappable word inside an annotated sentence.
class _AnnChip extends StatelessWidget {
  final _AnnWord word;
  final bool active;
  final VoidCallback onTap;
  const _AnnChip({required this.word, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          word.text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: active ? PolyColors.annoActiveText : Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// White annotation card for the tapped word: small translation + reading
/// and a play-sound button.
class _AnnoCard extends StatelessWidget {
  final _AnnWord word;
  final VoidCallback onPlay;
  const _AnnoCard({required this.word, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (word.pos != null)
            Text(
              [word.pos, word.reading].where((e) => e != null).join(' · '),
              style: const TextStyle(
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
              Flexible(
                child: Text(
                  word.text,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
              if (word.reading != null) ...[
                const SizedBox(width: 10),
                Text(
                  word.reading!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // The translation — kept small, per the task.
          Text(
            word.translation ?? '',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _PillButton(label: 'Play', icon: Icons.volume_up, onTap: onPlay),
        ],
      ),
    );
  }
}

/// Simpler annotated sentence: tapping a word pops a compact tooltip
/// directly above it with just the translation + a play icon (no separate
/// card below). Each word owns its own overlay bubble.
class _TooltipSentenceCard extends StatelessWidget {
  final List<_AnnWord> words;
  final ValueChanged<_AnnWord> onPlay;
  const _TooltipSentenceCard({required this.words, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final w in words)
            w.annotated
                ? _TooltipWord(word: w, onPlay: () => onPlay(w))
                : Text(
                    w.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.5,
                      shadows: [
                        Shadow(
                            blurRadius: 18,
                            color: Colors.black54,
                            offset: Offset(0, 4)),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }
}

class _TooltipWord extends StatefulWidget {
  final _AnnWord word;
  final VoidCallback onPlay;
  const _TooltipWord({required this.word, required this.onPlay});

  @override
  State<_TooltipWord> createState() => _TooltipWordState();
}

class _TooltipWordState extends State<_TooltipWord> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();

  void _toggle() {
    _controller.isShowing ? _controller.hide() : _controller.show();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showing = _controller.isShowing;
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (context) {
        return Stack(
          children: [
            // Tap-anywhere-else barrier to dismiss.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -6),
              child: _TooltipBubble(
                translation: widget.word.translation ?? '',
                onPlay: widget.onPlay,
              ),
            ),
          ],
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: showing
                  ? PolyColors.orange300
                  : PolyColors.orange300.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(7),
              border: showing
                  ? null
                  : Border(
                      bottom:
                          BorderSide(color: PolyColors.orange300, width: 2),
                    ),
            ),
            child: Text(
              widget.word.text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: showing ? PolyColors.annoActiveText : Colors.white,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The small bubble shown above a tapped word: translation text + a play
/// icon, with a little downward-pointing tail.
class _TooltipBubble extends StatelessWidget {
  final String translation;
  final VoidCallback onPlay;
  const _TooltipBubble({required this.translation, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    offset: const Offset(0, 8),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      translation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onPlay,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.volume_up,
                          size: 18, color: PolyColors.brandPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Downward tail.
          Transform.translate(
            offset: const Offset(0, -3),
            child: Transform.rotate(
              angle: 0.7853981633974483, // π/4
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Tap any  ',
            style: TextStyle(fontSize: 11, color: PolyColors.white(0.6)),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: PolyColors.orange300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          TextSpan(
            text: '  word to see its meaning & sound.',
            style: TextStyle(fontSize: 11, color: PolyColors.white(0.6)),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PolyColors.brandPrimary,
      borderRadius: PolyRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
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

// ── Ruby text + tooltip annotation ──────────────────────────────────────

/// Shared ruby-text styling for the combined section, so the plain words
/// and the tappable chips line up on the same baseline.
const TextStyle _rubyBaseStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w700,
  color: Colors.white,
  height: 1.1,
  shadows: [
    Shadow(blurRadius: 18, color: Colors.black54, offset: Offset(0, 4)),
  ],
);
const TextStyle _rubyReadingStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.2,
  color: PolyColors.orange300,
);
// The fixed height every word reserves for its reading line so the base
// glyphs share a baseline whether or not they carry furigana.
const double _rubyLineHeight = 11 * 1.2;

/// Ruby text where the meaningful words show furigana *and* are tappable —
/// tapping pops the same tooltip (translation + play) directly above the
/// word. Combines the furigana demo with the simple-tooltip demo.
class _RubyTooltipCard extends StatelessWidget {
  final List<_RubyAnnWord> words;
  final ValueChanged<_RubyAnnWord> onPlay;
  const _RubyTooltipCard({required this.words, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 1,
            runSpacing: 10,
            children: [
              for (final w in words)
                w.annotated
                    ? _RubyTooltipWord(word: w, onPlay: () => onPlay(w))
                    : _RubyColumn(
                        base: w.base,
                        reading: w.hasReading ? w.reading : null,
                      ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap a highlighted word for its meaning & sound.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: PolyColors.white(0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single ruby column: the reading line (reserved even when empty) sits
/// above the base glyphs. [baseChild] overrides the plain base text so a
/// tappable chip can take its place while keeping the same layout.
class _RubyColumn extends StatelessWidget {
  final String base;
  final String? reading;
  final Widget? baseChild;
  const _RubyColumn({required this.base, this.reading, this.baseChild});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _rubyLineHeight,
          child: reading != null
              ? Text(reading!,
                  style: _rubyReadingStyle, textAlign: TextAlign.center)
              : null,
        ),
        baseChild ?? Text(base, style: _rubyBaseStyle),
      ],
    );
  }
}

/// A ruby word that is also annotated: furigana above a highlighted chip,
/// and an overlay tooltip (translation + play) anchored above it on tap.
class _RubyTooltipWord extends StatefulWidget {
  final _RubyAnnWord word;
  final VoidCallback onPlay;
  const _RubyTooltipWord({required this.word, required this.onPlay});

  @override
  State<_RubyTooltipWord> createState() => _RubyTooltipWordState();
}

class _RubyTooltipWordState extends State<_RubyTooltipWord> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();

  void _toggle() {
    _controller.isShowing ? _controller.hide() : _controller.show();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showing = _controller.isShowing;
    final w = widget.word;
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (context) {
        return Stack(
          children: [
            // Tap-anywhere-else barrier to dismiss.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -6),
              child: _TooltipBubble(
                translation: w.translation ?? '',
                onPlay: widget.onPlay,
              ),
            ),
          ],
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: GestureDetector(
          onTap: _toggle,
          child: _RubyColumn(
            base: w.base,
            reading: w.hasReading ? w.reading : null,
            baseChild: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: showing
                    ? PolyColors.orange300
                    : PolyColors.orange300.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(7),
                border: showing
                    ? null
                    : Border(
                        bottom:
                            BorderSide(color: PolyColors.orange300, width: 2),
                      ),
              ),
              child: Text(
                w.base,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: showing ? PolyColors.annoActiveText : Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
