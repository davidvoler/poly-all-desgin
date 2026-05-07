import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class CoursePage extends StatelessWidget {
  const CoursePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      '5 modules · scroll for more',
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
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _modules.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _ModuleRow(module: _modules[i]),
                  ),
                ),
                const SizedBox(height: 14),

                // Section row — Lessons
                Row(
                  children: [
                    Text('Lessons in Module 3',
                        style: PolyText.sectionLabel(color: PolyColors.white(0.6))),
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

                // Lessons — horizontal scroll
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    itemCount: _lessons.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _LessonCard(lesson: _lessons[i]),
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

const _modules = <_ModuleInfo>[
  _ModuleInfo(
      number: '1', name: 'First Words', progress: 1, pct: '4 / 4', state: _ModuleState.done),
  _ModuleInfo(
      number: '2',
      name: 'Numbers & Colors',
      progress: 1,
      pct: '5 / 5',
      state: _ModuleState.done),
  _ModuleInfo(
      number: '3',
      name: 'Greetings & Introductions',
      progress: 0.75,
      pct: '3 / 4',
      state: _ModuleState.selected),
  _ModuleInfo(
      number: '4', name: 'Family & People', progress: 0, pct: '0 / 5', state: _ModuleState.locked),
  _ModuleInfo(
      number: '5', name: 'Food & Drink', progress: 0, pct: '0 / 6', state: _ModuleState.locked),
];

class _ModuleRow extends StatelessWidget {
  final _ModuleInfo module;
  const _ModuleRow({required this.module});

  @override
  Widget build(BuildContext context) {
    final selected = module.state == _ModuleState.selected;

    return Material(
      color: Colors.white.withValues(alpha: selected ? 0.16 : 0.05),
      borderRadius: PolyRadii.cardSm,
      child: InkWell(
        onTap: () {},
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

const _lessons = <_LessonInfo>[
  _LessonInfo(num: 'L1', jp: 'はじめまして', en: 'Nice to meet you', done: true, selected: false, route: '/quiz'),
  _LessonInfo(num: 'L2', jp: 'わたしは', en: 'I am…', done: true, selected: false, route: '/quiz'),
  _LessonInfo(num: 'L3', jp: 'どうぞよろしく', en: 'Pleased to meet you', done: true, selected: false, route: '/annotated'),
  _LessonInfo(num: 'L4 · CURRENT', jp: 'お名前は何ですか', en: 'What is your name?', done: false, selected: true, route: '/quiz'),
];

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
