import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Product primary: friendly orange ([idea-reminer-app.txt]).
const Color kNotiMePrimary = Color(0xFFFFC26C);

const String kFontFamily = 'IosevkaCharonMono';
const String kMonoFontFamily = 'IosevkaCharonMono';

ThemeData buildNotiMeTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kNotiMePrimary,
    primary: kNotiMePrimary,
    brightness: Brightness.light,
  );

  const base = TextStyle(fontFamily: kFontFamily);

  return ThemeData(
    useMaterial3: true,
    fontFamily: kFontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: TextTheme(
      displayLarge:  base.copyWith(fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -1.5),
      displayMedium: base.copyWith(fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -1.0),
      displaySmall:  base.copyWith(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineLarge:  base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: base.copyWith(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      headlineSmall:  base.copyWith(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleLarge:  base.copyWith(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      titleSmall:  base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0),
      bodyLarge:   base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0),
      bodyMedium:  base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0),
      bodySmall:   base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0),
      labelLarge:  base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
      labelSmall:  base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black12,
      centerTitle: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kNotiMePrimary,
      foregroundColor: Colors.black87,
      elevation: 2,
      focusElevation: 4,
      hoverElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: kNotiMePrimary.withValues(alpha: 0.35),
      elevation: 0,
      height: 64,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kNotiMePrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kNotiMePrimary,
        foregroundColor: Colors.black87,
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: colorScheme.outlineVariant),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 0.5,
    ),

    dialogTheme: DialogThemeData(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: colorScheme.surfaceContainerHigh,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontFamily: kFontFamily,
        color: colorScheme.onInverseSurface,
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.black87;
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return kNotiMePrimary;
        return null;
      }),
    ),
  );
}
