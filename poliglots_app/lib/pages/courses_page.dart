import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

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
                        flag: '🇺🇸',
                        native: 'English',
                        sub: 'Native',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: _ArrowCell(),
                    ),
                    Expanded(
                      child: _Picker(
                        label: 'Learning',
                        flag: '🇯🇵',
                        native: '日本語',
                        sub: 'Japanese',
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
                Row(
                  children: [
                    Text('Pick a course', style: PolyText.sectionLabel(color: PolyColors.white(0.6))),
                    const Spacer(),
                    Text(
                      '5 available',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Course list
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _courses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _CourseCard(course: _courses[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  final String label;
  final String flag;
  final String native;
  final String sub;
  const _Picker({
    required this.label,
    required this.flag,
    required this.native,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: PolyText.smallCaps(size: 9)),
        ),
        ClipRRect(
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
                onTap: () {}, // placeholder — opens language list in real app
                borderRadius: PolyRadii.pill,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      _FlagPill(flag: flag),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              native,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              sub.toUpperCase(),
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
                      Icon(Icons.expand_more,
                          size: 18, color: Colors.white.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
              ),
            ),
          ),
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

class _CourseInfo {
  final IconData icon;
  final String name;
  final String sub;
  final String levelPill;
  final bool inProgress;
  final double? progress;
  final String? footer;
  const _CourseInfo({
    required this.icon,
    required this.name,
    required this.sub,
    required this.levelPill,
    this.inProgress = false,
    this.progress,
    this.footer,
  });
}

const _courses = <_CourseInfo>[
  _CourseInfo(
    icon: Icons.play_arrow,
    name: 'Japanese for Beginners',
    sub: 'First words, greetings, numbers',
    levelPill: 'In Progress',
    inProgress: true,
    progress: 0.45,
    footer: '45% · 12/24',
  ),
  _CourseInfo(
    icon: Icons.flight_takeoff,
    name: 'Travel Phrases',
    sub: 'Directions, food, hotels',
    levelPill: 'A1·A2',
    footer: '18 lessons · 145 phrases',
  ),
  _CourseInfo(
    icon: Icons.menu_book,
    name: 'Hiragana & Katakana',
    sub: 'Master both kana scripts',
    levelPill: 'A1',
    footer: '14 lessons · 92 characters',
  ),
  _CourseInfo(
    icon: Icons.work,
    name: 'Japanese for Business',
    sub: 'Keigo, meetings, email etiquette',
    levelPill: 'B1·B2',
    footer: '22 lessons · 280 phrases',
  ),
  _CourseInfo(
    icon: Icons.forum,
    name: 'Everyday Conversation',
    sub: 'Real dialogues, casual speech',
    levelPill: 'A2·B1',
    footer: '20 lessons · 320 phrases',
  ),
];

class _CourseCard extends StatelessWidget {
  final _CourseInfo course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final active = course.inProgress;
    return Material(
      color: Colors.white.withValues(alpha: active ? 0.14 : 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/course'),
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
                      course.icon,
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
                          course.name,
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
                          course.sub,
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
