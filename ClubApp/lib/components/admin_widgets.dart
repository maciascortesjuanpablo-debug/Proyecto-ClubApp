import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Diálogo de confirmación. Devuelve true si la persona acepta.
Future<bool> confirmar(BuildContext context, {required String titulo, required String mensaje, String accion = 'Confirmar', bool peligro = false}) async =>
    await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(titulo, style: const TextStyle(color: AppColors.textWhite)),
        content: Text(mensaje, style: const TextStyle(color: AppColors.textGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(accion, style: TextStyle(color: peligro ? AppColors.error : AppColors.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ??
    false;

/// Cuerpo común de las pestañas: cargando, error con reintento, vacío y lista con "tirar para actualizar"
class AdminCuerpo extends StatelessWidget {
  final bool cargando;
  final String? error;
  final Future<void> Function() onRefresh;
  final List<Widget> hijos;
  final Widget? encabezado;
  final String vacio;

  const AdminCuerpo({super.key, required this.cargando, required this.error, required this.onRefresh, required this.hijos, this.encabezado, this.vacio = 'Sin resultados'});

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray))),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRefresh, child: const Text('Reintentar')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (encabezado != null) encabezado!,
          if (hijos.isEmpty) Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(vacio, style: const TextStyle(color: AppColors.textGray)))),
          ...hijos,
        ],
      ),
    );
  }
}

/// Tarjeta de una fila de lista (usuario, torneo, equipo, inscripción…)
class AdminTarjeta extends StatelessWidget {
  final Widget? leading;
  final String titulo;
  final String? subtitulo;
  final List<Widget> chips;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdminTarjeta({super.key, this.leading, required this.titulo, this.subtitulo, this.chips = const [], this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                    if (subtitulo != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitulo!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textGray))),
                    if (chips.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 6, runSpacing: 6, children: chips)),
                  ]),
                ),
                if (trailing != null) trailing!,
              ]),
            ),
          ),
        ),
      );
}

/// Fila de chips para filtrar (una sola opción activa). Un valor null significa "Todos".
class FiltroChips<T> extends StatelessWidget {
  final Map<String, T?> opciones;
  final T? valor;
  final ValueChanged<T?> onChanged;

  const FiltroChips({super.key, required this.opciones, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final e in opciones.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(e.key, style: const TextStyle(color: AppColors.textWhite, fontSize: 12)),
                selected: valor == e.value,
                showCheckmark: false,
                selectedColor: AppColors.blue,
                backgroundColor: AppColors.bgCard,
                side: BorderSide.none,
                onSelected: (_) => onChanged(e.value),
              ),
            ),
        ]),
      );
}

/// Gráfico de barras horizontales sencillo (etiqueta, barra, cantidad)
class AdminBarras extends StatelessWidget {
  final String titulo;
  final Map<String, int> datos;

  const AdminBarras({super.key, required this.titulo, required this.datos});

  @override
  Widget build(BuildContext context) {
    final maximo = datos.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (datos.isEmpty) const Text('Sin datos', style: TextStyle(color: AppColors.textGray, fontSize: 12)),
        for (final e in datos.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(width: 100, child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textGray))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: maximo == 0 ? 0 : e.value / maximo, minHeight: 8, color: AppColors.blue, backgroundColor: AppColors.bgCardLight),
                ),
              ),
              SizedBox(width: 36, child: Text('${e.value}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
            ]),
          ),
      ]),
    );
  }
}