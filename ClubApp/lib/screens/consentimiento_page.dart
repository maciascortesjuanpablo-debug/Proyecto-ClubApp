import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/legal_texts.dart';
import '../core/navigation.dart';
import '../components/app_button.dart';
import '../components/date_picker_field.dart';
import '../services/auth_service.dart';

/// Pantalla de autorización: aparece cuando la cuenta no ha aceptado la versión vigente de los términos
/// y la política (cuentas nuevas de Google y cuentas anteriores). Si la cuenta no tiene fecha de nacimiento
/// la pide, y a los menores de 18 años les pide la autorización de su padre, madre o representante.
class ConsentimientoPage extends StatefulWidget {
  /// Qué hacer cuando la persona acepta (normalmente ir al inicio)
  final void Function(BuildContext context) alAceptar;

  const ConsentimientoPage({super.key, required this.alAceptar});

  @override
  State<ConsentimientoPage> createState() => _ConsentimientoPageState();
}

class _ConsentimientoPageState extends State<ConsentimientoPage> {
  final _fecha = TextEditingController();
  late final bool _faltaFecha;
  late final bool _menorConocido;
  bool _acepto = false;
  bool _autorizaAcudiente = false;
  bool _guardando = false;

  late final TapGestureRecognizer _tapTerminos;
  late final TapGestureRecognizer _tapPrivacidad;

  @override
  void initState() {
    super.initState();
    final pendiente = AuthService.consentimientoPendiente ?? const {};
    _faltaFecha = pendiente['falta_fecha_nacimiento'] == true;
    _menorConocido = pendiente['es_menor'] == true;
    _tapTerminos = TapGestureRecognizer()..onTap = () => _leer('Términos y condiciones', LegalTexts.terminos);
    _tapPrivacidad = TapGestureRecognizer()..onTap = () => _leer('Política de privacidad', LegalTexts.politicaDatos);
    _fecha.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tapTerminos.dispose();
    _tapPrivacidad.dispose();
    _fecha.dispose();
    super.dispose();
  }

  // Edad calculada de la fecha escrita (DD/MM/YYYY); null si aún no hay una fecha completa
  int? get _edadEscrita {
    final p = _fecha.text.split('/');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    final hoy = DateTime.now();
    var edad = hoy.year - y;
    if (hoy.month < m || (hoy.month == m && hoy.day < d)) edad--;
    return edad;
  }

  bool get _esMenor => _faltaFecha ? ((_edadEscrita ?? 99) < 18) : _menorConocido;

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _leer(String titulo, String texto) => showDialog<void>(
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
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cerrar'))],
        ),
      );

  String _aIso(String f) {
    final p = f.split('/');
    return p.length == 3 ? '${p[2]}-${p[1]}-${p[0]}' : f;
  }

  Future<void> _continuar() async {
    if (_faltaFecha && _edadEscrita == null) return _aviso('Indica tu fecha de nacimiento');
    if (!_acepto) return _aviso('Debes aceptar los términos y la política de privacidad');
    if (_esMenor && !_autorizaAcudiente) return _aviso('Siendo menor de edad necesitas la autorización de tu padre, madre o representante legal');

    setState(() => _guardando = true);
    final r = await AuthService.aceptarTerminos(
      fechaNacimiento: _faltaFecha ? _aIso(_fecha.text) : null,
      autorizacionAcudiente: _esMenor && _autorizaAcudiente,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    widget.alAceptar(context);
  }

  Future<void> _rechazar() async {
    await AuthService.logout();
    if (mounted) irALogin(context);
  }

  Widget _casilla({required bool valor, required ValueChanged<bool> alCambiar, required Widget texto}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: valor, onChanged: (v) => alCambiar(v ?? false), activeColor: AppColors.primaryLight, checkColor: AppColors.textWhite),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: texto)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGray);
    final enlace = base?.copyWith(color: AppColors.secondary, decoration: TextDecoration.underline);
    return PopScope(
      canPop: false, // no se puede saltar: sin aceptar no se entra
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Antes de continuar', style: TextStyle(fontSize: 22, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Para usar ClubApp necesitamos tu autorización para tratar tus datos personales, como explican nuestros términos y nuestra política de privacidad.',
                  style: TextStyle(fontSize: 14, color: AppColors.textGray, height: 1.4),
                ),
                const SizedBox(height: 24),
                if (_faltaFecha) ...[
                  DatePickerField(
                    label: 'Fecha de nacimiento',
                    hint: 'DD/MM/AAAA',
                    controller: _fecha,
                    lastDate: DateTime.now(),
                    validator: (v) => (v == null || v.isEmpty) ? 'Indica tu fecha de nacimiento' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                _casilla(
                  valor: _acepto,
                  alCambiar: (v) => setState(() => _acepto = v),
                  texto: Text.rich(TextSpan(style: base, children: [
                    const TextSpan(text: 'Acepto los '),
                    TextSpan(text: 'Términos y condiciones', style: enlace, recognizer: _tapTerminos),
                    const TextSpan(text: ' y autorizo el tratamiento de mis datos según la '),
                    TextSpan(text: 'Política de privacidad', style: enlace, recognizer: _tapPrivacidad),
                    const TextSpan(text: '.'),
                  ])),
                ),
                if (_esMenor)
                  _casilla(
                    valor: _autorizaAcudiente,
                    alCambiar: (v) => setState(() => _autorizaAcudiente = v),
                    texto: Text(
                      'Soy menor de 18 años y mi padre, madre o representante legal autoriza mi uso de ClubApp y el tratamiento de mis datos.',
                      style: base,
                    ),
                  ),
                const SizedBox(height: 28),
                AppButton(label: 'Continuar', isLoading: _guardando, onPressed: _continuar),
                Center(
                  child: TextButton(
                    onPressed: _guardando ? null : _rechazar,
                    child: const Text('No acepto, cerrar sesión', style: TextStyle(color: AppColors.textGray)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
