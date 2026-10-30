import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/perfil_constants.dart';
import '../core/roles.dart';
import '../core/validators.dart';
import '../components/app_button.dart';
import '../components/app_dropdown.dart';
import '../components/app_text_field.dart';
import '../components/citydrop_down.dart';
import '../components/date_picker_field.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// Edita los datos personales y el perfil de jugador. Al guardar vuelve con `true`.
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final Map<String, dynamic>? perfil; // null = todavía no tiene perfil de jugador

  const EditProfilePage({super.key, required this.usuario, this.perfil});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario['nombre']?.toString());
  late final _apellido = TextEditingController(text: widget.usuario['apellido']?.toString());
  late final _celular = TextEditingController(text: widget.usuario['numero_celular']?.toString());
  late final _fecha = TextEditingController(text: _aVisible(widget.usuario['fecha_nacimiento']));
  late final _posicion = TextEditingController(text: widget.perfil?['posicion']?.toString());
  late final _pais = TextEditingController(text: widget.perfil?['pais']?.toString());
  late final _tipo = TextEditingController(text: widget.perfil?['tipo_jugador']?.toString());

  late String? _ciudad = CityDropdown.cities.contains(widget.usuario['ciudad']) ? widget.usuario['ciudad'] as String : null;
  late String? _nivel = nivelesJuego.contains(widget.usuario['nivel_juego']) ? widget.usuario['nivel_juego'] as String : null;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _celular, _fecha, _posicion, _pais, _tipo]) {
      c.dispose();
    }
    super.dispose();
  }

  // El backend guarda AAAA-MM-DD y el selector de fecha muestra DD/MM/AAAA
  String _aVisible(dynamic iso) {
    final p = iso?.toString().split('T').first.split('-') ?? [];
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : '';
  }

  String _aIso(String visible) {
    final p = visible.split('/');
    return p.length == 3 ? '${p[2]}-${p[1]}-${p[0]}' : '';
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  // Solo el jugador tiene nivel de juego y perfil deportivo; los demás roles editan solo sus datos personales
  bool get _esJugador => RolApp.deId(widget.usuario['rol_id']) == RolApp.jugador;

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);

    final nombre = _nombre.text.trim();
    final apellido = _apellido.text.trim();
    final r = await ProfileService.actualizarUsuario({

      'nombre': nombre,
      'apellido': apellido,
      'numero_celular': _celular.text.trim(),
      'fecha_nacimiento': _aIso(_fecha.text.trim()),
      'ciudad': _ciudad ?? '',
      if (_esJugador) 'nivel_juego': _nivel ?? '',
    });
    if (r['exito'] != true) return _fallo(r['mensaje'].toString());

    final jugador = {'posicion': _posicion.text.trim(), 'pais': _pais.text.trim(), 'tipo_jugador': _tipo.text.trim()};
    if (_esJugador && (jugador.values.any((v) => v.isNotEmpty) || widget.perfil != null)) {
      final rj = await ProfileService.guardarPerfilJugador(jugador, existe: widget.perfil != null);
      if (rj['exito'] != true) return _fallo(rj['mensaje'].toString());
    }

    await AuthService.actualizarUsuarioLocal({'nombre': nombre, 'apellido': apellido});
    if (mounted) Navigator.pop(context, true);
  }

  void _fallo(String mensaje) {
    if (!mounted) return;
    setState(() => _guardando = false);
    _aviso(mensaje);
  }

  Widget _titulo(String texto) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(texto, style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
      );

  @override
  Widget build(BuildContext context) => Scaffold(

        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Editar perfil')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _titulo('Datos personales'),
                AppTextField(label: 'Nombre', hint: 'Juan Pablo', controller: _nombre, validator: AppValidators.validateName),
                const SizedBox(height: 16),
                AppTextField(label: 'Apellidos', hint: 'Triviño Bustos', controller: _apellido, validator: AppValidators.validateLastNames),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Celular',
                  hint: '3001234567',
                  controller: _celular,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v ?? '').trim().isEmpty ? null : AppValidators.validatePhone(v), // opcional
                ),
                const SizedBox(height: 16),
                DatePickerField(label: 'Fecha de nacimiento', hint: 'DD/MM/YYYY', controller: _fecha, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now()),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Departamento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
                    const SizedBox(height: 10),
                    CityDropdown(selectedCity: _ciudad, onChanged: (c) => setState(() => _ciudad = c)),
                  ]),
                ),
                const SizedBox(height: 16),

                if (_esJugador) ...[
                  AppDropdown<String>(label: 'Nivel de juego', hint: 'Selecciona tu nivel', value: _nivel, items: {for (final n in nivelesJuego) n: n}, onChanged: (v) => setState(() => _nivel = v)),
                  const SizedBox(height: 28),
                  _titulo('Perfil de jugador'),
                  AppTextField(label: 'Posición en el campo', hint: 'Ej: Delantero, Portero...', controller: _posicion),
                  const SizedBox(height: 16),
                  AppTextField(label: 'País', hint: 'Colombia', controller: _pais),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Tipo de jugador', hint: 'Ej: Amateur, Semiprofesional...', controller: _tipo),
                ],
                const SizedBox(height: 32),
                AppButton(label: 'Guardar cambios', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _guardar),
              ]),
            ),
          ),
        ),
      );
}