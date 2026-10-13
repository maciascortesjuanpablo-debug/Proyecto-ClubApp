import 'package:flutter/material.dart';
import '../components/nav_bar.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'coming_soon_page.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  void _ir(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: [
          HomePage(onIrATab: _ir),
          const ComingSoonPage(titulo: 'Torneos', icono: Icons.emoji_events),
          const ProfilePage(),
          const ComingSoonPage(titulo: 'Mi equipo', icono: Icons.group, requiereLogin: true),
          const ComingSoonPage(titulo: 'Calendario', icono: Icons.calendar_today),
        ]),
        bottomNavigationBar: BottomNavBar(currentIndex: _index, onTap: _ir),
      );
}