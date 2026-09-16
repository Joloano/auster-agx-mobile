import 'package:flutter/material.dart';

abstract final class AusterColors {
  static const primary50 = Color(0xFFEEF5FC);
  static const primary100 = Color(0xFFD6E6F5);
  static const primary300 = Color(0xFF5FA0DB);
  static const primary500 = Color(0xFF0261BD);
  static const primary700 = Color(0xFF034F9B);
  static const primary900 = Color(0xFF00366F);

  static const secondary50 = Color(0xFFEFFAF6);
  static const secondary100 = Color(0xFFD8F2E9);
  static const secondary300 = Color(0xFF4BC7A2);
  static const secondary500 = Color(0xFF00B37B);
  static const secondary700 = Color(0xFF009C52);
  static const secondary900 = Color(0xFF008236);

  static const neutral50 = Color(0xFFF8FAFC);
  static const neutral100 = Color(0xFFEEF2F5);
  static const neutral200 = Color(0xFFDDE4EA);
  static const neutral300 = Color(0xFFC7CDD1);
  static const neutral500 = Color(0xFF7A838A);
  static const neutral700 = Color(0xFF4A5054);
  static const neutral900 = Color(0xFF1C1D1D);

  static const outlineVariant = Color(0xFFC2C9BB);
  static const success = Color(0xFF009C52);
  static const warning = Color(0xFFE0A526);
  static const error = Color(0xFFD1483F);
  static const info = Color(0xFF0261BD);

  static const successBackground = Color(0xFFE7F6EF);
  static const warningBackground = Color(0xFFFFF4D7);
  static const errorBackground = Color(0xFFFCEBEA);
  static const infoBackground = Color(0xFFE7F1FB);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    const colorScheme = ColorScheme.light(
      primary: AusterColors.primary500,
      onPrimary: Colors.white,
      primaryContainer: AusterColors.primary100,
      onPrimaryContainer: AusterColors.primary900,
      secondary: AusterColors.secondary500,
      onSecondary: Colors.white,
      secondaryContainer: AusterColors.secondary100,
      onSecondaryContainer: AusterColors.secondary900,
      error: AusterColors.error,
      onError: Colors.white,
      errorContainer: AusterColors.errorBackground,
      onErrorContainer: Color(0xFF8F231D),
      surface: Colors.white,
      onSurface: AusterColors.neutral900,
      onSurfaceVariant: AusterColors.neutral700,
      outline: AusterColors.neutral300,
      outlineVariant: AusterColors.outlineVariant,
    );

    final bodyTheme = base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: AusterColors.neutral900,
      displayColor: AusterColors.neutral900,
    );
    final textTheme = bodyTheme.copyWith(
      displayLarge: _display(bodyTheme.displayLarge, 48),
      displayMedium: _display(bodyTheme.displayMedium, 42),
      displaySmall: _display(bodyTheme.displaySmall, 36),
      headlineLarge: _display(bodyTheme.headlineLarge, 34),
      headlineMedium: _display(bodyTheme.headlineMedium, 30),
      headlineSmall: _display(bodyTheme.headlineSmall, 27),
      titleLarge: bodyTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: bodyTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: bodyTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: bodyTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: bodyTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: bodyTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        color: AusterColors.neutral700,
      ),
      labelLarge: bodyTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AusterColors.neutral50,
      canvasColor: AusterColors.neutral50,
      dividerColor: AusterColors.neutral200,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AusterColors.neutral100,
        foregroundColor: AusterColors.neutral900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        toolbarHeight: 64,
        shape: Border(
          bottom: BorderSide(color: AusterColors.neutral200),
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AusterColors.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _inputBorder(AusterColors.neutral300),
        enabledBorder: _inputBorder(AusterColors.neutral300),
        focusedBorder: _inputBorder(AusterColors.primary500, width: 2),
        errorBorder: _inputBorder(AusterColors.error),
        focusedErrorBorder: _inputBorder(AusterColors.error, width: 2),
        labelStyle: const TextStyle(color: AusterColors.neutral700),
        hintStyle: const TextStyle(color: AusterColors.neutral500),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: AusterColors.primary500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AusterColors.neutral300,
          disabledForegroundColor: AusterColors.neutral700,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: AusterColors.primary700,
          side: const BorderSide(color: AusterColors.primary300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AusterColors.primary700,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AusterColors.neutral100,
        selectedColor: AusterColors.primary100,
        side: const BorderSide(color: AusterColors.neutral300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AusterColors.neutral700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: AusterColors.neutral100,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AusterColors.primary100,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AusterColors.primary700
                : AusterColors.neutral700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AusterColors.primary700
                : AusterColors.neutral700,
          );
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AusterColors.primary500,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AusterColors.neutral900,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  static TextStyle? _display(TextStyle? base, double size) {
    return base?.copyWith(
      fontFamily: 'BebasNeue',
      fontSize: size,
      fontWeight: FontWeight.w400,
      height: 1.05,
      letterSpacing: 0,
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
