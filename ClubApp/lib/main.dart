import 'package:flutter/material.dart';
import 'components/scout_burbuja.dart';
import 'core/app_theme.dart';
import 'services/notification_service.dart';
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
        scaffoldMessengerKey: scaffoldMessengerKey, // avisos de notificaciones nuevas desde cualquier pantalla
        navigatorObservers: [ScoutObserver()],
        // La burbuja de Scout AI flota sobre toda la app (solo con sesión iniciada)
        builder: (context, child) => Stack(children: [if (child != null) child, const ScoutBurbuja()]),
        home: const SplashScreen(),
      );
}