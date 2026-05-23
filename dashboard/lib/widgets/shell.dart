import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../data/mock.dart';
import '../theme.dart';
import 'common.dart';

/// One entry in the sidebar nav.
class NavItem {
  final String label;
  final IconData icon;
  final String route;
  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

const List<NavItem> kNavItems = [
  NavItem(label: 'Overview', icon: Icons.home_outlined, route: '/'),
  NavItem(label: 'Languages', icon: Icons.language, route: '/languages'),
  NavItem(label: 'Courses', icon: Icons.menu_book_outlined, route: '/courses'),
  NavItem(label: 'Editors', icon: Icons.edit_outlined, route: '/editors'),
  NavItem(label: 'Students', icon: Icons.people_outline, route: '/students'),
  NavItem(label: 'Settings', icon: Icons.tune, route: '/settings'),
];

/// The full dashboard chrome: gradient background, sticky sidebar, topbar,
/// and a scrolling content area. Pages slot their content via [child].
class DashboardShell extends StatelessWidget {
  /// Page title shown in the topbar (e.g. "Overview").
  final String title;

  /// Optional overline above the title (e.g. "Riverside Academy").
  final String? overline;

  /// Route the current page is rendering for — drives the active nav item.
  final String activeRoute;

  /// Trailing widgets in the topbar (CTAs, dropdowns, etc.). Stacked
  /// to the right of the streak chip.
  final List<Widget> topbarTrailing;

  /// Page body.
  final Widget child;

  const DashboardShell({
    super.key,
    required this.title,
    required this.activeRoute,
    required this.child,
    this.overline,
    this.topbarTrailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: kDashBackground,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(activeRoute: activeRoute),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Topbar(
                    title: title,
                    overline: overline,
                    trailing: topbarTrailing,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 64),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String activeRoute;
  const _Sidebar({required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
        decoration: BoxDecoration(
          color: DashColors.w(0.04),
          border: Border(right: BorderSide(color: DashColors.w(0.08))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'POLYGLOTS · SCHOOLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.98,
                  color: DashColors.w(0.70),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _SchoolBadge(),
            const SizedBox(height: 18),
            for (final item in kNavItems)
              _NavRow(item: item, active: item.route == activeRoute),
            const Spacer(),
            const Divider(color: Color(0x14FFFFFF), height: 1),
            const SizedBox(height: 10),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _SchoolBadge extends StatelessWidget {
  const _SchoolBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DashColors.w(0.06),
        borderRadius: DashRadii.card,
        border: Border.all(color: DashColors.w(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [DashColors.brand, DashColors.blue900],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              MockData.school.mark,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MockData.school.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  MockData.school.plan.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: DashColors.w(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final NavItem item;
  final bool active;
  const _NavRow({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DashColors.w(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          if (active) return;
          Navigator.pushReplacementNamed(context, item.route);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(color: DashColors.w(0.14))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(item.icon,
                  size: 16, color: active ? Colors.white : DashColors.w(0.70)),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : DashColors.w(0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer the signed-in user; fall back to mock data for designs/tests.
    final me = ref.watch(currentUserProvider);
    final initials = me?.initials ?? MockData.me.initials;
    final name = me?.name.isNotEmpty == true ? me!.name : MockData.me.name;
    return Row(
      children: [
        LetterAvatar(label: initials, gradientKey: 'lh', size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        Tooltip(
          message: 'Sign out',
          child: InkWell(
            onTap: () => ref.read(authProvider.notifier).signOut(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.north_east,
                  size: 14, color: DashColors.w(0.55)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Topbar extends StatelessWidget {
  final String title;
  final String? overline;
  final List<Widget> trailing;
  const _Topbar({
    required this.title,
    required this.overline,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            color: DashColors.darkBg.withValues(alpha: 0.4),
            border: Border(
              bottom: BorderSide(color: DashColors.w(0.06)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overline != null)
                      Text(
                        overline!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: DashColors.w(0.55),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(title, style: DashText.h1),
                  ],
                ),
              ),
              for (final w in trailing) ...[
                w,
                const SizedBox(width: 10),
              ],
              if (trailing.isEmpty) ...[
                StreakChip(days: MockData.school.streakDays),
                const SizedBox(width: 10),
                const DashIconButton(icon: Icons.search, tooltip: 'Search'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One-line "head row" inside the content area — a small-caps section
/// label + optional subtitle + right-aligned trailing widgets.
class HeadRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final List<Widget> trailing;
  const HeadRow({
    super.key,
    required this.label,
    this.subtitle,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SectionLabel(label),
          if (subtitle != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: _SubtitleText(text: subtitle!),
            ),
          ],
          const Spacer(),
          for (final w in trailing) ...[
            w,
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Subtitle next to a head row's section label. Bolds the substring
/// wrapped in `**` markers (e.g. "·  **248** students · 142 active").
class _SubtitleText extends StatelessWidget {
  final String text;
  const _SubtitleText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd
            ? const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )
            : null,
      ));
    }
    return Text.rich(
      TextSpan(style: DashText.subtitle, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
