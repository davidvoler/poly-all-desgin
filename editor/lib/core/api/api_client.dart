import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth.dart';

/// Server base URL. Override at build time with
/// `--dart-define=API_BASE_URL=https://...`.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8006',
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
      // Sends the HttpOnly session cookie to the editor server, which is on
      // another origin than the editor site.
      extra: {'withCredentials': true},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        // The session expired or was revoked: back to the login page.
        if (error.response?.statusCode == 401) {
          ref.read(authProvider.notifier).sessionEnded(authErrorMessage(error));
        }
        handler.next(error);
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
