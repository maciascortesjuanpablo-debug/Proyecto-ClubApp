import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/home_services.dart';
import '../services/scout_service.dart';

/// Lista de conversaciones. Al cerrar devuelve el id elegido, `false` para empezar una nueva o null si no se eligió nada.
class ScoutConversationsPage extends StatefulWidget {
  final Object? actualId;

  const ScoutConversationsPage({super.key, this.actualId});

  @override
  State<ScoutConversationsPage> createState() => _ScoutConversationsPageState();
}

class _ScoutConversationsPageState extends State<ScoutConversationsPage> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final r = await ScoutService.conversaciones();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r['exito'] == true) {
        _items = (r['conversaciones'] as List).cast<Map<String, dynamic>>();
      } else {
        _error = r['mensaje'].toString();
      }
    });
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  AlertDialog _dialogo(String titulo, Widget contenido, List<Widget> acciones) =>
      AlertDialog(backgroundColor: AppColors.bgCard, title: Text(titulo, style: const TextStyle(color: AppColors.textWhite)), content: contenido, actions: acciones);

  Future<void> _eliminar(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => _dialogo(
        'Eliminar conversación',
        Text('Se borrará "${c['titulo']}" con todos sus mensajes.', style: const TextStyle(color: AppColors.textGray)),
        [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;

    final r = await ScoutService.eliminar(c['id']);
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje']);
    if (c['id'].toString() == widget.actualId?.toString()) return Navigator.pop(context, false); // borró la que tenía abierta
    setState(() => _items?.remove(c));
  }

  Future<void> _renombrar(Map<String, dynamic> c) async {
    final controlador = TextEditingController(text: (c['titulo'] ?? '').toString());
    final titulo = await showDialog<String>(
      context: context,
      builder: (d) => _dialogo(
        'Renombrar',
        TextField(controller: controlador, autofocus: true, maxLength: 60, style: const TextStyle(color: AppColors.textWhite)),
        [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, controlador.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    if (titulo == null || titulo.isEmpty) return;

    final r = await ScoutService.renombrar(c['id'], titulo);
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje']);
    setState(() => c['titulo'] = titulo);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          title: const Text('Conversaciones'),
          actions: [IconButton(tooltip: 'Nueva conversación', icon: const Icon(Icons.add), onPressed: () => Navigator.pop(context, false))],
        ),
        body: _cuerpo,
      );

  Widget get _cuerpo {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
        ]),
      );
    }
    final items = _items ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('Aún no tienes conversaciones', style: TextStyle(color: AppColors.textGray)));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _tarjeta(items[i]),
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> c) {
    final actual = c['id'].toString() == widget.actualId?.toString();
    return Material(
      color: actual ? AppColors.blue.withValues(alpha: 0.25) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () => Navigator.pop(context, c['id']),
        leading: const CircleAvatar(backgroundColor: AppColors.blue, child: Icon(Icons.chat_bubble_outline, color: AppColors.textWhite, size: 20)),
        title: Text((c['titulo'] ?? 'Conversación').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
        subtitle: Text(HomeService.hace((c['actualizado_en'] ?? c['creado_en'])?.toString()), style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
        trailing: PopupMenuButton<String>(
          color: AppColors.bgCard,
          iconColor: AppColors.textGray,
          onSelected: (v) => v == 'renombrar' ? _renombrar(c) : _eliminar(c),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'renombrar', child: Text('Renombrar', style: TextStyle(color: AppColors.textWhite))),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: AppColors.error))),
          ],
        ),
      ),
    );
  }
}