import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/screens/login_screen.dart';
import 'package:model2/screens/signup_screen.dart';
import 'package:model2/screens/home_screen.dart';
import 'package:model2/screens/profile_screen.dart';
import 'package:model2/screens/post_screen.dart';
import 'package:model2/screens/message_screen.dart';
import 'package:model2/screens/moderator_screen.dart';
import 'package:model2/screens/admin_screen.dart';
import 'package:model2/providers/auth_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'TruthNet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0D0D16), // Deep Cyberpunk Background
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00FFD1), // Neon Cyan
            primary: const Color(0xFF00FFD1),
            secondary: const Color(0xFFFF003C), // Neon Magenta
            tertiary: const Color(0xFFFFE600), // Neon Yellow/Gold
            surface: const Color(0xFF1A1A2E), // Slightly lighter surface
            onSurface: Colors.white,
            brightness: Brightness.dark,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Color(0xFF00FFD1),
            selectionColor: Color(0x6600FFD1),
            selectionHandleColor: Color(0xFF00FFD1),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          textTheme: GoogleFonts.spaceMonoTextTheme(
            ThemeData.dark().textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.righteous(color: const Color(0xFF00FFD1)),
            displayMedium: GoogleFonts.righteous(color: const Color(0xFF00FFD1)),
            displaySmall: GoogleFonts.righteous(color: const Color(0xFF00FFD1)),
            headlineLarge: GoogleFonts.righteous(color: const Color(0xFF00FFD1)),
            headlineMedium: GoogleFonts.righteous(color: const Color(0xFF00FFD1)),
            headlineSmall: GoogleFonts.righteous(color: const Color(0xFF00FFD1)),
            titleLarge: GoogleFonts.righteous(color: const Color(0xFF00FFD1), fontWeight: FontWeight.bold),
            bodyLarge: GoogleFonts.spaceMono(color: Colors.white),
            bodyMedium: GoogleFonts.spaceMono(color: Colors.white70),
          ),
        ),        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/signup': (context) => SignUpScreen(),
          '/home': (context) => HomeScreen(),
          '/profile': (context) => ProfileScreen(),
          '/post': (context) => PostScreen(),
          '/message': (context) => MessageScreen(),
          '/mod': (context) => ModeratorScreen(),
          '/admin': (context) => AdminScreen(),
        },
      ),
    );
  }
}
