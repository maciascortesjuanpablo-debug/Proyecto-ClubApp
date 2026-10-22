import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/perfil_constants.dart';
import '../core/validators.dart';
import '../components/admin_widgets.dart';
import '../components/app_button.dart';
import '../components/app_dropdown.dart';
import '../components/app_text_field.dart';
import '../components/citydrop_down.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

/// El administrador edita cualquier dato de un usuario, cambia su rol, lo activa o desactiva y puede borrarlo.
class AdminUsuarioPage extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const AdminUsuarioPage({super.key, required this.usuario});

  @override
  State<AdminUsuarioPage> createState() => _AdminUsuarioPageState();
}

class _AdminUsuarioPageState extends State<AdminUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario['nombre']?.toString());
  late final _apellido = TextEditingController(text: widget.usuario['apellido']?.toString());
  late final _correo = TextEditingController(text: widget.usuario['correo']?.toString());
  late final _celular = TextEditingController(text: widget.usuario['numero_celular']?.toString());
  late String? _ciudad = CityDropdown.cities.contains(widget.usuario['ciudad']) ? widget.usuario['ciudad'] as String : null;
  late String? _nivel = nivelesJuego.contains(widget.usuario['nivel_juego']) ? widget.usuario['nivel_juego'] as String : null;
  late int _rol = (widget.usuario['rol_id'] as num?)?.toInt() ?? 1;
  late bool _activo = widget.usuario['activo'] != false;
  late bool _verificado = widget.usuario['correo_verificado'] == true;
  bool _guardando = false;

  // Uno mismo no puede quitarse el rol ni desactivarse (el backend también lo bloquea)
  bool get _esYo => AuthService.usuario?['id'].toString() == widget.usuario['id'].toString();

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _correo, _celular]) {
      c.dispose();
    }
    super.dispose();
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  /// Muestra el resultado; si salió bien cierra la pantalla
  void _terminar(Map<String, dynamic> r, String exito) {
    setState(() => _guardando = false);
    _aviso(r['exito'] == true ? exito : r['mensaje'].toString());
    if (r['exito'] == true) Navigator.pop(context);
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    final nombre = _nombre.text.trim();
    final apellido = _apellido.text.trim();
    final r = await AdminService.actualizarUsuario(widget.usuario['id'], {
      'nombre': nombre,
      'apellido': apellido,
      'correo': _correo.text.trim(),
      'numero_celular': _celular.text.trim(),
      'ciudad': _ciudad ?? '',
      'nivel_juego': _nivel ?? '',
      'correo_verificado': _verificado,
      if (!_esYo) ...{'rol_id': _rol, 'activo': _activo},
    });
    if (!mounted) return;
    if (r['exito'] == true && _esYo) await AuthService.actualizarUsuarioLocal({'nombre': nombre, 'apellido': apellido});
    if (!mounted) return;
    _terminar(r, 'Usuario actualizado');
  }

  Future<void> _eliminar() async {
    final nombre = '${widget.usuario['nombre'] ?? ''} ${widget.usuario['apellido'] ?? ''}'.trim();
    final ok = await confirmar(
      context,
      titulo: 'Eliminar definitivamente',
      mensaje: 'Se borrará la cuenta de $nombre con todos sus datos (favoritos, estadísticas, plantillas…). No se puede deshacer.\n\nSi solo quieres que no pueda entrar, usa el interruptor "Cuenta activa".',
      accion: 'Eliminar',
      peligro: true,
    );
    if (!ok || !mounted) return;
    setState(() => _guardando = true);
    final r = await AdminService.eliminarUsuario(widget.usuario['id'], permanente: true);
    if (!mounted) return;
    _terminar(r, 'Usuario eliminado');
  }

  Widget _interruptor(String titulo, String detalle, bool valor, ValueChanged<bool>? onChanged) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(titulo, style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(detalle, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
        value: valor,
        onChanged: onChanged,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Editar usuario')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(children: [
                AppTextField(label: 'Nombre', hint: 'Nombre', controller: _nombre, validator: AppValidators.validateName),
                const SizedBox(height: 16),
                AppTextField(label: 'Apellidos', hint: 'Apellidos', controller: _apellido, validator: AppValidators.validateLastNames),
                const SizedBox(height: 16),
                AppTextField(label: 'Correo', hint: 'correo@email.com', controller: _correo, keyboardType: TextInputType.emailAddress, validator: AppValidators.validateEmail),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Celular',
                  hint: '3001234567',
                  controller: _celular,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v ?? '').trim().isEmpty ? null : AppValidators.validatePhone(v),
                ),
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
                AppDropdown<String>(label: 'Nivel de juego', hint: 'Sin definir', value: _nivel, items: {for (final n in nivelesJuego) n: n}, onChanged: (v) => setState(() => _nivel = v)),
                const SizedBox(height: 16),
                AppDropdown<int>(label: 'Rol', hint: 'Rol', value: _rol, items: rolesNombre, onChanged: _esYo ? (_) {} : (v) => setState(() => _rol = v ?? _rol)),
                const SizedBox(height: 8),
                _interruptor('Cuenta activa', _esYo ? 'No puedes desactivar tu propia cuenta' : 'Si la apagas, no podrá iniciar sesión', _activo, _esYo ? null : (v) => setState(() => _activo = v)),
                _interruptor('Correo verificado', 'Márcalo si confirmaste que el correo es suyo', _verificado, (v) => setState(() => _verificado = v)),
                const SizedBox(height: 20),
                AppButton(label: 'Guardar cambios', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _guardar),
                if (!_esYo) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _guardando ? null : _eliminar,
                    icon: const Icon(Icons.delete_forever, color: AppColors.error),
                    label: const Text('Eliminar definitivamente', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ]),
            ),
          ),
        ),
      );
}