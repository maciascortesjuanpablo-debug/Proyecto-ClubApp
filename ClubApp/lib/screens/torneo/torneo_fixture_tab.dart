import 'dart:math';
import 'package:flutter/material.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/calendar_utils.dart';
import '../../models/models.dart';
import '../../services/calendar_service.dart';
import '../../services/tournament_service.dart';

/// Fixture automático (solo organizador dueño del torneo y admin): se eligen los equipos, el formato, las fechas
/// y los horarios, y los partidos se crean y se reparten solos en el calendario de todos los participantes.
class TorneoFixtureTab extends StatefulWidget {
  final Torneo torneo;
  final Future<void> Function() onCambio;
  const TorneoFixtureTab({super.key, required this.torneo, required this.onCambio});

  @override
  State<TorneoFixtureTab> createState() => _TorneoFixtureTabState();
}

class _TorneoFixtureTabState extends State<TorneoFixtureTab> {
  static const _formatos = {
    'todos': ('Todos contra todos', 'Cada equipo juega una vez contra todos los demás.'),
    'ida_vuelta': ('Ida y vuelta', 'Todos contra todos, dos veces: de local y de visitante.'),
    'grupos': ('Por grupos', 'Los equipos se reparten en grupos y juegan dentro de su grupo.'),
    'eliminacion': ('Eliminación directa', 'Se arma la primera ronda de cruces; el que pierde queda fuera.'),
  };
  static const _dias = [('L', 1, 'Lunes'), ('M', 2, 'Martes'), ('X', 3, 'Miércoles'), ('J', 4, 'Jueves'), ('V', 5, 'Viernes'), ('S', 6, 'Sábado'), ('D', 0, 'Domingo')];

  // Datos para elegir
  List<Inscripcion> _aceptados = [];
  Map<Object, String> _sedes = {};
  bool _cargando = true;
  String? _errorCarga;

  // Configuración
  final Set<String> _equiposElegidos = {};
  String _modo = 'todos';
  int _numGrupos = 2;
  bool _idaVueltaGrupos = false;
  bool _sorteo = true;
  int _semilla = Random().nextInt(1 << 30) + 1;
  late DateTime _fechaInicio = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)));
  final Set<int> _diasJuego = {6, 0};
  final List<String> _horas = ['16:00'];
  final Set<Object> _sedesElegidas = {};
  int _simultaneos = 1;
  bool _reemplazar = false;

  // Resultado
  PropuestaFixture? _propuesta;
  String? _error;
  bool _calculando = false;
  bool _creando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await Future.wait([TournamentService.inscripciones(widget.torneo.id), CalendarService.sedes()]);
    if (!mounted) return;
    final ins = r[0] as dynamic;
    final sedes = r[1] as Map<String, dynamic>;
    setState(() {
      _cargando = false;
      if (ins.ok == true) {
        _aceptados = (ins.dato as List<Inscripcion>).where((i) => i.estado == 'Aceptado' && i.equipo != null).toList();
        _equiposElegidos
          ..clear()
          ..addAll(_aceptados.map((i) => '${i.equipo!.id}'));
      } else {
        _errorCarga = ins.error as String?;
      }
      if (sedes['exito'] == true) _sedes = {for (final s in toLista(sedes['datos'])) s['id'] as Object: s['nombre'].toString()};
    });
  }

  /// Cualquier cambio de configuración invalida la vista previa anterior
  void _cambio(VoidCallback f) => setState(() {
        f();
        _propuesta = null;
        _error = null;
      });

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> get _config => {
        // El orden de selección es el de la lista de aceptados (siembra para eliminación y grupos cuando no hay sorteo)
        'equipos': [for (final i in _aceptados) if (_equiposElegidos.contains('${i.equipo!.id}')) i.equipo!.id],
        'modo': _modo,
        if (_modo == 'grupos') 'num_grupos': _numGrupos,
        if (_modo == 'grupos') 'ida_vuelta_grupos': _idaVueltaGrupos,
        'sorteo': _sorteo,
        'semilla': _semilla,
        'fecha_inicio': isoFecha(_fechaInicio),
        'dias': _diasJuego.toList()..sort(),
        'horas': _horas,
        if (_sedesElegidas.isNotEmpty) 'sedes': _sedesElegidas.toList(),
        'simultaneos': _simultaneos,
        'reemplazar': _reemplazar,
      };

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final f = await showDatePicker(context: context, initialDate: _fechaInicio.isBefore(hoy) ? hoy : _fechaInicio, firstDate: hoy, lastDate: hoy.add(const Duration(days: 365)), helpText: 'Fecha de inicio del campeonato');
    if (f != null) _cambio(() => _fechaInicio = f);
  }

  Future<void> _agregarHora() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 16, minute: 0), helpText: 'Horario de partido');
    if (t == null) return;
    final h = _hhmm(t);
    if (_horas.contains(h)) return;
    if (_horas.length >= 8) return _aviso('Puedes elegir hasta 8 horarios');
    _cambio(() => _horas
      ..add(h)
      ..sort());
  }

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _previsualizar({bool resortear = false}) async {
    if (_equiposElegidos.length < 2) return _aviso('Elige al menos 2 equipos');
    if (_diasJuego.isEmpty) return _aviso('Elige al menos un día de la semana');
    if (_horas.isEmpty) return _aviso('Agrega al menos un horario');
    if (resortear) _semilla = Random().nextInt(1 << 30) + 1;
    setState(() {
      _calculando = true;
      _error = null;
      _propuesta = null;
    });
    final r = await TournamentService.previsualizarFixture(widget.torneo.id, _config);
    if (!mounted) return;
    setState(() {
      _calculando = false;
      _propuesta = r.dato;
      _error = r.error;
    });
  }

  Future<void> _crear() async {
    final p = _propuesta;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Crear el calendario', style: TextStyle(color: AppColors.textWhite)),
        content: Text('Se crearán ${p.total} partidos en ${p.jornadas} jornada${p.jornadas == 1 ? '' : 's'}, del ${fechaLarga(p.primera!)} al ${fechaLarga(p.ultima!)}.\n\n'
            'Aparecerán en el calendario de los equipos y se avisará a sus integrantes.${_reemplazar && p.reemplazables > 0 ? '\n\nSe reemplazarán ${p.reemplazables} partidos programados que ya existían.' : ''}',
            style: const TextStyle(color: AppColors.textGray)),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Crear partidos', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)))],
      ),
    );
    if (ok != true) return;
    setState(() => _creando = true);
    final r = await TournamentService.crearFixture(widget.torneo.id, _config);
    if (!mounted) return;
    setState(() => _creando = false);
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    _aviso(r['aviso']?.toString() ?? r['mensaje'].toString());
    setState(() {
      _propuesta = null;
      _reemplazar = false;
    });
    await widget.onCambio(); // actualiza el resumen, los partidos y el calendario del torneo
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_errorCarga != null) return Center(child: Text(_errorCarga!, style: const TextStyle(color: AppColors.textGray)));
    if (widget.torneo.cerrado) return const EstadoVacio(icono: Icons.lock_outline, mensaje: 'Este torneo ya terminó: no se pueden programar más partidos');
    if (_aceptados.length < 2) {
      return const EstadoVacio(icono: Icons.groups_outlined, mensaje: 'Necesitas al menos 2 equipos aceptados para generar el calendario.\nAcepta inscripciones en la pestaña Equipos.');
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 60), children: [
      _paso(1, 'Equipos', _equipos()),
      _paso(2, 'Formato del campeonato', _formato()),
      _paso(3, 'Fechas y horarios', _fechas()),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _calculando ? null : () => _previsualizar(),
        icon: _calculando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
        label: Text(_calculando ? 'Calculando…' : 'Previsualizar calendario'),
      ),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: _tarjetaError(_error!)),
      if (_propuesta != null) ..._vistaPrevia(_propuesta!),
    ]);
  }

  // ---------------------------------------------------------------- pasos
  Widget _paso(int n, String titulo, Widget contenido) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 12, backgroundColor: AppColors.secondary, child: Text('$n', style: const TextStyle(fontSize: 12, color: AppColors.bgDark, fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            Text(titulo, style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          contenido,
        ]),
      );

  Widget _equipos() {
    final todos = _equiposElegidos.length == _aceptados.length;
    return TarjetaBase(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 8),
          Expanded(child: Text('${_equiposElegidos.length} de ${_aceptados.length} equipos seleccionados', style: const TextStyle(fontSize: 12.5, color: AppColors.textGray))),
          TextButton(
            onPressed: () => _cambio(() {
              _equiposElegidos.clear();
              if (!todos) _equiposElegidos.addAll(_aceptados.map((i) => '${i.equipo!.id}'));
            }),
            child: Text(todos ? 'Quitar todos' : 'Seleccionar todos'),
          ),
        ]),
        for (final i in _aceptados)
          CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            controlAffinity: ListTileControlAffinity.trailing,
            value: _equiposElegidos.contains('${i.equipo!.id}'),
            onChanged: (v) => _cambio(() => v == true ? _equiposElegidos.add('${i.equipo!.id}') : _equiposElegidos.remove('${i.equipo!.id}')),
            title: Text(i.equipo!.nombre, style: const TextStyle(color: AppColors.textWhite, fontSize: 14)),
            secondary: EquipoAvatar(nombre: i.equipo!.nombre, logoUrl: i.equipo!.logoUrl, tamano: 32),
          ),
      ]),
    );
  }

  Widget _formato() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in _formatos.entries) ChoiceChip(label: Text(e.value.$1), selected: _modo == e.key, onSelected: (_) => _cambio(() => _modo = e.key)),
        ]),
        const SizedBox(height: 8),
        Text(_formatos[_modo]!.$2, style: const TextStyle(fontSize: 12.5, color: AppColors.textGray)),
        if (_modo == 'grupos') ...[
          const SizedBox(height: 12),
          TarjetaBase(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(children: [
              Row(children: [
                const SizedBox(width: 8),
                const Expanded(child: Text('Cantidad de grupos', style: TextStyle(color: AppColors.textWhite))),
                IconButton(onPressed: _numGrupos > 2 ? () => _cambio(() => _numGrupos--) : null, icon: const Icon(Icons.remove_circle_outline, color: AppColors.secondary)),
                Text('$_numGrupos', style: const TextStyle(fontSize: 18, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                IconButton(onPressed: _numGrupos < 8 ? () => _cambio(() => _numGrupos++) : null, icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary)),
              ]),
              SwitchListTile(dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8), title: const Text('Ida y vuelta dentro del grupo', style: TextStyle(color: AppColors.textWhite, fontSize: 14)), value: _idaVueltaGrupos, onChanged: (v) => _cambio(() => _idaVueltaGrupos = v)),
            ]),
          ),
        ],
        if (_modo == 'grupos' || _modo == 'eliminacion')
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Sortear los equipos al azar', style: TextStyle(color: AppColors.textWhite, fontSize: 14)),
            subtitle: Text(_sorteo ? 'Se mezclan antes de armar los ${_modo == 'grupos' ? 'grupos' : 'cruces'}.' : 'Se respeta el orden de la lista (el primero es el mejor sembrado).', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            value: _sorteo,
            onChanged: (v) => _cambio(() => _sorteo = v),
          ),
      ]);

  Widget _fechas() => TarjetaBase(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Primer día', style: TextStyle(fontSize: 12.5, color: AppColors.textGray)),
          const SizedBox(height: 6),
          OutlinedButton.icon(onPressed: _elegirFecha, icon: const Icon(Icons.event), label: Text(fechaLarga(_fechaInicio))),
          const SizedBox(height: 16),
          const Text('Días en que se juega', style: TextStyle(fontSize: 12.5, color: AppColors.textGray)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            for (final d in _dias)
              FilterChip(
                label: Text(d.$1),
                tooltip: d.$3,
                selected: _diasJuego.contains(d.$2),
                onSelected: (v) => _cambio(() => v ? _diasJuego.add(d.$2) : _diasJuego.remove(d.$2)),
              ),
          ]),
          const SizedBox(height: 16),
          const Text('Horarios de los partidos', style: TextStyle(fontSize: 12.5, color: AppColors.textGray)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final h in _horas) InputChip(label: Text(h), onDeleted: _horas.length > 1 ? () => _cambio(() => _horas.remove(h)) : null),
            ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Agregar horario'), onPressed: _agregarHora),
          ]),
          const SizedBox(height: 16),
          const Text('Canchas', style: TextStyle(fontSize: 12.5, color: AppColors.textGray)),
          const SizedBox(height: 6),
          if (_sedes.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 4, children: [
              for (final s in _sedes.entries)
                FilterChip(label: Text(s.value), selected: _sedesElegidas.contains(s.key), onSelected: (v) => _cambio(() => v ? _sedesElegidas.add(s.key) : _sedesElegidas.remove(s.key))),
            ]),
          if (_sedesElegidas.isEmpty) ...[
            if (_sedes.isNotEmpty) const SizedBox(height: 8),
            Row(children: [
              const Expanded(child: Text('Partidos a la vez en cada horario', style: TextStyle(color: AppColors.textWhite, fontSize: 14))),
              IconButton(onPressed: _simultaneos > 1 ? () => _cambio(() => _simultaneos--) : null, icon: const Icon(Icons.remove_circle_outline, color: AppColors.secondary)),
              Text('$_simultaneos', style: const TextStyle(fontSize: 18, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _simultaneos < 8 ? () => _cambio(() => _simultaneos++) : null, icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary)),
            ]),
          ] else
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('Se juega en ${_sedesElegidas.length} cancha${_sedesElegidas.length == 1 ? '' : 's'} a la vez.', style: const TextStyle(fontSize: 12, color: AppColors.textGray))),
        ]),
      );

  // ---------------------------------------------------------------- vista previa
  Widget _tarjetaError(String t) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.error.withValues(alpha: 0.4))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5))),
        ]),
      );

  List<Widget> _vistaPrevia(PropuestaFixture p) {
    final hijos = <Widget>[const SeccionTitulo('Vista previa del calendario')];
    hijos.add(KpiGrid([
      KpiTile(icono: Icons.sports_soccer, valor: '${p.total}', etiqueta: 'Partidos', color: AppColors.primaryLight),
      KpiTile(icono: Icons.format_list_numbered, valor: '${p.jornadas}', etiqueta: 'Jornadas', color: AppColors.orange),
      KpiTile(icono: Icons.event_available, valor: p.primera == null ? '-' : '${p.primera!.day}/${p.primera!.month}', etiqueta: 'Empieza', color: AppColors.success),
      KpiTile(icono: Icons.flag, valor: p.ultima == null ? '-' : '${p.ultima!.day}/${p.ultima!.month}', etiqueta: 'Termina', color: AppColors.secondary),
    ]));

    for (final a in p.advertencias) {
      hijos.add(Padding(padding: const EdgeInsets.only(top: 12), child: _tarjetaError(a)));
    }
    if (p.reemplazables > 0 && p.bloqueantes == 0) {
      hijos.add(SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Reemplazar los partidos programados', style: TextStyle(color: AppColors.textWhite, fontSize: 14)),
        subtitle: Text('El torneo ya tiene ${p.reemplazables} partidos programados; se borrarán y se crearán de nuevo.', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
        value: _reemplazar,
        onChanged: (v) async {
          setState(() => _reemplazar = v);
          await _previsualizar();
        },
      ));
    }

    if (p.grupos.isNotEmpty) {
      hijos.add(const SeccionTitulo('Grupos'));
      hijos.add(Wrap(spacing: 10, runSpacing: 10, children: [
        for (final g in p.grupos)
          Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.nombre, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              for (final e in g.equipos) Padding(padding: const EdgeInsets.only(top: 2), child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textWhite))),
            ]),
          ),
      ]));
    }
    if (p.descansan.isNotEmpty) {
      hijos.add(Padding(padding: const EdgeInsets.only(top: 12), child: Text('Pasan directo a la siguiente ronda: ${p.descansan.join(', ')}', style: const TextStyle(fontSize: 12.5, color: AppColors.textGray))));
    }

    // Partidos agrupados por jornada
    int? jornada;
    for (final x in p.partidos.toList()..sort((a, b) => a.jornada != b.jornada ? a.jornada.compareTo(b.jornada) : '${a.fecha}${a.hora}'.compareTo('${b.fecha}${b.hora}'))) {
      if (x.jornada != jornada) {
        jornada = x.jornada;
        hijos.add(Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text('Jornada $jornada', style: const TextStyle(fontSize: 14, color: AppColors.secondary, fontWeight: FontWeight.bold))));
      }
      hijos.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TarjetaBase(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.schedule, size: 14, color: AppColors.textGray.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text('${x.fecha == null ? '' : fechaLarga(x.fecha!)} · ${x.hora}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
              const Spacer(),
              if (x.fase != null) TournamentChip(x.fase!, color: AppColors.primaryLight),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(x.local, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('vs', style: TextStyle(color: AppColors.textGray, fontSize: 12))),
              Expanded(child: Text(x.visitante, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
            ]),
            if (x.sede != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(x.sede!, style: const TextStyle(fontSize: 11.5, color: AppColors.textGray))),
          ]),
        ),
      ));
    }

    hijos.add(const SizedBox(height: 14));
    if (_sorteo && (_modo == 'grupos' || _modo == 'eliminacion')) {
      hijos.add(OutlinedButton.icon(onPressed: _calculando ? null : () => _previsualizar(resortear: true), icon: const Icon(Icons.shuffle), label: const Text('Volver a sortear')));
      hijos.add(const SizedBox(height: 10));
    }
    hijos.add(FilledButton.icon(
      onPressed: (p.puedeCrear && !_creando) ? _crear : null,
      icon: _creando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
      label: Text(_creando ? 'Creando…' : 'Crear calendario y partidos'),
    ));
    return hijos;
  }
}