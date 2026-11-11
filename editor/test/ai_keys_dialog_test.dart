import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:editor/features/ai_keys/data/ai_keys.dart';
import 'package:editor/features/ai_keys/widgets/ai_keys_dialog.dart';
import 'package:editor/features/chat/data/ai_models.dart';

/// Keeps keys in memory, as the server would show them.
class FakeAiKeysRepository implements AiKeysRepository {
  final keys = <(String, KeyScope), String>{};

  @override
  Future<List<ApiKeyInfo>> fetchKeys() async => [
    for (final MapEntry(key: (provider, scope), value: key) in keys.entries)
      ApiKeyInfo(
        provider: provider,
        scope: scope,
        last4: key.substring(key.length - 4),
        updatedAt: DateTime(2026, 11, 10),
      ),
  ];

  @override
  Future<void> saveKey(String provider, KeyScope scope, String apiKey) async =>
      keys[(provider, scope)] = apiKey;

  @override
  Future<void> deleteKey(String provider, KeyScope scope) async =>
      keys.remove((provider, scope));
}

void main() {
  testWidgets('adds and removes a user key, showing only its last 4', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeAiKeysRepository()
      ..keys[('gemini', KeyScope.school)] = 'school-key-1111';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiKeysRepositoryProvider.overrideWithValue(repo),
          aiProvidersProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: AiKeysDialog())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('•••• 1111'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(5));

    // Gemini's "My key" is the second row.
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sk-user-key-2222');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.keys[('gemini', KeyScope.user)], 'sk-user-key-2222');
    expect(find.textContaining('•••• 2222'), findsOneWidget);
    expect(find.textContaining('sk-user-key'), findsNothing);

    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(repo.keys.containsKey(('gemini', KeyScope.user)), isFalse);
    expect(find.text('Not set'), findsNWidgets(5));
  });
}
