import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'session_event.dart';
import 'session_state.dart';

/// Bloc para manejar el estado de sesion global
/// Implementa HU-004: Cierre de Sesion
///
/// Criterios de Aceptacion:
/// - CA-001: Opcion de cerrar sesion visible (LogoutButton usa este Bloc)
/// - CA-002: Cierre de sesion exitoso -> SessionUnauthenticated
/// - CA-003: Acceso denegado post-logout -> SessionUnauthenticated
/// - CA-004: Sesion no persistente -> CheckSession al iniciar app
///
/// Reglas de Negocio:
/// - RN-001: Disponibilidad de opcion de cierre mientras autenticado
/// - RN-002: Invalidacion inmediata de la sesion
/// - RN-003: Redireccion obligatoria post-cierre (manejado en UI)
/// - RN-004: No persistencia de credenciales post-cierre
/// - RN-005: Proteccion de recursos post-cierre
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AuthRepository repository;
  final SupabaseClient supabase;

  SessionBloc({
    required this.repository,
    required this.supabase,
  }) : super(const SessionLoading()) {
    on<CheckSessionEvent>(_onCheckSession);
    on<LogoutEvent>(_onLogout);
    on<SessionAuthenticatedEvent>(_onSessionAuthenticated);
  }

  /// Verifica si hay una sesion activa al iniciar la app
  /// CA-004: Sesion no persistente - verificar al reabrir
  Future<void> _onCheckSession(
    CheckSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    // Verificar si hay usuario autenticado en Supabase Auth
    final currentUser = supabase.auth.currentUser;

    if (currentUser != null) {
      // Hay sesion activa - consultar datos actualizados del usuario
      // desde la tabla usuarios via RPC para obtener el rol correcto
      try {
        final response = await supabase.rpc('obtener_perfil_propio');
        final responseMap = response as Map<String, dynamic>;

        if (responseMap['success'] == true) {
          final data = responseMap['data'] as Map<String, dynamic>;
          emit(SessionAuthenticated(
            usuarioId: data['usuario_id'] ?? currentUser.id,
            nombreCompleto: data['nombre_completo'] ?? '',
            email: data['email'] ?? currentUser.email ?? '',
            rol: data['rol'] ?? 'jugador',
          ));
        } else {
          // Si falla el RPC, usar datos basicos del metadata
          emit(SessionAuthenticated(
            usuarioId: currentUser.id,
            nombreCompleto: currentUser.userMetadata?['nombre_completo'] ?? '',
            email: currentUser.email ?? '',
            rol: currentUser.userMetadata?['rol'] ?? 'jugador',
          ));
        }
      } catch (e) {
        // En caso de error de conexion, usar datos del metadata como fallback
        emit(SessionAuthenticated(
          usuarioId: currentUser.id,
          nombreCompleto: currentUser.userMetadata?['nombre_completo'] ?? '',
          email: currentUser.email ?? '',
          rol: currentUser.userMetadata?['rol'] ?? 'jugador',
        ));
      }
    } else {
      // No hay sesion activa
      emit(const SessionUnauthenticated());
    }
  }

  /// Cierra la sesion del usuario
  /// CA-002: Cierre de sesion exitoso
  /// RN-002: Invalidacion inmediata de la sesion
  /// RN-004: No persistencia de credenciales post-cierre
  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoggingOut());

    final result = await repository.cerrarSesion();

    result.fold(
      (failure) {
        // Si falla el RPC pero queremos asegurar el logout local
        // Intentamos cerrar sesion de Supabase Auth de todas formas
        _forceLocalSignOut();
        emit(SessionError(message: failure.message));
        // Despues del error, marcar como no autenticado
        emit(const SessionUnauthenticated());
      },
      (response) {
        // RN-003: Redireccion obligatoria post-cierre (UI maneja esto)
        emit(const SessionUnauthenticated());
      },
    );
  }

  /// Marca la sesion como autenticada despues de login exitoso
  void _onSessionAuthenticated(
    SessionAuthenticatedEvent event,
    Emitter<SessionState> emit,
  ) {
    emit(SessionAuthenticated(
      usuarioId: event.usuarioId,
      nombreCompleto: event.nombreCompleto,
      email: event.email,
      rol: event.rol,
    ));
  }

  /// Fuerza cierre de sesion local si falla el RPC
  /// RN-004: Asegurar que credenciales no persistan
  Future<void> _forceLocalSignOut() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {
      // Ignorar errores del signOut forzado
    }
  }
}
