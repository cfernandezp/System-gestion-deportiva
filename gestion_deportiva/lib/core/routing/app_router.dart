import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../../features/admin/presentation/pages/usuarios_page.dart';
import '../../features/auth/presentation/bloc/session/session.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/registro_page.dart';
import '../../features/auth/presentation/pages/solicitar_recuperacion_page.dart';
import '../../features/auth/presentation/pages/restablecer_contrasena_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
// E002-HU-001: Ver Perfil Propio
import '../../features/profile/presentation/bloc/perfil/perfil.dart';
import '../../features/profile/presentation/pages/perfil_page.dart';
// E002-HU-003: Lista de Jugadores
import '../../features/jugadores/presentation/bloc/jugadores/jugadores.dart';
import '../../features/jugadores/presentation/pages/jugadores_page.dart';
// E002-HU-004: Ver Perfil de Otro Jugador
import '../../features/jugadores/presentation/bloc/perfil_jugador/perfil_jugador.dart';
import '../../features/jugadores/presentation/pages/jugador_perfil_page.dart';
// E003-HU-001: Crear Fecha
import '../../features/fechas/presentation/bloc/crear_fecha/crear_fecha.dart';
import '../../features/fechas/presentation/pages/crear_fecha_page.dart';

/// Configuracion del router de la aplicacion
/// Usa go_router para navegacion declarativa
///
/// HU-004: Cierre de Sesion
/// - CA-003: Acceso denegado post-logout -> redirect a /login
/// - RN-003: Redireccion obligatoria post-cierre
/// - RN-005: Proteccion de recursos post-cierre
class AppRouter {
  /// Rutas de la aplicacion
  static const String home = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String adminUsuarios = '/admin/usuarios';
  // HU-003: Recuperacion de contrasena
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String restablecerContrasena = '/restablecer-contrasena';
  // E002-HU-001: Ver Perfil Propio
  static const String perfil = '/perfil';
  // E002-HU-003: Lista de Jugadores
  static const String jugadores = '/jugadores';
  // E002-HU-004: Ver Perfil de Otro Jugador
  static const String jugadorPerfil = '/jugadores/:id';
  // E003-HU-001: Crear Fecha (solo admin)
  static const String crearFecha = '/fechas/crear';

  /// Rutas publicas (no requieren autenticacion)
  static const List<String> _publicRoutes = [
    login,
    registro,
    recuperarContrasena,
    '/restablecer-contrasena', // Incluye parametro :token
  ];

  /// Verifica si una ruta es publica
  static bool _isPublicRoute(String path) {
    return _publicRoutes.any((route) {
      // Manejar rutas con parametros
      if (route.contains(':')) {
        final baseRoute = route.split('/:').first;
        return path.startsWith(baseRoute);
      }
      return path == route;
    });
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    /// HU-004: CA-003 - Acceso denegado post-logout
    /// RN-005: Proteccion de recursos post-cierre
    /// Guard de autenticacion global
    redirect: (context, state) {
      final sessionBloc = sl<SessionBloc>();
      final sessionState = sessionBloc.state;
      final currentPath = state.uri.path;

      // Verificar si es ruta publica
      final isPublicRoute = _isPublicRoute(currentPath);

      // Si estamos verificando sesion (loading), permitir navegacion
      if (sessionState is SessionLoading) {
        return null;
      }

      // Verificar si el usuario esta autenticado
      final isAuthenticated = sessionState is SessionAuthenticated;

      // CA-003, RN-005: Si NO esta autenticado y trata de acceder a ruta protegida
      if (!isAuthenticated && !isPublicRoute) {
        return login;
      }

      // Si esta autenticado y trata de acceder a login/registro, ir a home
      if (isAuthenticated && (currentPath == login || currentPath == registro)) {
        return home;
      }

      // Permitir navegacion normal
      return null;
    },

    routes: [
      // Ruta home (protegida) - HU-004
      // CA-001: LogoutButton visible en AppBar
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
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

      // Ruta de gestion de usuarios (HU-005: Gestion de Roles)
      // CA-006: Solo administradores (validado en backend)
      GoRoute(
        path: '/admin/usuarios',
        name: 'adminUsuarios',
        builder: (context, state) => const UsuariosPage(),
      ),

      // HU-003: Recuperacion de contrasena
      // CA-001: Solicitar recuperacion con email
      GoRoute(
        path: '/recuperar-contrasena',
        name: 'recuperarContrasena',
        builder: (context, state) => const SolicitarRecuperacionPage(),
      ),

      // CA-004, CA-005, CA-006: Restablecer contrasena con token
      GoRoute(
        path: '/restablecer-contrasena/:token',
        name: 'restablecerContrasena',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return RestablecerContrasenaPage(token: token);
        },
      ),

      // E002-HU-001: Ver Perfil Propio
      // CA-001: Acceso al perfil desde seccion "Mi Perfil"
      GoRoute(
        path: '/perfil',
        name: 'perfil',
        builder: (context, state) => BlocProvider(
          create: (context) => sl<PerfilBloc>()..add(const CargarPerfilEvent()),
          child: const PerfilPage(),
        ),
      ),

      // E002-HU-003: Lista de Jugadores
      // CA-001: Acceso a lista desde "Jugadores" o "Miembros"
      GoRoute(
        path: '/jugadores',
        name: 'jugadores',
        builder: (context, state) => BlocProvider(
          create: (context) => sl<JugadoresBloc>()..add(const CargarJugadoresEvent()),
          child: const JugadoresPage(),
        ),
      ),

      // E002-HU-004: Ver Perfil de Otro Jugador
      // CA-001: Acceso desde lista de jugadores
      GoRoute(
        path: '/jugadores/:id',
        name: 'jugadorPerfil',
        builder: (context, state) {
          final jugadorId = state.pathParameters['id'] ?? '';
          return BlocProvider(
            create: (context) => sl<PerfilJugadorBloc>()
              ..add(CargarPerfilJugadorEvent(jugadorId)),
            child: JugadorPerfilPage(jugadorId: jugadorId),
          );
        },
      ),

      // E003-HU-001: Crear Fecha
      // CA-001: Solo accesible para administradores (validado en backend)
      GoRoute(
        path: '/fechas/crear',
        name: 'crearFecha',
        builder: (context, state) => BlocProvider(
          create: (context) => sl<CrearFechaBloc>(),
          child: const CrearFechaPage(),
        ),
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
            Text('Ruta: \${state.uri.path}'),
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
