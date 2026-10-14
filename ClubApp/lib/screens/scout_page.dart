import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/scout_service.dart';
import 'scout_conversations_page.dart';

class _Msg {
  final String texto;
  final bool esUsuario;
  final bool error;
  const _Msg(this.texto, {this.esUsuario = false, this.error = false});
}

class ScoutPage extends StatefulWidget {
  const ScoutPage({super.key});

  @override
  State<ScoutPage> createState() => _ScoutPageState();
}

class _ScoutPageState extends State<ScoutPage> {
  static const _sugerencias = [
    'Recomiéndame un jugador',
    '¿Qué torneos hay activos?',
    'Compara a los delanteros disponibles',
    'Consejos para armar mi plantilla',
  ];

  final _mensajes = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Object? _conversacionId; // null = conversación nueva
  bool _enviando = false;

  bool _cargandoHistorial = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  // La IA a veces responde con Markdown: se quitan los símbolos para que se lea limpio
  String _limpiar(String t) => t.replaceAll('**', '').replaceAll(RegExp(r'^#+\s*', multiLine: true), '');

  Future<void> _enviar([String? sugerido]) async {
    final texto = (sugerido ?? _input.text).trim();
    if (texto.isEmpty || _enviando) return;
    _input.clear();
    setState(() {
      _mensajes.add(_Msg(texto, esUsuario: true));
      _enviando = true;
    });
    _bajar();

    final r = await ScoutService.enviar(texto, conversacionId: _conversacionId);
    if (!mounted) return;
    setState(() {
      _enviando = false;
      if (r['exito'] == true) {
        _conversacionId = r['conversacionId'];

        _mensajes.add(_Msg(_limpiar(r['respuesta'].toString())));
      } else {
        _mensajes.add(_Msg(r['mensaje'].toString(), error: true));
      }
    });
    _bajar();
  }

  /// Quita el último mensaje del usuario y el error que le siguió, y lo vuelve a enviar
  void _reintentar() {
    final i = _mensajes.lastIndexWhere((m) => m.esUsuario);
    if (i < 0) return;
    final texto = _mensajes[i].texto;
    setState(() => _mensajes.removeRange(i, _mensajes.length));
    _enviar(texto);
  }

  void _nueva() => setState(() {
        _mensajes.clear();
        _conversacionId = null;
      });

  Future<void> _abrirConversaciones() async {
    final r = await Navigator.push<Object>(context, MaterialPageRoute(builder: (_) => ScoutConversationsPage(actualId: _conversacionId)));
    if (!mounted || r == null) return;
    if (r == false) {
      _nueva();
    } else {
      _abrir(r);
    }
  }


  Future<void> _abrir(Object id) async {
    setState(() {
      _cargandoHistorial = true;
      _mensajes.clear();
      _conversacionId = id;
    });
    final r = await ScoutService.historial(id);
    if (!mounted) return;
    setState(() {
      _cargandoHistorial = false;
      if (r['exito'] == true) {
        _mensajes.addAll((r['historial'] as List).map((m) => _Msg(_limpiar(m['contenido'].toString()), esUsuario: m['rol'] == 'user')));
      } else {
        _conversacionId = null;
        _mensajes.add(_Msg(r['mensaje'].toString(), error: true));
      }
    });
    _bajar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          title: const Row(children: [
            CircleAvatar(radius: 14, backgroundColor: AppColors.blue, child: Icon(Icons.smart_toy, size: 16, color: AppColors.textWhite)),
            SizedBox(width: 10),
            Text('Scout AI'),
          ]),
          actions: [

            IconButton(tooltip: 'Nueva conversación', icon: const Icon(Icons.add_comment_outlined), onPressed: _nueva),
            IconButton(tooltip: 'Conversaciones', icon: const Icon(Icons.history), onPressed: _abrirConversaciones),
          ],
        ),
        body: Column(children: [Expanded(child: _cuerpo), _barraEntrada]),
      );

  Widget get _cuerpo {
    if (_cargandoHistorial) return const Center(child: CircularProgressIndicator());
    if (_mensajes.isEmpty) return _bienvenida;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _mensajes.length + (_enviando ? 1 : 0),
      itemBuilder: (_, i) => i == _mensajes.length ? _pensando : _burbuja(_mensajes[i]),
    );
  }

  Widget get _bienvenida => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.smart_toy, color: AppColors.textWhite, size: 38),
            ),
            const SizedBox(height: 16),
            const Text('¡Hola! Soy Scout AI', style: TextStyle(fontSize: 20, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Te ayudo a encontrar jugadores, comparar rendimiento y resolver dudas sobre tus torneos.',

                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textGray)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in _sugerencias)
                  ActionChip(
                    label: Text(s, style: const TextStyle(color: AppColors.textWhite, fontSize: 12)),
                    backgroundColor: AppColors.bgCard,
                    side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                    onPressed: () => _enviar(s),
                  ),
              ],
            ),
          ]),
        ),
      );

  Widget _burbuja(_Msg m) {
    final usuario = m.esUsuario;
    return Align(
      alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        decoration: BoxDecoration(
          color: m.error ? AppColors.error.withValues(alpha: 0.15) : (usuario ? AppColors.blue : AppColors.bgCard),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),

            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(usuario ? 16 : 4),
            bottomRight: Radius.circular(usuario ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          SelectableText(m.texto, style: TextStyle(fontSize: 14, height: 1.35, color: m.error ? AppColors.error : AppColors.textWhite)),
          if (m.error && _mensajes.any((x) => x.esUsuario))
            TextButton(
              onPressed: _reintentar,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Reintentar', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ),
        ]),
      ),
    );
  }

  Widget get _pensando => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Scout AI está pensando…', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
          ]),
        ),
      );


  Widget get _barraEntrada => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'Pregúntale algo a Scout AI',
                  hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.bgCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _enviando ? null : () => _enviar(),
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: AppColors.textWhite),
            ),
          ]),
        ),

      );
}