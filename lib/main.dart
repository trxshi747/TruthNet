import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:model2/screens/login_screen.dart';
import 'package:model2/screens/home_screen.dart';
import 'package:model2/screens/profile_screen.dart';
import 'package:model2/screens/post_screen.dart';
import 'package:model2/screens/message_screen.dart';
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
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/profile': (context) => ProfileScreen(),
          '/post': (context) => PostScreen(),
          '/message': (context) => MessageScreen(),
        },
      ),
    );
  }
}
