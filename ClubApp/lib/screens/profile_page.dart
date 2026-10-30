import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../core/navigation.dart';
import '../core/roles.dart';
import '../components/charts.dart';
import '../components/login_required_view.dart';
import '../components/tournament_chip.dart';
import '../components/ui_kit.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/panel_service.dart';
import '../services/profile_service.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'admin_page.dart';

/// Perfil de la persona. La cabecera, los datos personales y las acciones son comunes;
/// lo que hay en medio depende del rol: el jugador ve sus estadísticas de juego, el entrenador sus equipos,
/// el organizador sus torneos y el árbitro sus partidos dirigidos.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _usuarioJson;
  Usuario? _usuario;
  Map<String, dynamic>? _perfilJson; // null = todavía no tiene perfil con foto
  PerfilJugador? get _perfil => _perfilJson == null ? null : PerfilJugador.fromJson(_perfilJson!);

  PanelJugador? _pj;
  PanelEntrenador? _pe;
  PanelOrganizador? _po;
  PanelArbitro? _pa;

  bool _cargando = true;
  bool _subiendoFoto = false;
  String? _error;

  RolApp get _rol => _usuario?.rol ?? RolApp.actual;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (AuthService.isGuest) return;
    final rol = RolApp.actual;
    final r = await Future.wait([ProfileService.usuario(), ProfileService.perfilJugador()]);
    // Solo se pide el panel del rol propio (el backend rechaza los demás)
    PanelJugador? pj;
    PanelEntrenador? pe;
    PanelOrganizador? po;
    PanelArbitro? pa;
    switch (rol) {
      case RolApp.jugador:
        pj = (await PanelService.jugador()).dato;
      case RolApp.entrenador:
        pe = (await PanelService.entrenador()).dato;
      case RolApp.organizador:
        po = (await PanelService.organizador()).dato;
      case RolApp.arbitro:
        pa = (await PanelService.arbitro()).dato;
      default:
        break;
    }
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r[0]['exito'] != true) {
        _error = r[0]['mensaje'].toString();
        return;
      }
      _error = null;
      _usuarioJson = r[0];
      _usuario = Usuario.fromJson(r[0]);
      _perfilJson = r[1]['exito'] == true ? r[1] : null;
      _pj = pj;
      _pe = pe;
      _po = po;
      _pa = pa;
    });
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  String _fecha(DateTime? d) => d == null ? '-' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _texto(String? valor) => (valor == null || valor.trim().isEmpty) ? '-' : valor;

  Future<void> _editar() async {
    final guardado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditProfilePage(usuario: _usuarioJson!, perfil: _perfilJson)));
    if (guardado == true && mounted) _cargar();
  }

  Future<void> _cambiarFoto() async {
    if (_perfilJson == null) {
      if (_rol == RolApp.jugador) {
        _aviso('Primero completa tu perfil de jugador');
        return _editar();
      }
      // Quien no es jugador no tiene perfil deportivo: se crea uno vacío solo para guardar la foto
      final creado = await ProfileService.guardarPerfilJugador({}, existe: false);
      if (creado['exito'] != true) return _aviso(creado['mensaje'].toString());
      final nuevo = await ProfileService.perfilJugador();
      if (nuevo['exito'] != true) return _aviso('No se pudo preparar tu perfil');
      _perfilJson = nuevo;
    }
    final foto = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);
    if (foto == null) return;
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(foto.path.split('.').last.toLowerCase())) return _aviso('Usa una imagen JPG, PNG o WEBP');

    setState(() => _subiendoFoto = true);
    final r = await ProfileService.subirFoto(foto.path);
    if (!mounted) return;
    setState(() {
      _subiendoFoto = false;
      if (r['exito'] == true) _perfilJson = r['perfil'] as Map<String, dynamic>;
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      _cabecera,
                      const SizedBox(height: 20),
                      ..._seccionesDelRol(),
                      const SizedBox(height: 24),
                      _datosPersonales,
                      const SizedBox(height: 24),
                      _acciones,
                    ],
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
    final url = _perfil?.avatarUrl;
    return Column(children: [
      Stack(children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: _rol.color.withValues(alpha: 0.6),
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url != null ? null : Text(u.iniciales, style: const TextStyle(fontSize: 32, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
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
        Flexible(child: Text(u.nombreCompleto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textWhite))),
        if (_perfil?.verificado == true) ...[const SizedBox(width: 6), const Icon(Icons.verified, color: AppColors.primaryLight, size: 20)],
      ]),
      const SizedBox(height: 8),
      TournamentChip(_rol.nombre, color: _rol.color, icono: _rol.icono),
    ]);
  }

  // ---- Contenido según el rol ----
  List<Widget> _seccionesDelRol() => switch (_rol) {
        RolApp.jugador => _jugador(),
        RolApp.entrenador => _entrenador(),
        RolApp.organizador => _organizador(),
        RolApp.arbitro => _arbitro(),
        RolApp.admin => [_accion(Icons.admin_panel_settings_outlined, 'Panel de administración', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())), color: AppColors.secondary)],
        _ => const [],
      };

  List<Widget> _jugador() {
    final p = _pj;
    final e = p?.estadisticas ?? const EstadisticasJugador();
    final perfil = _perfil;
    final serie = p?.ultimosPartidos ?? const <EstadisticaPartido>[];
    return [
      KpiGrid([
        KpiTile(icono: Icons.sports_soccer, valor: '${e.goles}', etiqueta: 'Goles', color: AppColors.orange, detalle: e.partidos == 0 ? null : '${e.golesPorPartido.toStringAsFixed(2)} por partido'),
        KpiTile(icono: Icons.handshake_outlined, valor: '${e.asistencias}', etiqueta: 'Asistencias', color: AppColors.secondary),
        KpiTile(icono: Icons.event_available, valor: '${e.partidos}', etiqueta: 'Partidos', color: AppColors.primaryLight, detalle: '${e.minutos} min jugados'),
        KpiTile(icono: Icons.style, valor: '${e.tarjetas}', etiqueta: 'Tarjetas', color: AppColors.warning, detalle: '${e.amarillas} amarillas · ${e.rojas} rojas'),
      ]),
      const SeccionTitulo('Goles en los últimos partidos'),
      TarjetaBase(
        child: LineaTendencia(
          valores: [for (final s in serie) s.goles],
          etiquetas: [for (final s in serie) s.fecha == null ? '' : '${s.fecha!.day}/${s.fecha!.month}'],
        ),
      ),
      const SizedBox(height: 20),
      _seccion('Perfil de jugador', perfil == null
          ? [
              const Padding(padding: EdgeInsets.only(top: 8), child: Text('Aún no tienes perfil de jugador. Complétalo para aparecer con tu posición y foto.', style: TextStyle(color: AppColors.textGray, fontSize: 13))),
              TextButton(onPressed: _editar, child: const Text('Completar perfil', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold))),
            ]
          : [
              _fila(Icons.sports_soccer, 'Posición', _texto(perfil.posicion)),
              _fila(Icons.flag_outlined, 'País', _texto(perfil.pais)),
              _fila(Icons.person_search_outlined, 'Tipo de jugador', _texto(perfil.tipoJugador)),
              if (perfil.distincion != null) _fila(Icons.emoji_events_outlined, 'Distinción', perfil.distincion!),
            ]),
    ];
  }

  List<Widget> _entrenador() {
    final p = _pe;
    if (p == null) return const [];
    return [
      KpiGrid([
        KpiTile(icono: Icons.groups, valor: '${p.totalEquipos}', etiqueta: 'Equipos', color: AppColors.orange),
        KpiTile(icono: Icons.person, valor: '${p.totalJugadores}', etiqueta: 'Jugadores', color: AppColors.secondary),
        KpiTile(icono: Icons.emoji_events, valor: '${p.torneosActivos}', etiqueta: 'Torneos activos', color: AppColors.success),
        KpiTile(icono: Icons.hourglass_top, valor: '${p.inscripcionesPendientes}', etiqueta: 'Inscripciones pendientes', color: AppColors.warning),
      ]),
      if (p.equipos.isNotEmpty) ...[
        const SeccionTitulo('Equipos que dirijo'),
        for (final e in p.equipos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TarjetaBase(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                EquipoAvatar(nombre: e.nombre, logoUrl: e.logoUrl),
                const SizedBox(width: 12),
                Expanded(child: Text(e.nombre, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
                Text('${e.jugadores} jugadores', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
              ]),
            ),
          ),
      ],
    ];
  }

  List<Widget> _organizador() {
    final p = _po;
    if (p == null) return const [];
    return [
      KpiGrid([
        KpiTile(icono: Icons.emoji_events, valor: '${p.totalTorneos}', etiqueta: 'Torneos organizados', color: AppColors.primaryLight),
        KpiTile(icono: Icons.groups, valor: '${p.totalEquipos}', etiqueta: 'Equipos participando', color: AppColors.orange),
        KpiTile(icono: Icons.today, valor: '${p.partidosHoy}', etiqueta: 'Partidos hoy', color: AppColors.success),
        KpiTile(icono: Icons.date_range, valor: '${p.partidosSemana}', etiqueta: 'Esta semana', color: AppColors.secondary),
      ]),
      if (p.torneos.isNotEmpty) ...[
        const SeccionTitulo('Avance de mis torneos'),
        TarjetaBase(
          child: BarrasVerticales(
            datos: [for (final t in p.torneos.take(6)) BarraDato(t.torneo.nombre.length > 8 ? '${t.torneo.nombre.substring(0, 7)}…' : t.torneo.nombre, (t.avance * 100).round())],
            color: AppColors.primaryLight,
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 6), child: Text('Porcentaje de partidos jugados por torneo', style: TextStyle(fontSize: 11, color: AppColors.textGrayDark))),
      ],
    ];
  }

  List<Widget> _arbitro() {
    final p = _pa;
    if (p == null) return const [];
    final tarjetas = [
      SegmentoDonut('Amarillas', p.amarillas, AppColors.warning),
      SegmentoDonut('Rojas', p.rojas, AppColors.error),
    ];
    return [
      KpiGrid([
        KpiTile(icono: Icons.sports_score, valor: '${p.dirigidos}', etiqueta: 'Partidos dirigidos', color: AppColors.warning),
        KpiTile(icono: Icons.upcoming, valor: '${p.porDirigir}', etiqueta: 'Por dirigir', color: AppColors.primaryLight),
        KpiTile(icono: Icons.sports_soccer, valor: '${p.goles}', etiqueta: 'Goles en mis partidos', color: AppColors.orange),
        KpiTile(icono: Icons.style, valor: '${p.tarjetas}', etiqueta: 'Tarjetas mostradas', color: AppColors.error),
      ]),
      if (p.tarjetas > 0) ...[
        const SeccionTitulo('Disciplina en mis partidos'),
        TarjetaBase(child: Row(children: [DonutChart(segmentos: tarjetas, centro: '${p.tarjetas}', subcentro: 'tarjetas', tamano: 110), const SizedBox(width: 20), Expanded(child: LeyendaChart(tarjetas))])),
      ],
    ];
  }

  // ---- Secciones de datos ----
  Widget get _datosPersonales {
    final u = _usuario!;
    return _seccion('Información personal', [
      _fila(Icons.email_outlined, 'Correo', _texto(u.correo), extra: TournamentChip(u.correoVerificado ? 'Verificado' : 'Sin verificar', color: u.correoVerificado ? AppColors.success : AppColors.warning)),
      _fila(Icons.phone_outlined, 'Celular', _texto(u.celular)),
      _fila(Icons.cake_outlined, 'Nacimiento', _fecha(u.fechaNacimiento)),
      _fila(Icons.location_on_outlined, 'Departamento', _texto(u.ciudad)),
      if (_rol == RolApp.jugador) _fila(Icons.trending_up, 'Nivel de juego', _texto(u.nivelJuego)),
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
