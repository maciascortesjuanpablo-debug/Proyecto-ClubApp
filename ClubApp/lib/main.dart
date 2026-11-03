import 'package:flutter/material.dart';
import 'components/scout_burbuja.dart';
import 'core/app_theme.dart';
import 'screens/splash_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ClubApp',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        navigatorObservers: [ScoutObserver()],
        builder: (context, child) => Stack(children: [if (child != null) child, const ScoutBurbuja()]),
        home: const SplashScreen(),
      );
}