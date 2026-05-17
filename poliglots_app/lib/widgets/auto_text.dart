import 'package:flutter/widgets.dart';

/// Strong-RTL Unicode blocks: Hebrew, Arabic, Arabic Supplement,
/// Thaana, NKo, Arabic Presentation Forms A & B.
final RegExp _rtl = RegExp(
  r'[֐-׿؀-ۿ܀-ݏݐ-ݿހ-޿'
  r'߀-߿ࢠ-ࣿיִ-﷿ﹰ-﻿]',
);

/// Strong-LTR letters (Latin, incl. extended).
final RegExp _ltr = RegExp(r'[A-Za-zÀ-ɏ]');

/// Base text direction inferred from the first *strong* directional
/// character (the Unicode bidi heuristic). Digits/punctuation/spaces
/// are neutral and skipped; falls back to LTR when there's no strong
/// character. This is what decides where a trailing `.` lands.
TextDirection directionOf(String text) {
  for (final ch in text.characters) {
    if (_rtl.hasMatch(ch)) return TextDirection.rtl;
    if (_ltr.hasMatch(ch)) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}

/// Drop-in [Text] that picks its base direction from its own content,
/// so Arabic/Hebrew render correctly (punctuation on the right) even
/// inside an LTR UI, and vice-versa.
class AutoText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AutoText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: directionOf(data),
    );
  }
}
