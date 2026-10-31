import 'package:dio/dio.dart';

/// Pulls the server's `detail` message out of a DioException instead of
/// showing Dio's generic "bad response, status code 400" text. Every
/// error shown to the user (SnackBar, inline error text) should route
/// through this rather than interpolating the caught exception directly.
String apiErrorText(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final detail = data is Map ? (data['detail'] ?? data['error'] ?? data['message']) : null;
    final where = e.requestOptions.uri.path;
    final parts = [
      if (code != null) 'HTTP $code',
      if (detail != null) '$detail' else e.type.name,
      where,
    ];
    return parts.join(' · ');
  }
  return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
