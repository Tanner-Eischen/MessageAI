import 'package:flutter/material.dart';

/// MessageAI Theme System
/// Monochrome black/white/gray palette for clean, accessible design
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // ============================================================================
  // COLORS - Grayscale System
  // ============================================================================
  
  /// Pure colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  /// Gray scale (Light Mode)
  static const Color gray50 = Color(0xFFFAFAFA);   // Almost white
  static const Color gray100 = Color(0xFFF5F5F5);  // Off white
  static const Color gray200 = Color(0xFFEEEEEE);  // Very light gray
  static const Color gray300 = Color(0xFFE0E0E0);  // Light gray
  static const Color gray400 = Color(0xFFBDBDBD);  // Light-medium gray
  static const Color gray500 = Color(0xFF9E9E9E);  // Medium gray
  static const Color gray600 = Color(0xFF757575);  // Medium-dark gray
  static const Color gray700 = Color(0xFF616161);  // Dark gray
  static const Color gray800 = Color(0xFF424242);  // Very dark gray
  static const Color gray900 = Color(0xFF212121);  // Almost black
  
  /// Dark mode grays
  static const Color darkGray100 = Color(0xFF1A1A1A);  // Near black surface
  static const Color darkGray200 = Color(0xFF242424);  // Dark surface
  static const Color darkGray300 = Color(0xFF2E2E2E);  // Medium dark
  static const Color darkGray400 = Color(0xFF3A3A3A);  // Lighter dark
  
  /// Accent colors (minimal use only)
  static const Color accentBlue = Color(0xFF000000);     // Actions, links
  static const Color accentGreen = Color(0xFF4CAF50);    // Online, success
  static const Color accentRed = Color(0xFFF44336);      // Error, urgent
  static const Color accentOrange = Color(0xFFFF9800);   // Warning
  
  /// Peek Zone Icon Colors
  static const Color rsdColor = Color(0xFFFFC107);       // Amber for RSD
  static const Color boundaryColor = Color(0xFFFF9800);  // Orange for Boundaries
  static const Color actionColor = Color(0xFF4CAF50);    // Green for Actions
  
  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================
  
  /// Font sizes
  static const double fontSizeXXL = 32.0;  // Page titles
  static const double fontSizeXL = 24.0;   // Section headers
  static const double fontSizeL = 20.0;    // Card titles
  static const double fontSizeM = 16.0;    // Body text (BASE)
  static const double fontSizeS = 14.0;    // Captions
  static const double fontSizeXS = 12.0;   // Timestamps
  static const double fontSizeXXS = 10.0;  // Micro-copy
  
  /// Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  /// Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;
  
  // ============================================================================
  // SPACING
  // ============================================================================
  
  /// Base unit: 4px - all spacing uses multiples of this
  static const double spacingXXS = 4.0;
  static const double spacingXS = 8.0;
  static const double spacingS = 12.0;
  static const double spacingM = 16.0;   // Standard spacing (BASE)
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingXXXL = 64.0;
  
  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  
  static const double radiusNone = 0.0;
  static const double radiusXS = 2.0;
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;    // Standard radius (BASE)
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;
  static const double radiusPill = 9999.0;
  
  // ============================================================================
  // SHADOWS
  // ============================================================================
  
  /// Light mode shadows
  static List<BoxShadow> get shadow1Light => [
    BoxShadow(
      color: black.withOpacity(0.12),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: black.withOpacity(0.08),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get shadow2Light => [
    BoxShadow(
      color: black.withOpacity(0.12),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: black.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadow3Light => [
    BoxShadow(
      color: black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  
  /// Dark mode shadows (more subtle)
  static List<BoxShadow> get shadow1Dark => [
    BoxShadow(
      color: black.withOpacity(0.30),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: black.withOpacity(0.20),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get shadow2Dark => [
    BoxShadow(
      color: black.withOpacity(0.35),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: black.withOpacity(0.25),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  // ============================================================================
  // THEME DATA
  // ============================================================================
  
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: accentBlue,
        onPrimary: white,
        secondary: gray900,
        onSecondary: white,
        surface: white,
        onSurface: black,
        surfaceContainerHighest: gray100,
        error: accentRed,
        onError: white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: white,
      
      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: fontSizeL,
          fontWeight: fontWeightSemibold,
        ),
        iconTheme: IconThemeData(
          color: black,
          size: 24,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: const BorderSide(color: gray300, width: 1),
        ),
        margin: const EdgeInsets.all(spacingS),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXL,
          fontWeight: fontWeightBold,
          color: black,
          height: lineHeightTight,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightBold,
          color: black,
          height: lineHeightTight,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeL,
          fontWeight: fontWeightSemibold,
          color: black,
          height: lineHeightTight,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightRegular,
          color: black,
          height: lineHeightNormal,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeS,
          fontWeight: fontWeightRegular,
          color: gray800,
          height: lineHeightNormal,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeXS,
          fontWeight: fontWeightRegular,
          color: gray600,
          height: lineHeightNormal,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightSemibold,
          color: black,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeS,
          fontWeight: fontWeightMedium,
          color: black,
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeS,
            fontWeight: fontWeightSemibold,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeS,
            fontWeight: fontWeightSemibold,
          ),
        ),
      ),
      
      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: black,
        foregroundColor: white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: gray300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: gray300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
        hintStyle: const TextStyle(color: gray500),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: gray300,
        thickness: 1,
        space: 1,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: black,
        size: 24,
      ),
    );
  }
  
  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        onPrimary: black,
        secondary: white,
        onSecondary: black,
        surface: black,
        onSurface: white,
        surfaceContainerHighest: darkGray100,
        error: accentRed,
        onError: black,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: black,
      
      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: fontSizeL,
          fontWeight: fontWeightSemibold,
        ),
        iconTheme: IconThemeData(
          color: white,
          size: 24,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: darkGray100,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: const BorderSide(color: darkGray300, width: 1),
        ),
        margin: const EdgeInsets.all(spacingS),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXL,
          fontWeight: fontWeightBold,
          color: white,
          height: lineHeightTight,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightBold,
          color: white,
          height: lineHeightTight,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeL,
          fontWeight: fontWeightSemibold,
          color: white,
          height: lineHeightTight,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightRegular,
          color: white,
          height: lineHeightNormal,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeS,
          fontWeight: fontWeightRegular,
          color: gray400,
          height: lineHeightNormal,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeXS,
          fontWeight: fontWeightRegular,
          color: gray500,
          height: lineHeightNormal,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightSemibold,
          color: white,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeS,
          fontWeight: fontWeightMedium,
          color: white,
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          foregroundColor: black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeS,
            fontWeight: fontWeightSemibold,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeS,
            fontWeight: fontWeightSemibold,
          ),
        ),
      ),
      
      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: darkGray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: darkGray300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: darkGray300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
        hintStyle: const TextStyle(color: gray600),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: darkGray300,
        thickness: 1,
        space: 1,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: white,
        size: 24,
      ),
    );
  }
}

