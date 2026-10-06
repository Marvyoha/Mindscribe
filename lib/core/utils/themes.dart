import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Themes {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
        primary: const Color(0xff4b0082),
        secondary: const Color(0xFF6366F1),
        surface: Color(0xffffffff),
        error: const Color(0xFFEF4444),
        tertiary: Colors.green,
      ),
      scaffoldBackgroundColor: const Color(0xfff6f6f4),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF818CF8),
        brightness: Brightness.dark,
        primary: const Color(0xffccccff),
        secondary: const Color(0xFF818CF8),
        surface: const Color.fromARGB(255, 20, 27, 39),
        error: const Color(0xFFF87171),
        tertiary: Colors.green,
      ),
      scaffoldBackgroundColor: const Color(0xff141414), // Deep Charcoal
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class Themes {
//   static ThemeData light() {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.light,
//       fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: const Color.fromARGB(255, 245, 92, 92),
//         brightness: Brightness.light,
//         primary: const Color(0xff4b0082),
//         secondary: const Color.fromARGB(255, 245, 92, 92),
//         surface: Color(0xffffffff),
//         error: const Color(0xFFEF4444),
//       ),
//       scaffoldBackgroundColor: const Color(0xfff6f6f4),
//       appBarTheme: const AppBarTheme(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         centerTitle: true,
//       ),
//     );
//   }

//   static ThemeData dark() {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: Color(0xffccccff),
//         brightness: Brightness.dark,
//         primary: const Color(0xffccccff),
//         secondary: const Color.fromARGB(255, 245, 92, 92),
//         surface: const Color(0XFF121212),
//         error: const Color(0xFFF87171),
//       ),
//       scaffoldBackgroundColor: const Color(0xff141414), // Deep Charcoal
//       appBarTheme: const AppBarTheme(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         centerTitle: true,
//       ),
//     );
//   }
// }
