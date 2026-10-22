import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/admin_widgets.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import '../services/admin_service.dart';

/// El administrador renombra un equipo, quita jugadores de su plantilla o elimina el equipo con todos sus datos.
class AdminEquipoPage extends StatefulWidget {
  final Map<String, dynamic> equipo;

  const AdminEquipoPage({super.key, required this.equipo});

  @override
  State<AdminEquipoPage> createState() => _AdminEquipoPageState();
}

class _AdminEquipoPageState extends State<AdminEquipoPage> {
  late final _nombre = TextEditingController(text: widget.equipo['nombre']?.toString());
  List<Map<String, dynamic>> _jugadores = [];
  String? _error;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _cargar() async {
    final r = await AdminService.plantilla(widget.equipo['id']);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = r['exito'] == true ? null : r['mensaje'].toString();
      if (r['exito'] == true) _jugadores = (r['datos'] as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _renombrar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) return _aviso('El nombre no puede estar vacío');
    setState(() => _guardando = true);
    final r = await AdminService.renombrarEquipo(widget.equipo['id'], nombre);
    if (!mounted) return;
    setState(() => _guardando = false);
    _aviso(r['exito'] == true ? 'Nombre actualizado' : r['mensaje'].toString());
  }

  Future<void> _quitar(Map<String, dynamic> j) async {
    final u = j['usuarios'] as Map<String, dynamic>? ?? {};
    final nombre = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
    final ok = await confirmar(context, titulo: 'Quitar jugador', mensaje: '¿Quitar a $nombre de este equipo? Su cuenta no se elimina.', accion: 'Quitar', peligro: true);
    if (!ok || !mounted) return;
    final r = await AdminService.quitarJugador(widget.equipo['id'], u['id'] as Object);
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    setState(() => _jugadores.remove(j));
    _aviso('Jugador quitado');
  }

  Future<void> _eliminar() async {
    final e = widget.equipo;
    final ok = await confirmar(
      context,
      titulo: 'Eliminar equipo',
      mensaje: 'Se borrará "${e['nombre']}" con su plantilla, su staff, sus inscripciones y los partidos que jugó (también se recalculan las tablas de posiciones).\n\nNo se puede deshacer.',
      accion: 'Eliminar todo',
      peligro: true,
    );
    if (!ok || !mounted) return;
    setState(() => _guardando = true);
    final r = await AdminService.eliminarEquipo(e['id']);
    if (!mounted) return;
    setState(() => _guardando = false);
    _aviso(r['exito'] == true ? 'Equipo eliminado' : r['mensaje'].toString());
    if (r['exito'] == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Equipo')),
        body: SafeArea(
          child: AdminCuerpo(
            cargando: _cargando,
            error: _error,
            onRefresh: _cargar,
            vacio: 'Este equipo no tiene jugadores',
            encabezado: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppTextField(label: 'Nombre del equipo', hint: 'Nombre', controller: _nombre),
              const SizedBox(height: 12),
              AppButton(label: 'Guardar nombre', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _renombrar),
              const SizedBox(height: 24),
              Text('Plantilla (${_jugadores.length})', style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ]),
            hijos: [
              for (final j in _jugadores)
                AdminTarjeta(
                  leading: CircleAvatar(backgroundColor: AppColors.blue, child: Text('${j['dorsal'] ?? '-'}', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold))),
                  titulo: '${j['usuarios']?['nombre'] ?? ''} ${j['usuarios']?['apellido'] ?? ''}'.trim(),
                  subtitulo: (j['posicion'] ?? 'Sin posición').toString(),
                  trailing: IconButton(tooltip: 'Quitar del equipo', icon: const Icon(Icons.person_remove_outlined, color: AppColors.error), onPressed: () => _quitar(j)),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _guardando ? null : _eliminar,
                icon: const Icon(Icons.delete_forever, color: AppColors.error),
                label: const Text('Eliminar equipo y todos sus datos', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );
}