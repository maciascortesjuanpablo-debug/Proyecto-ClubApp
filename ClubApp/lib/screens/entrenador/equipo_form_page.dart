import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../components/role_guard.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/formaciones.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/team_service.dart';

/// Formulario completo de equipo (solo ENTRENADOR). Sin [equipo] crea uno nuevo; con [equipo] edita su ficha.
/// Se cierra devolviendo `true` si guardó algo.
class EquipoFormPage extends StatefulWidget {
  final Equipo? equipo;
  const EquipoFormPage({super.key, this.equipo});

  @override
  State<EquipoFormPage> createState() => _EquipoFormPageState();
}

class _EquipoFormPageState extends State<EquipoFormPage> {
  static const _colores = [
    Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFF8E24AA),
    Color(0xFF00ACC1), Color(0xFFFDD835), Color(0xFF6D4C41), Color(0xFF212121), Color(0xFFEC407A),
  ];

  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.equipo?.nombre ?? '');
  late final _eslogan = TextEditingController(text: widget.equipo?.eslogan ?? '');
  late final _ciudad = TextEditingController(text: widget.equipo?.ciudad ?? '');
  late final _descripcion = TextEditingController(text: widget.equipo?.descripcion ?? '');

  late String _formato = widget.equipo?.formato ?? Formaciones.formatos.first;
  late String _formacion = widget.equipo?.formacion ?? Formaciones.porDefecto(widget.equipo?.formato);
  late int _cupo = widget.equipo?.maxJugadores ?? Formaciones.cupoSugerido(widget.equipo?.formato ?? Formaciones.formatos.first);
  late Color _color = widget.equipo?.color ?? _colores.first;
  String? _escudoLocal; // ruta de la imagen elegida
  bool _guardando = false;

  bool get _edicion => widget.equipo != null;

  @override
  void dispose() {
    for (final c in [_nombre, _eslogan, _ciudad, _descripcion]) {
      c.dispose();
    }
    super.dispose();
  }

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _elegirEscudo() async {
    final foto = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);
    if (foto == null) return;
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(foto.path.split('.').last.toLowerCase())) return _aviso('Usa una imagen JPG, PNG o WEBP');
    setState(() => _escudoLocal = foto.path);
  }

  void _cambiarFormato(String f) => setState(() {
        // Si el cupo no se tocó (sigue siendo el sugerido del formato anterior), se ajusta al del nuevo formato
        if (_cupo == Formaciones.cupoSugerido(_formato)) _cupo = Formaciones.cupoSugerido(f);
        _formato = f;
        if (!Formaciones.de(f).contains(_formacion)) _formacion = Formaciones.porDefecto(f);
      });

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cupo < Formaciones.jugadoresEnCancha(_formato)) return _aviso('El cupo debe alcanzar al menos para los ${Formaciones.jugadoresEnCancha(_formato)} jugadores de la cancha');
    setState(() => _guardando = true);

    final ficha = <String, dynamic>{
      'nombre': _nombre.text.trim(),
      'eslogan': _eslogan.text.trim(),
      'ciudad': _ciudad.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'formato': _formato,
      'formacion': _formacion,
      'max_jugadores': _cupo,
      'color_principal': colorAHex(_color),
    };
    final r = _edicion ? await TeamService.actualizar(widget.equipo!.id, ficha) : await TeamService.crear(ficha);
    if (!mounted) return;
    if (r['exito'] != true) {
      setState(() => _guardando = false);
      return _aviso(r['mensaje'].toString());
    }

    // El escudo se sube aparte, una vez que el equipo existe
    final id = _edicion ? widget.equipo!.id : (r['equipo'] as Map)['id'] as Object;
    String? problema = r['aviso']?.toString();
    if (_escudoLocal != null) {
      final s = await TeamService.subirEscudo(id, _escudoLocal!);
      if (s['exito'] != true) problema = '${problema ?? ''} ${s['mensaje']}'.trim();
    }
    if (!mounted) return;
    _aviso(problema ?? (_edicion ? 'Equipo actualizado' : 'Equipo creado'));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => RoleGuard(
        roles: const {RolApp.entrenador},
        child: Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: Text(_edicion ? 'Editar equipo' : 'Crear equipo')),
          body: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
              _vistaPrevia(),
              const SeccionTitulo('Identidad'),
              AppTextField(
                label: 'Nombre del equipo *',
                hint: 'Ej: Halcones FC',
                controller: _nombre,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Escribe el nombre del equipo' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Eslogan', hint: 'Ej: Juntos hasta el final', controller: _eslogan, onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              AppTextField(label: 'Ciudad o municipio', hint: 'Ej: Neiva', controller: _ciudad),
              const SizedBox(height: 16),
              AppTextField(label: 'Descripción', hint: 'Cuenta quiénes son y qué buscan', controller: _descripcion, minLines: 3, maxLines: 5),
              const SeccionTitulo('Color del equipo'),
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (final c in _colores)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: _color == c ? AppColors.textWhite : Colors.transparent, width: 3)),
                      child: _color == c ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  ),
              ]),
              const SeccionTitulo('Formato de juego'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final f in Formaciones.formatos) ChoiceChip(label: Text(f), selected: _formato == f, onSelected: (_) => _cambiarFormato(f)),
              ]),
              const SeccionTitulo('Formación táctica'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final f in Formaciones.de(_formato)) ChoiceChip(label: Text(f), selected: _formacion == f, onSelected: (_) => setState(() => _formacion = f)),
              ]),
              const SizedBox(height: 6),
              const Text('Podrás cambiarla después desde el panel de la alineación.', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
              const SeccionTitulo('Cantidad de jugadores'),
              TarjetaBase(
                child: Row(children: [
                  IconButton(onPressed: _cupo > 1 ? () => setState(() => _cupo--) : null, icon: const Icon(Icons.remove_circle_outline, color: AppColors.secondary)),
                  Expanded(
                    child: Column(children: [
                      Text('$_cupo', style: const TextStyle(fontSize: 26, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                      const Text('cupo máximo de la plantilla', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                    ]),
                  ),
                  IconButton(onPressed: _cupo < 60 ? () => setState(() => _cupo++) : null, icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary)),
                ]),
              ),
              const SizedBox(height: 28),
              AppButton(label: _edicion ? 'Guardar cambios' : 'Crear equipo', isLoading: _guardando, onPressed: _guardar),
            ]),
          ),
        ),
      );

  /// Cómo se verá el equipo: escudo, nombre y eslogan sobre su color
  Widget _vistaPrevia() {
    final logo = widget.equipo?.logoUrl;
    final nombre = _nombre.text.trim().isEmpty ? 'Nombre del equipo' : _nombre.text.trim();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [_color, _color.withValues(alpha: 0.45)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        GestureDetector(
          onTap: _elegirEscudo,
          child: Stack(children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: Colors.black26,
              backgroundImage: _escudoLocal != null ? FileImage(File(_escudoLocal!)) : (logo != null ? NetworkImage(logo) as ImageProvider : null),
              child: (_escudoLocal == null && logo == null) ? const Icon(Icons.shield_outlined, size: 40, color: Colors.white70) : null,
            ),
            const Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 15, backgroundColor: AppColors.secondary, child: Icon(Icons.camera_alt, size: 16, color: AppColors.bgDark))),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, color: Colors.white, fontWeight: FontWeight.bold)),
            if (_eslogan.text.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('“${_eslogan.text.trim()}”', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white70, fontStyle: FontStyle.italic))),
            const SizedBox(height: 8),
            Text('$_formato · $_formacion · $_cupo jugadores', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            const Text('Toca el escudo para elegir tu foto', style: TextStyle(fontSize: 11, color: Colors.white60)),
          ]),
        ),
      ]),
    );
  }
}