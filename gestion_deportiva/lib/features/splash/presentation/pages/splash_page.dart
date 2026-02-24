import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla splash que muestra el logo de ChocoApp
/// al abrir la aplicacion, antes de navegar a login o seleccion de grupo.
/// Se muestra 2 segundos solo la primera vez y luego navega a / donde el
/// redirect del router decide el destino final.
/// Si ya se mostro antes (ej: usuario navega a /splash de nuevo), redirige
/// inmediatamente sin delay.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Flag estatico: la splash solo se muestra con animacion una vez por sesion.
  /// Si el usuario vuelve a navegar a /splash, se salta inmediatamente.
  static bool _shown = false;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // Si la splash ya se mostro, navegar inmediatamente sin delay
    if (SplashPage._shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
      _controller = AnimationController(
        duration: Duration.zero,
        vsync: this,
      );
      _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
      return;
    }

    // Primera vez: mostrar splash con animacion
    SplashPage._shown = true;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Image.asset(
              'assets/images/splash_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
