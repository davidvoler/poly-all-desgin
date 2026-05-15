import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/courses_api.dart';
import '../api/models.dart' as api;
import '../theme.dart';
import '../widgets/common.dart';

class CoursePage extends ConsumerWidget {
  const CoursePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseId = (ModalRoute.of(context)?.settings.arguments as int?) ?? 1;
    final modulesAsync = ref.watch(modulesProvider(courseId));
    final selectedId = ref.watch(selectedModuleIdProvider);

    // Effective module id once modules load: explicit selection wins,
    // otherwise default to the first module so lessons still render.
    int? effectiveModuleId(List<api.Module> modules) {
      if (modules.isEmpty) return null;
      if (selectedId != null && modules.any((m) => m.id == selectedId)) {
        return selectedId;
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
                    const Expanded(
                      child: Center(
                        child: TitleBlock(
                            overline: 'Japanese · Nihongo',
                            title: 'Japanese for Beginners'),
                      ),
                    ),
                    const StreakChip(text: '5'),
                  ],
                ),
                const SizedBox(height: 18),

                // Hero — compact progress strip
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  borderRadius: PolyRadii.cardSm,
                  blur: 20,
                  child: Row(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            '45',
                            style: TextStyle(
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
                          '12 of 24 lessons\n248 words learned',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: PolyProgressBar(value: 0.45, height: 5),
                      ),
                    ],
                  ),
                ),
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

                // Modules — vertical scroll, fixed height
                SizedBox(
                  height: 240,
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
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: modules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _ModuleRow(
                          module: _infoFromServer(modules, i, effId),
                          onTap: () => ref
                              .read(selectedModuleIdProvider.notifier)
                              .set(modules[i].id),
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
                      'swipe →',
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

                // Lessons — horizontal scroll, fetched per-module
                SizedBox(
                  height: 150,
                  child: modulesAsync.maybeWhen(
                    data: (modules) {
                      final id = effectiveModuleId(modules);
                      if (id == null) return const SizedBox.shrink();
                      return _LessonsSection(moduleId: id);
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),

                const Spacer(),

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

class _ModuleRow extends StatelessWidget {
  final _ModuleInfo module;
  final VoidCallback onTap;
  const _ModuleRow({required this.module, required this.onTap});

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
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: PolyRadii.cardSm,
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.32 : 0.10),
            ),
          ),
          child: Row(
            children: [
              _ModuleNum(state: module.state, number: module.number),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
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
              Icon(
                selected ? Icons.expand_more : Icons.chevron_right,
                size: 18,
                color: Colors.white.withValues(alpha: selected ? 1.0 : 0.5),
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
  final String num;
  final String jp;
  final String en;
  final bool done;
  final bool selected;
  final String? route;
  const _LessonInfo({
    required this.num,
    required this.jp,
    required this.en,
    required this.done,
    required this.selected,
    this.route,
  });
}

/// Lessons strip for the currently-open module. Pulled lazily so it
/// only fetches when the user actually scrolls the module into view.
class _LessonsSection extends ConsumerWidget {
  final int moduleId;
  const _LessonsSection({required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider(moduleId));
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
      data: (lessons) => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: lessons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _LessonCard(
          lesson: _lessonInfoFromServer(lessons, i),
        ),
      ),
    );
  }
}

/// Bridge server [Lesson] → row view model. The server's `title` is
/// just `lesson <id>` today, so we surface the first word as the main
/// label and the rest as the secondary line; falls back to title if
/// the words list is empty.
_LessonInfo _lessonInfoFromServer(List<api.Lesson> lessons, int i) {
  final l = lessons[i];
  final firstUndoneIdx = lessons.indexWhere((x) => !x.completed);
  final native = l.words.isNotEmpty ? l.words.first : l.title;
  final translation =
      l.words.length > 1 ? l.words.skip(1).join(' · ') : l.description;
  return _LessonInfo(
    num: 'L${i + 1}',
    jp: native,
    en: translation,
    done: l.completed,
    selected: !l.completed && i == firstUndoneIdx,
    route: '/quiz',
  );
}

class _LessonCard extends StatelessWidget {
  final _LessonInfo lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final selected = lesson.selected;
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: lesson.route == null
            ? null
            : () => Navigator.pushNamed(context, lesson.route!),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        offset: const Offset(0, 10),
                        blurRadius: 24),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
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
                  ),
                  _LessonBadge(done: lesson.done, selected: selected),
                ],
              ),
              const Spacer(),
              Text(
                lesson.jp,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? PolyColors.brandPrimary : Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lesson.en,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? Colors.grey.shade700
                      : Colors.white.withValues(alpha: 0.6),
                  height: 1.3,
                ),
              ),
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
