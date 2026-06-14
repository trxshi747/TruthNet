import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors from 1.png
  static const Color darkPurple = Color(0xFF312C51);
  static const Color mediumPurple = Color(0xFF48426D);
  static const Color peach = Color(0xFFF0C38E);
  static const Color coral = Color(0xFFF1AA9B);
  
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color primary = peach;
  static Color surface = white.withOpacity(0.1);
  static Color glassBorder = white.withOpacity(0.2);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkPurple,
      colorScheme: const ColorScheme.dark(
        primary: peach,
        secondary: coral,
        surface: mediumPurple,
        onSurface: white,
        onPrimary: darkPurple,
        onSecondary: darkPurple,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: white),
        titleTextStyle: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: peach,
        selectionColor: Color(0x66F0C38E),
        selectionHandleColor: peach,
      ),
      textTheme: GoogleFonts.righteousTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.righteous(color: peach),
        displayMedium: GoogleFonts.righteous(color: peach),
        displaySmall: GoogleFonts.righteous(color: peach),
        headlineLarge: GoogleFonts.righteous(color: peach),
        headlineMedium: GoogleFonts.righteous(color: peach),
        headlineSmall: GoogleFonts.righteous(color: peach),
        titleLarge: GoogleFonts.righteous(color: peach, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.spaceMono(color: white),
        bodyMedium: GoogleFonts.spaceMono(color: white.withOpacity(0.7)),
        bodySmall: GoogleFonts.spaceMono(color: white.withOpacity(0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: peach,
          foregroundColor: darkPurple,
          textStyle: GoogleFonts.righteous(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        color: mediumPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  // Light theme using the same palette but adjusted if needed, 
  // though the request implies "only these colors" which are dark-leaning.
  static ThemeData get lightTheme {
    return darkTheme; // Defaulting to dark as per image style
  }
}
