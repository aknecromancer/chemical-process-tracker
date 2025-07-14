import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium Enterprise Design System for Chemical Process Tracker
/// Industry-grade theming with professional color palette and typography
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Core Brand Colors - Industrial Precision Palette
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlueDark = Color(0xFF0D47A1);
  static const Color primaryBlueLight = Color(0xFF1976D2);
  
  static const Color secondaryOrange = Color(0xFFFF8F00);
  static const Color secondaryOrangeLight = Color(0xFFFFB74D);
  static const Color secondaryOrangeDark = Color(0xFFE65100);
  
  /// Status Colors - Professional Grade
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successGreenLight = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFF57F17);
  static const Color warningAmberLight = Color(0xFFFFB300);
  static const Color errorRed = Color(0xFFC62828);
  static const Color errorRedLight = Color(0xFFEF5350);
  
  /// Neutral Palette - Enterprise Grade
  static const Color neutralGrey50 = Color(0xFFFAFAFA);
  static const Color neutralGrey100 = Color(0xFFF5F5F5);
  static const Color neutralGrey200 = Color(0xFFEEEEEE);
  static const Color neutralGrey300 = Color(0xFFE0E0E0);
  static const Color neutralGrey400 = Color(0xFFBDBDBD);
  static const Color neutralGrey500 = Color(0xFF9E9E9E);
  static const Color neutralGrey600 = Color(0xFF757575);
  static const Color neutralGrey700 = Color(0xFF616161);
  static const Color neutralGrey800 = Color(0xFF424242);
  static const Color neutralGrey900 = Color(0xFF212121);
  
  /// Surface Colors
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF8F9FA);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  
  /// Accent Colors for Data Visualization
  static const Color chartBlue = Color(0xFF2196F3);
  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color chartOrange = Color(0xFFFF9800);
  static const Color chartPurple = Color(0xFF9C27B0);
  static const Color chartTeal = Color(0xFF009688);
  static const Color chartIndigo = Color(0xFF3F51B5);

  /// Typography Scale - Professional Hierarchy
  static const String primaryFontFamily = 'Inter';
  static const String dataFontFamily = 'JetBrainsMono';
  
  static const TextStyle headlineXL = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.33,
  );
  
  // Data-specific typography
  static const TextStyle dataLarge = TextStyle(
    fontFamily: dataFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );
  
  static const TextStyle dataMedium = TextStyle(
    fontFamily: dataFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.2,
  );
  
  static const TextStyle dataSmall = TextStyle(
    fontFamily: dataFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.2,
  );

  /// Spacing System - 8pt Grid
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  /// Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  
  // Alternative naming for compatibility
  static const double borderRadius4 = radiusSmall;
  static const double borderRadius8 = radiusMedium;
  static const double borderRadius12 = radiusLarge;
  static const double borderRadius16 = radiusXLarge;

  /// Elevation Levels
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationExtra = 16.0;

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primaryBlue,
      primaryContainer: Color(0xFFE3F2FD),
      onPrimary: Colors.white,
      onPrimaryContainer: primaryBlueDark,
      
      secondary: secondaryOrange,
      secondaryContainer: Color(0xFFFFF3E0),
      onSecondary: Colors.white,
      onSecondaryContainer: secondaryOrangeDark,
      
      tertiary: successGreen,
      tertiaryContainer: Color(0xFFE8F5E8),
      onTertiary: Colors.white,
      onTertiaryContainer: Color(0xFF1B5E20),
      
      error: errorRed,
      errorContainer: Color(0xFFFFEBEE),
      onError: Colors.white,
      onErrorContainer: Color(0xFFB71C1C),
      
      surface: surfaceWhite,
      surfaceContainer: surfaceGrey,
      surfaceContainerHigh: neutralGrey100,
      onSurface: neutralGrey900,
      onSurfaceVariant: neutralGrey700,
      
      outline: neutralGrey300,
      outlineVariant: neutralGrey200,
      
      background: surfaceGrey,
      onBackground: neutralGrey900,
      
      shadow: Color(0x1A000000),
      scrim: Color(0x54000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: primaryFontFamily,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: primaryBlue,
        titleTextStyle: TextStyle(
          color: neutralGrey900,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFontFamily,
        ),
        iconTheme: IconThemeData(color: neutralGrey700),
        actionsIconTheme: IconThemeData(color: neutralGrey700),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        color: surfaceWhite,
        surfaceTintColor: primaryBlue,
        shadowColor: Colors.black.withOpacity(0.08),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing8,
          vertical: spacing4,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevationLow,
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: neutralGrey300,
          disabledForegroundColor: neutralGrey500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            fontFamily: primaryFontFamily,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            fontFamily: primaryFontFamily,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing8,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            fontFamily: primaryFontFamily,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: neutralGrey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: neutralGrey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
        labelStyle: const TextStyle(
          color: neutralGrey600,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: primaryFontFamily,
        ),
        hintStyle: const TextStyle(
          color: neutralGrey500,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: primaryFontFamily,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: neutralGrey100,
        selectedColor: primaryBlue.withOpacity(0.12),
        disabledColor: neutralGrey200,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: primaryFontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        elevation: elevationMedium,
        selectedItemColor: primaryBlue,
        unselectedItemColor: neutralGrey500,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: primaryFontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: primaryFontFamily,
        ),
        type: BottomNavigationBarType.fixed,
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: neutralGrey200,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: neutralGrey700,
        size: 24,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryOrange,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
        shape: CircleBorder(),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: neutralGrey800,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: primaryFontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevationMedium,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: surfaceGrey,

      // Visual Density for Desktop
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Platform Brightness
      brightness: Brightness.light,
    );
  }

  /// System UI Overlay Style for Status Bar
  static const SystemUiOverlayStyle lightSystemUiOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// Custom Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successGreen, Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningAmber, secondaryOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorRed, Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Box Shadow Definitions
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}