import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

enum AppThemeStyle {
  islamic('Islamic', FlexScheme.green, Colors.green),
  ocean('Ocean Blue', FlexScheme.blue, Colors.blue),
  sunset('Sunset', FlexScheme.amber, Colors.orange),
  forest('Forest', FlexScheme.materialBaseline, Colors.teal),
  royal('Royal Purple', FlexScheme.deepPurple, Colors.deepPurple),
  elegant('Elegant Dark', FlexScheme.materialHc, Colors.blueGrey);

  const AppThemeStyle(this.name, this.flexScheme, this.primaryColor);
  final String name;
  final FlexScheme flexScheme;
  final Color primaryColor;
}

enum ArabicFontFamily {
  amiri('Amiri', 'Amiri'),
  scheherazade('Scheherazade New', 'Scheherazade New'),
  notoSansArabic('Noto Sans Arabic', 'Noto Sans Arabic'),
  cairo('Cairo', 'Cairo'),
  tajawal('Tajawal', 'Tajawal');

  const ArabicFontFamily(this.displayName, this.fontFamily);
  final String displayName;
  final String fontFamily;
}

class AppTheme {
  // Brand colors
  static const Color _primaryBlue = Color(0xFF667eea);
  static const Color _secondaryPurple = Color(0xFF764ba2);

  // Modern color palettes
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: _primaryBlue,
    onPrimary: Colors.white,
    secondary: _secondaryPurple,
    onSecondary: Colors.white,
    surface: Color(0xFFFFFBFE),
    onSurface: Color(0xFF1D1B20),
    surfaceContainerHighest: Color(0xFFE6E0E9),
    outline: Color(0xFF79747E),
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: Color(0xFF667eea),
    onPrimary: Color(0xFF000000),
    secondary: Color(0xFF764ba2),
    onSecondary: Color(0xFF000000),
    surface: Color(0xFF1D1B20),
    onSurface: Color(0xFFE6E1E5),
    surfaceContainerHighest: Color(0xFF4A4458),
    outline: Color(0xFF938F99),
  );

  // Typography
  static TextTheme _getTextTheme({
    required bool isArabic,
    ArabicFontFamily arabicFont = ArabicFontFamily.cairo,
    double fontScale = 1.0,
  }) {
    if (isArabic) {
      return GoogleFonts.getTextTheme(
        arabicFont.fontFamily,
        _baseTextTheme.apply(fontSizeFactor: fontScale),
      );
    }
    return GoogleFonts.robotoTextTheme(
        _baseTextTheme.apply(fontSizeFactor: fontScale));
  }

  static const TextTheme _baseTextTheme = TextTheme(
    displayLarge:
        TextStyle(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12),
    displayMedium:
        TextStyle(fontSize: 45, fontWeight: FontWeight.w400, height: 1.16),
    displaySmall:
        TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22),
    headlineLarge:
        TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.25),
    headlineMedium:
        TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.29),
    headlineSmall:
        TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.33),
    titleLarge:
        TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27),
    titleMedium:
        TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.50),
    titleSmall:
        TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
    bodyLarge:
        TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.50),
    bodyMedium:
        TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
    bodySmall:
        TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33),
    labelLarge:
        TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
    labelMedium:
        TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
    labelSmall:
        TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
  );

  // Light Theme
  static ThemeData lightTheme({
    AppThemeStyle style = AppThemeStyle.islamic,
    ArabicFontFamily arabicFont = ArabicFontFamily.cairo,
    double fontScale = 1.0,
    bool isHighContrast = false,
  }) {
    final colorScheme = isHighContrast
        ? _lightColorScheme.copyWith(
            primary: Colors.black,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          )
        : FlexThemeData.light(
            scheme: style.flexScheme,
            useMaterial3: true,
          ).colorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _getTextTheme(
        isArabic: false,
        arabicFont: arabicFont,
        fontScale: fontScale,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _getTextTheme(
          isArabic: false,
          arabicFont: arabicFont,
          fontScale: fontScale,
        ).titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.2),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return colorScheme.outline.withOpacity(0.3);
        }),
      ),
      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme({
    AppThemeStyle style = AppThemeStyle.islamic,
    ArabicFontFamily arabicFont = ArabicFontFamily.cairo,
    double fontScale = 1.0,
    bool isHighContrast = false,
  }) {
    final colorScheme = isHighContrast
        ? _darkColorScheme.copyWith(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
          )
        : FlexThemeData.dark(
            scheme: style.flexScheme,
            useMaterial3: true,
          ).colorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _getTextTheme(
        isArabic: false,
        arabicFont: arabicFont,
        fontScale: fontScale,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _getTextTheme(
          isArabic: false,
          arabicFont: arabicFont,
          fontScale: fontScale,
        ).titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.2),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return colorScheme.outline.withOpacity(0.3);
        }),
      ),
      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Arabic text theme for Quran verses
  static TextTheme arabicTextTheme({
    ArabicFontFamily arabicFont = ArabicFontFamily.cairo,
    double fontScale = 1.0,
  }) {
    return GoogleFonts.getTextTheme(
      arabicFont.fontFamily,
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          height: 1.8,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          height: 1.8,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          height: 1.8,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 1.8,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.8,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.8,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.8,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 2.0,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 2.0,
        ),
      ).apply(fontSizeFactor: fontScale),
    );
  }

  // Custom gradients
  static const Gradient islamicGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient oceanGradient = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient forestGradient = LinearGradient(
    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 12.0;
}
