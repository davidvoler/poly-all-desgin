import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
import '../api/models.dart';
import '../i18n/translations.g.dart';
import '../state/lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/lang_menu_item.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe so the page rebuilds when the UI lang flips. Slang's `t`
    // global doesn't subscribe via context, so without this watch the
    // hard-coded `t.xxx` reads inside child widgets stick on whatever
    // locale was active when this page was first built.
    ref.watch(uiLangProvider);
    return Scaffold(
      body: PhoneBackground(
        showMosaic: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar — brand + UI language selector + streak
                Row(
                  children: [
                    const BrandWordmark(),
                    const Spacer(),
                    const _UiLangSelector(),
                    const SizedBox(width: 8),
                    StreakChip(text: t.common.streak_days(n: 5)),
                  ],
                ),
                const SizedBox(height: 28),

                // Two distinct tap targets:
                //  • round medallion  → /courses  (pick course/language)
                //  • rect caption     → /course   (open the current course)
                Column(
                  children: [
                    Center(
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pushNamed(context, '/courses'),
                        child: const _Medallion(progress: 0.45),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pushNamed(context, '/course'),
                      child: const _CourseCaption(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats label + glass capsule
                Center(
                  child: Text(
                    t.home.vocabulary_label,
                    style: PolyText.sectionLabel(color: PolyColors.white(0.5)),
                  ),
                ),
                const SizedBox(height: 7),
                Consumer(builder: (context, ref, _) {
                  final stats = ref.watch(userStatsProvider);
                  String v(int Function(UserStats) pick) => stats.maybeWhen(
                        data: (s) => '${pick(s)}',
                        orElse: () => '…',
                      );
                  return GlassCard(
                    child: Row(
                      children: [
                        _StatSeg(value: v((s) => s.words), label: t.home.stat_words),
                        const _StatDivider(),
                        _StatSeg(value: v((s) => s.lessons), label: t.home.stat_lessons),
                        const _StatDivider(),
                        _StatSeg(value: v((s) => s.sentences), label: t.home.stat_sentences),
                      ],
                    ),
                  );
                }),

                const Spacer(),

                // CTA row — Practice Now + settings glass button
                Row(
                  children: [
                    Expanded(
                      child: CtaButton(
                        label: t.home.practice_now,
                        leadingIcon: Icons.play_arrow,
                        onTap: () => Navigator.pushNamed(context, '/quiz'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.tune,
                      tooltip: t.home.settings_tooltip,
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

class _Medallion extends ConsumerWidget {
  final double progress;
  const _Medallion({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speak = ref.watch(speakLangProvider);
    final learning = ref.watch(learningLangProvider);
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
          // Centered identity — flag pair + target's native name come from
          // the speak/learning providers so the medallion reflects the
          // user's actual selection on the courses page.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${speak.flag} → ${learning.flag}',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 3.9,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                learning.native,
                textDirection:
                    learning.rtl ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(
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
                t.home.complete(percent: (progress * 100).round()).toUpperCase(),
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

class _CourseCaption extends ConsumerWidget {
  const _CourseCaption();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve the current course's title from the saved preference +
    // the courses list. Fall back to the translated placeholder while
    // either is still loading or the course isn't in the list.
    final courseId = ref.watch(
      preferenceProvider.select((p) => p.value?.courseId),
    );
    final title = ref.watch(coursesListProvider).maybeWhen(
          data: (courses) {
            for (final c in courses) {
              if (c.id == courseId?.toString()) return c.title;
            }
            return t.home.course_title;
          },
          orElse: () => t.home.course_title,
        );
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
              Text(t.home.course_overline,
                  style: PolyText.smallCaps(size: 9, color: PolyColors.white(0.6))),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                t.home.course_module,
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
                    t.home.tap_to_change,
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

/// Compact UI-language selector for the home top bar. Writes to
/// [speakLangProvider], which already owns the side-effect of flipping
/// slang's UI locale (with English fallback when no bundle exists).
class _UiLangSelector extends ConsumerStatefulWidget {
  const _UiLangSelector();

  @override
  ConsumerState<_UiLangSelector> createState() => _UiLangSelectorState();
}

class _UiLangSelectorState extends ConsumerState<_UiLangSelector> {
  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(uiLangProvider);
    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
            PolyColors.darkBg.withValues(alpha: 0.96)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        )),
        elevation: const WidgetStatePropertyAll(12),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
      ),
      menuChildren: [
        for (final l in Lang.values)
          LanguageMenuItem(
            lang: l,
            selected: l == ui,
            onTap: () {
              _menu.close();
              ref.read(uiLangProvider.notifier).set(l);
            },
          ),
      ],
      builder: (context, controller, child) {
        return Tooltip(
          message: 'UI language',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Material(
                color: Colors.white.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () =>
                      controller.isOpen ? controller.close() : controller.open(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ui.flag,
                            style: const TextStyle(fontSize: 14, height: 1.0)),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: controller.isOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(Icons.expand_more,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
