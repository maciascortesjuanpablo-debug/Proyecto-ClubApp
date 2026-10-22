import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/admin_widgets.dart';
import '../components/app_button.dart';
import '../components/app_dropdown.dart';
import '../components/app_text_field.dart';
import '../services/admin_service.dart';

/// El administrador edita cualquier dato de un torneo, cambia al organizador o lo elimina con todos sus datos.
class AdminTorneoPage extends StatefulWidget {
  final Map<String, dynamic> torneo;
  final Set<String> estadosExistentes; // estados que ya usan los torneos, para ofrecerlos en la lista

  const AdminTorneoPage({super.key, required this.torneo, this.estadosExistentes = const {}});

  @override
  State<AdminTorneoPage> createState() => _AdminTorneoPageState();
}

class _AdminTorneoPageState extends State<AdminTorneoPage> {
  static const _estadosBase = ['Activo', 'Finalizado', 'Cancelado'];

  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.torneo['nombre']?.toString());
  late final _ciudad = TextEditingController(text: widget.torneo['ciudad']?.toString());
  late final _maxEquipos = TextEditingController(text: widget.torneo['max_equipos']?.toString());
  late final _jornadaActual = TextEditingController(text: (widget.torneo['jornada_actual'] ?? 0).toString());
  late final _jornadaTotal = TextEditingController(text: widget.torneo['jornada_total']?.toString());
  late String? _estado = (widget.torneo['estado'] as String?)?.isEmpty ?? true ? null : widget.torneo['estado'] as String;
  Object? _organizadorId;
  Map<Object, String> _organizadores = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _organizadorId = widget.torneo['organizador_id'] as Object?;
    _cargarOrganizadores();
  }

  @override
  void dispose() {
    for (final c in [_nombre, _ciudad, _maxEquipos, _jornadaActual, _jornadaTotal]) {
      c.dispose();
    }
    super.dispose();
  }

  String _nombreDe(Map<String, dynamic> u) => '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();

  /// Candidatos a organizador: usuarios con rol Organizador (4) o Administrador (6). Siempre incluye al actual.
  Future<void> _cargarOrganizadores() async {
    final r = await Future.wait([AdminService.usuarios(rol: 4), AdminService.usuarios(rol: 6)]);
    if (!mounted) return;
    final mapa = <Object, String>{};
    final actual = widget.torneo['usuarios'] as Map<String, dynamic>?;
    if (_organizadorId != null && actual != null) mapa[_organizadorId!] = _nombreDe(actual);
    for (final respuesta in r) {
      if (respuesta['exito'] == true) {
        for (final u in (respuesta['usuarios'] as List).cast<Map<String, dynamic>>().where((u) => u['activo'] != false)) {
          mapa[u['id'] as Object] = _nombreDe(u);
        }
      }
    }
    setState(() => _organizadores = mapa);
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  void _terminar(Map<String, dynamic> r, String exito) {
    setState(() => _guardando = false);
    _aviso(r['exito'] == true ? exito : r['mensaje'].toString());
    if (r['exito'] == true) Navigator.pop(context);
  }

  String? _numero(String? v, int min, int max, {bool opcional = false}) {
    if (opcional && (v ?? '').trim().isEmpty) return null;
    final n = int.tryParse(v ?? '');
    return n == null || n < min || n > max ? 'Número entre $min y $max' : null;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_estado == null) return _aviso('Elige el estado del torneo');
    setState(() => _guardando = true);
    final r = await AdminService.actualizarTorneo(widget.torneo['id'], {
      'nombre': _nombre.text.trim(),
      'estado': _estado,
      'ciudad': _ciudad.text.trim(),
      'max_equipos': int.parse(_maxEquipos.text),
      'jornada_actual': int.parse(_jornadaActual.text),
      if (_jornadaTotal.text.trim().isNotEmpty) 'jornada_total': int.parse(_jornadaTotal.text),
      if (_organizadorId != null) 'organizador_id': _organizadorId,
    });
    if (!mounted) return;
    _terminar(r, 'Torneo actualizado');
  }

  Future<void> _eliminar() async {
    final t = widget.torneo;
    final ok = await confirmar(
      context,
      titulo: 'Eliminar torneo',
      mensaje: 'Se borrará "${t['nombre']}" junto con sus ${t['partidos']} partido(s), las inscripciones de ${t['equipos']} equipo(s), la tabla de posiciones y las estadísticas de esos partidos.\n\nNo se puede deshacer.',
      accion: 'Eliminar todo',
      peligro: true,
    );
    if (!ok || !mounted) return;
    setState(() => _guardando = true);
    final r = await AdminService.eliminarTorneo(t['id']);
    if (!mounted) return;
    _terminar(r, 'Torneo eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final estados = {..._estadosBase, ...widget.estadosExistentes.where((e) => e.isNotEmpty), if (_estado != null) _estado!};
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Editar torneo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(children: [
              AppTextField(label: 'Nombre', hint: 'Nombre del torneo', controller: _nombre, validator: (v) => (v ?? '').trim().isEmpty ? 'El nombre es requerido' : null),
              const SizedBox(height: 16),
              AppDropdown<String>(label: 'Estado', hint: 'Selecciona el estado', value: _estado, items: {for (final e in estados) e: e}, onChanged: (v) => setState(() => _estado = v)),
              const SizedBox(height: 16),
              AppDropdown<Object>(label: 'Organizador', hint: 'Cargando…', value: _organizadores.containsKey(_organizadorId) ? _organizadorId : null, items: _organizadores, onChanged: (v) => setState(() => _organizadorId = v)),
              const SizedBox(height: 16),
              AppTextField(label: 'Ciudad', hint: 'Ciudad o departamento', controller: _ciudad),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: AppTextField(label: 'Máx. equipos', hint: '16', controller: _maxEquipos, keyboardType: TextInputType.number, validator: (v) => _numero(v, 2, 256))),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Jornada actual', hint: '0', controller: _jornadaActual, keyboardType: TextInputType.number, validator: (v) => _numero(v, 0, 500))),
              ]),
              const SizedBox(height: 16),
              AppTextField(label: 'Jornadas totales (opcional)', hint: '10', controller: _jornadaTotal, keyboardType: TextInputType.number, validator: (v) => _numero(v, 0, 500, opcional: true)),
              const SizedBox(height: 28),
              AppButton(label: 'Guardar cambios', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _guardar),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _guardando ? null : _eliminar,
                icon: const Icon(Icons.delete_forever, color: AppColors.error),
                label: const Text('Eliminar torneo y todos sus datos', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}