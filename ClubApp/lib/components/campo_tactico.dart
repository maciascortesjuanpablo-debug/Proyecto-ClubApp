import 'package:flutter/material.dart';
import '../core/formaciones.dart';
import '../models/models.dart';

/// Campo de fútbol visto desde arriba con las casillas de la formación. El portero va abajo y los delanteros arriba.
/// Cada casilla muestra al jugador que la ocupa (dorsal y apellido) o un "+" si está vacía.
class CampoTactico extends StatelessWidget {
  final String formacion;
  final Map<int, JugadorPlantilla> ocupantes; // casilla -> jugador
  final Color colorEquipo;
  final ValueChanged<int> onCasilla;

  const CampoTactico({super.key, required this.formacion, required this.ocupantes, required this.colorEquipo, required this.onCasilla});

  static String _abreviatura(String rol) => switch (rol) { 'Portero' => 'POR', 'Defensa' => 'DEF', 'Delantero' => 'DEL', _ => 'MED' };

  @override
  Widget build(BuildContext context) {
    final lineas = Formaciones.lineas(formacion);
    return AspectRatio(
      aspectRatio: 0.78,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final casillas = <Widget>[];

        Widget casilla(int slot, double x, double y) {
          final j = ocupantes[slot];
          final rol = Formaciones.rolDeCasilla(formacion, slot);
          const ancho = 72.0;
          return Positioned(
            left: x * w - ancho / 2,
            top: y * h - 30,
            width: ancho,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onCasilla(slot),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: j == null ? Colors.black26 : colorEquipo,
                    shape: BoxShape.circle,
                    border: Border.all(color: j == null ? Colors.white54 : Colors.white, width: j == null ? 1.5 : 2.5),
                    boxShadow: j == null ? null : const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: j == null
                      ? Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.add, color: Colors.white70, size: 17), Text(_abreviatura(rol), style: const TextStyle(fontSize: 8.5, color: Colors.white60, fontWeight: FontWeight.bold))])
                      : Text(j.dorsal?.toString() ?? j.iniciales, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                if (j != null)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text(j.apellido.isNotEmpty ? j.apellido.split(' ').first : j.nombre.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
          );
        }

        // Portero abajo
        casillas.add(casilla(0, 0.5, 0.88));
        var slot = 1;
        for (var i = 0; i < lineas.length; i++) {
          final y = lineas.length == 1 ? 0.4 : 0.72 - (0.60 * i / (lineas.length - 1));
          for (var k = 0; k < lineas[i]; k++) {
            casillas.add(casilla(slot, (k + 1) / (lineas[i] + 1), y));
            slot++;
          }
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _CampoPainter())),
            ...casillas,
          ]),
        );
      }),
    );
  }
}

class _CampoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Franjas de césped
    const franjas = 8;
    for (var i = 0; i < franjas; i++) {
      canvas.drawRect(Rect.fromLTWH(0, h * i / franjas, w, h / franjas), Paint()..color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF388E3C));
    }
    final linea = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const m = 10.0;
    canvas.drawRect(Rect.fromLTRB(m, m, w - m, h - m), linea);
    canvas.drawLine(Offset(m, h / 2), Offset(w - m, h / 2), linea);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.14, linea);
    canvas.drawCircle(Offset(w / 2, h / 2), 3, Paint()..color = Colors.white70);
    // Áreas
    final areaAncho = w * 0.55;
    final areaAlto = h * 0.15;
    canvas.drawRect(Rect.fromLTWH((w - areaAncho) / 2, h - m - areaAlto, areaAncho, areaAlto), linea);
    canvas.drawRect(Rect.fromLTWH((w - areaAncho) / 2, m, areaAncho, areaAlto), linea);
    final pequenoAncho = w * 0.28;
    final pequenoAlto = h * 0.06;
    canvas.drawRect(Rect.fromLTWH((w - pequenoAncho) / 2, h - m - pequenoAlto, pequenoAncho, pequenoAlto), linea);
    canvas.drawRect(Rect.fromLTWH((w - pequenoAncho) / 2, m, pequenoAncho, pequenoAlto), linea);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}