import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../theme.dart';
import 'common.dart';

/// Editor Terms & Conditions text + version, fetched once for the gate.
final editorTermsProvider =
    FutureProvider<({String terms, int version})>((ref) async {
  return ref.read(dashboardApiProvider).fetchEditorTerms();
});

/// Hard gate shown on content-authoring surfaces (Courses, Create with AI)
/// when the signed-in user hasn't yet accepted the current editor Terms &
/// Conditions (server reports permissions['signed_terms'] == true).
///
/// Renders the terms text in a glass card with a short [explanation] of why
/// it's required and an Accept button; accepting POSTs to
/// /api/v1/school/sign_editor_terms and invalidates [meProvider] so the host
/// page re-renders with its real content. Pass [onAccepted] to refresh any
/// page-specific providers (e.g. the courses list) after signing.
class TermsGate extends ConsumerStatefulWidget {
  final String explanation;
  final VoidCallback? onAccepted;
  const TermsGate({super.key, required this.explanation, this.onAccepted});

  @override
  ConsumerState<TermsGate> createState() => _TermsGateState();
}

class _TermsGateState extends ConsumerState<TermsGate> {
  bool _accepting = false;

  Future<void> _accept() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _accepting = true);
    try {
      await ref.read(dashboardApiProvider).signEditorTerms();
      // Re-read permissions (clears signed_terms) so the host page swaps to
      // its real content; let the caller refresh anything page-specific.
      ref.invalidate(meProvider);
      widget.onAccepted?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not record acceptance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsAsync = ref.watch(editorTermsProvider);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Editor Terms & Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.explanation,
            style: TextStyle(fontSize: 13, color: DashColors.w(0.70)),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: DashColors.w(0.04),
                borderRadius: DashRadii.cardSm,
                border: Border.all(color: DashColors.w(0.08)),
              ),
              child: termsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                ),
                error: (e, _) => Text(
                  'Could not load the terms.\n$e',
                  style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
                ),
                data: (t) => SingleChildScrollView(
                  child: SelectableText(
                    t.terms,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: DashColors.w(0.85),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: _accepting ? 'Recording…' : 'Accept & continue',
              leading: Icons.check,
              onTap: _accepting || termsAsync.value == null ? null : _accept,
            ),
          ),
        ],
      ),
    );
  }
}
