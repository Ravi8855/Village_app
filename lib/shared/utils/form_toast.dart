import 'package:flutter/material.dart';

import 'user_message.dart';

/// Short floating message for validation or feedback.
void showFormToast(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  _showAppSnackBar(
    context,
    message: message,
    isError: isError,
  );
}

/// User-friendly error from an exception.
void showFormError(BuildContext context, Object error) {
  showFormToast(context, formatUserMessage(error), isError: true);
}

/// Positive confirmation (signup success, OTP sent, etc.).
void showFormSuccess(BuildContext context, String message) {
  _showAppSnackBar(
    context,
    message: message,
    isSuccess: true,
  );
}

void _showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isSuccess = false,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  Color background;
  Color foreground;
  IconData icon;

  if (isError) {
    background = colorScheme.errorContainer;
    foreground = colorScheme.onErrorContainer;
    icon = Icons.error_outline_rounded;
  } else if (isSuccess) {
    background = colorScheme.primaryContainer;
    foreground = colorScheme.onPrimaryContainer;
    icon = Icons.check_circle_outline_rounded;
  } else {
    background = colorScheme.inverseSurface;
    foreground = colorScheme.onInverseSurface;
    icon = Icons.info_outline_rounded;
  }

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      duration: Duration(seconds: isError ? 4 : 3),
    ),
  );
}
