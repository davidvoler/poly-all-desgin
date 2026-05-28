import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
import '../api/models.dart' as api;
import '../theme.dart';
import '../widgets/auto_text.dart';
import '../widgets/common.dart';

class CoursePage extends ConsumerStatefulWidget {
  const CoursePage({super.key});

  @override
  ConsumerState<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends ConsumerState<CoursePage> {
  // Horizontal scroll controller for the modules strip. Used to align
  // the user's current module into view when the page first paints.
  final ScrollController _modulesCtrl = ScrollController();
  // (courseId, effectiveModuleId) we've already auto-scrolled for, so
  // the strip doesn't re-jump every time the user taps a different
  // module afterwards.
  String? _scrolledKey;

  // Approx per-card extent — matches _ModuleCard's width (168) +
  // separator (10). Kept in one place so the auto-scroll math doesn't
  // drift if the card sizing changes later.
  static const double _moduleCardExtent = 168 + 10;

  @override
  void dispose() {
    _modulesCtrl.dispose();
    super.dispose();
  }

  /// One-shot auto-scroll: bring [index] of the modules strip into
  /// view, scoped to a unique [key] so the same call site only fires
  /// once per (course, effective-module) tuple.
  void _maybeScrollModules(String key, int index) {
    if (_scrolledKey == key) return;
    _scrolledKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_modulesCtrl.hasClients) return;
      final target = (index * _moduleCardExtent).clamp(
        0.0,
        _modulesCtrl.position.maxScrollExtent,
      );
      _modulesCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseId = (ModalRoute.of(context)?.settings.arguments as int?) ?? 1;
    final modulesAsync = ref.watch(modulesProvider(courseId));
    final selectedId = ref.watch(selectedModuleIdProvider);

    // Course title + overline come from the courses list, looked up by
    // id. Empty strings while loading or not found — the rest of the
    // page still renders.
    final course = ref.watch(coursesListProvider).maybeWhen(
      data: (courses) {
        for (final c in courses) {
          if (c.id == courseId.toString()) return c;
        }
        return null;
      },
      orElse: () => null,
    );
    final courseTitle = course?.title ?? '';
    final courseOverline = course == null
        ? ''
        : '${course.targetLang.englishName} · ${course.targetLang.native}';

    // Effective module id once modules load: explicit selection wins,
    // otherwise the user's current_module from the courses summary,
    // otherwise the first module so lessons still render.
    int? effectiveModuleId(List<api.Module> modules) {
      if (modules.isEmpty) return null;
      if (selectedId != null && modules.any((m) => m.id == selectedId)) {
        return selectedId;
      }
      final cur = course?.currentModuleId;
      if (cur != null && modules.any((m) => m.id == cur)) {
        return cur;
      }
      return modules.first.id;
    }
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
                      child: Center(
                        child: TitleBlock(
                          overline: courseOverline,
                          title: courseTitle,
                        ),
                      ),
                    ),
                    const StreakChip(text: '5'),
                  ],
                ),
                const SizedBox(height: 18),

                // Hero — compact progress strip, driven by the course
                // summary so the figures match the courses list card.
                _CourseProgressHero(course: course),
                const SizedBox(height: 14),

                // Section row — Modules
                Row(
                  children: [
                    Text('Modules',
                        style: PolyText.sectionLabel(color: PolyColors.white(0.6))),
                    const Spacer(),
                    Text(
                      modulesAsync.maybeWhen(
                        data: (ms) => '${ms.length} modules · scroll for more',
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
                ),
                const SizedBox(height: 6),

                // Modules — horizontal scroll, fixed height
                SizedBox(
                  height: 92,
                  child: modulesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        "Couldn't load modules\n$err",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    data: (modules) {
                      final effId = effectiveModuleId(modules);
                      final effIdx = effId == null
                          ? -1
                          : modules.indexWhere((m) => m.id == effId);
                      if (effIdx >= 0) {
                        _maybeScrollModules('$courseId:$effId', effIdx);
                      }
                      return ListView.separated(
                        controller: _modulesCtrl,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: modules.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => _ModuleCard(
                          module: _infoFromServer(modules, i, effId),
                          onTap: () => ref
                              .read(selectedModuleIdProvider.notifier)
                              .set(modules[i].id, name: modules[i].title),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Section row — Lessons (reflects the selected module)
                Row(
                  children: [
                    Text(
                      modulesAsync.maybeWhen(
                        data: (modules) {
                          final id = effectiveModuleId(modules);
                          if (id == null) return 'Lessons';
                          final m = modules.firstWhere((x) => x.id == id);
                          return 'Lessons in ${m.title}';
                        },
                        orElse: () => 'Lessons',
                      ),
                      style: PolyText.sectionLabel(color: PolyColors.white(0.6)),
                    ),
                    const Spacer(),
                    Text(
                      'scroll for more',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Lessons — vertical scroll, fetched per-module
                Expanded(
                  child: modulesAsync.maybeWhen(
                    data: (modules) {
                      final id = effectiveModuleId(modules);
                      if (id == null) return const SizedBox.shrink();
                      final module = modules.firstWhere((m) => m.id == id);
                      return _LessonsSection(
                        moduleId: id,
                        moduleName: module.title,
                        currentLessonId: course?.currentLessonId,
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),

                const SizedBox(height: 14),

                CtaButton(
                  label: 'Continue Lesson',
                  leadingIcon: Icons.play_arrow,
                  onTap: () => Navigator.pushNamed(context, '/quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact "X% · L of N lessons · avg Y" strip driven by the courses
/// summary. Falls back to dashes while the courses list is still
/// loading or the course id couldn't be matched.
class _CourseProgressHero extends StatelessWidget {
  final api.CourseSummary? course;
  const _CourseProgressHero({required this.course});

  @override
  Widget build(BuildContext context) {
    final progress = course?.progress;
    final lessonCount = course?.lessonCount ?? 0;
    final lessonsDone = course?.lessonsDone ?? 0;
    final avgScore = course?.avgScore ?? 0.0;
    final pct = progress == null ? '–' : '${(progress * 100).round()}';
    final lessonsLine = course == null
        ? 'Loading…'
        : '$lessonsDone of $lessonCount lessons'
            '${avgScore > 0 ? '\navg score ${avgScore.toStringAsFixed(2)}' : ''}';
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      borderRadius: PolyRadii.cardSm,
      blur: 20,
      child: Row(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                pct,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.36,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lessonsLine,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PolyProgressBar(value: progress ?? 0.0, height: 5),
          ),
        ],
      ),
    );
  }
}

enum _ModuleState { done, selected, locked }

class _ModuleInfo {
  final String number;
  final String name;
  final double progress;
  final String pct;
  final _ModuleState state;
  const _ModuleInfo({
    required this.number,
    required this.name,
    required this.progress,
    required this.pct,
    required this.state,
  });
}

/// Bridge the server's [Module] to the row widget's view model. State:
/// done if the server flag is set; selected if its id matches the
/// effective open-module id; locked otherwise.
_ModuleInfo _infoFromServer(List<api.Module> modules, int i, int? effId) {
  final m = modules[i];
  final state = m.completed
      ? _ModuleState.done
      : (m.id == effId ? _ModuleState.selected : _ModuleState.locked);
  return _ModuleInfo(
    number: '${i + 1}',
    name: m.title,
    progress: m.completed ? 1.0 : 0.0,
    pct: m.completed ? '✓' : '–',
    state: state,
  );
}

class _ModuleCard extends StatelessWidget {
  final _ModuleInfo module;
  final VoidCallback onTap;
  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = module.state == _ModuleState.selected;

    return Material(
      color: Colors.white.withValues(alpha: selected ? 0.16 : 0.05),
      borderRadius: PolyRadii.cardSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: PolyRadii.cardSm,
        child: Container(
          width: 168,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: PolyRadii.cardSm,
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.32 : 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _ModuleNum(state: module.state, number: module.number),
                  const Spacer(),
                  Icon(
                    selected ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: Colors.white.withValues(alpha: selected ? 1.0 : 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                module.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: PolyProgressBar(value: module.progress, height: 3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    module.pct,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.65),
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

class _ModuleNum extends StatelessWidget {
  final _ModuleState state;
  final String number;
  const _ModuleNum({required this.state, required this.number});

  @override
  Widget build(BuildContext context) {
    if (state == _ModuleState.done) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: PolyColors.green500,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }
    final selected = state == _ModuleState.selected;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? PolyColors.brandPrimary : Colors.white,
        ),
      ),
    );
  }
}

class _LessonInfo {
  final int id;
  final String num;
  final String jp;
  final String en;
  final bool done;
  final bool selected;
  final String? route;
  // Stats from user_data.lesson_status — null when the user has
  // never attempted this lesson, so the card can hide the stats row
  // for fresh lessons instead of showing "Best 0.00 · 0 attempts".
  final double? bestScore;
  final int attempts;
  const _LessonInfo({
    required this.id,
    required this.num,
    required this.jp,
    required this.en,
    required this.done,
    required this.selected,
    this.route,
    this.bestScore,
    this.attempts = 0,
  });
}

/// Lessons strip for the currently-open module. Pulled lazily so it
/// only fetches when the user actually scrolls the module into view.
class _LessonsSection extends ConsumerStatefulWidget {
  final int moduleId;
  final String moduleName;
  // Server's `current_lesson` from the courses summary. When the
  // module being shown contains this id, that lesson wins the
  // "selected" highlight over the first-undone fallback.
  final int? currentLessonId;
  const _LessonsSection({
    required this.moduleId,
    required this.moduleName,
    this.currentLessonId,
  });

  @override
  ConsumerState<_LessonsSection> createState() => _LessonsSectionState();
}

class _LessonsSectionState extends ConsumerState<_LessonsSection> {
  final ScrollController _ctrl = ScrollController();
  // (moduleId, effectiveLessonId) we've already auto-scrolled to so the
  // list doesn't jump around as the user scrolls manually.
  String? _scrolledKey;

  // Approx lesson-card height including the 8px separator. Two text
  // rows (≈80px); slightly taller (~96px) when the "Best / attempts"
  // stats row appears. The middle of that range is good enough for a
  // one-shot scroll-into-view.
  static const double _rowExtent = 88;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _maybeScrollLessons(String key, int index) {
    if (_scrolledKey == key) return;
    _scrolledKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_ctrl.hasClients) return;
      final target = (index * _rowExtent).clamp(
        0.0,
        _ctrl.position.maxScrollExtent,
      );
      _ctrl.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsProvider(widget.moduleId));
    return lessonsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (err, _) => Center(
        child: Text(
          "Couldn't load lessons",
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
      data: (lessons) {
        // If the server's current_lesson lives in this module, use it;
        // otherwise fall back to the first-undone heuristic.
        final selectedIdx = widget.currentLessonId != null
            ? lessons.indexWhere((x) => x.id == widget.currentLessonId)
            : -1;
        final fallbackIdx = lessons.indexWhere((x) => !x.completed);
        final effectiveSelectedIdx =
            selectedIdx >= 0 ? selectedIdx : fallbackIdx;
        if (effectiveSelectedIdx >= 0) {
          _maybeScrollLessons(
            '${widget.moduleId}:${widget.currentLessonId ?? "auto"}',
            effectiveSelectedIdx,
          );
        }
        return ListView.separated(
          controller: _ctrl,
          padding: EdgeInsets.zero,
          itemCount: lessons.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final lesson = lessons[i];
            final info =
                _lessonInfoFromServer(lessons, i, effectiveSelectedIdx);
            return _LessonCard(
              lesson: info,
              onTap: info.route == null
                  ? null
                  : () {
                      // Persist the full lesson-start tuple so the home
                      // page can render course/module/lesson labels
                      // without re-resolving them from /lessons.
                      ref.read(preferenceProvider.notifier).save(
                            moduleId: widget.moduleId,
                            moduleName: widget.moduleName,
                            lessonId: info.id,
                            lessonName: lesson.title.isNotEmpty
                                ? lesson.title
                                : info.jp,
                          );
                      Navigator.pushNamed(context, info.route!,
                          arguments: info.id);
                    },
            );
          },
        );
      },
    );
  }
}

/// Bridge server [Lesson] → row view model. The server's `title` is
/// just `lesson <id>` today, so we surface the first word as the main
/// label and the rest as the secondary line; falls back to title if
/// the words list is empty.
_LessonInfo _lessonInfoFromServer(
    List<api.Lesson> lessons, int i, int selectedIdx) {
  final l = lessons[i];
  final native = l.words.isNotEmpty ? l.words.first : l.title;
  final translation =
      l.words.length > 1 ? l.words.skip(1).join(' · ') : l.description;
  return _LessonInfo(
    id: l.id,
    num: 'L${i + 1}',
    jp: native,
    en: translation,
    done: l.completed,
    selected: !l.completed && i == selectedIdx,
    route: '/quiz',
    bestScore: l.hasAttempted ? l.maxScore : null,
    attempts: l.numAttempts,
  );
}

class _LessonCard extends StatelessWidget {
  final _LessonInfo lesson;
  final VoidCallback? onTap;
  const _LessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = lesson.selected;
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        offset: const Offset(0, 8),
                        blurRadius: 20),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lesson.num,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: selected
                            ? PolyColors.blue900.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AutoText(
                      lesson.jp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? PolyColors.brandPrimary : Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AutoText(
                      lesson.en,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? Colors.grey.shade700
                            : Colors.white.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ),
                    if (lesson.bestScore != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Best ${lesson.bestScore!.toStringAsFixed(2)}'
                        ' · ${lesson.attempts}'
                        ' ${lesson.attempts == 1 ? "attempt" : "attempts"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: selected
                              ? Colors.grey.shade600
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _LessonBadge(done: lesson.done, selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonBadge extends StatelessWidget {
  final bool done;
  final bool selected;
  const _LessonBadge({required this.done, required this.selected});
  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: PolyColors.green500,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    if (selected) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: PolyColors.brandPrimary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.play_arrow, size: 14, color: Colors.white),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
    );
  }
}
