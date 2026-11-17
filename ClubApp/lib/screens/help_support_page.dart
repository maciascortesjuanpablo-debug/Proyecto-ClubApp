
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import 'manual_page.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {

  static const _correo = 'clubapp03@gmail.com.com';
  static const _telefono = '+573228583103';
  static const _whatsapp = '573228583103';
  static const _horario = 'Lunes a viernes, 8:00 a.m. - 6:00 p.m.';

  bool _abriendoManual = false;

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _abrir(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _aviso('No se pudo abrir la aplicación');
  }

  Future<void> _abrirManual() async {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualPage()));
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Ayuda y soporte'), backgroundColor: AppColors.bgDark, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _titulo('Manual de usuario'),
          _item(
            Icons.picture_as_pdf_outlined,
            'Ver manual de usuario',
            'Guía completa de uso de la aplicación (PDF)',
            _abriendoManual ? null : _abrirManual,
            cargando: _abriendoManual,
          ),
          const SizedBox(height: 24),
          _titulo('Contacto'),
          _item(Icons.email_outlined, 'Correo', _correo, () => _abrir(Uri(scheme: 'mailto', path: _correo, query: 'subject=Soporte ClubApp'))),
          _item(Icons.phone_outlined, 'Teléfono', _telefono, () => _abrir(Uri(scheme: 'tel', path: _telefono))),
          _item(Icons.chat_outlined, 'WhatsApp', 'Escríbenos por chat', () => _abrir(Uri.parse('https://wa.me/$_whatsapp'))),
          const SizedBox(height: 24),
          _titulo('Horario de atención'),
          _item(Icons.schedule, 'Horario', _horario, null),
        ],
      ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
      );

  Widget _item(IconData icono, String titulo, String subtitulo, VoidCallback? onTap, {bool cargando = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(icono, color: AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titulo, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: const TextStyle(color: AppColors.textGray, fontSize: 13)),
                  ]),
                ),
                if (cargando)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                else if (onTap != null)
                  const Icon(Icons.chevron_right, color: AppColors.textGray),
              ]),
            ),
          ),
        ),
      );
}