import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../core/app_colors.dart';

class ManualPage extends StatefulWidget {
  const ManualPage({super.key});

  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(document: PdfDocument.openAsset('assets/pdf/manual_usuario.pdf'));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Manual de usuario'), backgroundColor: AppColors.bgDark, elevation: 0),
      body: PdfViewPinch(
        controller: _controller,
        onDocumentError: (e) => debugPrint('Error PDF: $e'),
      ),
    );
  }
}