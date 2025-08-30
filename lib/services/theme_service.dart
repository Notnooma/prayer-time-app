import 'package:flutter/material.dart';

class ThemeService {
  static const Color islamicGreen = Color(0xFF388E3C); // deep green
  static const Color softGreen = Color(0xFFA5D6A7);   // pastel green

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: islamicGreen,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    appBarTheme: const AppBarTheme(
      backgroundColor: islamicGreen,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.light(
      primary: islamicGreen,
      secondary: softGreen,
      background: const Color(0xFFFAFAFA),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
    ),
    fontFamily: 'Roboto',
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: islamicGreen,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: islamicGreen,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: islamicGreen,
      secondary: softGreen,
      background: const Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
    ),
    fontFamily: 'Roboto',
  );
}
