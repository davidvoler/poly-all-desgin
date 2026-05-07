import 'dart:ui';

import 'package:flutter/material.dart';

import '../i18n/translations.g.dart';
import '../theme.dart';

/// Phone-style background — the deep blue radial gradient used across
/// every page. Includes the optional Japanese-word mosaic that sits
/// behind the home page only.
class PhoneBackground extends StatelessWidget {
  final Widget child;
  final bool showMosaic;
  const PhoneBackground({super.key, required this.child, this.showMosaic = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: PolyGradients.phoneBackground),
      child: Stack(
        children: [
          if (showMosaic) const Positioned.fill(child: _Mosaic()),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Mosaic extends StatelessWidget {
  const _Mosaic();

  static const _words = <_MosaicWord>[
    _MosaicWord('こんにちは', top: 0.04, left: -0.02, size: 45, opacity: 0.14),
    _MosaicWord('ありがとう', top: 0.08, right: 0.06, size: 20, opacity: 0.34, rotateDeg: -2),
    _MosaicWord('日本',     top: 0.17, left: 0.08, size: 25, opacity: 0.22),
    _MosaicWord('学校',     top: 0.24, right: -0.04, size: 62, opacity: 0.10),
    _MosaicWord('すみません', top: 0.31, left: 0.04, size: 15, opacity: 0.50),
    _MosaicWord('食べる',    top: 0.36, right: 0.12, size: 21, opacity: 0.26),
    _MosaicWord('本',       top: 0.44, left: -0.03, size: 77, opacity: 0.09),
    _MosaicWord('先生',     top: 0.56, right: 0.04, size: 27, opacity: 0.24),
    _MosaicWord('はじめまして', top: 0.65, left: 0.10, size: 18, opacity: 0.46),
    _MosaicWord('水',       top: 0.72, right: 0.08, size: 49, opacity: 0.13),
    _MosaicWord('友達',     top: 0.80, left: 0.04, size: 24, opacity: 0.32),
    _MosaicWord('おはよう',  top: 0.88, right: 0.14, size: 17, opacity: 0.54),
    _MosaicWord('学',       top: 0.92, left: 0.16, size: 39, opacity: 0.13),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            for (final word in _words)
              Positioned(
                top: word.top * h,
                left: word.left == null ? null : word.left! * w,
                right: word.right == null ? null : word.right! * w,
                child: Transform.rotate(
                  angle: word.rotateDeg * 3.1415927 / 180.0,
                  child: Opacity(
                    opacity: word.opacity,
                    child: Text(
                      word.text,
                      style: TextStyle(
                        fontSize: word.size,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -word.size * 0.02,
                      ),
                    ),
                  ),
                ),
              ),
            // Vertical scrim — keeps top + bottom legible
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        PolyColors.blue900.withValues(alpha: 0.18),
                        PolyColors.blue900.withValues(alpha: 0.05),
                        PolyColors.blue900.withValues(alpha: 0.18),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MosaicWord {
  final String text;
  final double top;
  final double? left;
  final double? right;
  final double size;
  final double opacity;
  final double rotateDeg;
  const _MosaicWord(this.text,
      {required this.top,
      this.left,
      this.right,
      required this.size,
      required this.opacity,
      this.rotateDeg = 0});
}

/// Frosted-glass surface — translucent white with a 1px white border.
/// `BackdropFilter` works only when there's something behind it, but
/// keeping it on every page keeps the visual language consistent.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final double fillOpacity;
  final double borderOpacity;
  final double blur;
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = PolyRadii.card,
    this.fillOpacity = 0.06,
    this.borderOpacity = 0.14,
    this.blur = 28,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: fillOpacity),
            border: Border.all(color: Colors.white.withValues(alpha: borderOpacity)),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 36×36 glass round icon button. Used in the top bar (back, close, tune).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool enabled;
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 36,
    this.iconSize = 18,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: enabled ? 0.08 : 0.04),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18), width: 1),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.35)),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// "5 day streak" pill in the top-right.
class StreakChip extends StatelessWidget {
  final String text;
  const StreakChip({super.key, this.text = '5 day streak'});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: PolyRadii.pill,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: PolyRadii.pill,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: PolyColors.orange300,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: PolyColors.orange300.withValues(alpha: 0.85),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
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

/// Thin white-on-translucent progress strip.
class PolyProgressBar extends StatelessWidget {
  final double value; // 0..1
  final double height;
  const PolyProgressBar({super.key, required this.value, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: PolyRadii.pill,
        child: Stack(
          children: [
            Container(color: Colors.white.withValues(alpha: 0.12)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1).toDouble(),
              child: Container(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary white-pill CTA — "Practice Now", "Continue Lesson", etc.
class CtaButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  const CtaButton({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: PolyRadii.pill,
      shadowColor: Colors.black.withValues(alpha: 0.30),
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18, color: PolyColors.brandPrimary),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.26,
                  color: PolyColors.brandPrimary,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 7),
                Icon(trailingIcon, size: 18, color: PolyColors.brandPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard top-bar layout: optional leading icon-button, centered
/// title block, trailing slot (often the streak chip or another button).
class TopBar extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final EdgeInsets padding;
  const TopBar({
    super.key,
    this.leading,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 18),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 36, child: leading),
          if (title != null) Expanded(child: Center(child: title!)) else const Spacer(),
          SizedBox(child: trailing ?? const SizedBox(width: 36)),
        ],
      ),
    );
  }
}

/// "Japanese · Nihongo" small-cap subtitle + h1 title used in many top bars.
class TitleBlock extends StatelessWidget {
  final String overline;
  final String title;
  const TitleBlock({super.key, required this.overline, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(overline, style: PolyText.smallCaps(size: 9)),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// "polyglots" wordmark used at top of home. Pulled from i18n so the brand
/// can be transliterated for non-Latin locales if ever needed.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});
  @override
  Widget build(BuildContext context) {
    return Text(
      t.brand,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.76,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}
