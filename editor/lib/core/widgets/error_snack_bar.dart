import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows [message] in a snack bar with a Copy button, kept up long enough to
/// copy it.
void showErrorSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 15),
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'Copy',
        onPressed: () => Clipboard.setData(ClipboardData(text: message)),
      ),
    ),
  );
}
