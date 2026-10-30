import 'package:flutter/material.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../services/team_service.dart';
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
    final controlador = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Nuevo equipo', style: TextStyle(color: AppColors.textWhite)),
        content: TextField(controller: controlador, autofocus: true, maxLength: 80, style: const TextStyle(color: AppColors.textWhite), decoration: const InputDecoration(hintText: 'Nombre del equipo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, controlador.text.trim()), child: const Text('Crear', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty) return;
    final r = await TeamService.crear(nombre);
    if (!mounted) return;
    if (r['exito'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
      return;
    }
    setState(() => _version++);
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
              const Text('Administra plantillas, invitaciones e inscripciones', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
              const SizedBox(height: 16),
              if (equipos.isEmpty) const EstadoVacio(icono: Icons.groups_outlined, mensaje: 'Todavía no tienes equipos.\nToca "Crear equipo" para empezar.'),
              for (final e in equipos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TarjetaBase(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => GestionEquipoPage(equipo: e)));
                      await recargar();
                    },
                    child: Row(children: [
                      EquipoAvatar(nombre: e.nombre, logoUrl: e.logoUrl, tamano: 46),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.nombre, style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                        Text('${e.jugadores} jugador${e.jugadores == 1 ? '' : 'es'}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                      ])),
                      const Icon(Icons.chevron_right, color: AppColors.textGray),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      );
}
