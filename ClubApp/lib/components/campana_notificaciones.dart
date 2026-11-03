import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/notification_service.dart';

/// Campana con el contador de notificaciones sin leer. Al tocarla abre la lista.
class CampanaNotificaciones extends StatelessWidget {
  final Color color;
  const CampanaNotificaciones({super.key, this.color = AppColors.textWhite});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: NotificationService.noLeidas,
        builder: (context, n, _) => Stack(clipBehavior: Clip.none, children: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: Icon(n > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: color),
            onPressed: NotificationService.abrir,
          ),
          if (n > 0)
            Positioned(
              right: 4,
              top: 4,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.bgDark, width: 1.5)),
                  child: Text(n > 9 ? '9+' : '$n', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, height: 1.1)),
                ),
              ),
            ),
        ]),
      );
}