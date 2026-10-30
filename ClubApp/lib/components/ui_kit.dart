import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/resultado.dart';

/// Piezas visuales comunes a las pantallas de todos los roles.

/// Título de sección con acción opcional ("Ver todo")
class SeccionTitulo extends StatelessWidget {
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;
  const SeccionTitulo(this.texto, {super.key, this.accion, this.onAccion});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(children: [
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
          if (accion != null) GestureDetector(onTap: onAccion, child: Text(accion!, style: const TextStyle(fontSize: 12.5, color: AppColors.secondary, fontWeight: FontWeight.w600))),
        ]),
      );
}

/// Contenedor de tarjeta estándar
class TarjetaBase extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  const TarjetaBase({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});

  @override
  Widget build(BuildContext context) => Material(
        color: color ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: padding, child: child)),
      );
}

/// Cifra grande con icono, etiqueta y detalle opcional
class KpiTile extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;
  final String? detalle;
  const KpiTile({super.key, required this.icono, required this.valor, required this.etiqueta, this.color = AppColors.secondary, this.detalle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(valor, style: const TextStyle(fontSize: 24, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
          if (detalle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(detalle!, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
        ]),
      );
}

/// Cuadrícula de 2 columnas para KpiTile (se ajusta sola al alto del contenido)
class KpiGrid extends StatelessWidget {
  final List<Widget> hijos;
  const KpiGrid(this.hijos, {super.key});

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < hijos.length; i += 2) {
      filas.add(Padding(
        padding: EdgeInsets.only(bottom: i + 2 < hijos.length ? 10 : 0),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: hijos[i]),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < hijos.length ? hijos[i + 1] : const SizedBox.shrink()),
          ]),
        ),
      ));
    }
    return Column(children: filas);
  }
}

/// Mensaje de "no hay nada aquí" con icono
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final Widget? accion;
  const EstadoVacio({super.key, required this.icono, required this.mensaje, this.accion});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icono, size: 44, color: AppColors.textGrayDark),
            const SizedBox(height: 10),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray)),
            if (accion != null) ...[const SizedBox(height: 14), accion!],
          ]),
        ),
      );
}

/// Escudo del equipo: logo si lo tiene; si no, sus iniciales
class EquipoAvatar extends StatelessWidget {
  final String nombre;
  final String? logoUrl;
  final double tamano;
  const EquipoAvatar({super.key, required this.nombre, this.logoUrl, this.tamano = 40});

  String get _iniciales {
    final p = nombre.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
    if (p.isEmpty) return '?';
    return p.length == 1 ? p[0].substring(0, p[0].length >= 2 ? 2 : 1).toUpperCase() : (p[0][0] + p[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(color: AppColors.bgCardLight, shape: BoxShape.circle, image: logoUrl != null ? DecorationImage(image: NetworkImage(logoUrl!), fit: BoxFit.cover) : null),
        alignment: Alignment.center,
        child: logoUrl != null ? null : Text(_iniciales, style: TextStyle(fontSize: tamano * 0.34, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
      );
}

/// Carga un Resultado del backend y dibuja la lista de widgets que devuelve [construir].
/// Maneja el indicador de carga, el error con "Reintentar" y "tirar para actualizar".
class CargadorLista<T> extends StatefulWidget {
  final Future<Resultado<T>> Function() cargar;
  final List<Widget> Function(BuildContext context, T dato, Future<void> Function() recargar) construir;
  final EdgeInsetsGeometry padding;
  final Widget? flotante;

  const CargadorLista({super.key, required this.cargar, required this.construir, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 120), this.flotante});

  @override
  State<CargadorLista<T>> createState() => _CargadorListaState<T>();
}

class _CargadorListaState<T> extends State<CargadorLista<T>> {
  T? _dato;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  Future<void> _recargar() async {
    final r = await widget.cargar();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _dato = r.dato;
      _error = r.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null || _dato == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(_error ?? 'No se pudo cargar', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray))),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() => _cargando = true);
              _recargar();
            },
            child: const Text('Reintentar'),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _recargar,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: widget.padding, children: widget.construir(context, _dato as T, _recargar)),
    );
  }
}

/// Saludo y datos de cabecera de las pantallas de inicio
class CabeceraRol extends StatelessWidget {
  final String saludo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  const CabeceraRol({super.key, required this.saludo, required this.subtitulo, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.35), AppColors.bgCard], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(icono, color: color, size: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(saludo, style: const TextStyle(fontSize: 19, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitulo, style: const TextStyle(fontSize: 12.5, color: AppColors.textGray)),
            ]),
          ),
        ]),
      );
}
