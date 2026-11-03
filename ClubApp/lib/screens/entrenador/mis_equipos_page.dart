import 'package:flutter/material.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../services/team_service.dart';
import 'equipo_form_page.dart';
import 'gestion_equipo_page.dart';

/// Pestaña "Equipos" del ENTRENADOR: crea y administra sus equipos
class MisEquiposPage extends StatefulWidget {
  const MisEquiposPage({super.key});

  @override
  State<MisEquiposPage> createState() => _MisEquiposPageState();
}

class _MisEquiposPageState extends State<MisEquiposPage> {
  int _version = 0;

  Future<void> _crear() async {
    final creado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const EquipoFormPage()));
    if (creado == true && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _crear,
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.textWhite,
          icon: const Icon(Icons.add),
          label: const Text('Crear equipo', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: CargadorLista<List<Equipo>>(
            key: ValueKey(_version),
            cargar: TeamService.mios,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            construir: (context, equipos, recargar) => [
              const Text('Mis equipos', style: TextStyle(fontSize: 24, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Plantillas, alineación, invitaciones e inscripciones', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
              const SizedBox(height: 16),
              if (equipos.isEmpty)
                EstadoVacio(icono: Icons.groups_outlined, mensaje: 'Todavía no tienes equipos.\nCrea el primero con su escudo, formato y formación.', accion: FilledButton(onPressed: _crear, child: const Text('Crear equipo'))),
              for (final e in equipos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Tarjeta(
                    equipo: e,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => GestionEquipoPage(equipo: e)));
                      await recargar();
                    },
                  ),
                ),
            ],
          ),
        ),
      );
}

class _Tarjeta extends StatelessWidget {
  final Equipo equipo;
  final VoidCallback onTap;
  const _Tarjeta({required this.equipo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = equipo;
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 6, color: e.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  EquipoAvatar(nombre: e.nombre, logoUrl: e.logoUrl, tamano: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                      if (e.eslogan != null) Text('“${e.eslogan}”', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (e.formato != null) TournamentChip(e.formato!, color: AppColors.primaryLight),
                        if (e.formacion != null) TournamentChip(e.formacion!, color: AppColors.secondary),
                        TournamentChip('${e.jugadores}${e.maxJugadores != null ? '/${e.maxJugadores}' : ''} jugadores', color: AppColors.success, icono: Icons.person),
                      ]),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textGray),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}