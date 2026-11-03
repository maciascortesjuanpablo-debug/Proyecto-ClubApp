import 'package:flutter/material.dart';
import '../../components/nav_bar.dart';
import '../calendar_page.dart';
import '../login_page.dart';
import '../tournaments_page.dart';
import 'invitado_inicio_page.dart';

/// Navegación de quien entra SIN iniciar sesión: solo consulta (inicio, torneos, calendario) y un acceso directo para ingresar.
/// No tiene perfil ni Scout AI: eso es para quien tiene cuenta.
class InvitadoShell extends StatefulWidget {
  final int initialIndex;
  const InvitadoShell({super.key, this.initialIndex = 0});

  @override
  State<InvitadoShell> createState() => _InvitadoShellState();
}

class _InvitadoShellState extends State<InvitadoShell> {
  late int _index = widget.initialIndex.clamp(0, 2);
  late final Set<int> _visitadas = {_index};

  static const _destinos = [
    NavDestino(Icons.home_rounded, 'Inicio'),
    NavDestino(Icons.emoji_events_rounded, 'Torneos'),
    NavDestino(Icons.calendar_month_rounded, 'Calendario'),
    NavDestino(Icons.login_rounded, 'Ingresar'),
  ];

  void _ir(int i) {
    if (i == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    setState(() {
      _index = i;
      _visitadas.add(i);
    });
  }

  Widget _pagina(int i) {
    if (!_visitadas.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => InvitadoInicioPage(onIrATab: _ir),
      1 => const TournamentsPage(),
      _ => const CalendarPage(permitirTodos: false),
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: [for (var i = 0; i < 3; i++) _pagina(i)]),
        bottomNavigationBar: BottomNavBar(currentIndex: _index, onTap: _ir, items: _destinos),
      );
}