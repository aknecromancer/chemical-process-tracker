import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Utility class for managing status bar appearance across the app
class StatusBarUtils {
  StatusBarUtils._();

  /// Apply primary status bar style (blue background, white icons)
  static void applyPrimaryStyle() {
    SystemChrome.setSystemUIOverlayStyle(AppTheme.lightSystemUiOverlay);
  }

  /// Apply transparent status bar style (for specific screens)
  static void applyTransparentStyle() {
    SystemChrome.setSystemUIOverlayStyle(AppTheme.transparentSystemUiOverlay);
  }

  /// Apply dark status bar style (for light backgrounds)
  static void applyDarkStyle() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  /// Apply custom status bar style with specific colors
  static void applyCustomStyle({
    required Color statusBarColor,
    required Brightness statusBarIconBrightness,
    required Brightness statusBarBrightness,
    Color? systemNavigationBarColor,
    Brightness? systemNavigationBarIconBrightness,
  }) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: statusBarColor,
      statusBarIconBrightness: statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness,
      systemNavigationBarColor: systemNavigationBarColor ?? Colors.white,
      systemNavigationBarIconBrightness: systemNavigationBarIconBrightness ?? Brightness.dark,
    ));
  }

  /// Widget wrapper that applies status bar style automatically
  static Widget wrapWithStatusBar({
    required Widget child,
    SystemUiOverlayStyle? style,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style ?? AppTheme.lightSystemUiOverlay,
      child: child,
    );
  }

  /// Check if current theme is dark
  static bool isDarkTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Apply theme-aware status bar style
  static void applyThemeAwareStyle(BuildContext context) {
    if (isDarkTheme(context)) {
      // Apply dark theme status bar style
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF121212),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF121212),
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    } else {
      // Apply light theme status bar style
      applyPrimaryStyle();
    }
  }
}