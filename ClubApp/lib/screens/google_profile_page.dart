import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/navigation.dart';
import '../core/perfil_constants.dart';
import '../components/app_button.dart';
import '../components/app_dropdown.dart';
import '../components/app_text_field.dart';
import '../components/citydrop_down.dart';
import '../components/icon_badge.dart';
import '../components/role_selector.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// Primer ingreso con Google: la cuenta nace como "Usuario" y aquí elige su rol (y opcionalmente nivel, departamento y posición)
class GoogleProfilePage extends StatefulWidget {
  const GoogleProfilePage({super.key});

  @override
  State<GoogleProfilePage> createState() => _GoogleProfilePageState();
}

class _GoogleProfilePageState extends State<GoogleProfilePage> {
  final _posicion = TextEditingController();
  int? _rolId;
  String? _nivel;
  String? _ciudad;
  bool _guardando = false;

  @override
  void dispose() {
    _posicion.dispose();
    super.dispose();

  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _continuar() async {
    if (_rolId == null) return _aviso('Elige cómo vas a usar ClubApp');
    setState(() => _guardando = true);

    final rol = await AuthService.elegirRol(_rolId!);
    if (rol['exito'] != true) {
      if (!mounted) return;
      setState(() => _guardando = false);
      return _aviso(rol['mensaje'].toString());
    }

    // Lo demás es opcional: si algo falla no se bloquea la entrada, se completa luego desde el perfil
    final datos = {if (_nivel != null) 'nivel_juego': _nivel, if (_ciudad != null) 'ciudad': _ciudad};
    if (datos.isNotEmpty) await ProfileService.actualizarUsuario(datos);
    if (_posicion.text.trim().isNotEmpty) await AuthService.crearPerfilJugador(posicion: _posicion.text.trim());

    if (mounted) irAInicio(context);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = AuthService.usuario?['nombre'] ?? '';
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [

            const SizedBox(height: 16),
            const IconBadge(icon: Icons.sports_soccer, color: AppColors.blue, iconColor: AppColors.textWhite, size: 84, iconSize: 44, radius: 22),
            const SizedBox(height: 20),
            const Text('¡Bienvenido a ClubApp!', style: TextStyle(fontSize: 22, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Hola $nombre, cuéntanos cómo vas a usar la app', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textGray)),
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Rol en la plataforma', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
              ),
            ),
            RoleSelector(value: _rolId, onChanged: (id) => setState(() => _rolId = id)),
            const SizedBox(height: 20),
            AppDropdown<String>(label: 'Nivel de juego (opcional)', hint: 'Selecciona tu nivel', value: _nivel, items: {for (final n in nivelesJuego) n: n}, onChanged: (v) => setState(() => _nivel = v)),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Departamento (opcional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
                const SizedBox(height: 10),
                CityDropdown(selectedCity: _ciudad, onChanged: (c) => setState(() => _ciudad = c)),
              ]),
            ),
            const SizedBox(height: 20),
            AppTextField(label: 'Posición en el campo (opcional)', hint: 'Ej: Delantero, Portero...', controller: _posicion),
            const SizedBox(height: 28),
            AppButton(label: 'Continuar', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _continuar),
            TextButton(
              onPressed: _guardando ? null : () => irAInicio(context),

              child: const Text('Ahora no, continuar como usuario', style: TextStyle(color: AppColors.textGray)),
            ),
          ]),
        ),
      ),
    );
  }
}