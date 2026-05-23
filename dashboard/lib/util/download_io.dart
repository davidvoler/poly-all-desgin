import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Save [bytes] to a user-picked location, defaulting to [filename].
/// Returns the chosen path, or null if the user cancelled.
Future<String?> saveBytes({
  required String filename,
  required List<int> bytes,
}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save course export',
    fileName: filename,
    bytes: Uint8List.fromList(bytes),
  );
  if (path == null) return null;
  // On macOS the saveFile prompt already writes the file when `bytes`
  // is passed; on other desktop platforms the prompt only returns a
  // path so we still need to write. Probe + only write if missing.
  final file = File(path);
  if (!await file.exists() || (await file.length()) == 0) {
    await file.writeAsBytes(bytes);
  }
  return path;
}
