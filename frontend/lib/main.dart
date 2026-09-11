import 'package:clubapp_frontend/pantallas/home_page.dart';
import 'package:clubapp_frontend/pantallas/login_page.dart';
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
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Para importar LoginPage y HomePage:
// import 'lib/presentation/pages/auth/login_page.dart';
// import 'lib/presentation/pages/home/home_page.dart';