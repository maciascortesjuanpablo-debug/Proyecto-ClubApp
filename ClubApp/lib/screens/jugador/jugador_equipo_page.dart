import 'package:flutter/material.dart';
import '../../components/admin_widgets.dart';
import '../../components/equipo_widgets.dart';
import '../../components/partido_tile.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/resultado.dart';
import '../../services/team_service.dart';
import '../event_detail_page.dart';

/// "Mi equipo" del JUGADOR: ve su equipo en modo consulta (balance, partidos, compañeros y cuerpo técnico).
/// No tiene herramientas de gestión: eso es del entrenador.
class JugadorEquipoPage extends StatefulWidget {
  const JugadorEquipoPage({super.key});

  @override
  State<JugadorEquipoPage> createState() => _JugadorEquipoPageState();
}

class _JugadorEquipoPageState extends State<JugadorEquipoPage> {
  Object? _elegido; // si juega en varios equipos

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Mi equipo')),
        body: CargadorLista<List<Equipo>>(
          cargar: TeamService.mios,
          construir: (context, equipos, _) {
            if (equipos.isEmpty) {
              return [const EstadoVacio(icono: Icons.groups_outlined, mensaje: 'Todavía no perteneces a ningún equipo.\nCuando un entrenador te invite, aparecerá en tu inicio.')];
            }
            final equipo = equipos.firstWhere((e) => '${e.id}' == '$_elegido', orElse: () => equipos.first);
            return [
              if (equipos.length > 1) ...[
                FiltroChips<Object>(opciones: {for (final e in equipos) e.nombre: e.id}, valor: equipo.id, onChanged: (v) => setState(() => _elegido = v)),
                const SizedBox(height: 12),
              ],
              _FichaEquipo(key: ValueKey(equipo.id), equipo: equipo),
            ];
          },
        ),
      );
}

class _FichaEquipo extends StatefulWidget {
  final Equipo equipo;
  const _FichaEquipo({super.key, required this.equipo});

  @override
  State<_FichaEquipo> createState() => _FichaEquipoState();
}

class _FichaEquipoState extends State<_FichaEquipo> {
  late final Future<List<dynamic>> _datos = Future.wait([TeamService.partidos(widget.equipo.id), TeamService.plantilla(widget.equipo.id), TeamService.staff(widget.equipo.id)]);

  @override
  Widget build(BuildContext context) {
    final e = widget.equipo;
    return FutureBuilder<List<dynamic>>(
      future: _datos,
      builder: (context, snap) {
        final cabecera = TarjetaBase(
          child: Row(children: [
            EquipoAvatar(nombre: e.nombre, logoUrl: e.logoUrl, tamano: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.nombre, style: const TextStyle(fontSize: 19, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${e.posicion ?? 'Jugador'}${e.dorsal != null ? ' · Dorsal ${e.dorsal}' : ''}${e.esTitular ? ' · Titular' : ''}', style: const TextStyle(fontSize: 12.5, color: AppColors.textGray)),
              ]),
            ),
          ]),
        );
        if (snap.connectionState != ConnectionState.done) {
          return Column(children: [cabecera, const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))]);
        }
        final partidosR = snap.data![0] as Resultado<({List<Partido> partidos, BalanceEquipo balance})>;
        final plantillaR = snap.data![1] as Resultado<List<JugadorPlantilla>>;
        final staffR = snap.data![2] as Resultado<List<MiembroStaff>>;
        final partidos = partidosR.dato?.partidos ?? const <Partido>[];
        final proximos = partidos.where((p) => p.esPartido && !p.finalizado && p.estado != 'Cancelado').take(3).toList();
        final jugados = partidos.where((p) => p.finalizado).toList().reversed.take(3).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          cabecera,
          const SizedBox(height: 12),
          FormaReciente(partidos: partidos, equipoId: e.id),
          const SeccionTitulo('Balance del equipo'),
          BalanceCard(partidosR.dato?.balance ?? const BalanceEquipo()),
          if (proximos.isNotEmpty) ...[
            const SeccionTitulo('Próximos partidos'),
            for (final p in proximos) PartidoTile(partido: p, mostrarFecha: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: p.id)))),
          ],
          if (jugados.isNotEmpty) ...[
            const SeccionTitulo('Últimos resultados'),
            for (final p in jugados) PartidoTile(partido: p, mostrarFecha: true, destacarEquipoId: e.id, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: p.id)))),
          ],
          SeccionTitulo('Compañeros (${plantillaR.dato?.length ?? 0})'),
          PlantillaLista(jugadores: plantillaR.dato ?? const [], miUsuarioId: AuthService.usuario?['id']),
          if ((staffR.dato ?? const []).isNotEmpty) ...[
            const SeccionTitulo('Cuerpo técnico'),
            StaffLista(staffR.dato!),
          ],
        ]);
      },
    );
  }
}
