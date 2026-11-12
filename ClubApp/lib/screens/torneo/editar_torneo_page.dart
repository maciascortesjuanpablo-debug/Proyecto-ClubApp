import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/app_dropdown.dart';
import '../../components/app_text_field.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';

/// El organizador edita los datos de su torneo. Se cierra devolviendo `true` si guardó cambios.
/// El deporte y el formato solo se pueden cambiar mientras el torneo no tenga partidos.
class EditarTorneoPage extends StatefulWidget {
  final Torneo torneo;
  final bool tienePartidos;
  final int equiposAceptados;

  const EditarTorneoPage({super.key, required this.torneo, required this.tienePartidos, required this.equiposAceptados});

  @override
  State<EditarTorneoPage> createState() => _EditarTorneoPageState();
}

class _EditarTorneoPageState extends State<EditarTorneoPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.torneo.nombre);
  late final _ciudad = TextEditingController(text: widget.torneo.ciudad ?? '');
  late final _maxEquipos = TextEditingController(text: widget.torneo.maxEquipos == 0 ? '' : '${widget.torneo.maxEquipos}');
  late final _jornadas = TextEditingController(text: widget.torneo.jornadaTotal?.toString() ?? '');

  Map<Object, String> _deportes = {};
  Map<Object, String> _formatos = {};
  late Object? _deporteId = widget.torneo.deporteId;
  late Object? _formatoId = widget.torneo.formatoId;
  bool _cargandoCatalogos = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (!widget.tienePartidos) _cargarCatalogos();
  }

  @override
  void dispose() {
    for (final c in [_nombre, _ciudad, _maxEquipos, _jornadas]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    setState(() => _cargandoCatalogos = true);
    final r = await Future.wait([TournamentService.deportes(), TournamentService.formatos()]);
    if (!mounted) return;
    Map<Object, String> mapa(List<Map<String, dynamic>>? l) => {for (final e in l ?? <Map<String, dynamic>>[]) e['id'] as Object: e['nombre'].toString()};
    setState(() {
      _deportes = mapa(r[0]);
      _formatos = mapa(r[1]);
      _cargandoCatalogos = false;
    });
  }

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  String? _validarMaximo(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 2 || n > 256) return 'Número entre 2 y 256';
    if (n < widget.equiposAceptados) return 'Ya hay ${widget.equiposAceptados} equipos aceptados';
    return null;
  }

  String? _validarJornadas(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = int.tryParse(v!);
    return n == null || n < 0 || n > 500 ? 'Número entre 0 y 500' : null;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = widget.torneo;
    final cambios = <String, dynamic>{
      if (_nombre.text.trim() != t.nombre) 'nombre': _nombre.text.trim(),
      if (_ciudad.text.trim() != (t.ciudad ?? '')) 'ciudad': _ciudad.text.trim(),
      if (int.parse(_maxEquipos.text) != t.maxEquipos) 'max_equipos': int.parse(_maxEquipos.text),
      if (_jornadas.text.trim() != (t.jornadaTotal?.toString() ?? '')) 'jornada_total': _jornadas.text.trim().isEmpty ? null : int.parse(_jornadas.text),
      if (!widget.tienePartidos && _deporteId != null && '$_deporteId' != '${t.deporteId}') 'deporte_id': _deporteId,
      if (!widget.tienePartidos && _formatoId != null && '$_formatoId' != '${t.formatoId}') 'formato_id': _formatoId,
    };
    if (cambios.isEmpty) return _aviso('No hay cambios para guardar');

    setState(() => _guardando = true);
    final r = await TournamentService.actualizar(t.id, cambios);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    _aviso('Torneo actualizado');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                AppTextField(label: 'Ciudad o municipio', hint: 'Ej: Neiva, Huila', controller: _ciudad),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: AppTextField(label: 'Máx. equipos', hint: '16', controller: _maxEquipos, keyboardType: TextInputType.number, validator: _validarMaximo)),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(label: 'Jornadas (opcional)', hint: '10', controller: _jornadas, keyboardType: TextInputType.number, validator: _validarJornadas)),
                ]),
                const SizedBox(height: 16),
                if (widget.tienePartidos)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'Deporte: ${widget.torneo.deporte} · Formato: ${widget.torneo.formato}\nNo se pueden cambiar porque el torneo ya tiene partidos.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textGray, height: 1.4),
                    ),
                  )
                else if (_cargandoCatalogos)
                  const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
                else ...[
                  AppDropdown<Object>(label: 'Deporte', hint: 'Selecciona el deporte', value: _deportes.containsKey(_deporteId) ? _deporteId : null, items: _deportes, onChanged: (v) => setState(() => _deporteId = v)),
                  const SizedBox(height: 16),
                  AppDropdown<Object>(label: 'Formato', hint: 'Selecciona el formato', value: _formatos.containsKey(_formatoId) ? _formatoId : null, items: _formatos, onChanged: (v) => setState(() => _formatoId = v)),
                ],
                const SizedBox(height: 28),
                AppButton(label: 'Guardar cambios', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _guardar),
              ]),
            ),
          ),
        ),
      );
}