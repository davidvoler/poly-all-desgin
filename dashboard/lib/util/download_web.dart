// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web variant — wraps [bytes] in a Blob, anchors a hidden link with
/// the download attribute, clicks it, then revokes the object URL.
/// Returns the filename so callers can show a "downloaded X" toast.
Future<String?> saveBytes({
  required String filename,
  required List<int> bytes,
}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], 'application/zip');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return filename;
}
