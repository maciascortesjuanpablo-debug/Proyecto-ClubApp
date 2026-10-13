import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../components/app_button.dart';
import '../components/back_button_widget.dart';
import '../components/icon_badge.dart';
import '../services/auth_service.dart';
import 'new_password_page.dart';

const _espera = 60; // segundos antes de poder pedir otro código

class VerifyCodePage extends StatefulWidget {
  final String email;

  const VerifyCodePage({super.key, required this.email});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focos = List.generate(6, (_) => FocusNode());

  int _segundos = _espera;
  Timer? _timer;
  bool _cargando = false;

  bool get _puedeReenviar => _segundos == 0;

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
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

  /// Escribir avanza al siguiente cuadro, borrar retrocede y pegar el código completo lo reparte
  void _onCodeChanged(String value, int index) {
    if (value.isEmpty) {
      if (index > 0) _focos[index - 1].requestFocus();
      return;
    }
    final digitos = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < digitos.length && index + i < 6; i++) {
      _controllers[index + i].text = digitos[i];
    }
    final ultimo = (index + digitos.length - 1).clamp(0, 5).toInt();
    if (ultimo < 5) {
      _focos[ultimo + 1].requestFocus();
    } else {
      _focos[5].unfocus();
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) return _aviso('Ingresa los 6 dígitos');

    setState(() => _cargando = true);
    final resultado = await AuthService.verificarCodigoRecuperacion(correo: widget.email, codigo: code);
    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => NewPasswordPage(tokenTemporal: resultado['tokenTemporal'])));
    } else {
      _aviso(resultado['mensaje']);
    }
  }

  Future<void> _resendCode() async {
    final resultado = await AuthService.enviarCodigoRecuperacion(correo: widget.email);
    if (!mounted) return;

    if (resultado['exito'] == true) {
      for (final c in _controllers) {
        c.clear();
      }
      _iniciarTimer();
    } else {
      _aviso(resultado['mensaje']);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focos) {
      f.dispose();
    }
    super.dispose();
  }

  InputBorder _borde(Color color, [double ancho = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: ancho));

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              BackButtonWidget(onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 40),
              const IconBadge(icon: Icons.mail_outline, color: AppColors.success, iconColor: AppColors.textWhite),
              const SizedBox(height: 32),
              Text('Revisa tu correo', style: textos.headlineSmall?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Enviamos un código de 6 dígitos a\n${widget.email}',
                  style: textos.bodySmall?.copyWith(color: AppColors.textGray, fontSize: 15), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (i) => SizedBox(
                    width: 50,
                    height: 56,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focos[i],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
                      onChanged: (v) => _onCodeChanged(v, i),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgCard,
                        border: _borde(AppColors.bgCardLight),
                        enabledBorder: _borde(AppColors.bgCardLight),
                        focusedBorder: _borde(AppColors.secondary, 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('¿No recibiste el código?', style: textos.bodySmall?.copyWith(color: AppColors.textGray)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _puedeReenviar ? _resendCode : null,
                child: Text(
                  _puedeReenviar ? 'Reenviar' : 'Reenviar ($_tiempo)',
                  style: TextStyle(color: _puedeReenviar ? AppColors.secondary : AppColors.textGrayDark, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(label: 'Verificar Código', isLoading: _cargando, onPressed: _verifyCode),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text('Por tu seguridad, el código expira\nen 10 minutos',
                        style: textos.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
