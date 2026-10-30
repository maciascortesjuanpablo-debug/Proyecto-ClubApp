import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Gráficos sencillos dibujados a mano (sin dependencias externas) para las estadísticas de la app.

class SegmentoDonut {
  final String etiqueta;
  final num valor;
  final Color color;
  const SegmentoDonut(this.etiqueta, this.valor, this.color);
}

/// Dona con un texto al centro
class DonutChart extends StatelessWidget {
  final List<SegmentoDonut> segmentos;
  final String centro;
  final String? subcentro;
  final double tamano;

  const DonutChart({super.key, required this.segmentos, this.centro = '', this.subcentro, this.tamano = 140});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => SizedBox(
          width: tamano,
          height: tamano,
          child: CustomPaint(
            painter: _DonutPainter(segmentos, t),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(centro, style: const TextStyle(fontSize: 22, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                if (subcentro != null) Text(subcentro!, style: const TextStyle(fontSize: 10.5, color: AppColors.textGray)),
              ]),
            ),
          ),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  final List<SegmentoDonut> segmentos;
  final double avance;
  _DonutPainter(this.segmentos, this.avance);

  @override
  void paint(Canvas canvas, Size size) {
    final grosor = size.width * 0.16;
    final rect = Rect.fromLTWH(grosor / 2, grosor / 2, size.width - grosor, size.height - grosor);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = AppColors.bgCardLight;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    final total = segmentos.fold<double>(0, (a, s) => a + s.valor);
    if (total <= 0) return;
    var inicio = -math.pi / 2;
    for (final s in segmentos) {
      if (s.valor <= 0) continue;
      final barrido = (s.valor / total) * math.pi * 2 * avance;
      final pincel = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.butt
        ..color = s.color;
      canvas.drawArc(rect, inicio, math.max(0, barrido - 0.03), false, pincel);
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.avance != avance || old.segmentos != segmentos;
}

/// Leyenda de colores con su cantidad
class LeyendaChart extends StatelessWidget {
  final List<SegmentoDonut> segmentos;
  const LeyendaChart(this.segmentos, {super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in segmentos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Text('${s.etiqueta}  ', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                Text('${s.valor}', style: const TextStyle(fontSize: 12, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              ]),
            ),
        ],
      );
}

/// Anillo de progreso (0 a 1) con un texto al centro
class AnilloProgreso extends StatelessWidget {
  final double valor;
  final String texto;
  final Color color;
  final double tamano;

  const AnilloProgreso({super.key, required this.valor, required this.texto, this.color = AppColors.secondary, this.tamano = 64});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: valor.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => SizedBox(
          width: tamano,
          height: tamano,
          child: CustomPaint(
            painter: _AnilloPainter(v, color),
            child: Center(child: Text(texto, style: TextStyle(fontSize: tamano * 0.24, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
          ),
        ),
      );
}

class _AnilloPainter extends CustomPainter {
  final double valor;
  final Color color;
  _AnilloPainter(this.valor, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final g = size.width * 0.13;
    final rect = Rect.fromLTWH(g / 2, g / 2, size.width - g, size.height - g);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = g..color = AppColors.bgCardLight);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * valor, false, Paint()..style = PaintingStyle.stroke..strokeWidth = g..strokeCap = StrokeCap.round..color = color);
  }

  @override
  bool shouldRepaint(covariant _AnilloPainter old) => old.valor != valor || old.color != color;
}

class BarraDato {
  final String etiqueta;
  final num valor;
  final Color? color;
  const BarraDato(this.etiqueta, this.valor, {this.color});
}

/// Barras verticales con el valor encima y la etiqueta debajo
class BarrasVerticales extends StatelessWidget {
  final List<BarraDato> datos;
  final Color color;
  final double alto;

  const BarrasVerticales({super.key, required this.datos, this.color = AppColors.primaryLight, this.alto = 130});

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Sin datos', style: TextStyle(color: AppColors.textGray, fontSize: 12)));
    final maximo = datos.fold<num>(0, (a, b) => a > b.valor ? a : b.valor);
    return SizedBox(
      height: alto + 38,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final d in datos)
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('${d.valor}', style: const TextStyle(fontSize: 11, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: maximo == 0 ? 0 : (d.valor / maximo).toDouble()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Container(
                  width: 22,
                  height: math.max(4, alto * v),
                  decoration: BoxDecoration(
                    color: d.color ?? color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(d.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
            ]),
          ),
      ]),
    );
  }
}

/// Línea con área suave para ver una tendencia (por ejemplo goles por partido)
class LineaTendencia extends StatelessWidget {
  final List<num> valores;
  final List<String> etiquetas;
  final Color color;
  final double alto;

  const LineaTendencia({super.key, required this.valores, this.etiquetas = const [], this.color = AppColors.secondary, this.alto = 120});

  @override
  Widget build(BuildContext context) {
    if (valores.length < 2) return const Padding(padding: EdgeInsets.all(16), child: Text('Se necesitan al menos 2 partidos para ver la tendencia', style: TextStyle(color: AppColors.textGray, fontSize: 12)));
    return Column(children: [
      SizedBox(height: alto, width: double.infinity, child: CustomPaint(painter: _LineaPainter(valores.map((v) => v.toDouble()).toList(), color))),
      if (etiquetas.length == valores.length) ...[
        const SizedBox(height: 6),
        Row(children: [for (final e in etiquetas) Expanded(child: Center(child: Text(e, style: const TextStyle(fontSize: 9.5, color: AppColors.textGray))))]),
      ],
    ]);
  }
}

class _LineaPainter extends CustomPainter {
  final List<double> v;
  final Color color;
  _LineaPainter(this.v, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final maximo = math.max(1.0, v.reduce(math.max));
    const margen = 8.0;
    final ancho = size.width - margen * 2;
    final alto = size.height - margen * 2;
    final puntos = <Offset>[for (var i = 0; i < v.length; i++) Offset(margen + ancho * i / (v.length - 1), margen + alto * (1 - v[i] / maximo))];

    // Guías horizontales
    final guia = Paint()..color = AppColors.bgCardLight..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = margen + alto * i / 2;
      canvas.drawLine(Offset(margen, y), Offset(size.width - margen, y), guia);
    }

    final linea = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (var i = 1; i < puntos.length; i++) {
      final ant = puntos[i - 1];
      final act = puntos[i];
      final medio = (ant.dx + act.dx) / 2;
      linea.cubicTo(medio, ant.dy, medio, act.dy, act.dx, act.dy);
    }
    final area = Path.from(linea)
      ..lineTo(puntos.last.dx, size.height - margen)
      ..lineTo(puntos.first.dx, size.height - margen)
      ..close();
    canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)]).createShader(Offset.zero & size));
    canvas.drawPath(linea, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round..color = color);
    for (final p in puntos) {
      canvas.drawCircle(p, 4, Paint()..color = AppColors.bgCard);
      canvas.drawCircle(p, 4, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LineaPainter old) => old.v != v || old.color != color;
}
