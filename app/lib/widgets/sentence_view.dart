import 'package:flutter/material.dart';

import '../theme.dart';

/// One token of a sentence rendered by [SentenceView]: a base run with an
/// optional reading (furigana) above it and an optional translation. A token
/// with a non-empty [translation] renders as a highlighted, tappable chip
/// that pops a tooltip; the rest render as plain (optionally ruby) text.
class SentenceToken {
  final String text;
  final String? reading;
  final String? translation;
  const SentenceToken(this.text, {this.reading, this.translation});

  bool get hasReading => reading != null && reading!.isNotEmpty;
  bool get annotated => translation != null && translation!.isNotEmpty;
}

/// Renders a sentence as a [Wrap] of per-token columns: when any token has a
/// reading, every token reserves the reading line's height so the base glyphs
/// share a baseline (furigana style). Annotated tokens are highlighted and,
/// on tap, pop a small tooltip with the translation directly above the word.
///
/// This is the live-quiz counterpart of the building blocks demonstrated on
/// the `/annotated` page — it covers plain text, per-token furigana,
/// tappable annotations, and the two combined, all from one token list.
class SentenceView extends StatelessWidget {
  final List<SentenceToken> tokens;
  final TextStyle baseStyle;
  final TextStyle readingStyle;
  final TextAlign textAlign;
  final bool rtl;
  // Horizontal gap between adjacent tokens and vertical gap between lines.
  final double spacing;
  final double runSpacing;

  const SentenceView(
    this.tokens, {
    super.key,
    required this.baseStyle,
    required this.readingStyle,
    this.textAlign = TextAlign.start,
    this.rtl = false,
    this.spacing = 1,
    this.runSpacing = 10,
  });

  WrapAlignment get _alignment {
    switch (textAlign) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      default:
        return WrapAlignment.start;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserveReading = tokens.any((t) => t.hasReading);
    final readingFontSize = readingStyle.fontSize ?? 12;
    final readingLineHeight = readingFontSize * (readingStyle.height ?? 1.2);

    return Wrap(
      alignment: _alignment,
      spacing: spacing,
      runSpacing: runSpacing,
      crossAxisAlignment: WrapCrossAlignment.end,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      children: [
        for (final t in tokens)
          t.annotated
              ? _AnnotatedToken(
                  token: t,
                  baseStyle: baseStyle,
                  readingStyle: readingStyle,
                  reserveReading: reserveReading,
                  readingLineHeight: readingLineHeight,
                )
              : _PlainToken(
                  token: t,
                  baseStyle: baseStyle,
                  readingStyle: readingStyle,
                  reserveReading: reserveReading,
                  readingLineHeight: readingLineHeight,
                ),
      ],
    );
  }
}

/// A column: the reading line (reserved when the sentence uses furigana) over
/// the base. [baseChild] overrides the plain base text so a tappable chip can
/// take its place while keeping the same layout/baseline.
class _TokenColumn extends StatelessWidget {
  final SentenceToken token;
  final TextStyle baseStyle;
  final TextStyle readingStyle;
  final bool reserveReading;
  final double readingLineHeight;
  final Widget? baseChild;
  const _TokenColumn({
    required this.token,
    required this.baseStyle,
    required this.readingStyle,
    required this.reserveReading,
    required this.readingLineHeight,
    this.baseChild,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (reserveReading)
          SizedBox(
            height: readingLineHeight,
            child: token.hasReading
                ? Text(token.reading!,
                    style: readingStyle, textAlign: TextAlign.center)
                : null,
          ),
        baseChild ?? Text(token.text, style: baseStyle),
      ],
    );
  }
}

class _PlainToken extends StatelessWidget {
  final SentenceToken token;
  final TextStyle baseStyle;
  final TextStyle readingStyle;
  final bool reserveReading;
  final double readingLineHeight;
  const _PlainToken({
    required this.token,
    required this.baseStyle,
    required this.readingStyle,
    required this.reserveReading,
    required this.readingLineHeight,
  });

  @override
  Widget build(BuildContext context) => _TokenColumn(
        token: token,
        baseStyle: baseStyle,
        readingStyle: readingStyle,
        reserveReading: reserveReading,
        readingLineHeight: readingLineHeight,
      );
}

/// An annotated (and possibly ruby) token: furigana above a highlighted chip,
/// with an overlay tooltip (the translation) anchored above it on tap.
class _AnnotatedToken extends StatefulWidget {
  final SentenceToken token;
  final TextStyle baseStyle;
  final TextStyle readingStyle;
  final bool reserveReading;
  final double readingLineHeight;
  const _AnnotatedToken({
    required this.token,
    required this.baseStyle,
    required this.readingStyle,
    required this.reserveReading,
    required this.readingLineHeight,
  });

  @override
  State<_AnnotatedToken> createState() => _AnnotatedTokenState();
}

class _AnnotatedTokenState extends State<_AnnotatedToken> {
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
              child: _TooltipBubble(text: widget.token.translation ?? ''),
            ),
          ],
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: GestureDetector(
          onTap: _toggle,
          child: _TokenColumn(
            token: widget.token,
            baseStyle: widget.baseStyle,
            readingStyle: widget.readingStyle,
            reserveReading: widget.reserveReading,
            readingLineHeight: widget.readingLineHeight,
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
                widget.token.text,
                style: widget.baseStyle.copyWith(
                  color: showing ? PolyColors.annoActiveText : Colors.white,
                  height: 1.0,
                  shadows: const [],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small white bubble shown above a tapped annotated word: the translation
/// text with a little downward-pointing tail.
class _TooltipBubble extends StatelessWidget {
  final String text;
  const _TooltipBubble({required this.text});

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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
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
