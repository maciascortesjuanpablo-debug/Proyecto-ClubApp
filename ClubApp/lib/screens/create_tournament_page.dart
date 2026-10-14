import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/app_button.dart';
import '../components/app_dropdown.dart';
import '../components/app_text_field.dart';
import '../components/citydrop_down.dart';
import '../components/home/load_error.dart';
import '../services/tournament_service.dart';

class CreateTournamentPage extends StatefulWidget {
  const CreateTournamentPage({super.key});

  @override
  State<CreateTournamentPage> createState() => _CreateTournamentPageState();
}

class _CreateTournamentPageState extends State<CreateTournamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _maxEquipos = TextEditingController(text: '16');
  final _jornadas = TextEditingController();

  Map<Object, String> _deportes = {};
  Map<Object, String> _formatos = {};
  Object? _deporteId;
  Object? _formatoId;
  String? _ciudad;
  bool _cargando = true;
  bool _errorCatalogo = false;
  bool _guardando = false;


  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    for (final c in [_nombre, _maxEquipos, _jornadas]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargando = true;
      _errorCatalogo = false;
    });
    final r = await Future.wait([TournamentService.deportes(), TournamentService.formatos()]);
    if (!mounted) return;
    Map<Object, String> mapa(List<Map<String, dynamic>>? l) => {for (final e in l ?? <Map<String, dynamic>>[]) e['id'] as Object: e['nombre'].toString()};
    setState(() {
      _errorCatalogo = r[0] == null || r[1] == null;
      _deportes = mapa(r[0]);
      _formatos = mapa(r[1]);
      _cargando = false;
    });
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));


  String? _validarEquipos(String? v) {
    final n = int.tryParse(v ?? '');
    return n == null || n < 2 || n > 256 ? 'Ingresa un número entre 2 y 256' : null;
  }

  String? _validarJornadas(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    final n = int.tryParse(v);
    return n == null || n < 0 || n > 500 ? 'Ingresa un número entre 0 y 500' : null;
  }

  Future<void> _crear() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_deporteId == null || _formatoId == null) return _aviso('Selecciona el deporte y el formato');

    setState(() => _guardando = true);
    final r = await TournamentService.crear(
      nombre: _nombre.text.trim(),
      deporteId: _deporteId!,
      formatoId: _formatoId!,
      maxEquipos: int.parse(_maxEquipos.text),
      ciudad: _ciudad,
      jornadaTotal: int.tryParse(_jornadas.text.trim()),
    );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (r['exito'] != true) return _aviso(r['mensaje']);
    Navigator.pop(context, true); // la lista recarga y avisa
  }

  @override

  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Crear torneo')),
        body: SafeArea(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _errorCatalogo
                  ? Center(child: LoadError(onRetry: _cargarCatalogos))
                  : SingleChildScrollView(padding: const EdgeInsets.all(20), child: _formulario),
        ),
      );

  Widget get _formulario => Form(
        key: _formKey,
        child: Column(children: [
          AppTextField(
            label: 'Nombre del torneo',
            hint: 'Ej: Liga Amateur Bogotá 2026',
            controller: _nombre,
            validator: (v) => AppValidators.validateRequired(v, 'El nombre es requerido'),
          ),
          const SizedBox(height: 16),
          AppDropdown<Object>(label: 'Deporte', hint: 'Selecciona un deporte', value: _deporteId, items: _deportes, onChanged: (v) => setState(() => _deporteId = v)),
          const SizedBox(height: 16),
          AppDropdown<Object>(label: 'Formato', hint: 'Selecciona un formato', value: _formatoId, items: _formatos, onChanged: (v) => setState(() => _formatoId = v)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Departamento (opcional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
              const SizedBox(height: 10),
              CityDropdown(selectedCity: _ciudad, onChanged: (c) => setState(() => _ciudad = c)),

            ]),
          ),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AppTextField(label: 'Máx. equipos', hint: '16', controller: _maxEquipos, keyboardType: TextInputType.number, validator: _validarEquipos),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(label: 'Jornadas (opcional)', hint: '10', controller: _jornadas, keyboardType: TextInputType.number, validator: _validarJornadas),
            ),
          ]),
          const SizedBox(height: 32),
          AppButton(label: 'Crear torneo', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _crear),
        ]),
      );
}