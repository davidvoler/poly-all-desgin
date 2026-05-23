import 'package:flutter/material.dart';

import '../data/mock.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

class LanguagesPage extends StatelessWidget {
  const LanguagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Languages',
      overline: MockData.school.name,
      activeRoute: '/languages',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeadRow(
            label: 'Languages we teach',
            subtitle:
                '·  **3** active · what your courses are in',
            trailing: [
              GhostButton(
                label: 'Add language',
                leading: Icons.add,
                onTap: () {},
              ),
            ],
          ),
          _LanguageGrid(cards: MockData.taughtLanguages),
          const SizedBox(height: 32),
          HeadRow(
            label: 'Student languages',
            subtitle:
                '·  **3** native languages · what your students already speak',
            trailing: [
              GhostButton(
                label: 'Add language',
                leading: Icons.add,
                onTap: () {},
              ),
            ],
          ),
          _LanguageGrid(cards: MockData.nativeLanguages),
        ],
      ),
    );
  }
}

class _LanguageGrid extends StatelessWidget {
  final List<LanguageCard> cards;
  const _LanguageGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth < 720 ? 1 : (c.maxWidth < 1024 ? 2 : 3);
      const gap = 14.0;
      final tileWidth = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final card in cards)
            SizedBox(width: tileWidth, child: _LangTile(card: card)),
        ],
      );
    });
  }
}

class _LangTile extends StatelessWidget {
  final LanguageCard card;
  const _LangTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      // Fixed height (rather than just min-height) so the inner [Spacer]
      // resolves. Wrap doesn't bound child height, so a min-only
      // constraint would leave the column unbounded — Spacer would then
      // hit a `hasBoundedHeight` assertion.
      child: SizedBox(
        height: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.flag,
                style: const TextStyle(fontSize: 36, height: 1.0)),
            const SizedBox(height: 14),
            Directionality(
              textDirection:
                  card.rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                card.native,
                textAlign: card.rtl ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.english.toUpperCase(),
              style: DashText.sectionLabel(),
            ),
            const Spacer(),
            Row(
              children: [
                if (card.courses != null) ...[
                  _Pair(value: '${card.courses}', label: 'Courses'),
                  const SizedBox(width: 16),
                  _Sep(),
                  const SizedBox(width: 16),
                ],
                _Pair(value: '${card.students}', label: 'Students'),
                if (card.percentOfSchool != null) ...[
                  const SizedBox(width: 16),
                  _Sep(),
                  const SizedBox(width: 16),
                  _Pair(value: card.percentOfSchool!, label: 'Of school'),
                ],
                if (card.courses != null && card.percentOfSchool == null) ...[
                  const SizedBox(width: 16),
                  _Sep(),
                  const SizedBox(width: 16),
                  StatusPill(
                    label: card.active ? 'Active' : 'Inactive',
                    kind: card.active ? PillKind.active : PillKind.muted,
                    swatch: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  final String value;
  final String label;
  const _Pair({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(label.toUpperCase(),
            style: DashText.sectionLabel(size: 10)),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: DashColors.w(0.14),
    );
  }
}
