import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/data/ai_models.dart';
import '../data/ai_keys.dart';

/// Adds, replaces and removes the school's and the user's AI API keys.
class AiKeysDialog extends ConsumerWidget {
  const AiKeysDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(aiKeysProvider);
    return Dialog(
      backgroundColor: const Color(0xFFFFFCF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'AI keys',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17252D),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Your own key is used before the school\'s. Keys are stored '
                'encrypted and only their last 4 characters are shown.',
                style: TextStyle(color: Color(0xFF748087), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: keys.when(
                  data: (keys) => ListView(
                    shrinkWrap: true,
                    children: [
                      for (final MapEntry(key: provider, value: label)
                          in keyProviders.entries)
                        _ProviderKeys(
                          provider: provider,
                          label: label,
                          keys: keys.where((k) => k.provider == provider),
                        ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load the keys.\n${_message(error)}'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(aiKeysProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderKeys extends StatelessWidget {
  const _ProviderKeys({
    required this.provider,
    required this.label,
    required this.keys,
  });

  final String provider;
  final String label;
  final Iterable<ApiKeyInfo> keys;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E0D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF17252D),
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final scope in KeyScope.values)
            _KeyRow(
              provider: provider,
              scope: scope,
              stored: keys.where((k) => k.scope == scope).firstOrNull,
            ),
        ],
      ),
    );
  }
}

/// One key: its last 4 characters and what can be done with it, or a field
/// to enter a new one.
class _KeyRow extends ConsumerStatefulWidget {
  const _KeyRow({
    required this.provider,
    required this.scope,
    required this.stored,
  });

  final String provider;
  final KeyScope scope;
  final ApiKeyInfo? stored;

  @override
  ConsumerState<_KeyRow> createState() => _KeyRowState();
}

class _KeyRowState extends ConsumerState<_KeyRow> {
  final controller = TextEditingController();
  bool editing = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Runs a change, then reloads the keys and which providers can be used.
  Future<void> _run(Future<void> Function(AiKeysRepository) change) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await change(ref.read(aiKeysRepositoryProvider));
      controller.clear();
      editing = false;
      ref.invalidate(aiKeysProvider);
      ref.invalidate(aiProvidersProvider);
    } catch (e) {
      error = _message(e);
    }
    if (mounted) setState(() => busy = false);
  }

  void _save() {
    final key = controller.text.trim();
    if (key.isEmpty) return;
    _run((repo) => repo.saveKey(widget.provider, widget.scope, key));
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove the ${widget.scope.label.toLowerCase()}?'),
        content: Text(
          widget.scope == KeyScope.school
              ? 'Users without their own key will no longer be able to use '
                    'this provider.'
              : 'Prompts will use the school\'s key, if it has one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run((repo) => repo.deleteKey(widget.provider, widget.scope));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stored = widget.stored;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  widget.scope.label,
                  style: const TextStyle(
                    color: Color(0xFF8A979A),
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: editing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        enabled: !busy,
                        onSubmitted: (_) => _save(),
                        decoration: const InputDecoration(
                          hintText: 'Paste the API key',
                          isDense: true,
                        ),
                      )
                    : Text(
                        stored == null
                            ? 'Not set'
                            : '•••• ${stored.last4}   ·   updated '
                                  '${MaterialLocalizations.of(context).formatShortDate(stored.updatedAt)}',
                        style: TextStyle(
                          color: stored == null
                              ? const Color(0xFFB0B8BA)
                              : const Color(0xFF17252D),
                          fontSize: 13,
                        ),
                      ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (editing) ...[
                TextButton(
                  onPressed: () => setState(() {
                    editing = false;
                    error = null;
                    controller.clear();
                  }),
                  child: const Text('Cancel'),
                ),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ] else ...[
                TextButton(
                  onPressed: () => setState(() => editing = true),
                  child: Text(stored == null ? 'Add' : 'Replace'),
                ),
                if (stored != null)
                  TextButton(onPressed: _remove, child: const Text('Remove')),
              ],
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 90, bottom: 4),
              child: Text(
                error!,
                style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// The server's `detail` message when it sent one.
String _message(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'];
    return error.message ?? error.toString();
  }
  return error.toString();
}
