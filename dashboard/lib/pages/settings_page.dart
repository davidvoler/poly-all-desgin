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
            isPublic: s.isPublic,
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

class _PlansSection extends ConsumerWidget {
  const _PlansSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(plansProvider);
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
                onTap: () => _showEditDialog(context, ref, null),
              ),
            ],
          ),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Could not load plans\n$e',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
              ),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No plans yet — add one above.',
                      style: TextStyle(
                          fontSize: 12, color: DashColors.w(0.55)),
                    ),
                  ),
                );
              }
              return LayoutBuilder(builder: (context, c) {
                final cols =
                    c.maxWidth < 720 ? 1 : (c.maxWidth < 1024 ? 2 : 3);
                const gap = 14.0;
                final tileWidth = (c.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final p in plans)
                      SizedBox(
                        width: tileWidth,
                        child: _PlanCard(
                          plan: p,
                          onEdit: () => _showEditDialog(context, ref, p),
                          onDelete: () => _confirmDelete(context, ref, p),
                        ),
                      ),
                  ],
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? plan) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PlanEditDialog(plan: plan),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Map<String, dynamic> plan) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashColors.darkBg,
        title: const Text('Delete plan', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${plan['tier']}"? Subscribers stay enrolled but the plan disappears from the dashboard.',
          style: TextStyle(color: DashColors.w(0.70), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: DashColors.red400),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(dashboardApiProvider).deletePlan(
            schoolId: me.schoolId,
            planId: plan['plan_id'] as int,
          );
      ref.invalidate(plansProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  String get _price {
    final cents = (plan['price_cents'] as int?) ?? 0;
    if (cents == 0) return r'$0';
    final whole = cents ~/ 100;
    final rem = cents % 100;
    return rem == 0 ? '\$$whole' : '\$$whole.${rem.toString().padLeft(2, '0')}';
  }

  String get _cadenceSuffix {
    final cadence = (plan['cadence'] as String?) ?? 'monthly';
    return cadence == 'yearly' ? '/student/yr' : '/student/mo';
  }

  @override
  Widget build(BuildContext context) {
    final featured = (plan['featured'] as bool?) ?? false;
    final tier = (plan['tier'] as String?) ?? '';
    final blurb = (plan['blurb'] as String?) ?? '';
    final features = ((plan['features'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: featured
            ? DashColors.brand.withValues(alpha: 0.16)
            : DashColors.w(0.06),
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
                _price,
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
                  _cadenceSuffix,
                  style: TextStyle(
                    fontSize: 11,
                    color: DashColors.w(0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (blurb.isNotEmpty)
            Text(
              blurb,
              style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
            ),
          const SizedBox(height: 14),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    (f['included'] as bool? ?? false)
                        ? Icons.check
                        : Icons.remove,
                    size: 14,
                    color: (f['included'] as bool? ?? false)
                        ? DashColors.green500
                        : DashColors.w(0.35),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (f['label'] as String?) ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: (f['included'] as bool? ?? false)
                            ? Colors.white
                            : DashColors.w(0.55),
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
                _subscribers,
                style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline,
                    size: 18, color: DashColors.w(0.55)),
              ),
              const SizedBox(width: 4),
              GhostButton(label: 'Edit', onTap: onEdit),
            ],
          ),
        ],
      ),
    );
  }

  String get _subscribers {
    final n = (plan['subscriber_count'] as int?) ?? 0;
    if (n == 0) return 'No subscribers yet';
    if (n == 1) return '1 subscriber';
    return '$n subscribers';
  }
}

/// Modal for creating or editing one plan. Features are edited as a
/// reorderable list of (label, included) chips; submit replaces the
/// whole feature list server-side via PUT.
class _PlanEditDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? plan;
  const _PlanEditDialog({required this.plan});

  @override
  ConsumerState<_PlanEditDialog> createState() => _PlanEditDialogState();
}

class _PlanEditDialogState extends ConsumerState<_PlanEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tier = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _blurb = TextEditingController();
  final _newFeature = TextEditingController();
  String _cadence = 'monthly';
  bool _featured = false;
  // Mutable working copy of the features — applied to the server on
  // submit. Each entry is {label, included}.
  late final List<Map<String, dynamic>> _features = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    if (p != null) {
      _tier.text = (p['tier'] as String?) ?? '';
      final cents = (p['price_cents'] as int?) ?? 0;
      _price.text = (cents / 100).toStringAsFixed(2);
      _blurb.text = (p['blurb'] as String?) ?? '';
      _cadence = (p['cadence'] as String?) ?? 'monthly';
      _featured = (p['featured'] as bool?) ?? false;
      for (final f
          in ((p['features'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
        _features.add({
          'label': f['label'] ?? '',
          'included': f['included'] ?? true,
        });
      }
    }
  }

  @override
  void dispose() {
    _tier.dispose();
    _price.dispose();
    _blurb.dispose();
    _newFeature.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final priceDollars = double.tryParse(_price.text.trim()) ?? 0;
      await ref.read(dashboardApiProvider).upsertPlan(
            schoolId: me.schoolId,
            planId: widget.plan?['plan_id'] as int?,
            tier: _tier.text.trim(),
            priceCents: (priceDollars * 100).round(),
            cadence: _cadence,
            blurb: _blurb.text.trim().isEmpty ? null : _blurb.text.trim(),
            featured: _featured,
            features: _features,
          );
      ref.invalidate(plansProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Could not save: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.plan == null;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isNew ? 'Add plan' : 'Edit plan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                _PlanField(
                  controller: _tier,
                  label: 'Tier name (e.g. Pro)',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PlanField(
                        controller: _price,
                        label: 'Price (dollars)',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) {
                            return 'Number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CADENCE',
                              style: DashText.sectionLabel(size: 10)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final c in const ['monthly', 'yearly'])
                                ChoiceChip(
                                  label: Text(c.toUpperCase(),
                                      style: const TextStyle(fontSize: 11)),
                                  selected: _cadence == c,
                                  onSelected: (_) =>
                                      setState(() => _cadence = c),
                                  selectedColor: DashColors.brand,
                                  backgroundColor: DashColors.w(0.06),
                                  labelStyle: TextStyle(
                                    color: _cadence == c
                                        ? Colors.white
                                        : DashColors.w(0.70),
                                  ),
                                  side: BorderSide(color: DashColors.w(0.14)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _PlanField(controller: _blurb, label: 'Blurb (optional)'),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _featured,
                  onChanged: (v) => setState(() => _featured = v),
                  title: const Text(
                    'Mark as "Most popular"',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeThumbColor: DashColors.brand,
                ),
                const SizedBox(height: 4),
                Text('FEATURES', style: DashText.sectionLabel(size: 10)),
                const SizedBox(height: 6),
                if (_features.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Add the first feature below.',
                      style: TextStyle(
                          fontSize: 11, color: DashColors.w(0.55)),
                    ),
                  ),
                for (var i = 0; i < _features.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _features[i]['included'] as bool,
                          onChanged: (v) => setState(
                              () => _features[i]['included'] = v ?? false),
                          activeColor: DashColors.green500,
                        ),
                        Expanded(
                          child: Text(
                            _features[i]['label'] as String,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () => setState(() => _features.removeAt(i)),
                          icon: Icon(Icons.close,
                              size: 16, color: DashColors.w(0.55)),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newFeature,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Add a feature…',
                          hintStyle: TextStyle(
                              fontSize: 12, color: DashColors.w(0.35)),
                          filled: true,
                          fillColor: DashColors.w(0.04),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
                            borderSide: BorderSide(
                                color:
                                    DashColors.brand.withValues(alpha: 0.55)),
                          ),
                        ),
                        onSubmitted: (_) => _addFeature(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Add',
                      onPressed: _addFeature,
                      icon: Icon(Icons.add_circle,
                          color: DashColors.brand, size: 22),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style:
                        TextStyle(fontSize: 12, color: DashColors.red400),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: DashColors.w(0.70),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: _busy ? 'Saving…' : (isNew ? 'Create plan' : 'Save'),
                      leading: Icons.save_outlined,
                      onTap: _busy ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addFeature() {
    final label = _newFeature.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _features.add({'label': label, 'included': true});
      _newFeature.clear();
    });
  }
}

class _PlanField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  const _PlanField({
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
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

class _BillingSection extends ConsumerWidget {
  const _BillingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(billingProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: 'Billing',
            subtitle: '·  Payment method on file',
            right: [
              GhostButton(
                label: async.value == null ? 'Add card' : 'Update card',
                leading: Icons.credit_card,
                onTap: () => _showDialog(context, async.value),
              ),
            ],
          ),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Could not load billing\n$e',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
              ),
            ),
            data: (card) {
              if (card == null) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DashColors.w(0.04),
                    borderRadius: DashRadii.cardSm,
                    border: Border.all(color: DashColors.w(0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.credit_card_off,
                          size: 20, color: DashColors.w(0.55)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No card on file yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: DashColors.w(0.70),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
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
                          Text(
                            '${card['brand']} ending in ${card['last4']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Expires ${'${card['exp_month']}'.padLeft(2, '0')} / ${card['exp_year']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: DashColors.w(0.55),
                            ),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDialog(
      BuildContext context, Map<String, dynamic>? existing) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _BillingDialog(existing: existing),
    );
  }
}

class _BillingDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  const _BillingDialog({required this.existing});

  @override
  ConsumerState<_BillingDialog> createState() => _BillingDialogState();
}

class _BillingDialogState extends ConsumerState<_BillingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController(text: 'Visa');
  final _last4 = TextEditingController();
  final _expMonth = TextEditingController();
  final _expYear = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _brand.text = (e['brand'] as String?) ?? 'Visa';
      _last4.text = (e['last4'] as String?) ?? '';
      _expMonth.text = '${e['exp_month']}';
      _expYear.text = '${e['exp_year']}';
    }
  }

  @override
  void dispose() {
    _brand.dispose();
    _last4.dispose();
    _expMonth.dispose();
    _expYear.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(dashboardApiProvider).upsertBilling(
            schoolId: me.schoolId,
            brand: _brand.text.trim(),
            last4: _last4.text.trim(),
            expMonth: int.parse(_expMonth.text.trim()),
            expYear: int.parse(_expYear.text.trim()),
          );
      ref.invalidate(billingProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Could not save: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existing == null ? 'Add card' : 'Update card',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                _PlanField(
                  controller: _brand,
                  label: 'Brand',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                _PlanField(
                  controller: _last4,
                  label: 'Last 4 digits',
                  validator: (v) =>
                      (v != null && v.trim().length == 4 && int.tryParse(v.trim()) != null)
                          ? null
                          : '4 digits',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PlanField(
                        controller: _expMonth,
                        label: 'Exp. month',
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 1 || n > 12) return '1–12';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PlanField(
                        controller: _expYear,
                        label: 'Exp. year',
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 2024) return '4-digit year';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 12, color: DashColors.red400),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: DashColors.w(0.70),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: _busy ? 'Saving…' : 'Save card',
                      leading: Icons.save_outlined,
                      onTap: _busy ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DangerSection extends ConsumerStatefulWidget {
  const _DangerSection({super.key});

  @override
  ConsumerState<_DangerSection> createState() => _DangerSectionState();
}

class _DangerSectionState extends ConsumerState<_DangerSection> {
  bool _busy = false;

  /// Two-step confirm — the user types the school name to unlock the
  /// red Delete button. The DELETE endpoint already exists; on success
  /// we sign out so the gate falls back to the login page (the deleted
  /// school is no longer signable into).
  Future<void> _delete() async {
    final me = ref.read(currentUserProvider);
    final school = ref.read(schoolProvider).value;
    if (me == null) return;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteSchoolConfirm(name: school?.name ?? me.schoolName),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(dashboardApiProvider).deleteSchool(me.schoolId);
      ref.read(authProvider.notifier).signOut();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHead(
            title: 'Danger zone',
            subtitle: '·  Irreversible actions — proceed with care',
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
                  color: DashColors.red400.withValues(alpha: _busy ? 0.10 : 0.18),
                  shape: StadiumBorder(
                      side: BorderSide(
                          color: DashColors.red400.withValues(alpha: 0.45))),
                  child: InkWell(
                    onTap: _busy ? null : _delete,
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        _busy ? 'Deleting…' : 'Delete school',
                        style: const TextStyle(
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

class _DeleteSchoolConfirm extends StatefulWidget {
  final String name;
  const _DeleteSchoolConfirm({required this.name});

  @override
  State<_DeleteSchoolConfirm> createState() => _DeleteSchoolConfirmState();
}

class _DeleteSchoolConfirmState extends State<_DeleteSchoolConfirm> {
  final _typed = TextEditingController();
  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _typed.text.trim() == widget.name;
    return AlertDialog(
      backgroundColor: DashColors.darkBg,
      title: const Text('Delete school',
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Type the school name to confirm. This permanently deletes courses, editors, students, plans, billing methods, and activity history.',
            style: TextStyle(color: DashColors.w(0.70), fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _typed,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: widget.name,
              hintStyle:
                  TextStyle(fontSize: 13, color: DashColors.w(0.35)),
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
                    BorderSide(color: DashColors.red400.withValues(alpha: 0.55)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: matches ? DashColors.red400 : DashColors.w(0.35),
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Delete school'),
        ),
      ],
    );
  }
}
