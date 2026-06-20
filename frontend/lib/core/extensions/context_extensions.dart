import 'package:flutter/material.dart';
import 'package:manager_connect/core/theme/app_theme_extensions.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  AppThemeExtension get appThemeExtension =>
      theme.extension<AppThemeExtension>()!;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? colorScheme.errorContainer
            : theme.snackBarTheme.backgroundColor,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  Future<T?> showMcBottomSheet<T>({
    required Widget Function(BuildContext) builder,
    double initialChildSize = 0.7,
    double maxChildSize = 0.9,
    double minChildSize = 0.5,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        minChildSize: minChildSize,
        expand: false,
        builder: (context, scrollController) => builder(context),
      ),
    );
  }
}
