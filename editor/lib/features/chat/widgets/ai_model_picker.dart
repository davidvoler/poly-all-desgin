import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_models.dart';

/// Picks the AI provider and model the chat sends prompts with. Providers
/// the server cannot use, such as one without an API key, are disabled.
class AiModelPicker extends ConsumerWidget {
  const AiModelPicker({super.key});

  static const _labelStyle = TextStyle(color: Color(0xFF8A979A), fontSize: 13);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(aiChoiceProvider);
    final providers = ref.watch(aiProvidersProvider).value ?? const [];
    final current = providers
        .where((p) => p.provider == choice.provider)
        .firstOrNull;

    // Move off a provider the server cannot use, to the first that it can.
    if (current != null && !current.available) {
      final fallback = providers
          .where((p) => p.available && p.models.isNotEmpty)
          .firstOrNull;
      if (fallback != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref
              .read(aiChoiceProvider.notifier)
              .pick(AiChoice(fallback.provider, fallback.models.first)),
        );
      }
    }

    // The picked model stays listed even when the server no longer offers it.
    final models = [
      ...?current?.models,
      if (current == null || !current.models.contains(choice.model))
        choice.model,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('AI', style: _labelStyle),
        const SizedBox(width: 12),
        Flexible(
          child: DropdownButton<String>(
            value: choice.provider,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final p in providers)
                DropdownMenuItem(
                  value: p.provider,
                  enabled: p.available && p.models.isNotEmpty,
                  child: Tooltip(
                    message: p.reason ?? '',
                    child: Text(
                      p.available ? p.label : '${p.label} (unavailable)',
                      overflow: TextOverflow.ellipsis,
                      style: p.available
                          ? null
                          : const TextStyle(color: Color(0xFFB0B8BA)),
                    ),
                  ),
                ),
              // Shown before the list loads, or when it cannot be loaded.
              if (current == null)
                DropdownMenuItem(
                  value: choice.provider,
                  child: Text(choice.provider),
                ),
            ],
            onChanged: (value) {
              final picked = providers.firstWhere((p) => p.provider == value);
              ref
                  .read(aiChoiceProvider.notifier)
                  .pick(AiChoice(picked.provider, picked.models.first));
            },
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: DropdownButton<String>(
            value: choice.model,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final model in models)
                DropdownMenuItem(
                  value: model,
                  child: Text(model, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => ref
                .read(aiChoiceProvider.notifier)
                .pick(AiChoice(choice.provider, value!)),
          ),
        ),
      ],
    );
  }
}
