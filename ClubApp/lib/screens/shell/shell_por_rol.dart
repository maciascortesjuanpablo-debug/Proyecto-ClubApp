import 'package:flutter/material.dart';
import '../../components/nav_bar.dart';
import '../../components/role_guard.dart';
import '../../core/roles.dart';

/// Una pestaña: su icono/etiqueta y la pantalla que muestra. [pagina] recibe una función para saltar a otra pestaña.
class DestinoShell {
  final NavDestino nav;
  final Widget Function(ValueChanged<int> irA) pagina;
  const DestinoShell(this.nav, this.pagina);
}

/// Estructura común de la navegación de un rol: barra inferior + pantallas cargadas al visitarlas por primera vez.
/// Está envuelta en RoleGuard: si la sesión no es de uno de los [roles], no se muestra.
class ShellPorRol extends StatefulWidget {
  final Set<RolApp> roles;
  final List<DestinoShell> destinos;
  final int inicial;

  const ShellPorRol({super.key, required this.roles, required this.destinos, this.inicial = 0});

  @override
  State<ShellPorRol> createState() => _ShellPorRolState();
}

class _ShellPorRolState extends State<ShellPorRol> {
  late int _index = widget.inicial.clamp(0, widget.destinos.length - 1);
  late final Set<int> _visitadas = {_index};

  void _ir(int i) => setState(() {
        _index = i;
        _visitadas.add(i);
      });

  @override
  Widget build(BuildContext context) => RoleGuard(
        roles: widget.roles,
        child: Scaffold(
          body: IndexedStack(index: _index, children: [
            for (var i = 0; i < widget.destinos.length; i++) _visitadas.contains(i) ? widget.destinos[i].pagina(_ir) : const SizedBox.shrink(),
          ]),
          bottomNavigationBar: BottomNavBar(currentIndex: _index, onTap: _ir, items: [for (final d in widget.destinos) d.nav]),
        ),
      );
}
