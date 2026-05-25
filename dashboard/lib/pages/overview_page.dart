import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      title: 'Overview',
      activeRoute: '/',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatGrid(),
          SizedBox(height: 22),
          _OverviewSplit(),
        ],
      ),
    );
  }
}

class _StatGrid extends ConsumerWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(schoolStatsProvider);
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth < 720 ? 2 : 4;
      const gap = 14.0;
      final tileWidth = (c.maxWidth - gap * (cols - 1)) / cols;
      final tiles = _statTiles(stats);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final t in tiles)
            SizedBox(width: tileWidth, child: _StatTile(stat: t)),
        ],
      );
    });
  }

  /// Stat tile content. Server only returns the four counts; the
  /// "detail" subtitle is rendered client-side from the same counts so
  /// the design stays consistent with the static prototype.
  List<_TileData> _statTiles(AsyncValue<SchoolStats> stats) {
    String v(int Function(SchoolStats) pick) =>
        stats.maybeWhen(data: (s) => '${pick(s)}', orElse: () => '…');
    final s = stats.value;
    return [
      _TileData(
        value: v((s) => s.activeLanguages),
        label: 'Active languages',
        detail: 'of 6 available',
      ),
      _TileData(
        value: v((s) => s.courses),
        label: 'Courses',
        detail: s == null
            ? '—'
            : (s.courses > 0
                ? '${s.courses} total'
                : 'No courses yet'),
      ),
      _TileData(
        value: v((s) => s.editors),
        label: 'Editors',
        detail: s == null
            ? '—'
            : (s.editors > 0 ? 'including owners' : 'invite the first one'),
      ),
      _TileData(
        value: v((s) => s.students),
        label: 'Students',
        detail: s == null ? '—' : 'enrolled this term',
        trend: TrendDirection.up,
      ),
    ];
  }
}

class _TileData {
  final String value;
  final String label;
  final String detail;
  final TrendDirection trend;
  const _TileData({
    required this.value,
    required this.label,
    required this.detail,
    this.trend = TrendDirection.flat,
  });
}

enum TrendDirection { up, down, flat }

class _StatTile extends StatelessWidget {
  final _TileData stat;
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

class _ActivityPanel extends ConsumerWidget {
  const _ActivityPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Recent activity', style: DashText.h2),
          ),
          activity.when(
            loading: () => _empty('Loading activity…'),
            error: (e, _) => _empty('Could not load activity'),
            data: (rows) {
              if (rows.isEmpty) {
                return _empty('No activity yet — actions show up here.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _ActivityTile(row: rows[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _empty(String msg) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        child: Text(
          msg,
          style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
        ),
      );
}

class _ActivityTile extends StatelessWidget {
  final ActivityRowRemote row;
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
                  row.actorName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.summary,
                  style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.whenHuman,
            style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
          ),
        ],
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
