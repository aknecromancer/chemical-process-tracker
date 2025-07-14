import 'package:flutter/material.dart';

/// Premium Color System for Chemical Process Tracker
/// Industry-specific color palette for enterprise applications
class AppColors {
  // Private constructor
  AppColors._();

  /// Primary Brand Colors - Industrial Blue Series
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlue50 = Color(0xFFE3F2FD);
  static const Color primaryBlue100 = Color(0xFFBBDEFB);
  static const Color primaryBlue200 = Color(0xFF90CAF9);
  static const Color primaryBlue300 = Color(0xFF64B5F6);
  static const Color primaryBlue400 = Color(0xFF42A5F5);
  static const Color primaryBlue500 = Color(0xFF2196F3);
  static const Color primaryBlue600 = Color(0xFF1E88E5);
  static const Color primaryBlue700 = Color(0xFF1976D2);
  static const Color primaryBlue800 = Color(0xFF1565C0);
  static const Color primaryBlue900 = Color(0xFF0D47A1);

  /// Secondary Brand Colors - Chemical Orange Series
  static const Color secondaryOrange = Color(0xFFFF8F00);
  static const Color secondaryOrange50 = Color(0xFFFFF8E1);
  static const Color secondaryOrange100 = Color(0xFFFFECB3);
  static const Color secondaryOrange200 = Color(0xFFFFE082);
  static const Color secondaryOrange300 = Color(0xFFFFD54F);
  static const Color secondaryOrange400 = Color(0xFFFFCA28);
  static const Color secondaryOrange500 = Color(0xFFFFC107);
  static const Color secondaryOrange600 = Color(0xFFFFB300);
  static const Color secondaryOrange700 = Color(0xFFFFA000);
  static const Color secondaryOrange800 = Color(0xFFFF8F00);
  static const Color secondaryOrange900 = Color(0xFFE65100);

  /// Status Colors - Professional Grade
  /// Success (Profit/Good Status)
  static const Color success = Color(0xFF2E7D32);
  static const Color success50 = Color(0xFFE8F5E8);
  static const Color success100 = Color(0xFFC8E6C9);
  static const Color success200 = Color(0xFFA5D6A7);
  static const Color success300 = Color(0xFF81C784);
  static const Color success400 = Color(0xFF66BB6A);
  static const Color success500 = Color(0xFF4CAF50);
  static const Color success600 = Color(0xFF43A047);
  static const Color success700 = Color(0xFF388E3C);
  static const Color success800 = Color(0xFF2E7D32);
  static const Color success900 = Color(0xFF1B5E20);

  /// Warning (Attention/Amber Status)
  static const Color warning = Color(0xFFF57F17);
  static const Color warning50 = Color(0xFFFFFDE7);
  static const Color warning100 = Color(0xFFFFF9C4);
  static const Color warning200 = Color(0xFFFFF59D);
  static const Color warning300 = Color(0xFFFFF176);
  static const Color warning400 = Color(0xFFFFEE58);
  static const Color warning500 = Color(0xFFFFEB3B);
  static const Color warning600 = Color(0xFFFDD835);
  static const Color warning700 = Color(0xFFFBC02D);
  static const Color warning800 = Color(0xFFF9A825);
  static const Color warning900 = Color(0xFFF57F17);

  /// Error (Loss/Critical Status)
  static const Color error = Color(0xFFC62828);
  static const Color error50 = Color(0xFFFFEBEE);
  static const Color error100 = Color(0xFFFFCDD2);
  static const Color error200 = Color(0xFFEF9A9A);
  static const Color error300 = Color(0xFFE57373);
  static const Color error400 = Color(0xFFEF5350);
  static const Color error500 = Color(0xFFF44336);
  static const Color error600 = Color(0xFFE53935);
  static const Color error700 = Color(0xFFD32F2F);
  static const Color error800 = Color(0xFFC62828);
  static const Color error900 = Color(0xFFB71C1C);

  /// Info Colors
  static const Color info = Color(0xFF0277BD);
  static const Color info50 = Color(0xFFE1F5FE);
  static const Color info100 = Color(0xFFB3E5FC);
  static const Color info200 = Color(0xFF81D4FA);
  static const Color info300 = Color(0xFF4FC3F7);
  static const Color info400 = Color(0xFF29B6F6);
  static const Color info500 = Color(0xFF03A9F4);
  static const Color info600 = Color(0xFF039BE5);
  static const Color info700 = Color(0xFF0288D1);
  static const Color info800 = Color(0xFF0277BD);
  static const Color info900 = Color(0xFF01579B);

  /// Neutral Grays - Professional Palette
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
  static const Color neutral1000 = Color(0xFF000000);

  /// Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  static const Color surfaceContainer = Color(0xFFF3F4F6);
  static const Color surfaceContainerLow = Color(0xFFF9FAFB);
  static const Color surfaceContainerHigh = Color(0xFFE5E7EB);

  /// Data Visualization Colors
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF009688), // Teal
    Color(0xFF3F51B5), // Indigo
    Color(0xFFE91E63), // Pink
    Color(0xFF795548), // Brown
  ];

  /// Chart Color Variations for Analytics
  static const Color chartBlue = Color(0xFF2196F3);
  static const Color chartBlueLight = Color(0xFF64B5F6);
  static const Color chartBlueDark = Color(0xFF1565C0);

  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color chartGreenLight = Color(0xFF81C784);
  static const Color chartGreenDark = Color(0xFF2E7D32);

  static const Color chartOrange = Color(0xFFFF9800);
  static const Color chartOrangeLight = Color(0xFFFFB74D);
  static const Color chartOrangeDark = Color(0xFFE65100);

  static const Color chartPurple = Color(0xFF9C27B0);
  static const Color chartPurpleLight = Color(0xFFBA68C8);
  static const Color chartPurpleDark = Color(0xFF6A1B9A);

  static const Color chartTeal = Color(0xFF009688);
  static const Color chartTealLight = Color(0xFF4DB6AC);
  static const Color chartTealDark = Color(0xFF00695C);

  static const Color chartIndigo = Color(0xFF3F51B5);
  static const Color chartIndigoLight = Color(0xFF7986CB);
  static const Color chartIndigoDark = Color(0xFF283593);

  /// Semantic Color Mappings
  /// Financial Status Colors
  static const Color profit = success;
  static const Color profitLight = success300;
  static const Color profitDark = success800;

  static const Color loss = error;
  static const Color lossLight = error300;
  static const Color lossDark = error800;

  static const Color breakeven = neutral500;
  static const Color breakevenLight = neutral300;
  static const Color breakevenDark = neutral700;

  /// Efficiency Status Colors
  static const Color efficiencyExcellent = success;
  static const Color efficiencyGood = info;
  static const Color efficiencyAverage = warning;
  static const Color efficiencyPoor = error;

  /// Material Type Colors
  static const Color rawMaterial = primaryBlue;
  static const Color derivedMaterial = secondaryOrange;
  static const Color product = success;
  static const Color byproduct = info;

  /// Batch Status Colors
  static const Color statusDraft = warning;
  static const Color statusCompleted = success;
  static const Color statusArchived = neutral500;

  /// Background Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue600, primaryBlue800],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success600, success800],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning600, warning800],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error600, error800],
  );

  static const LinearGradient neutralGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [neutral100, neutral200],
  );

  /// Shadow Colors
  static Color shadow = neutral1000.withOpacity(0.08);
  static Color shadowLight = neutral1000.withOpacity(0.04);
  static Color shadowMedium = neutral1000.withOpacity(0.12);
  static Color shadowHeavy = neutral1000.withOpacity(0.16);

  /// Overlay Colors
  static Color overlay = neutral1000.withOpacity(0.5);
  static Color overlayLight = neutral1000.withOpacity(0.3);
  static Color overlayHeavy = neutral1000.withOpacity(0.7);

  /// Border Colors
  static const Color border = neutral300;
  static const Color borderLight = neutral200;
  static const Color borderFocus = primaryBlue;
  static const Color borderError = error;
  static const Color borderSuccess = success;

  /// Text Colors
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textTertiary = neutral500;
  static const Color textOnPrimary = neutral0;
  static const Color textOnSurface = neutral900;

  /// Background Colors
  static const Color backgroundPrimary = neutral0;
  static const Color backgroundSecondary = neutral50;
  static const Color backgroundTertiary = neutral100;
  static const Color backgroundGradientStart = Color(0xFFF8FAFC);
  static const Color backgroundGradientEnd = Color(0xFFF1F5F9);

  /// Additional Semantic Colors
  static const Color successGreen = success;

  /// Utility Methods
  /// Get color for P&L value
  static Color getPnLColor(double value) {
    if (value > 0) return profit;
    if (value < 0) return loss;
    return breakeven;
  }

  /// Get color for efficiency percentage
  static Color getEfficiencyColor(double percentage) {
    if (percentage >= 8.0) return efficiencyExcellent;
    if (percentage >= 5.0) return efficiencyGood;
    if (percentage >= 2.0) return efficiencyAverage;
    return efficiencyPoor;
  }

  /// Get color for batch status
  static Color getBatchStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return statusDraft;
      case 'completed':
        return statusCompleted;
      case 'archived':
        return statusArchived;
      default:
        return neutral500;
    }
  }

  /// Get material type color
  static Color getMaterialTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'raw':
      case 'rawmaterial':
        return rawMaterial;
      case 'derived':
      case 'derivedmaterial':
        return derivedMaterial;
      case 'product':
        return product;
      case 'byproduct':
        return byproduct;
      default:
        return neutral500;
    }
  }
}