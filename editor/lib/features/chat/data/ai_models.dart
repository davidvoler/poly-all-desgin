import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// An AI provider the server can call, with the models it offers.
class AiProvider {
  const AiProvider({
    required this.provider,
    required this.label,
    required this.models,
    required this.available,
    this.reason,
    this.keySource,
  });

  factory AiProvider.fromJson(Map<String, dynamic> json) => AiProvider(
    provider: json['provider'] as String,
    label: json['label'] as String? ?? json['provider'] as String,
    models: [for (final model in json['models'] as List? ?? []) '$model'],
    available: json['available'] as bool? ?? false,
    reason: json['reason'] as String?,
    keySource: json['key_source'] as String?,
  );

  /// The name the server's prompt request takes, such as `gemini`.
  final String provider;
  final String label;

  /// The first model is the provider's default.
  final List<String> models;

  /// False when, for example, its API key is not set on the server.
  final bool available;

  /// Why the provider is not available.
  final String? reason;

  /// Whose API key is used: `user`, `school` or `server`.
  final String? keySource;

  /// What the picker shows on hover.
  String get tooltip =>
      reason ??
      switch (keySource) {
        'user' => 'Using your key',
        'school' => 'Using the school\'s key',
        'server' => 'Using the server\'s key',
        _ => '',
      };
}

/// The provider and model prompts are sent with.
class AiChoice {
  const AiChoice(this.provider, this.model);

  final String provider;
  final String model;

  @override
  bool operator ==(Object other) =>
      other is AiChoice && other.provider == provider && other.model == model;

  @override
  int get hashCode => Object.hash(provider, model);
}

const defaultAiChoice = AiChoice('gemini', 'gemini-3.5-flash');

final aiProvidersProvider = FutureProvider<List<AiProvider>>((ref) async {
  final response = await ref
      .watch(dioProvider)
      .get<List<dynamic>>('/api/v1/prompt/ai_models');
  return [
    for (final row in response.data ?? const [])
      AiProvider.fromJson(row as Map<String, dynamic>),
  ];
});

/// The chat's current provider and model. Kept while the app runs, so it
/// carries across courses.
class AiChoiceNotifier extends Notifier<AiChoice> {
  @override
  AiChoice build() => defaultAiChoice;

  void pick(AiChoice choice) => state = choice;
}

final aiChoiceProvider = NotifierProvider<AiChoiceNotifier, AiChoice>(
  AiChoiceNotifier.new,
);
