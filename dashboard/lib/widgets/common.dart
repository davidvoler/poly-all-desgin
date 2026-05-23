import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Frosted-glass surface — the `.glass` class from the CSS prototype.
/// Adds a backdrop blur, white-6 fill, and a hairline white-14 border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = DashRadii.card,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: DashColors.w(0.06),
            borderRadius: radius,
            border: Border.all(color: DashColors.w(0.14)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Solid-white primary CTA pill — `.btn.btn-primary` in CSS.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? leading;
  final VoidCallback? onTap;
  const PrimaryButton({
    super.key,
    required this.label,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 14, color: DashColors.brand),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.26,
                  color: DashColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent ghost pill — `.btn.btn-ghost` in CSS. Used for "Add
/// language", "Invite editor", etc.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData? leading;
  final VoidCallback? onTap;
  const GhostButton({
    super.key,
    required this.label,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashColors.w(0.08),
      shape: StadiumBorder(side: BorderSide(color: DashColors.w(0.18))),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 14, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.26,
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

/// 36×36 circular icon button — `.icon-btn` in CSS.
class DashIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;
  final double size;
  const DashIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onTap,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: DashColors.w(0.08),
      shape: CircleBorder(side: BorderSide(color: DashColors.w(0.18))),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

/// Color schemes for the small letter-avatars used in tables. Keys
/// mirror the CSS `.avatar.a` … `.avatar.h` gradients.
class AvatarGradients {
  static const Map<String, List<Color>> _map = {
    'lh': [Color(0xFFFFCC80), Color(0xFFEF5350)],
    'a': [Color(0xFF66BB6A), Color(0xFF1565C0)],
    'b': [Color(0xFFBA68C8), Color(0xFF1E88E5)],
    'c': [Color(0xFFFFA726), Color(0xFFD84315)],
    'd': [Color(0xFF26C6DA), Color(0xFF1565C0)],
    'e': [Color(0xFFEF5350), Color(0xFF1E88E5)],
    'f': [Color(0xFF9CCC65), Color(0xFF2E7D32)],
    'g': [Color(0xFF7E57C2), Color(0xFF283593)],
    'h': [Color(0xFFEC407A), Color(0xFF6A1B9A)],
    'i': [Color(0xFF29B6F6), Color(0xFF00838F)],
  };
  static List<Color> of(String key) =>
      _map[key] ?? const [Color(0xFF1E88E5), Color(0xFF0D47A1)];
}

/// 28×28 letter-avatar with a 2-color gradient.
class LetterAvatar extends StatelessWidget {
  final String label;
  final String gradientKey;
  final double size;
  const LetterAvatar({
    super.key,
    required this.label,
    required this.gradientKey,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AvatarGradients.of(gradientKey);
    final isLh = gradientKey == 'lh';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isLh ? const Color(0xFF2E1100) : Colors.white,
        ),
      ),
    );
  }
}

/// Status / access pill used in tables and overview. The `kind`
/// controls the colour scheme.
enum PillKind { neutral, active, draft, error, muted, public, members, white }

class StatusPill extends StatelessWidget {
  final String label;
  final PillKind kind;
  final IconData? leading;
  final bool swatch;
  const StatusPill({
    super.key,
    required this.label,
    this.kind = PillKind.neutral,
    this.leading,
    this.swatch = false,
  });

  ({Color fill, Color border, Color text, Color swatchColor}) _palette() {
    switch (kind) {
      case PillKind.active:
        return (
          fill: DashColors.green500.withValues(alpha: 0.18),
          border: DashColors.green500.withValues(alpha: 0.45),
          text: Colors.white,
          swatchColor: DashColors.green500,
        );
      case PillKind.draft:
        return (
          fill: DashColors.orange300.withValues(alpha: 0.18),
          border: DashColors.orange300.withValues(alpha: 0.45),
          text: Colors.white,
          swatchColor: DashColors.orange300,
        );
      case PillKind.error:
        return (
          fill: DashColors.red400.withValues(alpha: 0.18),
          border: DashColors.red400.withValues(alpha: 0.45),
          text: Colors.white,
          swatchColor: DashColors.red400,
        );
      case PillKind.muted:
        return (
          fill: DashColors.w(0.08),
          border: DashColors.w(0.18),
          text: DashColors.w(0.55),
          swatchColor: DashColors.w(0.55),
        );
      case PillKind.public:
        return (
          fill: const Color(0xFF26C6DA).withValues(alpha: 0.16),
          border: const Color(0xFF26C6DA).withValues(alpha: 0.45),
          text: const Color(0xFFB2EBF2),
          swatchColor: const Color(0xFF26C6DA),
        );
      case PillKind.members:
        return (
          fill: DashColors.w(0.04),
          border: DashColors.w(0.14),
          text: DashColors.w(0.55),
          swatchColor: DashColors.w(0.55),
        );
      case PillKind.white:
        return (
          fill: DashColors.w(0.08),
          border: DashColors.w(0.18),
          text: Colors.white,
          swatchColor: Colors.white,
        );
      case PillKind.neutral:
        return (
          fill: DashColors.w(0.08),
          border: DashColors.w(0.18),
          text: Colors.white,
          swatchColor: DashColors.w(0.55),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.fill,
        borderRadius: DashRadii.pill,
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatch) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.swatchColor,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (leading != null) ...[
            Icon(leading, size: 11, color: p.text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06,
              color: p.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin progress bar (100×6) used inside table rows.
class TableProgressBar extends StatelessWidget {
  final double value;
  const TableProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 6,
      decoration: BoxDecoration(
        color: DashColors.w(0.08),
        borderRadius: DashRadii.pill,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: DashRadii.pill,
            ),
          ),
        ),
      ),
    );
  }
}

/// Streak chip in the top bar — pulsing orange dot + n-day-streak label.
class StreakChip extends StatelessWidget {
  final int days;
  const StreakChip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DashColors.w(0.08),
        borderRadius: DashRadii.pill,
        border: Border.all(color: DashColors.w(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DashColors.orange300,
              boxShadow: [
                BoxShadow(
                  color: DashColors.orange300.withValues(alpha: 0.85),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$days day streak',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small caps "section label" used to introduce a content group.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: DashText.sectionLabel());
  }
}
