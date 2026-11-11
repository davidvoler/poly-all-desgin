import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/navigation_rail_panel.dart';
import '../../chat/data/ai_models.dart';
import '../data/ai_keys.dart';

const _ink = Color(0xFF17252D);
const _muted = Color(0xFF748087);
const _border = Color(0xFFE4E0D9);
const _teal = Color(0xFF2B7771);

/// Saves the user's own AI key for a provider, and lists the saved keys.
class AiKeysPage extends StatelessWidget {
  const AiKeysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: Row(
        children: [
          const NavigationRailPanel(selected: NavSection.aiKeys),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI keys',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your own key is used before the school\'s. Keys are '
                          'stored encrypted; only their last 4 characters are '
                          'shown.',
                          style: TextStyle(color: _muted, fontSize: 14),
                        ),
                        SizedBox(height: 28),
                        _AddKeyForm(),
                        SizedBox(height: 36),
                        _SavedKeys(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider + key, saved as the user's own key.
class _AddKeyForm extends ConsumerStatefulWidget {
  const _AddKeyForm();

  @override
  ConsumerState<_AddKeyForm> createState() => _AddKeyFormState();
}

class _AddKeyFormState extends ConsumerState<_AddKeyForm> {
  final _key = TextEditingController();
  String _provider = keyProviders.keys.first;
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final apiKey = _key.text.trim();
    if (apiKey.length < 8) {
      setState(() => _error = 'Paste the full API key.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(aiKeysRepositoryProvider)
          .saveKey(_provider, KeyScope.user, apiKey);
      _key.clear();
      ref.invalidate(aiKeysProvider);
      ref.invalidate(aiProvidersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${keyProviders[_provider]} key saved')),
        );
      }
    } catch (e) {
      _error = errorMessage(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add a key',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _provider,
            decoration: const InputDecoration(
              labelText: 'Provider',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final MapEntry(key: id, value: label)
                  in keyProviders.entries)
                DropdownMenuItem(value: id, child: Text(label)),
            ],
            onChanged: _busy
                ? null
                : (value) => setState(() => _provider = value ?? _provider),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _key,
            obscureText: _hidden,
            enableSuggestions: false,
            autocorrect: false,
            enabled: !_busy,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'API key',
              hintText: 'Paste the key',
              border: const OutlineInputBorder(),
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: _hidden ? 'Show' : 'Hide',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _teal),
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save key'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The user's and the school's saved keys, by their last 4 characters.
class _SavedKeys extends ConsumerWidget {
  const _SavedKeys();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(aiKeysProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saved keys',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        keys.when(
          data: (keys) => keys.isEmpty
              ? const Text(
                  'No keys yet.',
                  style: TextStyle(color: _muted, fontSize: 14),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      for (final (i, key) in keys.indexed) ...[
                        if (i > 0) const Divider(height: 1, color: _border),
                        _SavedKeyRow(stored: key),
                      ],
                    ],
                  ),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Row(
            children: [
              Expanded(
                child: Text(
                  'Could not load the keys. ${errorMessage(error)}',
                  style: const TextStyle(color: Color(0xFFB3261E)),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(aiKeysProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SavedKeyRow extends ConsumerStatefulWidget {
  const _SavedKeyRow({required this.stored});

  final ApiKeyInfo stored;

  @override
  ConsumerState<_SavedKeyRow> createState() => _SavedKeyRowState();
}

class _SavedKeyRowState extends ConsumerState<_SavedKeyRow> {
  bool _busy = false;

  Future<void> _remove() async {
    final key = widget.stored;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove the ${keyProviders[key.provider]} key?'),
        content: Text(
          key.scope == KeyScope.school
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
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(aiKeysRepositoryProvider)
          .deleteKey(key.provider, key.scope);
      ref.invalidate(aiKeysProvider);
      ref.invalidate(aiProvidersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.stored;
    final updated = MaterialLocalizations.of(
      context,
    ).formatShortDate(key.updatedAt);
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
      leading: const Icon(Icons.key_outlined, color: _teal),
      title: Text(
        keyProviders[key.provider] ?? key.provider,
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${key.scope.label}  ·  •••• ${key.last4}  ·  updated $updated',
        style: const TextStyle(color: _muted, fontSize: 13),
      ),
      trailing: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(onPressed: _remove, child: const Text('Remove')),
    );
  }
}

/// The server's `detail` message when it sent one.
String errorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'];
    return error.message ?? error.toString();
  }
  return error.toString();
}
