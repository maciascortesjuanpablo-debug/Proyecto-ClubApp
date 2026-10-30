import 'package:flutter/material.dart';
import '../../components/nav_bar.dart';
import '../../core/roles.dart';
import '../admin_page.dart';
import '../arbitro/arbitro_inicio_page.dart';
import '../arbitro/arbitro_partidos_page.dart';
import '../calendar_page.dart';
import '../entrenador/entrenador_inicio_page.dart';
import '../entrenador/mis_equipos_page.dart';
import '../jugador/jugador_equipo_page.dart';
import '../jugador/jugador_inicio_page.dart';
import '../organizador/inscripciones_page.dart';
import '../organizador/organizador_inicio_page.dart';
import '../profile_page.dart';
import '../tournaments_page.dart';
import 'shell_por_rol.dart';

/// La navegación de cada rol. Cada una tiene SOLO las pantallas que le corresponden.

class JugadorShell extends StatelessWidget {
  final int initialIndex;
  const JugadorShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) => ShellPorRol(roles: const {RolApp.jugador}, inicial: initialIndex, destinos: [
        DestinoShell(const NavDestino(Icons.home_rounded, 'Inicio'), (ir) => JugadorInicioPage(onIrATab: ir)),
        DestinoShell(const NavDestino(Icons.emoji_events_rounded, 'Torneos'), (_) => const TournamentsPage()),
        DestinoShell(const NavDestino(Icons.groups_rounded, 'Mi equipo'), (_) => const JugadorEquipoPage()),
        DestinoShell(const NavDestino(Icons.calendar_month_rounded, 'Calendario'), (_) => const CalendarPage(miosPorDefecto: true)),
        DestinoShell(const NavDestino(Icons.person_rounded, 'Perfil'), (_) => const ProfilePage()),
      ]);
}

class EntrenadorShell extends StatelessWidget {
  final int initialIndex;
  const EntrenadorShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) => ShellPorRol(roles: const {RolApp.entrenador}, inicial: initialIndex, destinos: [
        DestinoShell(const NavDestino(Icons.home_rounded, 'Inicio'), (ir) => EntrenadorInicioPage(onIrATab: ir)),
        DestinoShell(const NavDestino(Icons.emoji_events_rounded, 'Torneos'), (_) => const TournamentsPage()),
        DestinoShell(const NavDestino(Icons.groups_rounded, 'Equipos'), (_) => const MisEquiposPage()),
        DestinoShell(const NavDestino(Icons.calendar_month_rounded, 'Calendario'), (_) => const CalendarPage(miosPorDefecto: true)),
        DestinoShell(const NavDestino(Icons.person_rounded, 'Perfil'), (_) => const ProfilePage()),
      ]);
}

class OrganizadorShell extends StatelessWidget {
  final int initialIndex;
  const OrganizadorShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) => ShellPorRol(roles: const {RolApp.organizador}, inicial: initialIndex, destinos: [
        DestinoShell(const NavDestino(Icons.home_rounded, 'Inicio'), (ir) => OrganizadorInicioPage(onIrATab: ir)),
        DestinoShell(const NavDestino(Icons.emoji_events_rounded, 'Torneos'), (_) => const TournamentsPage()),
        DestinoShell(const NavDestino(Icons.how_to_reg_rounded, 'Inscrip.'), (_) => const InscripcionesPage()),
        DestinoShell(const NavDestino(Icons.calendar_month_rounded, 'Calendario'), (_) => const CalendarPage(miosPorDefecto: true)),
        DestinoShell(const NavDestino(Icons.person_rounded, 'Perfil'), (_) => const ProfilePage()),
      ]);
}

class ArbitroShell extends StatelessWidget {
  final int initialIndex;
  const ArbitroShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) => ShellPorRol(roles: const {RolApp.arbitro}, inicial: initialIndex, destinos: [
        DestinoShell(const NavDestino(Icons.home_rounded, 'Inicio'), (ir) => ArbitroInicioPage(onIrATab: ir)),
        DestinoShell(const NavDestino(Icons.sports_score_rounded, 'Partidos'), (_) => const ArbitroPartidosPage()),
        DestinoShell(const NavDestino(Icons.calendar_month_rounded, 'Calendario'), (_) => const CalendarPage(miosPorDefecto: true, permitirTodos: false, titulo: 'Mis designaciones')),
        DestinoShell(const NavDestino(Icons.person_rounded, 'Perfil'), (_) => const ProfilePage()),
      ]);
}

class AdminShell extends StatelessWidget {
  final int initialIndex;
  const AdminShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) => ShellPorRol(roles: const {RolApp.admin}, inicial: initialIndex, destinos: [
        DestinoShell(const NavDestino(Icons.dashboard_rounded, 'Panel'), (_) => const AdminPage()),
        DestinoShell(const NavDestino(Icons.emoji_events_rounded, 'Torneos'), (_) => const TournamentsPage()),
        DestinoShell(const NavDestino(Icons.calendar_month_rounded, 'Calendario'), (_) => const CalendarPage()),
        DestinoShell(const NavDestino(Icons.person_rounded, 'Perfil'), (_) => const ProfilePage()),
      ]);
}
