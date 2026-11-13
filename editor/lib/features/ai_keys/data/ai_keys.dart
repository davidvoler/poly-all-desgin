import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// Whose key it is: the school's, shared by its users, or the user's own,
/// which is used before the school's.
enum KeyScope {
  school('School key'),
  user('My key');

  const KeyScope(this.label);

  final String label;
}

/// The providers that need an API key, by the server's name for them.
const keyProviders = {
  'gemini': 'Google Gemini',
  'claude': 'Anthropic Claude',
  'openai': 'OpenAI',
};

/// A stored key as the server shows it: only its last 4 characters.
class ApiKeyInfo {
  const ApiKeyInfo({
    required this.provider,
    required this.scope,
    required this.last4,
    required this.updatedAt,
  });

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) => ApiKeyInfo(
    provider: json['provider'] as String,
    scope: KeyScope.values.byName(json['scope'] as String),
    last4: json['last4'] as String,
    updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
  );

  final String provider;
  final KeyScope scope;
  final String last4;
  final DateTime updatedAt;
}

class AiKeysRepository {
  const AiKeysRepository(this._dio);

  final Dio _dio;

  static const _path = '/api/v1/ai/keys';

  Future<List<ApiKeyInfo>> fetchKeys() async {
    final response = await _dio.get<List<dynamic>>(_path);
    return [
      for (final row in response.data ?? const [])
        ApiKeyInfo.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Adds or replaces the key. The server encrypts it and never returns it.
  Future<void> saveKey(String provider, KeyScope scope, String apiKey) =>
      _dio.put<void>(
        _path,
        data: {'provider': provider, 'scope': scope.name, 'api_key': apiKey},
      );

  Future<void> deleteKey(String provider, KeyScope scope) => _dio.delete<void>(
    _path,
    queryParameters: {'provider': provider, 'scope': scope.name},
  );
}

final aiKeysRepositoryProvider = Provider<AiKeysRepository>(
  (ref) => AiKeysRepository(ref.watch(dioProvider)),
);

final aiKeysProvider = FutureProvider<List<ApiKeyInfo>>(
  (ref) => ref.watch(aiKeysRepositoryProvider).fetchKeys(),
);
