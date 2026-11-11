import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_keys/pages/ai_keys_page.dart';
import '../../features/auth/data/auth.dart';

import '../../features/courses/pages/courses_page.dart';

enum NavSection { courses, chat, aiKeys }

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

  void _openAiKeys(BuildContext context) {
    if (selected == NavSection.aiKeys) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AiKeysPage()));
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
                // The app's logo: a globe on its blue gradient.
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    ),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Polyglots Editor',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
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
            NavItem(
              icon: Icons.key_outlined,
              label: 'AI keys',
              selected: selected == NavSection.aiKeys,
              onTap: () => _openAiKeys(context),
            ),
            const NavItem(icon: Icons.settings_outlined, label: 'Settings'),
            const SizedBox(height: 16),
            const _SignedInUser(),
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

/// Who is signed in, to which school, and a way to sign out.
class _SignedInUser extends ConsumerWidget {
  const _SignedInUser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth is AuthSignedIn ? auth.user : null;
    if (user == null) return const SizedBox.shrink();
    final initial = user.email.isEmpty ? '?' : user.email[0].toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFF9BC3B2),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17252D),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                user.schoolName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: () {
            // Back to the first page, which shows the login once signed out.
            Navigator.of(context).popUntil((route) => route.isFirst);
            ref.read(authProvider.notifier).signOut();
          },
          icon: const Icon(
            Icons.logout_rounded,
            color: Colors.white54,
            size: 18,
          ),
        ),
      ],
    );
  }
}
