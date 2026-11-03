import 'package:flutter/material.dart';
import '../../components/campo_tactico.dart';
import '../../components/editar_jugador.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/formaciones.dart';
import '../../models/models.dart';
import '../../services/team_service.dart';

/// Panel táctico del ENTRENADOR: el campo con los titulares en su casilla. Toca una casilla para
/// colocar, cambiar o quitar un jugador; cambia la formación y guarda la alineación.
class AlineacionTab extends StatefulWidget {
  final Equipo equipo;
  const AlineacionTab({super.key, required this.equipo});

  @override
  State<AlineacionTab> createState() => _AlineacionTabState();
}

class _AlineacionTabState extends State<AlineacionTab> {
  List<JugadorPlantilla>? _plantilla;
  String? _error;
  late String _formacion = widget.equipo.formacion ?? Formaciones.porDefecto(widget.equipo.formato);
  final Map<int, JugadorPlantilla> _slots = {};
  bool _sucio = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await TeamService.plantilla(widget.equipo.id);
    if (!mounted) return;
    setState(() {
      _error = r.error;
      _plantilla = r.dato;
      _slots.clear();
      if (r.dato != null) _armarDesdePlantilla(r.dato!);
    });
  }

  /// Coloca a cada titular en su casilla guardada; los titulares antiguos sin casilla se ubican según su posición
  void _armarDesdePlantilla(List<JugadorPlantilla> p) {
    final total = Formaciones.casillas(_formacion);
    final sinCasilla = <JugadorPlantilla>[];
    for (final j in p.where((j) => j.esTitular)) {
      if (j.slotCampo != null && j.slotCampo! < total && !_slots.containsKey(j.slotCampo)) {
        _slots[j.slotCampo!] = j;
      } else {
        sinCasilla.add(j);
      }
    }
    if (sinCasilla.isNotEmpty) {
      _autoColocar(sinCasilla);
      _sucio = true;
    }
  }

  /// Llena casillas vacías con los candidatos cuya posición coincide con la de la casilla
  void _autoColocar(List<JugadorPlantilla> candidatos) {
    final usados = _slots.values.map((j) => '${j.usuarioId}').toSet();
    final libres = candidatos.where((j) => !usados.contains('${j.usuarioId}')).toList();
    for (var s = 0; s < Formaciones.casillas(_formacion); s++) {
      if (_slots.containsKey(s)) continue;
      final rol = Formaciones.rolDeCasilla(_formacion, s);
      final i = libres.indexWhere((j) => Formaciones.rolDePosicion(j.posicion) == rol);
      if (i >= 0) _slots[s] = libres.removeAt(i);
    }
  }

  void _cambiarFormacion(String f) {
    final titulares = _slots.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    setState(() {
      _formacion = f;
      _slots.clear();
      _autoColocar(titulares.map((e) => e.value).toList());
      // Los que no encontraron casilla de su línea ocupan las que sigan libres
      final usados = _slots.values.map((j) => '${j.usuarioId}').toSet();
      final resto = titulares.map((e) => e.value).where((j) => !usados.contains('${j.usuarioId}')).toList();
      for (var s = 0; s < Formaciones.casillas(f) && resto.isNotEmpty; s++) {
        if (!_slots.containsKey(s)) _slots[s] = resto.removeAt(0);
      }
      _sucio = true;
    });
  }

  void _sugerir() {
    final enCampo = _slots.values.map((j) => '${j.usuarioId}').toSet();
    setState(() {
      _autoColocar((_plantilla ?? []).where((j) => !enCampo.contains('${j.usuarioId}')).toList());
      _sucio = true;
    });
  }

  int? _casillaDe(JugadorPlantilla j) {
    for (final e in _slots.entries) {
      if ('${e.value.usuarioId}' == '${j.usuarioId}') return e.key;
    }
    return null;
  }

  void _asignar(int slot, JugadorPlantilla j) {
    setState(() {
      final previo = _slots[slot];
      final origen = _casillaDe(j);
      if (origen != null) {
        // El jugador ya estaba en el campo: intercambia lugar con quien ocupaba esta casilla
        if (previo != null) {
          _slots[origen] = previo;
        } else {
          _slots.remove(origen);
        }
      }
      _slots[slot] = j;
      _sucio = true;
    });
  }

  Future<void> _tocarCasilla(int slot) async {
    final rol = Formaciones.rolDeCasilla(_formacion, slot);
    final actual = _slots[slot];
    final jugadores = [...(_plantilla ?? <JugadorPlantilla>[])];
    // Primero los de la misma línea, luego el resto
    jugadores.sort((a, b) {
      final pa = Formaciones.rolDePosicion(a.posicion) == rol ? 0 : 1;
      final pb = Formaciones.rolDePosicion(b.posicion) == rol ? 0 : 1;
      return pa != pb ? pa.compareTo(pb) : (a.dorsal ?? 999).compareTo(b.dorsal ?? 999);
    });

    final accion = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.75),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 6), child: Align(alignment: Alignment.centerLeft, child: Text('Casilla de $rol', style: const TextStyle(fontSize: 17, color: AppColors.textWhite, fontWeight: FontWeight.bold)))),
            if (actual != null) ...[
              ListTile(leading: const Icon(Icons.edit_outlined, color: AppColors.secondary), title: Text('Editar a ${actual.nombreCompleto}', style: const TextStyle(color: AppColors.textWhite)), onTap: () => Navigator.pop(c, 'editar')),
              ListTile(leading: const Icon(Icons.remove_circle_outline, color: AppColors.error), title: const Text('Dejar la casilla vacía', style: TextStyle(color: AppColors.textWhite)), onTap: () => Navigator.pop(c, 'vaciar')),
              const Divider(color: AppColors.bgCardLight),
            ],
            if (jugadores.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Aún no hay jugadores en la plantilla. Invita jugadores primero.', style: TextStyle(color: AppColors.textGray))),
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                for (final j in jugadores)
                  ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.bgCardLight, child: Text(j.dorsal?.toString() ?? j.iniciales, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold))),
                    title: Text(j.nombreCompleto, style: const TextStyle(color: AppColors.textWhite)),
                    subtitle: Text('${j.posicion}${_casillaDe(j) != null ? ' · en el campo' : ' · suplente'}', style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                    trailing: '${actual?.usuarioId}' == '${j.usuarioId}' ? const Icon(Icons.check, color: AppColors.success) : null,
                    onTap: () => Navigator.pop(c, j),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
    if (!mounted || accion == null) return;
    if (accion == 'vaciar') {
      setState(() {
        _slots.remove(slot);
        _sucio = true;
      });
    } else if (accion == 'editar' && actual != null) {
      if (await editarJugadorEquipo(context, widget.equipo.id, actual)) await _recargarConservandoCambios();
    } else if (accion is JugadorPlantilla) {
      _asignar(slot, accion);
    }
  }

  /// Vuelve a pedir la plantilla (por ejemplo tras editar un dorsal) sin perder la alineación que se está armando
  Future<void> _recargarConservandoCambios() async {
    final r = await TeamService.plantilla(widget.equipo.id);
    if (!mounted || r.dato == null) return;
    final porUsuario = {for (final j in r.dato!) '${j.usuarioId}': j};
    setState(() {
      _plantilla = r.dato;
      for (final e in _slots.entries.toList()) {
        final nuevo = porUsuario['${e.value.usuarioId}'];
        if (nuevo != null) _slots[e.key] = nuevo;
      }
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final titulares = <Map<String, dynamic>>[];
    for (final e in _slots.entries) {
      final rol = Formaciones.rolDeCasilla(_formacion, e.key);
      final j = e.value;
      titulares.add({
        'usuario_id': j.usuarioId,
        'slot': e.key,
        // Solo se reescribe la posición si no coincide con la línea donde juega
        if (Formaciones.rolDePosicion(j.posicion) != rol) 'posicion': rol,
      });
    }
    final r = await TeamService.guardarAlineacion(widget.equipo.id, _formacion, titulares);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      if (r['exito'] == true) _sucio = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['exito'] == true ? 'Alineación guardada' : r['mensaje'].toString())));
    if (r['exito'] == true) await _recargarConservandoCambios();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColors.textGray)));
    if (_plantilla == null) return const Center(child: CircularProgressIndicator());
    final enCampo = _slots.values.map((j) => '${j.usuarioId}').toSet();
    final suplentes = _plantilla!.where((j) => !enCampo.contains('${j.usuarioId}')).toList();
    final total = Formaciones.casillas(_formacion);
    final formaciones = Formaciones.de(widget.equipo.formato);

    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 110), children: [
        Row(children: [
          Expanded(child: Text('Titulares ${_slots.length}/$total', style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
          TextButton.icon(onPressed: _sugerir, icon: const Icon(Icons.auto_fix_high, size: 18), label: const Text('Completar')),
        ]),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in {...formaciones, _formacion})
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(f), selected: _formacion == f, onSelected: (_) => _cambiarFormacion(f))),
          ]),
        ),
        const SizedBox(height: 12),
        CampoTactico(formacion: _formacion, ocupantes: _slots, colorEquipo: widget.equipo.color, onCasilla: _tocarCasilla),
        const SizedBox(height: 8),
        const Text('Toca una casilla para colocar, cambiar o quitar un jugador.', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
        SeccionTitulo('Suplentes (${suplentes.length})'),
        if (suplentes.isEmpty)
          const Text('Todos los jugadores de la plantilla están en el campo.', style: TextStyle(color: AppColors.textGray, fontSize: 13))
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final j in suplentes)
              ActionChip(
                avatar: CircleAvatar(backgroundColor: AppColors.bgCardLight, child: Text(j.dorsal?.toString() ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textWhite))),
                label: Text('${j.nombre.split(' ').first} · ${j.posicion}'),
                onPressed: () async {
                  if (await editarJugadorEquipo(context, widget.equipo.id, j)) await _recargarConservandoCambios();
                },
              ),
          ]),
      ]),
      Positioned(
        left: 16,
        right: 16,
        bottom: 16,
        child: FilledButton.icon(
          onPressed: (_sucio && !_guardando) ? _guardar : null,
          icon: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
          label: Text(_sucio ? 'Guardar alineación' : 'Alineación guardada'),
        ),
      ),
    ]);
  }
}