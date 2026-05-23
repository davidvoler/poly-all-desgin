import 'package:flutter/material.dart';

/// Design tokens for the school-admin dashboard. Mirrors the CSS custom
/// properties in design_experiments/school_dashboard/assets/app.css so
/// the Flutter port stays visually 1:1 with the HTML prototype.
class DashColors {
  static const Color brand = Color(0xFF1E88E5);
  static const Color blue700 = Color(0xFF1976D2);
  static const Color blue800 = Color(0xFF1565C0);
  static const Color blue900 = Color(0xFF0D47A1);
  static const Color darkBg = Color(0xFF0C0F1A);

  static const Color orange300 = Color(0xFFFFB74D);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color red400 = Color(0xFFEF5350);
  static const Color cyan = Color(0xFF26C6DA);

  /// Translucent white at the given opacity (matches --w-* tokens).
  static Color w(double opacity) => Colors.white.withValues(alpha: opacity);
}

class DashRadii {
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
  static const BorderRadius card = BorderRadius.all(Radius.circular(16));
  static const BorderRadius cardSm = BorderRadius.all(Radius.circular(12));
  static const BorderRadius input = BorderRadius.all(Radius.circular(10));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(10));
}

class DashText {
  /// Small-caps section label — used above grouped content & under stats.
  static TextStyle sectionLabel({double size = 11, Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
        color: color ?? DashColors.w(0.55),
      );

  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.22,
    color: Colors.white,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.14,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: Colors.white,
    height: 1.1,
  );

  static TextStyle subtitle = TextStyle(
    fontSize: 13,
    color: DashColors.w(0.70),
  );
}

/// The school-dashboard background gradient — same radial shape as the
/// phone app, scaled to a desktop viewport.
const Decoration kDashBackground = BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(0.0, 1.0),
    radius: 1.2,
    colors: [
      DashColors.brand,
      DashColors.blue800,
      DashColors.blue900,
      DashColors.darkBg,
    ],
    stops: [0.0, 0.25, 0.55, 1.0],
  ),
);
