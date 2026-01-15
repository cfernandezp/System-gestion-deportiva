import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/usuario_admin_model.dart';
import '../../../domain/repositories/admin_repository.dart';
import 'usuarios_event.dart';
import 'usuarios_state.dart';

/// Bloc para manejar la gestion de usuarios y roles
/// Implementa HU-005: Gestion de Roles
///
/// Criterios de Aceptacion:
/// - CA-001: Lista de usuarios con rol actual
/// - CA-002: Cambiar rol de usuario
/// - CA-003: Roles disponibles (admin, entrenador, jugador, arbitro)
/// - CA-004: Restriccion de auto-modificacion
/// - CA-005: Busqueda de usuarios
/// - CA-006: Solo administradores
///
/// Reglas de Negocio:
/// - RN-001: Roles validos del sistema
/// - RN-002: Solo admins pueden gestionar roles
/// - RN-003: Proteccion de auto-degradacion
/// - RN-004: Minimo un administrador activo
/// - RN-005: Efecto inmediato del cambio
/// - RN-006: Visibilidad completa de usuarios
/// - RN-007: Busqueda case-insensitive
class UsuariosBloc extends Bloc<UsuariosEvent, UsuariosState> {
  final AdminRepository repository;

  UsuariosBloc({required this.repository}) : super(const UsuariosInitial()) {
    on<CargarUsuariosEvent>(_onCargarUsuarios);
    on<BuscarUsuariosEvent>(_onBuscarUsuarios);
    on<CambiarRolEvent>(_onCambiarRol);
    on<LimpiarMensajeEvent>(_onLimpiarMensaje);
  }

  /// Carga la lista completa de usuarios
  /// CA-001: Lista de usuarios con rol actual
  /// RN-006: Visibilidad completa de usuarios
  Future<void> _onCargarUsuarios(
    CargarUsuariosEvent event,
    Emitter<UsuariosState> emit,
  ) async {
    emit(const UsuariosLoading());

    final result = await repository.listarUsuarios();

    result.fold(
      (failure) {
        final errorInfo = _mapearErrorBackend(failure);
        emit(UsuariosError(
          message: errorInfo.message,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
        ));
      },
      (response) {
        emit(UsuariosLoaded(
          usuarios: response.usuarios,
          total: response.total,
        ));
      },
    );
  }

  /// Busca usuarios por nombre o email
  /// CA-005: Busqueda de usuarios
  /// RN-007: Busqueda case-insensitive
  Future<void> _onBuscarUsuarios(
    BuscarUsuariosEvent event,
    Emitter<UsuariosState> emit,
  ) async {
    emit(const UsuariosLoading());

    final busqueda = event.query.trim().isEmpty ? null : event.query.trim();

    final result = await repository.listarUsuarios(busqueda: busqueda);

    result.fold(
      (failure) {
        final errorInfo = _mapearErrorBackend(failure);
        emit(UsuariosError(
          message: errorInfo.message,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
          busquedaActual: busqueda,
        ));
      },
      (response) {
        emit(UsuariosLoaded(
          usuarios: response.usuarios,
          total: response.total,
          busquedaActual: busqueda,
        ));
      },
    );
  }

  /// Cambia el rol de un usuario
  /// CA-002: Modificar rol
  /// CA-003: Roles disponibles
  /// CA-004: Restriccion de auto-modificacion
  /// RN-001 a RN-005
  Future<void> _onCambiarRol(
    CambiarRolEvent event,
    Emitter<UsuariosState> emit,
  ) async {
    // Guardamos estado actual para restaurar en caso de error
    final estadoActual = state;
    List<UsuarioAdminModel> usuariosActuales = [];
    int totalActual = 0;
    String? busquedaActual;

    if (estadoActual is UsuariosLoaded) {
      usuariosActuales = estadoActual.usuarios;
      totalActual = estadoActual.total;
      busquedaActual = estadoActual.busquedaActual;
    }

    // Emitimos estado de carga parcial
    emit(UsuariosCambiandoRol(
      usuarios: usuariosActuales,
      total: totalActual,
      busquedaActual: busquedaActual,
      usuarioIdCambiando: event.usuarioId,
    ));

    final result = await repository.cambiarRolUsuario(
      usuarioId: event.usuarioId,
      nuevoRol: event.nuevoRol,
    );

    result.fold(
      (failure) {
        final errorInfo = _mapearErrorBackend(failure);
        emit(UsuariosError(
          message: errorInfo.message,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
          usuariosPrevios: usuariosActuales,
          totalPrevio: totalActual,
          busquedaActual: busquedaActual,
        ));
      },
      (response) {
        // RN-005: Efecto inmediato - actualizamos la lista local
        final usuariosActualizados = usuariosActuales.map((usuario) {
          if (usuario.id == event.usuarioId) {
            return usuario.copyWith(rol: event.nuevoRol);
          }
          return usuario;
        }).toList();

        // Mensaje de exito
        String mensajeExito;
        if (response.sinCambios) {
          mensajeExito = 'El usuario ya tenia el rol ${_formatearRol(response.rolNuevo)}';
        } else {
          mensajeExito = 'Rol de ${response.nombreCompleto} cambiado a ${_formatearRol(response.rolNuevo)}';
        }

        emit(UsuariosLoaded(
          usuarios: usuariosActualizados,
          total: totalActual,
          busquedaActual: busquedaActual,
          mensajeExito: mensajeExito,
        ));
      },
    );
  }

  /// Limpia el mensaje de exito
  void _onLimpiarMensaje(
    LimpiarMensajeEvent event,
    Emitter<UsuariosState> emit,
  ) {
    final estadoActual = state;
    if (estadoActual is UsuariosLoaded) {
      emit(estadoActual.copyWith(clearMensaje: true));
    }
  }

  /// Formatea nombre de rol para mostrar
  String _formatearRol(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'entrenador':
        return 'Entrenador';
      case 'jugador':
        return 'Jugador';
      case 'arbitro':
        return 'Arbitro';
      default:
        return rol;
    }
  }

  /// Mapea hints del backend a tipos de error y mensajes amigables
  _UsuariosErrorInfo _mapearErrorBackend(Failure failure) {
    String mensaje = failure.message;
    UsuariosErrorType errorType = UsuariosErrorType.servidor;
    String? hint;

    if (failure is ServerFailure) {
      hint = failure.hint;

      switch (failure.hint) {
        case 'sin_permisos':
          // CA-006, RN-002: No es administrador
          mensaje = 'No tienes permisos para gestionar usuarios. Esta funcion es solo para administradores.';
          errorType = UsuariosErrorType.sinPermisos;
          break;

        case 'auto_degradacion':
          // CA-004, RN-003: Admin intenta quitarse rol
          mensaje = 'No puedes cambiar tu propio rol de administrador.';
          errorType = UsuariosErrorType.autoDegradacion;
          break;

        case 'ultimo_admin':
          // RN-004: Es el unico admin
          mensaje = 'No se puede cambiar el rol del unico administrador del sistema.';
          errorType = UsuariosErrorType.ultimoAdmin;
          break;

        case 'rol_invalido':
          // RN-001: Rol no existe
          mensaje = 'El rol especificado no es valido.';
          errorType = UsuariosErrorType.rolInvalido;
          break;

        case 'usuario_no_encontrado':
          mensaje = 'El usuario no fue encontrado.';
          errorType = UsuariosErrorType.usuarioNoEncontrado;
          break;

        case 'no_autenticado':
          mensaje = 'Debes iniciar sesion para acceder a esta funcion.';
          errorType = UsuariosErrorType.sinPermisos;
          break;

        default:
          mensaje = failure.message;
          errorType = UsuariosErrorType.servidor;
      }
    }

    return _UsuariosErrorInfo(
      message: mensaje,
      errorType: errorType,
      hint: hint,
    );
  }
}

/// Clase auxiliar para mapeo de errores
class _UsuariosErrorInfo {
  final String message;
  final UsuariosErrorType errorType;
  final String? hint;

  _UsuariosErrorInfo({
    required this.message,
    required this.errorType,
    this.hint,
  });
}
