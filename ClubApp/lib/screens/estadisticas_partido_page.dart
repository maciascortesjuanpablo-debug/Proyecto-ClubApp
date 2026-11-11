import 'package:flutter/material.dart';
import '../components/ui_kit.dart';
import '../core/app_colors.dart';
import '../models/models.dart';
import '../services/stats_service.dart';
import '../services/team_service.dart';

/// Una fila editable: un jugador con sus números en este partido
class _Fila {
  final Object usuarioId;
  final String nombre;
  final int? dorsal;
  final bool titular;
  bool jugo;
  int goles, asistencias, amarillas, rojas, minutos;

  _Fila({required this.usuarioId, required this.nombre, this.dorsal, this.titular = false, this.jugo = false, this.goles = 0, this.asistencias = 0, this.amarillas = 0, this.rojas = 0, this.minutos = 0});
}

class _EquipoEdicion {
  final Object id;
  final String nombre;
  final int? marcador; // goles que marcó según el resultado del partido
  final List<_Fila> filas;
  _EquipoEdicion({required this.id, required this.nombre, this.marcador, required this.filas});

  int get golesRegistrados => filas.fold(0, (a, f) => a + f.goles);
}

/// Registrar goles, asistencias, tarjetas y minutos de los jugadores de un partido.
/// [equiposEditables] son los equipos que esta persona puede registrar (el organizador, el admin y el árbitro asignado, ambos;
/// el entrenador, solo el suyo). El servidor vuelve a validar cada permiso.
class EstadisticasPartidoPage extends StatefulWidget {
  final Object eventoId;
  final Map<String, dynamic> evento; // el detalle del partido tal como lo devuelve el backend
  final Set<String> equiposEditables;

  const EstadisticasPartidoPage({super.key, required this.eventoId, required this.evento, required this.equiposEditables});

  @override
  State<EstadisticasPartidoPage> createState() => _EstadisticasPartidoPageState();
}

class _EstadisticasPartidoPageState extends State<EstadisticasPartidoPage> {
  final List<_EquipoEdicion> _equipos = [];
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final e = widget.evento;
    final existentes = await StatsService.delPartido(widget.eventoId);
    if (!mounted) return;
    if (!existentes.ok) {
      setState(() {
        _cargando = false;
        _error = existentes.error;
      });
      return;
    }
    final registradas = existentes.dato!;
    final armados = <_EquipoEdicion>[];
    for (final lado in [('equipo_local', 'resultado_local'), ('equipo_visitante', 'resultado_visitante')]) {
      final eq = toMap(e[lado.$1]);
      final id = eq['id'];
      if (id == null || !widget.equiposEditables.contains('$id')) continue;

      final plantilla = await TeamService.plantilla(id as Object);
      if (!mounted) return;
      final delEquipo = registradas.where((s) => '${s.equipoId}' == '$id').toList();
      final porUsuario = {for (final s in delEquipo) '${s.usuarioId}': s};
      final sinRegistros = delEquipo.isEmpty; // si nunca se registró nada, los titulares se proponen como que jugaron todo el partido

      final filas = <_Fila>[];
      for (final j in plantilla.dato ?? <JugadorPlantilla>[]) {
        if (j.usuarioId == null) continue;
        final s = porUsuario['${j.usuarioId}'];
        if (s != null) {
          filas.add(_Fila(usuarioId: j.usuarioId!, nombre: j.nombreCompleto, dorsal: j.dorsal, titular: j.esTitular, jugo: s.minutos > 0 || s.tieneAlgo, goles: s.goles, asistencias: s.asistencias, amarillas: s.amarillas, rojas: s.rojas, minutos: s.minutos));
        } else {
          final propuesto = sinRegistros && j.esTitular;
          filas.add(_Fila(usuarioId: j.usuarioId!, nombre: j.nombreCompleto, dorsal: j.dorsal, titular: j.esTitular, jugo: propuesto, minutos: propuesto ? 90 : 0));
        }
      }
      filas.sort((a, b) => a.titular != b.titular ? (a.titular ? -1 : 1) : (a.dorsal ?? 999).compareTo(b.dorsal ?? 999));
      armados.add(_EquipoEdicion(id: id, nombre: toStr(eq['nombre'], 'Equipo'), marcador: e[lado.$2] == null ? null : toInt(e[lado.$2]), filas: filas));
    }
    setState(() {
      _cargando = false;
      _equipos
        ..clear()
        ..addAll(armados);
    });
  }

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final cuerpo = <Map<String, dynamic>>[];
    for (final eq in _equipos) {
      for (final f in eq.filas) {
        // Quien no jugó queda en cero (si antes tenía datos, se limpian)
        cuerpo.add({
          'usuario_id': f.usuarioId,
          'equipo_id': eq.id,
          'goles': f.jugo ? f.goles : 0,
          'asistencias': f.jugo ? f.asistencias : 0,
          'tarjetas_amarillas': f.jugo ? f.amarillas : 0,
          'tarjetas_rojas': f.jugo ? f.rojas : 0,
          'minutos_jugados': f.jugo ? f.minutos : 0,
        });
      }
    }
    if (cuerpo.isEmpty) {
      setState(() => _guardando = false);
      return _aviso('No hay jugadores para guardar');
    }
    final r = await StatsService.guardar(widget.eventoId, cuerpo);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    final avisos = (r['advertencias'] as List? ?? []).map((e) => '$e').toList();
    _aviso(avisos.isEmpty ? 'Estadísticas guardadas' : 'Guardado. Ojo: ${avisos.join(' · ')}');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final titulo = AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Estadísticas del partido'));
    if (_cargando) return Scaffold(backgroundColor: AppColors.bgDark, appBar: titulo, body: const Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(backgroundColor: AppColors.bgDark, appBar: titulo, body: Center(child: Text(_error!, style: const TextStyle(color: AppColors.textGray))));
    if (_equipos.isEmpty) return Scaffold(backgroundColor: AppColors.bgDark, appBar: titulo, body: const EstadoVacio(icono: Icons.lock_outline, mensaje: 'No puedes registrar estadísticas de este partido.'));

    final cuerpo = _equipos.length == 1
        ? _lista(_equipos.first)
        : TabBarView(children: [for (final e in _equipos) _lista(e)]);

    return DefaultTabController(
      length: _equipos.length,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          title: const Text('Estadísticas del partido'),
          bottom: _equipos.length == 1 ? null : TabBar(indicatorColor: AppColors.secondary, labelColor: AppColors.secondary, unselectedLabelColor: AppColors.textGray, tabs: [for (final e in _equipos) Tab(text: e.nombre)]),
        ),
        body: Column(children: [
          Expanded(child: cuerpo),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Guardando…' : 'Guardar estadísticas'),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _lista(_EquipoEdicion eq) {
    final coincide = eq.marcador == null || eq.marcador == eq.golesRegistrados;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      // Control de goles contra el marcador
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: (coincide ? AppColors.success : AppColors.warning).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(coincide ? Icons.check_circle_outline : Icons.info_outline, size: 18, color: coincide ? AppColors.success : AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              eq.marcador == null ? 'Goles registrados: ${eq.golesRegistrados}' : 'Goles registrados: ${eq.golesRegistrados} de ${eq.marcador} (marcador)${coincide ? '' : '. No coinciden: revisa antes de guardar.'}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textWhite),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Marca quién jugó y ajusta sus números. Los titulares de tu alineación aparecen como que jugaron 90 minutos.', style: TextStyle(fontSize: 12, color: AppColors.textGray))),
      if (eq.filas.isEmpty) const EstadoVacio(icono: Icons.groups_outlined, mensaje: 'Este equipo no tiene jugadores en su plantilla.'),
      for (final f in eq.filas) _tarjetaJugador(f),
    ]);
  }

  /// Si se suma algo a un jugador que no estaba marcado como que jugó, se marca solo
  void _tocar(_Fila f, VoidCallback cambio) => setState(() {
        cambio();
        if (!f.jugo && (f.goles > 0 || f.asistencias > 0 || f.amarillas > 0 || f.rojas > 0)) {
          f.jugo = true;
          if (f.minutos == 0) f.minutos = 90;
        }
      });

  Widget _tarjetaJugador(_Fila f) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TarjetaBase(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(children: [
            Row(children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.bgCardLight, shape: BoxShape.circle),
                child: Text(f.dorsal?.toString() ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
                  if (f.titular) const Text('Titular', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                ]),
              ),
              const Text('Jugó', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
              Switch(
                value: f.jugo,
                onChanged: (v) => setState(() {
                  f.jugo = v;
                  if (v && f.minutos == 0) f.minutos = 90;
                  if (!v) {
                    f.goles = f.asistencias = f.amarillas = f.rojas = f.minutos = 0;
                  }
                }),
              ),
            ]),
            if (f.jugo) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Contador(icono: Icons.sports_soccer, color: AppColors.orange, etiqueta: 'Goles', valor: f.goles, max: 30, onCambio: (v) => _tocar(f, () => f.goles = v)),
                _Contador(icono: Icons.handshake_outlined, color: AppColors.secondary, etiqueta: 'Asist.', valor: f.asistencias, max: 30, onCambio: (v) => _tocar(f, () => f.asistencias = v)),
                _Contador(icono: Icons.style, color: AppColors.warning, etiqueta: 'Amarillas', valor: f.amarillas, max: 2, onCambio: (v) => _tocar(f, () => f.amarillas = v)),
                _Contador(icono: Icons.style, color: AppColors.error, etiqueta: 'Roja', valor: f.rojas, max: 1, onCambio: (v) => _tocar(f, () => f.rojas = v)),
                _Contador(icono: Icons.timer_outlined, color: AppColors.primaryLight, etiqueta: 'Min.', valor: f.minutos, max: 130, paso: 5, onCambio: (v) => setState(() => f.minutos = v)),
              ]),
            ],
          ]),
        ),
      );
}

/// Contador con botones − y +
class _Contador extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String etiqueta;
  final int valor;
  final int max;
  final int paso;
  final ValueChanged<int> onCambio;

  const _Contador({required this.icono, required this.color, required this.etiqueta, required this.valor, required this.max, this.paso = 1, required this.onCambio});

  Widget _boton(IconData i, bool activo, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: activo ? onTap : null,
        child: Padding(padding: const EdgeInsets.all(5), child: Icon(i, size: 18, color: activo ? AppColors.textWhite : AppColors.textGrayDark)),
      );

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: AppColors.bgCardLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 4),
          Text(etiqueta, style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
          const SizedBox(width: 4),
          _boton(Icons.remove, valor > 0, () => onCambio((valor - paso).clamp(0, max))),
          SizedBox(width: 30, child: Text('$valor', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
          _boton(Icons.add, valor < max, () => onCambio((valor + paso).clamp(0, max))),
        ]),
      );
}