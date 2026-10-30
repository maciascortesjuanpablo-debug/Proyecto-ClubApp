import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/models.dart';
import 'charts.dart';
import 'ui_kit.dart';

/// Piezas de la ficha de un equipo, usadas por el jugador (consulta) y por el entrenador (gestión).

/// Balance de partidos: dona de resultados y goles a favor y en contra
class BalanceCard extends StatelessWidget {
  final BalanceEquipo balance;
  const BalanceCard(this.balance, {super.key});

  @override
  Widget build(BuildContext context) {
    final b = balance;
    final segmentos = [
      SegmentoDonut('Ganados', b.g, AppColors.success),
      SegmentoDonut('Empatados', b.e, AppColors.warning),
      SegmentoDonut('Perdidos', b.p, AppColors.error),
    ];
    if (b.pj == 0) return const TarjetaBase(child: EstadoVacio(icono: Icons.query_stats, mensaje: 'Aún no hay partidos jugados'));
    return TarjetaBase(
      child: Column(children: [
        Row(children: [
          DonutChart(segmentos: segmentos.where((s) => s.valor > 0).toList(), centro: '${b.pj}', subcentro: 'jugados', tamano: 116),
          const SizedBox(width: 20),
          Expanded(child: LeyendaChart(segmentos)),
        ]),
        const Divider(color: AppColors.bgCardLight, height: 28),
        Row(children: [
          _cifra('${b.gf}', 'Goles a favor', AppColors.success),
          _cifra('${b.gc}', 'Goles en contra', AppColors.error),
          _cifra('${b.gf - b.gc > 0 ? '+' : ''}${b.gf - b.gc}', 'Diferencia', AppColors.secondary),
        ]),
      ]),
    );
  }

  Widget _cifra(String v, String e, Color c) => Expanded(
        child: Column(children: [
          Text(v, style: TextStyle(fontSize: 20, color: c, fontWeight: FontWeight.bold)),
          Text(e, style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
        ]),
      );
}

/// Últimos 5 resultados como fichas G / E / P
class FormaReciente extends StatelessWidget {
  final List<Partido> partidos;
  final Object equipoId;
  const FormaReciente({super.key, required this.partidos, required this.equipoId});

  @override
  Widget build(BuildContext context) {
    final jugados = partidos.where((p) => p.resultadoPara(equipoId) != null).toList().reversed.take(5).toList().reversed;
    if (jugados.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      const Text('Forma  ', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
      for (final p in jugados)
        Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(right: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: switch (p.resultadoPara(equipoId)) { 'G' => AppColors.success, 'P' => AppColors.error, _ => AppColors.warning },
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(p.resultadoPara(equipoId)!, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
        ),
    ]);
  }
}

/// Plantilla de un equipo (solo lectura). Si se pasa [miUsuarioId], se marca la fila de esa persona.
class PlantillaLista extends StatelessWidget {
  final List<JugadorPlantilla> jugadores;
  final Object? miUsuarioId;
  final Widget Function(JugadorPlantilla)? accion;
  const PlantillaLista({super.key, required this.jugadores, this.miUsuarioId, this.accion});

  @override
  Widget build(BuildContext context) {
    if (jugadores.isEmpty) return const TarjetaBase(child: EstadoVacio(icono: Icons.person_add_alt, mensaje: 'La plantilla todavía está vacía'));
    final orden = [...jugadores]..sort((a, b) => (a.dorsal ?? 999).compareTo(b.dorsal ?? 999));
    return Column(children: [
      for (final j in orden)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TarjetaBase(
            padding: const EdgeInsets.all(12),
            color: '${j.usuarioId}' == '$miUsuarioId' ? AppColors.primaryLight.withValues(alpha: 0.18) : null,
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.bgCardLight, shape: BoxShape.circle),
                child: Text(j.dorsal?.toString() ?? '-', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${j.nombreCompleto}${'${j.usuarioId}' == '$miUsuarioId' ? '  (tú)' : ''}', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
                  Text('${j.posicion}${j.esTitular ? ' · Titular' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                ]),
              ),
              if (accion != null) accion!(j),
            ]),
          ),
        ),
    ]);
  }
}

/// Cuerpo técnico
class StaffLista extends StatelessWidget {
  final List<MiembroStaff> staff;
  const StaffLista(this.staff, {super.key});

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      for (final s in staff)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TarjetaBase(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.sports, color: AppColors.orange),
              const SizedBox(width: 12),
              Expanded(child: Text(s.nombre, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
              Text(s.cargo, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            ]),
          ),
        ),
    ]);
  }
}
