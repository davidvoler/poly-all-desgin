import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
import '../api/models.dart';
import '../state/lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/lang_menu_item.dart';

/// Map server-side icon names → Flutter [IconData]. The server sends the
/// Material name (e.g. `"play_arrow"`) so the API stays platform-neutral.
const Map<String, IconData> _icons = {
  'play_arrow': Icons.play_arrow,
  'flight_takeoff': Icons.flight_takeoff,
  'menu_book': Icons.menu_book,
  'work': Icons.work,
  'forum': Icons.forum,
  'school': Icons.school,
};
IconData _iconFromName(String name) => _icons[name] ?? Icons.school;

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speak = ref.watch(speakLangProvider);
    final learning = ref.watch(learningLangProvider);
    return Scaffold(
      body: PhoneBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: const Center(
                        child: TitleBlock(overline: 'Set up', title: 'Languages & Courses'),
                      ),
                    ),
                    const StreakChip(text: '5'),
                  ],
                ),
                const SizedBox(height: 18),

                // Two compact pickers with swap arrow between
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _Picker(
                        label: 'I speak',
                        lang: speak,
                        sub: 'Native',
                        onChanged: (l) =>
                            ref.read(speakLangProvider.notifier).set(l),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: _ArrowCell(),
                    ),
                    Expanded(
                      child: _Picker(
                        label: 'Learning',
                        lang: learning,
                        sub: learning.englishName,
                        onChanged: (l) =>
                            ref.read(learningLangProvider.notifier).set(l),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Hairline divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Section row
                Consumer(builder: (context, ref, _) {
                  final coursesAsync = ref.watch(coursesListProvider);
                  return Row(
                    children: [
                      Text('Pick a course',
                          style: PolyText.sectionLabel(color: PolyColors.white(0.6))),
                      const Spacer(),
                      Text(
                        coursesAsync.maybeWhen(
                          data: (cs) => '${cs.length} available',
                          orElse: () => '…',
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),

                // Course list — pulled from /courses
                Expanded(
                  child: Consumer(builder: (context, ref, _) {
                    final coursesAsync = ref.watch(coursesListProvider);
                    return coursesAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (err, _) => _CoursesError(
                        error: err,
                        onRetry: () => ref.invalidate(coursesListProvider),
                      ),
                      data: (courses) => ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: courses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                        final c = courses[i];
                        return _CourseCard(
                          course: c,
                          onTap: () {
                            final id = int.parse(c.id);
                            ref
                                .read(preferenceProvider.notifier)
                                .save(courseId: id);
                            Navigator.pushNamed(context, '/course',
                                arguments: id);
                          },
                        );
                      },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Picker extends StatefulWidget {
  final String label;
  final Lang lang;
  final String sub;
  final ValueChanged<Lang> onChanged;
  const _Picker({
    required this.label,
    required this.lang,
    required this.sub,
    required this.onChanged,
  });

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(widget.label, style: PolyText.smallCaps(size: 9)),
        ),
        MenuAnchor(
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
                selected: l == widget.lang,
                onTap: () {
                  _menu.close();
                  widget.onChanged(l);
                },
              ),
          ],
          builder: (context, controller, child) {
            return ClipRRect(
              borderRadius: PolyRadii.pill,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: PolyRadii.pill,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: InkWell(
                    onTap: () =>
                        controller.isOpen ? controller.close() : controller.open(),
                    borderRadius: PolyRadii.pill,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          _FlagPill(flag: widget.lang.flag),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.lang.native,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: widget.lang.rtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.13,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  widget.sub.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.54,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: controller.isOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Icon(Icons.expand_more,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FlagPill extends StatelessWidget {
  final String flag;
  const _FlagPill({required this.flag});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(flag, style: const TextStyle(fontSize: 16, height: 1.0)),
    );
  }
}

class _ArrowCell extends StatelessWidget {
  const _ArrowCell();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: PolyColors.blue900.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, offset: Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseSummary course;
  final VoidCallback onTap;
  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = course.inProgress;
    return Material(
      color: Colors.white.withValues(alpha: active ? 0.14 : 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: active ? 0.30 : 0.14),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        offset: const Offset(0, 8),
                        blurRadius: 24),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(
                      _iconFromName(course.icon),
                      size: 18,
                      color: active ? PolyColors.brandPrimary : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _LevelPill(text: course.levelPill, inProgress: course.inProgress),
                ],
              ),
              if (course.footer != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (course.progress != null) ...[
                      Expanded(
                        child: PolyProgressBar(
                            value: course.progress!, height: 4),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (course.progress == null)
                      Expanded(
                        child: Text(
                          course.footer!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: active ? 0.9 : 0.7),
                          ),
                        ),
                      )
                    else
                      Text(
                        course.footer!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: active ? 0.9 : 0.7),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline error view shown when the courses fetch fails — keeps the
/// surrounding chrome (top bar, pickers) visible and offers a retry.
class _CoursesError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _CoursesError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 36, color: Colors.white.withValues(alpha: 0.55)),
            const SizedBox(height: 10),
            Text(
              "Couldn't load courses",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            CtaButton(
              label: 'Retry',
              leadingIcon: Icons.refresh,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final String text;
  final bool inProgress;
  const _LevelPill({required this.text, required this.inProgress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: inProgress
            ? PolyColors.orange300
            : Colors.white.withValues(alpha: 0.10),
        border: Border.all(
            color: inProgress
                ? PolyColors.orange300
                : Colors.white.withValues(alpha: 0.16)),
        borderRadius: PolyRadii.pill,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.26,
          color: inProgress ? PolyColors.annoActiveText : Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

