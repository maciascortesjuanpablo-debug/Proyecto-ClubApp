import 'package:ClubApp/components/succes_dialog.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/back_button_widget.dart';
import '../components/progress_bar.dart';
import '../components/form_section.dart';
import '../components/app_text_field.dart';
import '../components/app_button.dart';
import '../services/auth_service.dart';


class RegisterPage3 extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String correo;
  final String celular;
  final String fechaNacimiento;
  final String ciudad;
  final String posicion;

  const RegisterPage3({
    Key? key,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.celular,
    required this.fechaNacimiento,
    required this.ciudad,
    required this.posicion,
  }) : super(key: key);

  @override
  State<RegisterPage3> createState() => _RegisterPage3State();
}

class _RegisterPage3State extends State<RegisterPage3> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _cargando = false;
  PasswordStrength _strength = PasswordStrength(
    hasMinChars: false,
    hasUpperCase: false,
    hasNumber: false,
    hasSpecialChar: false,
  );

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    setState(() => _strength = AppValidators.checkPasswordStrength(password));
  }

  // Convierte DD/MM/YYYY (DatePickerField) a yyyy-MM-dd (backend)
  String _formatearFecha(String fecha) {
    final partes = fecha.split('/');
    if (partes.length != 3) return fecha;
    return '${partes[2]}-${partes[1]}-${partes[0]}';
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    if (!_strength.isStrong) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña no cumple los requisitos')),
      );
      return;
    }

    setState(() => _cargando = true);

    final resultadoRegistro = await AuthService.registrar(
      nombre: widget.nombre,
      apellido: widget.apellido,
      correo: widget.correo,
      numeroCelular: widget.celular,
      fechaNacimiento: _formatearFecha(widget.fechaNacimiento),
      ciudad: widget.ciudad,
      password: _passwordController.text,
    );

    if (!resultadoRegistro['exito']) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultadoRegistro['mensaje'])),
      );
      return;
    }

    final resultadoLogin = await AuthService.iniciarSesion(
      correo: widget.correo,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (!resultadoLogin['exito']) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (widget.posicion.isNotEmpty) {
      AuthService.crearPerfilJugador(posicion: widget.posicion);
    }

    if (!mounted) return;
    await SuccessDialog.show(
      context: context,
      title: '¡Cuenta Creada!',
      message: 'Bienvenido a ClubApp, ${widget.nombre}',
      buttonText: 'Empezar',
      onButtonPressed: () {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
    );
  } 

  Widget get _logo => Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo1.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('c',
                      style: TextStyle(color: AppColors.textWhite, fontSize: 40, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          const Text('ClubApp',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
          const Text('Plataforma deportiva integral',
              style: TextStyle(fontSize: 18, color: AppColors.textGray)),
        ],
      );

  Widget get _passwordFields => Column(
        children: [
          AppTextField(
            label: 'Contraseña',
            hint: '••••••••',
            controller: _passwordController,
            obscureText: true,
            showVisibilityToggle: true,
            validator: AppValidators.validatePassword,
            onChanged: _validatePassword,
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
        ],
      );

  Widget get _requirementsCard => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requisitos de contraseña',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _requisito('8 caracteres mínimo', _strength.hasMinChars),
            const SizedBox(height: 8),
            _requisito('Una mayúscula', _strength.hasUpperCase),
            const SizedBox(height: 8),
            _requisito('Un número', _strength.hasNumber),
            const SizedBox(height: 8),
            _requisito('Un carácter especial', _strength.hasSpecialChar),
          ],
        ),
      );

  Widget _requisito(String texto, bool valido) => Row(
        children: [
          Icon(valido ? Icons.check_circle : Icons.circle_outlined,
              size: 18, color: valido ? AppColors.success : AppColors.textGrayDark),
          const SizedBox(width: 10),
          Text(texto, style: TextStyle(fontSize: 13, color: valido ? AppColors.success : AppColors.textGrayDark)),
        ],
      );

  Widget get _termsCheckbox => Row(
        children: [
          Checkbox(
            value: _acceptTerms,
            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
            activeColor: AppColors.primaryLight,
            checkColor: AppColors.textWhite,
          ),
          Expanded(
            child: Text('Acepto los términos y condiciones',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGray)),
          ),
        ],
      );

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackButtonWidget(onPressed: () => Navigator.pop(context)),
                ),
                const SizedBox(height: 16),
                _logo,
                const SizedBox(height: 20),
                const ProgressBar(value: 1.0, label: 'Paso 3 de 3'),
                const SizedBox(height: 24),
                FormSection(
                  title: 'Seguridad',
                  subtitle: 'Crea una contraseña fuerte',
                  children: [
                    _passwordFields,
                    const SizedBox(height: 20),
                    _requirementsCard,
                    const SizedBox(height: 20),
                    _termsCheckbox,
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: _cargando ? 'Creando cuenta...' : 'Crear mi cuenta',
                  onPressed: _cargando ? () {} : _register,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}