import 'package:flutter/material.dart';

/// Convenient [BuildContext] extensions to avoid boilerplate.
extension SafiraContextX on BuildContext {
  // ─── Theme ────────────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // ─── Colors shorthand ─────────────────────────────────────────────────────
  Color get primary => colorScheme.primary;
  Color get onPrimary => colorScheme.onPrimary;
  Color get secondary => colorScheme.secondary;
  Color get surface => colorScheme.surface;
  Color get error => colorScheme.error;

  // ─── MediaQuery ───────────────────────────────────────────────────────────
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  // ─── Responsiveness ───────────────────────────────────────────────────────
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;

  // ─── Navigation ───────────────────────────────────────────────────────────
  NavigatorState get navigator => Navigator.of(this);
  void pop<T>([T? result]) => navigator.pop(result);
  Future<T?> push<T>(Route<T> route) => navigator.push(route);

  // ─── Scaffold ─────────────────────────────────────────────────────────────
  ScaffoldMessengerState get messenger => ScaffoldMessenger.of(this);

  void showSnackBar(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          duration: duration,
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void showErrorSnackBar(String message) => showSnackBar(
        message,
        backgroundColor: colorScheme.error,
      );

  void showSuccessSnackBar(String message) => showSnackBar(
        message,
        backgroundColor: Colors.green.shade700,
      );

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) =>
      showDialog<bool>(
        context: this,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: isDangerous
                  ? FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    )
                  : null,
              onPressed: () => ctx.pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
}
