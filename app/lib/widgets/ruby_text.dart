import 'package:flutter/widgets.dart';

/// One run of base text with an optional reading ("ruby") rendered above
/// it. For Japanese this is furigana over kanji; [reading] is null/empty
/// for kana or punctuation that needs no annotation.
class RubySegment {
  final String base;
  final String? reading;
  const RubySegment(this.base, [this.reading]);

  bool get hasReading => reading != null && reading!.isNotEmpty;
}

/// Multiline ruby text — the reading sits in a smaller line directly above
/// each base segment, and the whole thing flows onto multiple lines via a
/// [Wrap]. Implemented in-house (no package) so multiline is guaranteed
/// and the styling matches the app.
///
/// Every segment reserves the reading line's height even when it has no
/// reading, so the base glyphs all sit on the same baseline whether or not
/// they're annotated.
class RubyText extends StatelessWidget {
  final List<RubySegment> segments;
  final TextStyle baseStyle;
  final TextStyle rubyStyle;
  final TextAlign textAlign;
  // Horizontal gap between adjacent segments and vertical gap between
  // wrapped lines.
  final double spacing;
  final double runSpacing;

  const RubyText(
    this.segments, {
    super.key,
    required this.baseStyle,
    required this.rubyStyle,
    this.textAlign = TextAlign.center,
    this.spacing = 0,
    this.runSpacing = 8,
  });

  WrapAlignment get _alignment {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return WrapAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      default:
        return WrapAlignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rubyFontSize = rubyStyle.fontSize ?? 12;
    final rubyLineHeight = rubyFontSize * (rubyStyle.height ?? 1.2);

    return Wrap(
      alignment: _alignment,
      spacing: spacing,
      runSpacing: runSpacing,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final seg in segments)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: rubyLineHeight,
                child: seg.hasReading
                    ? Text(seg.reading!,
                        style: rubyStyle, textAlign: TextAlign.center)
                    : null,
              ),
              Text(seg.base, style: baseStyle),
            ],
          ),
      ],
    );
  }
}
