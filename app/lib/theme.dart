import 'package:flutter/material.dart';

/// Polyglots design tokens — colors and gradients pulled from
/// /step-7 (HTML/CSS reference).
class PolyColors {
  static const Color brandPrimary = Color(0xFF1E88E5); // blue-600
  static const Color blue700 = Color(0xFF1976D2);
  static const Color blue800 = Color(0xFF1565C0);
  static const Color blue900 = Color(0xFF0D47A1);
  static const Color darkBg = Color(0xFF0C0F1A);

  static const Color orange300 = Color(0xFFFFB74D);
  static const Color orange200 = Color(0xFFFFCC80);

  static const Color green500 = Color(0xFF4CAF50);
  static const Color red400 = Color(0xFFEF5350);

  static const Color annoActiveText = Color(0xFF5A2A00);

  static Color white(double opacity) => Colors.white.withValues(alpha: opacity);
}

class PolyGradients {
  // Approximation of:
  //   radial-gradient(140% 80% at 50% 100%, #1E88E5 0%, #1565C0 25%, #0D47A1 55%, #0c0f1a 100%)
  static const RadialGradient phoneBackground = RadialGradient(
    center: Alignment(0, 1),
    radius: 1.4,
    colors: [
      PolyColors.brandPrimary,
      PolyColors.blue800,
      PolyColors.blue900,
      PolyColors.darkBg,
    ],
    stops: [0.0, 0.25, 0.55, 1.0],
  );
}

class PolyText {
  // Small all-caps section labels — "— Your Vocabulary —" style
  static TextStyle sectionLabel({Color? color}) => TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: color ?? PolyColors.white(0.55),
      );

  // Pair-label rows: "I SPEAK", "LEARNING"
  static TextStyle smallCaps({Color? color, double size = 10}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * 0.18,
        color: color ?? PolyColors.white(0.55),
      );

  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.22,
    color: Colors.white,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.16,
    color: Colors.white,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle body = TextStyle(
    fontSize: 12,
    color: Colors.white,
  );
}

class PolyRadii {
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
  static const BorderRadius card = BorderRadius.all(Radius.circular(16));
  static const BorderRadius cardSm = BorderRadius.all(Radius.circular(12));
}
