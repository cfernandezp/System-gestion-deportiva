import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/registro_page.dart';

/// Configuracion del router de la aplicacion
/// Usa go_router para navegacion declarativa
class AppRouter {
  /// Rutas de la aplicacion
  static const String home = '/';
  static const String login = '/login';
  static const String registro = '/registro';

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Sistema de Gestion Deportiva'),
          ),
        ),
      ),
      // Ruta de login de usuario (HU-002)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      // Ruta de registro de usuario (HU-001)
      GoRoute(
        path: '/registro',
        name: 'registro',
        builder: (context, state) => const RegistroPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Pagina no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Ruta: ${state.uri.path}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
