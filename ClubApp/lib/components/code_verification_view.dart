import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'app_button.dart';
import 'back_button_widget.dart';
import 'code_input.dart';
import 'icon_badge.dart';

/// Pantalla "ingresa el código de 6 dígitos" con reenvío y cuenta regresiva.
/// onVerify y onResend devuelven null si todo salió bien, o el mensaje de error a mostrar.
class CodeVerificationView extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String nota;
  final VoidCallback onBack;
  final Future<String?> Function(String codigo) onVerify;
  final Future<String?> Function() onResend;

  const CodeVerificationView({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.nota,
    required this.onBack,
    required this.onVerify,
    required this.onResend,

  });

  @override
  State<CodeVerificationView> createState() => _CodeVerificationViewState();
}

class _CodeVerificationViewState extends State<CodeVerificationView> {
  static const _espera = 60; // segundos antes de poder pedir otro código

  int _segundos = _espera;
  Timer? _timer;
  bool _cargando = false;
  String _codigo = '';
  int _reinicio = 0; // al cambiar, las casillas se vacían

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _segundos = _espera;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();

      setState(() => _segundos--);
      if (_segundos == 0) t.cancel();
    });
  }

  String get _tiempo => '${(_segundos ~/ 60).toString().padLeft(2, '0')}:${(_segundos % 60).toString().padLeft(2, '0')}';

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _verificar() async {
    if (_codigo.length != 6) return _aviso('Ingresa los 6 dígitos');
    setState(() => _cargando = true);
    final error = await widget.onVerify(_codigo);
    if (!mounted) return;
    setState(() => _cargando = false);
    if (error != null) _aviso(error);
  }

  Future<void> _reenviar() async {
    final error = await widget.onResend();
    if (!mounted) return;
    if (error != null) return _aviso(error);
    setState(() {
      _codigo = '';
      _reinicio++;
    });
    _iniciarTimer();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    final puedeReenviar = _segundos == 0;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(children: [
            BackButtonWidget(onPressed: widget.onBack),
            const SizedBox(height: 40),
            IconBadge(icon: widget.icon, color: widget.color, iconColor: AppColors.textWhite),
            const SizedBox(height: 32),
            Text(widget.title, textAlign: TextAlign.center, style: textos.headlineSmall?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(widget.subtitle, style: textos.bodySmall?.copyWith(color: AppColors.textGray, fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            CodeInput(key: ValueKey(_reinicio), onChanged: (c) => _codigo = c),
            const SizedBox(height: 32),
            Text('¿No recibiste el código?', style: textos.bodySmall?.copyWith(color: AppColors.textGray)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: puedeReenviar ? _reenviar : null,
              child: Text(
                puedeReenviar ? 'Reenviar' : 'Reenviar ($_tiempo)',
                style: TextStyle(color: puedeReenviar ? AppColors.secondary : AppColors.textGrayDark, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(label: widget.buttonLabel, isLoading: _cargando, onPressed: _verificar),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(

                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text(widget.nota, style: textos.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}