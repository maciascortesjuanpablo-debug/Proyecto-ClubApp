import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'admin_equipos_tab.dart';
import 'admin_inscripciones_tab.dart';
import 'admin_resumen_tab.dart';
import 'admin_torneos_tab.dart';
import 'admin_usuarios_tab.dart';

/// Panel de administración. Solo para el rol Administrador (el backend lo vuelve a verificar en cada petición).
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (AuthService.usuario?['rol_id'] != 6) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0),
        body: const Center(child: Text('Esta sección es solo para administradores', style: TextStyle(color: AppColors.textGray))),
      );
    }
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          title: const Text('Panel de administración'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.secondary,
            labelColor: AppColors.textWhite,
            unselectedLabelColor: AppColors.textGray,
            tabs: [Tab(text: 'Resumen'), Tab(text: 'Usuarios'), Tab(text: 'Torneos'), Tab(text: 'Equipos'), Tab(text: 'Inscripciones')],
          ),
        ),
        body: const TabBarView(children: [AdminResumenTab(), AdminUsuariosTab(), AdminTorneosTab(), AdminEquiposTab(), AdminInscripcionesTab()]),
      ),
    );
  }
}