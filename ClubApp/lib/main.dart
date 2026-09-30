import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/profile_page.dart';
import '../screens/splash_page.dart';
import '../screens/verify_code_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClubApp',
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

