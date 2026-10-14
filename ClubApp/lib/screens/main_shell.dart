import 'package:flutter/material.dart';
import '../components/app_dialogs.dart';
import '../components/nav_bar.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'scout_page.dart';
import 'tournaments_page.dart';
import 'coming_soon_page.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  void _ir(int i) {
    // Scout AI se abre a pantalla completa (necesita el teclado y su propio historial)
    if (i == 5) {
      if (requireAuth(context)) Navigator.push(context, MaterialPageRoute(builder: (_) => const ScoutPage()));
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: [

          HomePage(onIrATab: _ir),
          const TournamentsPage(),
          const ProfilePage(),
          const ComingSoonPage(titulo: 'Mi equipo', icono: Icons.group, requiereLogin: true),
          const ScoutPage(), // Se abre a pantalla completa, no se muestra en el IndexedStack
        ]),
        bottomNavigationBar: BottomNavBar(currentIndex: _index, onTap: _ir),
      );
}
