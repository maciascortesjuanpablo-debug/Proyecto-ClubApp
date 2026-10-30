import 'package:flutter/material.dart';
import '../../components/admin_widgets.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../services/panel_service.dart';
import '../../services/tournament_service.dart';
import '../torneo/torneo_page.dart';

/// Pestaña "Inscripciones" del ORGANIZADOR: solicitudes de equipos a SUS torneos, para aceptar o rechazar
class InscripcionesPage extends StatefulWidget {
  const InscripcionesPage({super.key});

  @override
  State<InscripcionesPage> createState() => _InscripcionesPageState();
}

class _InscripcionesPageState extends State<InscripcionesPage> {
  Future<void> _resolver(Inscripcion i, String estado, Future<void> Function() recargar) async {
    final ok = await confirmar(context, titulo: estado == 'Aceptado' ? 'Aceptar equipo' : 'Rechazar equipo', mensaje: '${i.equipo?.nombre ?? 'El equipo'} quedará como $estado en ${i.torneo?.nombre ?? 'el torneo'}.', accion: estado == 'Aceptado' ? 'Aceptar' : 'Rechazar', peligro: estado == 'Rechazado');
    if (!ok) return;
    final r = await TournamentService.resolverInscripcion(i.id, estado);
    if (!mounted) return;
    if (r['exito'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
      return;
    }
    await recargar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: CargadorLista<PanelOrganizador>(
            cargar: PanelService.organizador,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
            construir: (context, p, recargar) => [
              const Text('Inscripciones', style: TextStyle(fontSize: 24, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Equipos que quieren entrar a tus torneos', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
              const SizedBox(height: 16),
              if (p.pendientes.isEmpty) const EstadoVacio(icono: Icons.inbox_outlined, mensaje: 'No tienes solicitudes pendientes'),
              for (final i in p.pendientes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TarjetaBase(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        EquipoAvatar(nombre: i.equipo?.nombre ?? '?', logoUrl: i.equipo?.logoUrl),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(i.equipo?.nombre ?? 'Equipo', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: i.torneo == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TorneoPage(torneoId: i.torneo!.id, nombre: i.torneo!.nombre))),
                            child: Text('Quiere entrar a ${i.torneo?.nombre ?? 'un torneo'}', style: const TextStyle(fontSize: 12, color: AppColors.primaryLight)),
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => _resolver(i, 'Rechazado', recargar), child: const Text('Rechazar'))),
                        const SizedBox(width: 10),
                        Expanded(child: FilledButton(onPressed: () => _resolver(i, 'Aceptado', recargar), child: const Text('Aceptar'))),
                      ]),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      );
}
