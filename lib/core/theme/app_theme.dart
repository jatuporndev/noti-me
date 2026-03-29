import 'package:flutter/material.dart';

/// Product primary: friendly orange ([idea-reminer-app.txt]).
const Color kNotiMePrimary = Color(0xFFFFC26C);

ThemeData buildNotiMeTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kNotiMePrimary,
      primary: kNotiMePrimary,
    ),
  );
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: kNotiMePrimary,
      foregroundColor: Colors.black87,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kNotiMePrimary,
      foregroundColor: Colors.black87,
    ),
  );
}
