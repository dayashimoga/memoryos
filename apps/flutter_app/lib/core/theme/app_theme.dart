import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

/// MemoryOS Design System — tokens, typography, motion, elevation.
///
/// Provides a consistent premium design language inspired by Material You,
/// Nothing OS, and Arc Browser — with glass effects, spring animations,
/// and adaptive density.
abstract class DesignTokens {
  // ── Color Palette ──────────────────────────────────────────────────────────
  static const brand = Color(0xFF6366F1); // Indigo-500
  static const brandDark = Color(0xFF4F46E5); // Indigo-600
  static const accent = Color(0xFF8B5CF6); // Violet-500
  static const tertiary = Color(0xFF06B6D4); // Cyan-500
  static const success = Color(0xFF10B981); // Emerald-500
  static const warning = Color(0xFFF59E0B); // Amber-500
  static const error = Color(0xFFEF4444); // Red-500
  static const info = Color(0xFF3B82F6); // Blue-500

  // ── Surface Colors (dark) ─────────────────────────────────────────────────
  static const darkBg = Color(0xFF080B14); // True dark — deeper than slate
  static const darkSurface = Color(0xFF0F1624); // Base surface
  static const darkCard = Color(0xFF161D2E); // Elevated card
  static const darkOverlay = Color(0xFF1C2438); // Modal/overlay
  static const darkBorder = Color(0xFF252F47); // Subtle border

  // ── Surface Colors (light) ────────────────────────────────────────────────
  static const lightBg = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);

  // ── Radius ────────────────────────────────────────────────────────────────
  static const radiusXs = 6.0;
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 18.0;
  static const radiusXl = 24.0;
  static const radiusXxl = 32.0;
  static const radiusFull = 999.0;

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const space2 = 2.0;
  static const space4 = 4.0;
  static const space6 = 6.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const space40 = 40.0;
  static const space48 = 48.0;

  // ── Icon sizes ────────────────────────────────────────────────────────────
  static const iconSm = 16.0;
  static const iconMd = 20.0;
  static const iconLg = 24.0;
  static const iconXl = 32.0;

  // ── Animation Durations ───────────────────────────────────────────────────
  static const durationFast = Duration(milliseconds: 150);
  static const durationNormal = Duration(milliseconds: 250);
  static const durationSlow = Duration(milliseconds: 400);
  static const durationVerySlow = Duration(milliseconds: 600);

  // ── Animation Curves ──────────────────────────────────────────────────────
  static const curveSnappy = Curves.easeOutCubic;
  static const curveSpring = Curves.elasticOut;
  static const curveSmooth = Curves.easeInOutCubic;
  static const curveDeccel = Curves.decelerate;

  // ── Category Colors ───────────────────────────────────────────────────────
  static const categoryColors = <String, Color>{
    'Cloud': Color(0xFF6366F1),
    'Security': Color(0xFFEF4444),
    'Development': Color(0xFF3B82F6),
    'Finance': Color(0xFF10B981),
    'Invoice': Color(0xFFF59E0B),
    'Receipt': Color(0xFF06B6D4),
    'Meeting': Color(0xFF8B5CF6),
    'Chess': Color(0xFF64748B),
    'Learning': Color(0xFFEC4899),
    'Travel': Color(0xFF14B8A6),
    'Medical': Color(0xFFEF4444),
    'Personal': Color(0xFF8B5CF6),
    'Work': Color(0xFF3B82F6),
    'Screenshot': Color(0xFF6366F1),
    'Unknown': Color(0xFF94A3B8),
  };
}

/// MemoryOS application theme system — Material 3 with premium design.
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({ColorScheme? dynamicScheme}) {
    final base = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: DesignTokens.brand,
          secondary: DesignTokens.accent,
          tertiary: DesignTokens.tertiary,
          brightness: Brightness.light,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: DesignTokens.lightBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: DesignTokens.lightBg,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: DesignTokens.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: DesignTokens.lightBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: base.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space16,
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space20,
            vertical: DesignTokens.space12,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        side: const BorderSide(color: DesignTokens.lightBorder),
        backgroundColor: DesignTokens.lightBg,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        elevation: 0,
        backgroundColor: DesignTokens.lightSurface,
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: DesignTokens.lightSurface,
        indicatorColor: DesignTokens.brand.withOpacity(0.12),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 11,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: DesignTokens.lightBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData darkTheme({ColorScheme? dynamicScheme}) {
    final base = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: DesignTokens.brand,
          secondary: DesignTokens.accent,
          tertiary: DesignTokens.tertiary,
          brightness: Brightness.dark,
          surface: DesignTokens.darkSurface,
          background: DesignTokens.darkBg,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        surface: DesignTokens.darkSurface,
        background: DesignTokens.darkBg,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: DesignTokens.darkBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: DesignTokens.darkBg,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: DesignTokens.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: DesignTokens.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: base.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space16,
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        side: const BorderSide(color: DesignTokens.darkBorder),
        backgroundColor: DesignTokens.darkCard,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFCBD5E1),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        elevation: 0,
        backgroundColor: DesignTokens.darkSurface,
        indicatorColor: Color(0xFF1E293B),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: DesignTokens.brand,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
        unselectedIconTheme: IconThemeData(color: Color(0xFF64748B)),
        selectedIconTheme: IconThemeData(color: DesignTokens.brand),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: DesignTokens.darkSurface,
        indicatorColor: DesignTokens.brand.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return TextStyle(
            fontFamily: 'Inter',
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
            color: selected ? DesignTokens.brand : const Color(0xFF64748B),
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: DesignTokens.darkBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor =
        brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
        fontSize: 48,
        letterSpacing: -1.5,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 36,
        letterSpacing: -1.0,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.5,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: -0.3,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: -0.2,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: mutedColor,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: mutedColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 10,
        color: mutedColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
