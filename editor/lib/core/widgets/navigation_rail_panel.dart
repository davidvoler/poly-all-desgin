import 'package:flutter/material.dart';

import '../../features/courses/pages/courses_page.dart';

enum NavSection { courses, chat }

class NavigationRailPanel extends StatelessWidget {
  const NavigationRailPanel({this.selected = NavSection.courses, super.key});

  final NavSection selected;

  void _openChat(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openCourses(BuildContext context) {
    if (selected == NavSection.courses) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CoursesPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF17252D),
      child: Container(
        width: 232,
        padding: const EdgeInsets.fromLTRB(24, 30, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7A37A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFF17252D),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'lumen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 66),
            NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              selected: selected == NavSection.chat,
              onTap: () => _openChat(context),
            ),
            NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Courses',
              selected: selected == NavSection.courses,
              onTap: () => _openCourses(context),
            ),
            const NavItem(icon: Icons.insights_rounded, label: 'Insights'),
            const NavItem(icon: Icons.people_alt_outlined, label: 'Learners'),
            const Spacer(),
            const Divider(color: Color(0xFF3B4A50)),
            const SizedBox(height: 16),
            const NavItem(icon: Icons.settings_outlined, label: 'Settings'),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF9BC3B2),
                  child: const Text(
                    'DL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17252D),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'David Lee',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        tileColor: selected ? const Color(0xFF2B7771) : null,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(
          icon,
          size: 19,
          color: selected ? Colors.white : Colors.white54,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
