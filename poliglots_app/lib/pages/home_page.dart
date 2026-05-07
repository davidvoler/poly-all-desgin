import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhoneBackground(
        showMosaic: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar — brand + streak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    BrandWordmark(),
                    StreakChip(),
                  ],
                ),
                const SizedBox(height: 28),

                // Tappable course block (medallion + caption)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pushNamed(context, '/courses'),
                  child: Column(
                    children: const [
                      _Medallion(progress: 0.45),
                      SizedBox(height: 16),
                      _CourseCaption(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stats label + glass capsule
                Center(
                  child: Text(
                    '— Your Vocabulary —',
                    style: PolyText.sectionLabel(color: PolyColors.white(0.5)),
                  ),
                ),
                const SizedBox(height: 7),
                GlassCard(
                  child: Row(
                    children: const [
                      _StatSeg(value: '248', label: 'Words'),
                      _StatDivider(),
                      _StatSeg(value: '12', label: 'Lessons'),
                      _StatDivider(),
                      _StatSeg(value: '86', label: 'Sentences'),
                    ],
                  ),
                ),

                const Spacer(),

                // CTA row — Practice Now + settings glass button
                Row(
                  children: [
                    Expanded(
                      child: CtaButton(
                        label: 'Practice Now',
                        leadingIcon: Icons.play_arrow,
                        onTap: () => Navigator.pushNamed(context, '/quiz'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.tune,
                      tooltip: 'Settings',
                      iconSize: 18,
                      size: 40,
                      onTap: () => Navigator.pushNamed(context, '/courses'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  final double progress;
  const _Medallion({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow halo
          Container(
            width: 188,
            height: 188,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // Frosted disc inside the ring
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
              ),
            ),
          ),
          // Track + progress ring
          SizedBox(
            width: 168,
            height: 168,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Centered identity
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🇺🇸 → 🇯🇵',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 3.9,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                '日本語',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.88,
                  shadows: [
                    Shadow(blurRadius: 18, color: Colors.black54, offset: Offset(0, 4)),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${(progress * 100).round()}% COMPLETE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseCaption extends StatelessWidget {
  const _CourseCaption();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Japanese · Nihongo',
                  style: PolyText.smallCaps(size: 9, color: PolyColors.white(0.6))),
              const SizedBox(height: 5),
              const Text(
                'Japanese for Beginners',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.16,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black38, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Module 3 · Greetings & Introductions',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune,
                      size: 12, color: Colors.white.withValues(alpha: 0.55)),
                  const SizedBox(width: 3),
                  Text(
                    'TAP TO CHANGE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.44,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatSeg extends StatelessWidget {
  final String value;
  final String label;
  const _StatSeg({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.36,
                )),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.08,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}
