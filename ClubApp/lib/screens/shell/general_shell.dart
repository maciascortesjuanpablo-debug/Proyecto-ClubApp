import 'package:flutter/material.dart';
import '../../components/app_dialogs.dart';
import '../../components/nav_bar.dart';
import '../home_page.dart';
import '../profile_page.dart';
import '../scout_page.dart';
import '../tournaments_page.dart';
import '../calendar_page.dart';

/// Navegación general: para invitados y para cuentas sin rol definido (Usuario). Solo consulta.
/// Quien ya eligió un rol usa su propia navegación (ver MainShell).
class GeneralShell extends StatefulWidget {
  final int initialIndex;
  const GeneralShell({super.key, this.initialIndex = 0});

  @override
  State<GeneralShell> createState() => _GeneralShellState();
}

class _GeneralShellState extends State<GeneralShell> {
  late int _index = widget.initialIndex;

  void _ir(int i) {
  // Scout AI se abre a pantalla completa (necesita el teclado y su propio historial)
  if (i == 4) {
    if (requireAuth(context)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ScoutPage()));
    }
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
          const CalendarPage(),
          const ScoutPage(), // Se abre a pantalla completa, no se muestra en el IndexedStack
        ]),
        bottomNavigationBar: BottomNavBar(currentIndex: _index, onTap: _ir),
      );
}
