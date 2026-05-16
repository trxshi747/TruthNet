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

import 'package:model2/core/theme/app_theme.dart';

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
        theme: AppTheme.darkTheme,
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
