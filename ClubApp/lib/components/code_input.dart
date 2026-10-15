import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';

/// Seis casillas para un código numérico. Avanza al escribir, retrocede al borrar y reparte el código al pegarlo.
/// Para vaciarlas, cambia su `key`.
class CodeInput extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const CodeInput({super.key, required this.onChanged});

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focos = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focos) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {

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
    } else if (index > 0) {
      _focos[index - 1].requestFocus();
    }
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  InputBorder _borde(Color color, [double ancho = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: ancho));

  @override
  Widget build(BuildContext context) => Row(
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
              onChanged: (v) => _onChanged(v, i),
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
      );
}