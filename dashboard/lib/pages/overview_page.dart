import 'package:flutter/material.dart';

import '../data/mock.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Overview',
      overline: MockData.school.name,
      activeRoute: '/',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _StatGrid(),
          SizedBox(height: 22),
          _OverviewSplit(),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth < 720 ? 2 : 4;
      const gap = 14.0;
      final tileWidth = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final s in MockData.overviewStats)
            SizedBox(width: tileWidth, child: _StatTile(stat: s)),
        ],
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  final StatTile stat;
  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final detailColor = switch (stat.trend) {
      TrendDirection.up => const Color(0xFFA5D6A7),
      TrendDirection.down => const Color(0xFFEF9A9A),
      TrendDirection.flat => DashColors.w(0.55),
    };
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.value, style: DashText.statValue),
          const SizedBox(height: 4),
          Text(
            stat.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: DashColors.w(0.70),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.detail,
            style: TextStyle(fontSize: 11, color: detailColor),
          ),
        ],
      ),
    );
  }
}

class _OverviewSplit extends StatelessWidget {
  const _OverviewSplit();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // 2fr · 1fr at ≥900px; stacks below that.
      if (c.maxWidth < 900) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActivityPanel(),
            SizedBox(height: 16),
            _QuickActionsPanel(),
          ],
        );
      }
      const gap = 16.0;
      final activityWidth = (c.maxWidth - gap) * 2 / 3;
      final actionsWidth = (c.maxWidth - gap) * 1 / 3;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: activityWidth, child: const _ActivityPanel()),
          const SizedBox(width: gap),
          SizedBox(width: actionsWidth, child: const _QuickActionsPanel()),
        ],
      );
    });
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Recent activity', style: DashText.h2),
          ),
          for (var i = 0; i < MockData.activity.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ActivityTile(row: MockData.activity[i]),
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityRow row;
  const _ActivityTile({required this.row});

  Color _dotColor() => switch (row.kind) {
        ActivityKind.upload => DashColors.green500,
        ActivityKind.invite => DashColors.orange300,
        ActivityKind.generic => DashColors.brand,
      };

  @override
  Widget build(BuildContext context) {
    final dot = _dotColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        borderRadius: DashRadii.cardSm,
        border: Border.all(color: DashColors.w(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot,
              boxShadow: [
                BoxShadow(
                  color: dot.withValues(alpha: 0.18),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.actor,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                _RichEmphasisText(text: row.summary),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.when,
            style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
          ),
        ],
      ),
    );
  }
}

/// Renders a string with `**bold**` and `*italic*` markers — used by the
/// activity rows and head-row subtitles. Italic regions render in the
/// same color but italic; bold regions render brighter (white).
class _RichEmphasisText extends StatelessWidget {
  final String text;
  const _RichEmphasisText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var rest = text;
    final pattern = RegExp(r'(\*\*([^*]+)\*\*)|(\*([^*]+)\*)');
    var pos = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > pos) {
        spans.add(TextSpan(text: rest.substring(pos, m.start)));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(2),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: m.group(4),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      pos = m.end;
    }
    if (pos < text.length) {
      spans.add(TextSpan(text: text.substring(pos)));
    }
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
        children: spans,
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      const _QuickAction(
        icon: Icons.file_upload_outlined,
        title: 'Upload a course',
        subtitle: 'Drop a zipped course folder',
        route: '/courses',
      ),
      const _QuickAction(
        icon: Icons.mail_outline,
        title: 'Invite an editor',
        subtitle: 'By email — assign languages',
        route: '/editors',
      ),
      const _QuickAction(
        icon: Icons.add,
        title: 'Add students',
        subtitle: 'Manually or by CSV',
        route: '/students',
      ),
      const _QuickAction(
        icon: Icons.language,
        title: 'Add a language',
        subtitle: 'Open the catalog of 6',
        route: '/languages',
      ),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Quick actions', style: DashText.h2),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            actions[i],
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashColors.w(0.04),
      borderRadius: DashRadii.cardSm,
      child: InkWell(
        borderRadius: DashRadii.cardSm,
        onTap: () => Navigator.pushReplacementNamed(context, route),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: DashRadii.cardSm,
            border: Border.all(color: DashColors.w(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: DashColors.w(0.08),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: DashColors.w(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: DashColors.w(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
