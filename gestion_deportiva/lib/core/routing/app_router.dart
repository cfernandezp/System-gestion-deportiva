import 'dart:async';

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
// E003-HU-002: Inscribirse a Fecha
import '../../features/fechas/presentation/bloc/inscripcion/inscripcion.dart';
// E003-HU-009: Listar Fechas por Rol
import '../../features/fechas/presentation/bloc/fechas_por_rol/fechas_por_rol.dart';
import '../../features/fechas/presentation/pages/fechas_disponibles_page.dart';
import '../../features/fechas/presentation/pages/fecha_detalle_page.dart';
// E003-HU-005: Asignar Equipos
import '../../features/fechas/presentation/bloc/asignaciones/asignaciones.dart';
import '../../features/fechas/presentation/pages/asignar_equipos_page.dart';
// E001-HU-006: Gestionar Solicitudes de Registro
import '../../features/solicitudes/presentation/bloc/solicitudes/solicitudes.dart';
import '../../features/solicitudes/presentation/pages/solicitudes_pendientes_page.dart';
// E004-HU-008: Mi Actividad en Vivo
import '../../features/mi_actividad/presentation/bloc/mi_actividad/mi_actividad_bloc.dart';
import '../../features/mi_actividad/presentation/bloc/mi_actividad/mi_actividad_event.dart';
import '../../features/mi_actividad/presentation/pages/mi_actividad_page.dart';
// E006-HU-001: Ranking de Goleadores
import '../../features/estadisticas/presentation/bloc/ranking_goleadores/ranking_goleadores.dart';
import '../../features/estadisticas/presentation/pages/ranking_goleadores_page.dart';

/// Notificador que escucha cambios en el SessionBloc y notifica al GoRouter
/// Esto resuelve la race condition entre login exitoso y la redireccion
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<SessionState> _subscription;

  GoRouterRefreshStream(Stream<SessionState> stream) {
    _subscription = stream.listen((_) {
      // Notificar al router que debe re-evaluar las redirecciones
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Configuracion del router de la aplicacion
/// Usa go_router para navegacion declarativa
///
/// HU-004: Cierre de Sesion
/// - CA-003: Acceso denegado post-logout -> redirect a /login
/// - RN-003: Redireccion obligatoria post-cierre
/// - RN-005: Proteccion de recursos post-cierre
class AppRouter {
  /// Duracion de la transicion entre paginas (suave e imperceptible)
  static const Duration _transitionDuration = Duration(milliseconds: 200);

  /// Crea una pagina con transicion fade suave
  /// Usado para todas las rutas para mantener consistencia
  static CustomTransitionPage<void> _buildPageWithFadeTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: _transitionDuration,
      reverseTransitionDuration: _transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
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
  // E003-HU-002: Inscribirse a Fecha
  static const String fechasDisponibles = '/fechas';
  static const String fechaDetalle = '/fechas/:id';
  // E003-HU-005: Asignar Equipos (solo admin)
  static const String asignarEquipos = '/fechas/:id/equipos';
  // E001-HU-006: Gestionar Solicitudes de Registro (solo admin)
  static const String adminSolicitudes = '/admin/solicitudes';
  // E004-HU-008: Mi Actividad en Vivo
  static const String miActividad = '/mi-actividad';
  // E006-HU-001: Ranking de Goleadores
  static const String rankingGoleadores = '/ranking-goleadores';

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

  /// Instancia privada del refresh notifier para evitar recreacion
  static GoRouterRefreshStream? _refreshNotifier;

  /// Obtiene o crea el refresh notifier
  static GoRouterRefreshStream _getRefreshNotifier() {
    _refreshNotifier ??= GoRouterRefreshStream(sl<SessionBloc>().stream);
    return _refreshNotifier!;
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    /// refreshListenable: Escucha cambios en SessionBloc y re-evalua redirecciones
    /// Esto resuelve la race condition: cuando SessionBloc cambia a SessionAuthenticated,
    /// el router automaticamente re-evalua y redirige al usuario a home
    refreshListenable: _getRefreshNotifier(),

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
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: const HomePage(),
        ),
      ),

      // Ruta de login de usuario (HU-002)
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),

      // Ruta de registro de usuario (HU-001)
      GoRoute(
        path: '/registro',
        name: 'registro',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: const RegistroPage(),
        ),
      ),

      // Ruta de gestion de usuarios (HU-005: Gestion de Roles)
      // CA-006: Solo administradores (validado en backend)
      GoRoute(
        path: '/admin/usuarios',
        name: 'adminUsuarios',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: const UsuariosPage(),
        ),
      ),

      // HU-003: Recuperacion de contrasena
      // CA-001: Solicitar recuperacion con email
      GoRoute(
        path: '/recuperar-contrasena',
        name: 'recuperarContrasena',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: const SolicitarRecuperacionPage(),
        ),
      ),

      // CA-004, CA-005, CA-006: Restablecer contrasena con token
      GoRoute(
        path: '/restablecer-contrasena/:token',
        name: 'restablecerContrasena',
        pageBuilder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return _buildPageWithFadeTransition(
            key: state.pageKey,
            child: RestablecerContrasenaPage(token: token),
          );
        },
      ),

      // E002-HU-001: Ver Perfil Propio
      // CA-001: Acceso al perfil desde seccion "Mi Perfil"
      GoRoute(
        path: '/perfil',
        name: 'perfil',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => sl<PerfilBloc>()..add(const CargarPerfilEvent()),
            child: const PerfilPage(),
          ),
        ),
      ),

      // E002-HU-003: Lista de Jugadores
      // CA-001: Acceso a lista desde "Jugadores" o "Miembros"
      GoRoute(
        path: '/jugadores',
        name: 'jugadores',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => sl<JugadoresBloc>()..add(const CargarJugadoresEvent()),
            child: const JugadoresPage(),
          ),
        ),
      ),

      // E002-HU-004: Ver Perfil de Otro Jugador
      // CA-001: Acceso desde lista de jugadores
      GoRoute(
        path: '/jugadores/:id',
        name: 'jugadorPerfil',
        pageBuilder: (context, state) {
          final jugadorId = state.pathParameters['id'] ?? '';
          return _buildPageWithFadeTransition(
            key: state.pageKey,
            child: BlocProvider(
              create: (context) => sl<PerfilJugadorBloc>()
                ..add(CargarPerfilJugadorEvent(jugadorId)),
              child: JugadorPerfilPage(jugadorId: jugadorId),
            ),
          );
        },
      ),

      // E003-HU-001: Crear Fecha
      // CA-001: Solo accesible para administradores (validado en backend)
      GoRoute(
        path: '/fechas/crear',
        name: 'crearFecha',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => sl<CrearFechaBloc>(),
            child: const CrearFechaPage(),
          ),
        ),
      ),

      // E003-HU-009: Lista de Fechas por Rol
      // Reemplaza FechasDisponiblesBloc por FechasPorRolBloc
      // para mostrar fechas segun el rol del usuario (jugador/admin)
      GoRoute(
        path: '/fechas',
        name: 'fechasDisponibles',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => sl<FechasPorRolBloc>()
              ..add(const CargarFechasPorRolEvent(seccion: 'proximas')),
            child: const FechasDisponiblesPage(),
          ),
        ),
      ),

      // E003-HU-005: Asignar Equipos
      // CA-001 a CA-008: Asignar jugadores a equipos con drag-drop o selector
      GoRoute(
        path: '/fechas/:id/equipos',
        name: 'asignarEquipos',
        pageBuilder: (context, state) {
          final fechaId = state.pathParameters['id'] ?? '';
          return _buildPageWithFadeTransition(
            key: state.pageKey,
            child: BlocProvider(
              create: (context) => sl<AsignacionesBloc>()
                ..add(CargarAsignacionesEvent(fechaId: fechaId)),
              child: AsignarEquiposPage(fechaId: fechaId),
            ),
          );
        },
      ),

      // E003-HU-002: Detalle de Fecha con inscripcion
      // CA-001 a CA-006: Ver detalle, inscribirse, cancelar, lista inscritos
      GoRoute(
        path: '/fechas/:id',
        name: 'fechaDetalle',
        pageBuilder: (context, state) {
          final fechaId = state.pathParameters['id'] ?? '';
          return _buildPageWithFadeTransition(
            key: state.pageKey,
            child: BlocProvider(
              create: (context) => sl<InscripcionBloc>()
                ..add(CargarFechaDetalleEvent(fechaId: fechaId)),
              child: FechaDetallePage(fechaId: fechaId),
            ),
          );
        },
      ),

      // E001-HU-006: Gestionar Solicitudes de Registro
      // CA-001: Solo administradores (validado en sidebar y backend)
      GoRoute(
        path: '/admin/solicitudes',
        name: 'adminSolicitudes',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => sl<SolicitudesBloc>()
              ..add(const CargarSolicitudesEvent()),
            child: const SolicitudesPendientesPage(),
          ),
        ),
      ),

      // E004-HU-008: Mi Actividad en Vivo
      // CA-003: Pantalla Mi Actividad - Lista de todos los partidos
      // CA-010: Sin pichanga activa - mensaje informativo
      GoRoute(
        path: '/mi-actividad',
        name: 'miActividad',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => sl<MiActividadBloc>()
              ..add(const CargarMiActividadEvent()),
            child: const MiActividadPage(),
          ),
        ),
      ),

      // E006-HU-001: Ranking de Goleadores
      // CA-001 a CA-007: Ranking de goleadores con podio, filtros y destacado
      GoRoute(
        path: '/ranking-goleadores',
        name: 'rankingGoleadores',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => sl<RankingGoleadoresBloc>()
              ..add(const CargarRankingEvent()),
            child: const RankingGoleadoresPage(),
          ),
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
