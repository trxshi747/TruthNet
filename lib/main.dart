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
import 'package:model2/screens/admine/admin_screen.dart';
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
          scaffoldBackgroundColor: const Color(0xFF312C51),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF48426D),
            primary: const Color(0xFF48426D),
            secondary: const Color(0xFFF0C38E),
            tertiary: const Color(0xFFF1AA9B),
            surface: const Color(0xFF312C51),
            onSurface: Colors.white,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Color(0xFFF0C38E),
            selectionColor: Color(0x66F0C38E),
            selectionHandleColor: Color(0xFFF0C38E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          textTheme: GoogleFonts.spaceMonoTextTheme(
            ThemeData.dark().textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.righteous(color: const Color(0xFFF0C38E)),
            displayMedium: GoogleFonts.righteous(color: const Color(0xFFF0C38E)),
            displaySmall: GoogleFonts.righteous(color: const Color(0xFFF0C38E)),
            headlineLarge: GoogleFonts.righteous(color: const Color(0xFFF0C38E)),
            headlineMedium: GoogleFonts.righteous(color: const Color(0xFFF0C38E)),
            headlineSmall: GoogleFonts.righteous(color: const Color(0xFFF0C38E)),
            titleLarge: GoogleFonts.righteous(color: const Color(0xFFF0C38E), fontWeight: FontWeight.bold),
            bodyLarge: GoogleFonts.spaceMono(color: Colors.white),
            bodyMedium: GoogleFonts.spaceMono(color: Colors.white70),
          ),
        ),
        initialRoute: '/',
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
