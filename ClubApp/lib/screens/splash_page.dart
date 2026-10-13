import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  late final Animation<double> _scale =
      Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  /// Restaura la sesión mientras se muestra el splash: con sesión va al inicio, si no, al login
  Future<void> _goNext() async {
    await Future.wait([AuthService.cargarSesion(), Future.delayed(AppDurations.splashDuration)]);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthService.isLoggedIn ? const MainShell() : const LoginPage()),
    );
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
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo1.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('c', style: TextStyle(color: AppColors.textWhite, fontSize: 40, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const Text('ClubApp', style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
                const SizedBox(height: 6),
                const Text('Plataforma deportiva integral', style: TextStyle(fontSize: 25, color: AppColors.textGray)),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
