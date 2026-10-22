import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../core/navigation.dart';
import '../core/perfil_constants.dart';
import '../components/login_required_view.dart';
import '../components/tournament_chip.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'admin_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _usuario;
  Map<String, dynamic>? _perfil; // null = todavía no tiene perfil de jugador
  List _stats = []; // una fila por partido jugado
  bool _cargando = true;
  bool _subiendoFoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }


  Future<void> _cargar() async {
    if (AuthService.isGuest) return;
    final r = await Future.wait([ProfileService.usuario(), ProfileService.perfilJugador(), ProfileService.estadisticas()]);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r[0]['exito'] != true) {
        _error = r[0]['mensaje'].toString();
        return;
      }
      _error = null;
      _usuario = r[0];
      _perfil = r[1]['exito'] == true ? r[1] : null;
      _stats = r[2]['exito'] == true ? (r[2]['datos'] as List? ?? []) : [];
    });
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  int _suma(String campo) => _stats.fold<int>(0, (a, e) => a + ((e[campo] ?? 0) as num).toInt());

  String _fecha(dynamic valor) {
    final p = valor?.toString().split('T').first.split('-') ?? [];
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : '-';
  }

  String _texto(dynamic valor) => (valor == null || valor.toString().trim().isEmpty) ? '-' : valor.toString();

  Future<void> _editar() async {
    final guardado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditProfilePage(usuario: _usuario!, perfil: _perfil)));
    if (guardado == true && mounted) _cargar();

  }

  Future<void> _cambiarFoto() async {
    if (_perfil == null) {
      _aviso('Primero completa tu perfil de jugador');
      return _editar();
    }
    final foto = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);
    if (foto == null) return;
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(foto.path.split('.').last.toLowerCase())) return _aviso('Usa una imagen JPG, PNG o WEBP');

    setState(() => _subiendoFoto = true);
    final r = await ProfileService.subirFoto(foto.path);
    if (!mounted) return;
    setState(() {
      _subiendoFoto = false;
      if (r['exito'] == true) _perfil = r['perfil'] as Map<String, dynamic>;
    });
    if (r['exito'] != true) _aviso(r['mensaje'].toString());
  }

  Future<void> _cerrarSesion() async {
    await AuthService.logout();
    if (mounted) irALogin(context);
  }

  Future<void> _eliminarCuenta() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Eliminar cuenta', style: TextStyle(color: AppColors.textWhite)),

        content: const Text('Tu cuenta se desactivará y no podrás volver a entrar con ella. Esta acción no se puede deshacer.', style: TextStyle(color: AppColors.textGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;

    final r = await ProfileService.eliminarCuenta();
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    await _cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService.isGuest) {
      return const LoginRequiredView(titulo: 'Mi Perfil', mensaje: 'Inicia sesión para ver tu perfil', icono: Icons.person);
    }
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Mi Perfil'), backgroundColor: AppColors.bgDark, elevation: 0),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _vistaError
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),

                    children: [_cabecera, const SizedBox(height: 20), _estadisticas, const SizedBox(height: 24), _datosPersonales, const SizedBox(height: 20), _perfilJugador, const SizedBox(height: 24), _acciones],
                  ),
                ),
    );
  }

  Widget get _vistaError => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() => _cargando = true);
              _cargar();
            },
            child: const Text('Reintentar'),
          ),
        ]),
      );

  // ---- Cabecera: foto, nombre y rol ----
  Widget get _cabecera {
    final u = _usuario!;
    final nombre = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
    final url = _perfil?['avatar_url'] as String?;
    final iniciales = nombre.isEmpty ? '?' : nombre.split(' ').take(2).map((p) => p[0].toUpperCase()).join();
    return Column(children: [
      Stack(children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: AppColors.blue,
          backgroundImage: url != null ? NetworkImage(url) : null,

          child: url != null ? null : Text(iniciales, style: const TextStyle(fontSize: 32, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        ),
        if (_subiendoFoto) const Positioned.fill(child: CircleAvatar(backgroundColor: Colors.black54, child: CircularProgressIndicator())),
        Positioned(
          right: 0,
          bottom: 0,
          child: InkWell(
            onTap: _subiendoFoto ? null : _cambiarFoto,
            child: const CircleAvatar(radius: 17, backgroundColor: AppColors.secondary, child: Icon(Icons.camera_alt, size: 17, color: AppColors.bgDark)),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: Text(nombre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textWhite))),
        if (_perfil?['verificado'] == true) ...[const SizedBox(width: 6), const Icon(Icons.verified, color: AppColors.primaryLight, size: 20)],
      ]),
      const SizedBox(height: 8),
      TournamentChip(rolesNombre[u['rol_id']] ?? 'Usuario', color: AppColors.secondary, icono: Icons.badge_outlined),
    ]);
  }

  // ---- Estadísticas ----
  Widget get _estadisticas => Row(children: [
        _stat('${_stats.length}', 'Partidos'),
        const SizedBox(width: 10),
        _stat('${_suma('goles')}', 'Goles'),
        const SizedBox(width: 10),
        _stat('${_suma('asistencias')}', 'Asist.'),
        const SizedBox(width: 10),
        _stat('${_suma('tarjetas_amarillas') + _suma('tarjetas_rojas')}', 'Tarjetas'),
      ]);


  Widget _stat(String valor, String etiqueta) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(valor, style: const TextStyle(fontSize: 22, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(etiqueta, style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
          ]),
        ),
      );

  // ---- Secciones de datos ----
  Widget get _datosPersonales {
    final u = _usuario!;
    return _seccion('Información personal', [
      _fila(Icons.email_outlined, 'Correo', _texto(u['correo']),
          extra: TournamentChip(u['correo_verificado'] == true ? 'Verificado' : 'Sin verificar', color: u['correo_verificado'] == true ? AppColors.success : AppColors.warning)),
      _fila(Icons.phone_outlined, 'Celular', _texto(u['numero_celular'])),
      _fila(Icons.cake_outlined, 'Nacimiento', _fecha(u['fecha_nacimiento'])),
      _fila(Icons.location_on_outlined, 'Departamento', _texto(u['ciudad'])),
      _fila(Icons.trending_up, 'Nivel de juego', _texto(u['nivel_juego'])),
    ]);
  }

  Widget get _perfilJugador {
    final p = _perfil;
    if (p == null) {
      return _seccion('Perfil de jugador', [
        const Text('Aún no tienes perfil de jugador. Complétalo para aparecer con tu posición y foto.', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
        TextButton(onPressed: _editar, child: const Text('Completar perfil', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold))),

      ]);
    }
    return _seccion('Perfil de jugador', [
      _fila(Icons.sports_soccer, 'Posición', _texto(p['posicion'])),
      _fila(Icons.flag_outlined, 'País', _texto(p['pais'])),
      _fila(Icons.person_search_outlined, 'Tipo de jugador', _texto(p['tipo_jugador'])),
      if (p['distincion'] != null && p['distincion'].toString().isNotEmpty) _fila(Icons.emoji_events_outlined, 'Distinción', p['distincion'].toString()),
    ]);
  }

  Widget _seccion(String titulo, List<Widget> hijos) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(titulo, style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14)),
          child: Column(children: hijos),
        ),
      ]);

  Widget _fila(IconData icono, String etiqueta, String valor, {Widget? extra}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icono, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Text(etiqueta, style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
          const SizedBox(width: 12),
          Expanded(child: Text(valor, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.w600))),
          if (extra != null) ...[const SizedBox(width: 8), extra],
        ]),
      );


  // ---- Acciones ----
  Widget get _acciones => Column(children: [
        _accion(Icons.edit_outlined, 'Editar perfil', _editar),
        _accion(Icons.lock_outline, 'Cambiar contraseña', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()))),
        _accion(Icons.logout, 'Cerrar sesión', _cerrarSesion),
        _accion(Icons.delete_outline, 'Eliminar cuenta', _eliminarCuenta, color: AppColors.error),
        if (_usuario?['rol_id'] == 6) _accion(Icons.admin_panel_settings_outlined, 'Panel de administración', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())), color: AppColors.secondary),
      ]);

  Widget _accion(IconData icono, String titulo, VoidCallback onTap, {Color color = AppColors.textWhite}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(icono, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right, color: AppColors.textGray),
              ]),
            ),
          ),
        ),
      );
}