import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/legal_texts.dart';
import '../core/navigation.dart';
import '../core/validators.dart';
import '../components/app_button.dart';
import '../components/app_header.dart';
import '../components/app_text_field.dart';
import '../components/back_button_widget.dart';
import '../components/form_section.dart';
import '../components/progress_bar.dart';
import '../components/success_dialog.dart';
import '../services/auth_service.dart';
import 'two_factor_page.dart';

class RegisterPage3 extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String correo;
  final String celular;
  final String fechaNacimiento;
  final String ciudad;
  final String posicion;
  final int rolId;
  final String nivelJuego;

  const RegisterPage3({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.celular,
    required this.fechaNacimiento,
    required this.ciudad,
    required this.posicion,
    required this.rolId,
    required this.nivelJuego,
  });

  @override
  State<RegisterPage3> createState() => _RegisterPage3State();
}

class _RegisterPage3State extends State<RegisterPage3> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _cargando = false;
  PasswordStrength _strength = AppValidators.checkPasswordStrength('');

  late final TapGestureRecognizer _tapTerminos;
  late final TapGestureRecognizer _tapPrivacidad;

  @override
  void initState() {
    super.initState();
    _tapTerminos = TapGestureRecognizer()
      ..onTap = () => _mostrarLegal('Términos y condiciones', LegalTexts.terminos);
    _tapPrivacidad = TapGestureRecognizer()
      ..onTap = () => _mostrarLegal('Política de privacidad', LegalTexts.politicaDatos);
  }

  @override
  void dispose() {
    _tapTerminos.dispose();
    _tapPrivacidad.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  // Ventana emergente con el texto legal completo. "Aceptar" marca la casilla.
  Future<void> _mostrarLegal(String titulo, String texto) async {
    final acepto = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(titulo, style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(d).size.height * 0.55,
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Text(texto.trim(), style: const TextStyle(color: AppColors.textGray, fontSize: 13, height: 1.5)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cerrar')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Aceptar', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (acepto == true && mounted) setState(() => _acceptTerms = true);
  }

  // Convierte DD/MM/YYYY (DatePickerField) a yyyy-MM-dd (backend)
  String _formatearFecha(String fecha) {
    final p = fecha.split('/');
    return p.length == 3 ? '${p[2]}-${p[1]}-${p[0]}' : fecha;
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) return _aviso('Debes aceptar los términos y la política de privacidad');

    setState(() => _cargando = true);

    final registro = await AuthService.registrar(
      nombre: widget.nombre,
      apellido: widget.apellido,
      correo: widget.correo,
      numeroCelular: widget.celular,
      fechaNacimiento: _formatearFecha(widget.fechaNacimiento),
      ciudad: widget.ciudad,
      password: _passwordController.text,
      rolId: widget.rolId,
      nivelJuego: widget.nivelJuego,
    );

    if (registro['exito'] != true) {
      if (!mounted) return;
      setState(() => _cargando = false);
      return _aviso(registro['mensaje']);
    }

    final login = await AuthService.iniciarSesion(correo: widget.correo, password: _passwordController.text);

    if (!mounted) return;
    setState(() => _cargando = false);

    // Si el inicio de sesión automático falla, la cuenta ya existe: se manda al login
    if (login['exito'] != true) return irALogin(context);

    final mensaje = 'Bienvenido a ClubApp, ${widget.nombre}';

    // El código llega al correo con el que se registró, así también se confirma que es suyo
    if (login['requiere2fa'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => TwoFactorPage(
            tokenDesafio: login['tokenDesafio'] as String,
            correo: login['correo'] as String,
            titulo: '¡Cuenta Creada!',
            mensaje: mensaje,
            posicionPerfil: widget.posicion,
            desdeRegistro: true,
          ),
        ),
        (_) => false,
      );
      return;
    }

    if (widget.posicion.isNotEmpty) await AuthService.crearPerfilJugador(posicion: widget.posicion);
    if (!mounted) return;
    await SuccessDialog.show(
      context: context,
      title: '¡Cuenta Creada!',
      message: mensaje,
      buttonText: 'Empezar',
      onButtonPressed: () => irAInicio(context),
    );
  }

  Widget get _requirementsCard => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requisitos de contraseña',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _requisito('8 caracteres mínimo', _strength.hasMinChars),
            _requisito('Una mayúscula', _strength.hasUpperCase),
            _requisito('Un número', _strength.hasNumber),
            _requisito('Un carácter especial', _strength.hasSpecialChar),
          ],
        ),
      );

  Widget _requisito(String texto, bool valido) {
    final color = valido ? AppColors.success : AppColors.textGrayDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(valido ? Icons.check_circle : Icons.circle_outlined, size: 18, color: color),
          const SizedBox(width: 10),
          Text(texto, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget get _aceptarTerminos {
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGray);
    final enlace = base?.copyWith(color: AppColors.secondary, decoration: TextDecoration.underline);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          activeColor: AppColors.primaryLight,
          checkColor: AppColors.textWhite,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: base,
                children: [
                  const TextSpan(text: 'Acepto los '),
                  TextSpan(text: 'Términos y condiciones', style: enlace, recognizer: _tapTerminos),
                  const TextSpan(text: ' y autorizo el tratamiento de mis datos según la '),
                  TextSpan(text: 'Política de privacidad', style: enlace, recognizer: _tapPrivacidad),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                BackButtonWidget(onPressed: () => Navigator.pop(context)),
                const SizedBox(height: 16),
                const AppHeader(title: 'ClubApp', subtitle: 'Plataforma deportiva integral', logoAssetPath: 'assets/images/logo1.png', logoSize: 150),
                const SizedBox(height: 20),
                const ProgressBar(value: 1.0, label: 'Paso 3 de 3'),
                const SizedBox(height: 24),
                FormSection(
                  title: 'Seguridad',
                  subtitle: 'Crea una contraseña fuerte',
                  children: [
                    AppTextField(
                      label: 'Contraseña',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: true,
                      showVisibilityToggle: true,
                      validator: AppValidators.validatePassword,
                      onChanged: (v) => setState(() => _strength = AppValidators.checkPasswordStrength(v)),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirmar Contraseña',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      showVisibilityToggle: true,
                      validator: (v) => AppValidators.validateConfirmPassword(v, _passwordController.text),
                    ),
                    const SizedBox(height: 20),
                    _requirementsCard,
                    const SizedBox(height: 20),
                    _aceptarTerminos,
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(label: 'Crear mi cuenta', isLoading: _cargando, onPressed: _register),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}