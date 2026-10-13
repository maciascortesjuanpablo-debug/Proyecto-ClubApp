import 'package:clubapp/components/app_button.dart';
import 'package:clubapp/core/app_colors.dart';
import 'package:flutter/material.dart';


class LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const LoadError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          const Icon(Icons.wifi_off, color: AppColors.textGray, size: 48),
          const SizedBox(height: 12),
          const Text('No se pudo cargar la información', style: TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 16),
          AppButton(label: 'Reintentar', onPressed: onRetry),
        ]),
      );
}