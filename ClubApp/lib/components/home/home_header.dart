import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final bool logueado;
  final String nombre;
  final int noLeidas;
  final VoidCallback onLogin;
  final VoidCallback onBuscar;
  final VoidCallback onNotificaciones;

  const HomeHeader({
    super.key,
    required this.logueado,
    required this.nombre,
    this.noLeidas = 0,
    required this.onLogin,
    required this.onBuscar,
    required this.onNotificaciones,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(children: [
            const CircleAvatar(radius: 20, backgroundColor: AppColors.textWhite, child: Icon(Icons.person, color: AppColors.bgDark)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(logueado ? 'Bienvenido de vuelta,' : 'Bienvenido,',

                    style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w500)),
                Text(logueado && nombre.isNotEmpty ? nombre : 'Invitado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              ]),
            ),
            logueado ? _iconos : _botonIngresar,
          ]),
        ),
      );

  Widget get _iconos => Row(children: [
        IconButton(icon: const Icon(Icons.search, color: AppColors.textWhite), onPressed: onBuscar),
        Stack(children: [
          IconButton(icon: const Icon(Icons.notifications_none, color: AppColors.textWhite), onPressed: onNotificaciones),
          if (noLeidas > 0)
            Positioned(
              right: 12,
              top: 12,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.textWhite, shape: BoxShape.circle)),
            ),
        ]),
      ]);

  Widget get _botonIngresar => OutlinedButton(
        onPressed: onLogin,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.secondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Iniciar sesión', style: TextStyle(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w600)),

      );
}