import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/perfil_constants.dart';
import '../components/admin_widgets.dart';
import '../components/tournament_chip.dart';
import '../services/admin_service.dart';
import 'admin_usuario_page.dart';

class AdminUsuariosTab extends StatefulWidget {
  const AdminUsuariosTab({super.key});

  @override
  State<AdminUsuariosTab> createState() => _AdminUsuariosTabState();
}

class _AdminUsuariosTabState extends State<AdminUsuariosTab> with AutomaticKeepAliveClientMixin {
  final _buscador = TextEditingController();
  final _usuarios = <Map<String, dynamic>>[];
  int _total = 0;
  int _pagina = 0;
  int? _rol;
  bool? _activo;
  String? _error;
  bool _cargando = true;
  bool _cargandoMas = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
=======

>>>>>>> a27ac5cc76426654df467432a6448d2b88dffd42
    _cargar();
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  /// Sin `mas` empieza desde la primera página; con `mas` agrega la siguiente
  Future<void> _cargar({bool mas = false}) async {
    if (mas) {
      setState(() => _cargandoMas = true);
    } else {
      _pagina = 0;
    }
    final r = await AdminService.usuarios(buscar: _buscador.text.trim(), rol: _rol, activo: _activo, pagina: mas ? _pagina + 1 : 0);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _cargandoMas = false;
      if (r['exito'] != true) {
        _error = r['mensaje'].toString();
        return;
      }
      _error = null;
      if (!mas) _usuarios.clear();
      _pagina = (r['pagina'] as num).toInt();
      _total = (r['total'] as num).toInt();
      _usuarios.addAll((r['usuarios'] as List).cast<Map<String, dynamic>>());
    });
  }

<<<<<<< HEAD
=======

>>>>>>> a27ac5cc76426654df467432a6448d2b88dffd42
  void _filtrar(VoidCallback cambio) {
    setState(cambio);
    _cargar();
  }

  Future<void> _abrir(Map<String, dynamic> u) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUsuarioPage(usuario: u)));
    if (mounted) _cargar();
  }

  String _iniciales(Map<String, dynamic> u) => '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim().split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AdminCuerpo(
      cargando: _cargando,
      error: _error,
      onRefresh: _cargar,
      vacio: 'No hay usuarios con esos filtros',
      encabezado: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _buscador,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _cargar(),
          style: const TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o correo',
            hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
            suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, color: AppColors.secondary), onPressed: _cargar),
<<<<<<< HEAD
=======

>>>>>>> a27ac5cc76426654df467432a6448d2b88dffd42
            filled: true,
            fillColor: AppColors.bgCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        FiltroChips<int>(opciones: {'Todos los roles': null, for (final e in rolesNombre.entries) e.value: e.key}, valor: _rol, onChanged: (v) => _filtrar(() => _rol = v)),
        const SizedBox(height: 8),
        FiltroChips<bool>(opciones: const {'Todos': null, 'Activos': true, 'Inactivos': false}, valor: _activo, onChanged: (v) => _filtrar(() => _activo = v)),
        const SizedBox(height: 12),
        Text('$_total usuarios', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
        const SizedBox(height: 10),
      ]),
      hijos: [
        for (final u in _usuarios)
          AdminTarjeta(
            leading: CircleAvatar(backgroundColor: u['activo'] == false ? AppColors.bgCardLight : AppColors.blue, child: Text(_iniciales(u), style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold))),
            titulo: '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim(),
            subtitulo: u['correo']?.toString(),
            chips: [
              TournamentChip(rolesNombre[u['rol_id']] ?? 'Usuario', color: AppColors.secondary),
              if (u['activo'] == false) const TournamentChip('Inactivo', color: AppColors.error),
              if (u['correo_verificado'] != true) const TournamentChip('Sin verificar', color: AppColors.warning),
            ],
            trailing: const Icon(Icons.chevron_right, color: AppColors.textGray),
            onTap: () => _abrir(u),
          ),
        if (_usuarios.length < _total)
          Center(
            child: _cargandoMas
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
<<<<<<< HEAD
=======

>>>>>>> a27ac5cc76426654df467432a6448d2b88dffd42
                : TextButton(onPressed: () => _cargar(mas: true), child: const Text('Cargar más', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold))),
          ),
      ],
    );
  }
}