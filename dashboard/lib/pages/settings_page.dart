import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../data/mock.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Anchor-tab selection. Pure UI state for now — clicking a tab
  // scrolls the shell's scroll view to the matching section (in HTML it
  // was href="#…", here we use per-section GlobalKeys +
  // Scrollable.ensureVisible).
  String _active = 'profile';
  final _keys = {
    'profile': GlobalKey(),
    'plans': GlobalKey(),
    'billing': GlobalKey(),
    'danger': GlobalKey(),
  };

  static const _tabs = [
    ('profile', 'School profile'),
    ('plans', 'Subscription plans'),
    ('billing', 'Billing'),
    ('danger', 'Danger zone'),
  ];

  void _scrollTo(String id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Settings',
      overline: MockData.school.name,
      activeRoute: '/settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TabStrip(
            tabs: _tabs,
            active: _active,
            onTap: (id) {
              setState(() => _active = id);
              _scrollTo(id);
            },
          ),
          const SizedBox(height: 22),
          _ProfileSection(key: _keys['profile']),
          const SizedBox(height: 18),
          _PlansSection(key: _keys['plans']),
          const SizedBox(height: 18),
          _BillingSection(key: _keys['billing']),
          const SizedBox(height: 18),
          _DangerSection(key: _keys['danger']),
        ],
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  final List<(String, String)> tabs;
  final String active;
  final ValueChanged<String> onTap;
  const _TabStrip({
    required this.tabs,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in tabs)
          _Tab(label: t.$2, on: t.$1 == active, onTap: () => onTap(t.$1)),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? Colors.white : DashColors.w(0.06),
      borderRadius: DashRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: DashRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: DashRadii.pill,
            border: Border.all(
                color: on ? Colors.white : DashColors.w(0.14)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: on ? DashColors.brand : DashColors.w(0.70),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> right;
  const _SectionHead({
    required this.title,
    this.subtitle,
    this.right = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.16,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                subtitle!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
            ),
          ],
          const Spacer(),
          for (final w in right) ...[w, const SizedBox(width: 8)],
        ],
      ),
    );
  }
}

class _ProfileSection extends ConsumerStatefulWidget {
  const _ProfileSection({super.key});

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  // Local edit copy of the editable fields. Seeded from the live
  // [schoolProvider] once it loads; user edits are not pushed to the
  // server until "Save changes" is tapped.
  final _name = TextEditingController();
  final _plan = TextEditingController();
  final _primaryColor = TextEditingController();
  String? _seedSlug; // pinned to detect when to re-seed on refetch
  bool _busy = false;
  String? _toast;

  @override
  void dispose() {
    _name.dispose();
    _plan.dispose();
    _primaryColor.dispose();
    super.dispose();
  }

  void _seedFrom(SchoolInfo s) {
    if (_seedSlug == s.slug) return;
    _seedSlug = s.slug;
    _name.text = s.name;
    _plan.text = s.plan;
    _primaryColor.text = s.primaryColor;
  }

  Future<void> _save(SchoolInfo s) async {
    setState(() {
      _busy = true;
      _toast = null;
    });
    try {
      await ref.read(dashboardApiProvider).updateSchool(
            schoolId: s.schoolId,
            name: _name.text.trim(),
            plan: _plan.text.trim(),
            logoUrl: s.logoUrl,
            primaryColor: _primaryColor.text.trim(),
            languagesTaught: s.languagesTaught,
            nativeLanguages: s.nativeLanguages,
          );
      ref.invalidate(schoolProvider);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _toast = 'Saved.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _toast = 'Could not save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(schoolProvider);
    return GlassCard(
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Could not load school profile\n$e',
            style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
          ),
        ),
        data: (school) {
          if (school == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Sign in to edit profile.',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
            );
          }
          _seedFrom(school);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHead(
                title: 'School profile',
                subtitle:
                    '·  How your school appears to students and editors',
                right: [
                  PrimaryButton(
                    label: _busy ? 'Saving…' : 'Save changes',
                    leading: Icons.save_outlined,
                    onTap: _busy ? null : () => _save(school),
                  ),
                ],
              ),
              _EditableField(controller: _name, label: 'School name'),
              const SizedBox(height: 16),
              _Field(
                label: 'URL slug',
                value: school.slug,
                prefix: 'polyglots.app/',
                hint: 'Students join at polyglots.app/${school.slug}',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _EditableField(controller: _plan, label: 'Plan'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _EditableField(
                      controller: _primaryColor,
                      label: 'Primary color',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('SCHOOL LOGO', style: DashText.sectionLabel(size: 10)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [DashColors.brand, DashColors.blue900],
                      ),
                    ),
                    child: Text(
                      school.mark,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GhostButton(
                    label: 'Upload image',
                    leading: Icons.file_upload_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'PNG or SVG · 256×256+ recommended',
                    style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
                  ),
                ],
              ),
              if (_toast != null) ...[
                const SizedBox(height: 14),
                Text(
                  _toast!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _toast == 'Saved.'
                        ? DashColors.green500
                        : DashColors.red400,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _EditableField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: DashColors.w(0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide: BorderSide(color: DashColors.w(0.14)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide: BorderSide(color: DashColors.w(0.14)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide:
                  BorderSide(color: DashColors.brand.withValues(alpha: 0.55)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final String? prefix;
  final String? hint;
  const _Field({
    required this.label,
    required this.value,
    this.prefix,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: DashColors.w(0.04),
            borderRadius: DashRadii.input,
            border: Border.all(color: DashColors.w(0.14)),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: DashColors.w(0.04),
                    border: Border(
                      right: BorderSide(color: DashColors.w(0.14)),
                    ),
                  ),
                  child: Text(
                    prefix!,
                    style: TextStyle(
                      fontSize: 13,
                      color: DashColors.w(0.55),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
          ),
        ],
      ],
    );
  }
}

class _PlansSection extends StatelessWidget {
  const _PlansSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: 'Subscription plans',
            subtitle: '·  What students pay to access your courses',
            right: [
              GhostButton(
                label: 'Add plan',
                leading: Icons.add,
                onTap: () {},
              ),
            ],
          ),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth < 720 ? 1 : (c.maxWidth < 1024 ? 2 : 3);
            const gap = 14.0;
            final tileWidth = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: const _PlanCard(
                    tier: 'Starter',
                    price: r'$0',
                    blurb: 'Free taster — Public courses only.',
                    features: [
                      (true, 'Access to Public courses'),
                      (true, '1 active language'),
                      (true, 'Words & sentence practice'),
                      (false, 'Audio downloads'),
                      (false, 'Editor 1:1 sessions'),
                    ],
                    subscribers: '183 subscribers',
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: const _PlanCard(
                    tier: 'Pro',
                    price: r'$9',
                    featured: true,
                    blurb: 'Full library — recommended for most students.',
                    features: [
                      (true, 'All Public + Members courses'),
                      (true, 'Up to 3 active languages'),
                      (true, 'Audio downloads (offline)'),
                      (true, 'Mastery tracking + streaks'),
                      (false, 'Editor 1:1 sessions'),
                    ],
                    subscribers: '52 subscribers',
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: const _PlanCard(
                    tier: 'Premium',
                    price: r'$29',
                    blurb: 'For serious students — everything included.',
                    features: [
                      (true, 'Everything in Pro'),
                      (true, 'All active languages'),
                      (true, 'Weekly editor 1:1'),
                      (true, 'Priority support'),
                      (true, 'Certificate of completion'),
                    ],
                    subscribers: '13 subscribers',
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String tier;
  final String price;
  final String blurb;
  final List<(bool, String)> features;
  final String subscribers;
  final bool featured;
  const _PlanCard({
    required this.tier,
    required this.price,
    required this.blurb,
    required this.features,
    required this.subscribers,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: featured ? DashColors.brand.withValues(alpha: 0.16) : DashColors.w(0.06),
        borderRadius: DashRadii.card,
        border: Border.all(
          color: featured
              ? DashColors.brand.withValues(alpha: 0.55)
              : DashColors.w(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: DashRadii.pill,
                color: DashColors.brand,
              ),
              child: const Text(
                'Most popular',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
          Text(
            tier,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: featured ? Colors.white : DashColors.w(0.70),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/student/mo',
                  style: TextStyle(
                    fontSize: 11,
                    color: DashColors.w(0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            blurb,
            style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
          ),
          const SizedBox(height: 14),
          for (final (on, label) in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    on ? Icons.check : Icons.remove,
                    size: 14,
                    color: on ? DashColors.green500 : DashColors.w(0.35),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: on ? Colors.white : DashColors.w(0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                subscribers,
                style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
              ),
              const Spacer(),
              GhostButton(label: 'Edit', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingSection extends StatelessWidget {
  const _BillingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: 'Billing',
            subtitle: '·  Payment method and invoices',
            right: [GhostButton(label: 'Manage payment', onTap: () {})],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DashColors.w(0.04),
              borderRadius: DashRadii.cardSm,
              border: Border.all(color: DashColors.w(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card,
                    size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visa ending in 4242',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Expires 04 / 2027 · Updated 3 days ago',
                        style: TextStyle(
                            fontSize: 11, color: DashColors.w(0.55)),
                      ),
                    ],
                  ),
                ),
                const StatusPill(
                  label: 'Primary',
                  kind: PillKind.active,
                  swatch: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerSection extends StatelessWidget {
  const _DangerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHead(
            title: 'Danger zone',
            subtitle:
                '·  Irreversible actions — proceed with care',
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DashColors.red400.withValues(alpha: 0.08),
              borderRadius: DashRadii.cardSm,
              border: Border.all(
                  color: DashColors.red400.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delete this school',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Removes all courses, editors, students, and billing data. This cannot be undone.',
                        style: TextStyle(
                            fontSize: 11, color: DashColors.w(0.70)),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: DashColors.red400.withValues(alpha: 0.18),
                  shape: StadiumBorder(
                      side: BorderSide(
                          color: DashColors.red400
                              .withValues(alpha: 0.45))),
                  child: InkWell(
                    onTap: () {},
                    customBorder: const StadiumBorder(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Delete school',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
