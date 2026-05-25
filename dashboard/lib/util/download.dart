// Cross-platform "save these bytes to a file the user can find".
//
// Web is the awkward one — there's no filesystem, so we stitch a Blob
// + anchor click via dart:html. Everywhere else we use file_picker's
// saveFile prompt and write through dart:io.
//
// Imported through a conditional barrel (download_web.dart vs
// download_io.dart) so the desktop build never sees dart:html and the
// web build never sees dart:io.

export 'download_io.dart' if (dart.library.html) 'download_web.dart';
