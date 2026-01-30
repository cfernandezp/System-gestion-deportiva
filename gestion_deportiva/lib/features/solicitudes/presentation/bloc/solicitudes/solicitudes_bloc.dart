import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/solicitud_pendiente_model.dart';
import '../../../domain/repositories/solicitudes_repository.dart';
import 'solicitudes_event.dart';
import 'solicitudes_state.dart';

/// Bloc para manejar la gestion de solicitudes de registro
/// Implementa E001-HU-006: Gestionar Solicitudes de Registro
///
/// Criterios de Aceptacion:
/// - CA-001: Acceso exclusivo admin (verificar rol)
/// - CA-002: Badge con contador de pendientes en menu
/// - CA-003: Lista con nombre, email, fecha registro, dias pendiente
/// - CA-004: Ordenar por antiguedad (mas antiguas primero)
/// - CA-005: Aprobar con seleccion de rol (default "Jugador")
/// - CA-006: Rechazar con motivo opcional
/// - CA-007: Estado vacio con mensaje e icono
/// - CA-008: Dialogos de confirmacion
/// - CA-009: SnackBar de feedback
class SolicitudesBloc extends Bloc<SolicitudesEvent, SolicitudesState> {
  final SolicitudesRepository repository;

  SolicitudesBloc({required this.repository})
      : super(const SolicitudesInitial()) {
    on<CargarSolicitudesEvent>(_onCargarSolicitudes);
    on<AprobarSolicitudEvent>(_onAprobarSolicitud);
    on<RechazarSolicitudEvent>(_onRechazarSolicitud);
    on<LimpiarMensajeSolicitudesEvent>(_onLimpiarMensaje);
  }

  /// Carga la lista de solicitudes pendientes
  /// CA-003, CA-004: Lista con datos ordenada por antiguedad
  Future<void> _onCargarSolicitudes(
    CargarSolicitudesEvent event,
    Emitter<SolicitudesState> emit,
  ) async {
    emit(const SolicitudesLoading());

    final result = await repository.obtenerUsuariosPendientes();

    result.fold(
      (failure) {
        final errorInfo = _mapearErrorBackend(failure);
        emit(SolicitudesError(
          message: errorInfo.message,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
        ));
      },
      (response) {
        emit(SolicitudesLoaded(
          solicitudes: response.usuarios,
          total: response.total,
        ));
      },
    );
  }

  /// Aprueba una solicitud de usuario
  /// CA-005: Aprobar con seleccion de rol
  Future<void> _onAprobarSolicitud(
    AprobarSolicitudEvent event,
    Emitter<SolicitudesState> emit,
  ) async {
    // Guardamos estado actual
    final estadoActual = state;
    List<SolicitudPendienteModel> solicitudesActuales = [];
    int totalActual = 0;

    if (estadoActual is SolicitudesLoaded) {
      solicitudesActuales = estadoActual.solicitudes;
      totalActual = estadoActual.total;
    }

    // Emitimos estado de procesamiento
    emit(SolicitudesProcesando(
      solicitudes: solicitudesActuales,
      total: totalActual,
      usuarioIdProcesando: event.usuarioId,
      accion: 'aprobar',
    ));

    final result = await repository.aprobarUsuario(
      usuarioId: event.usuarioId,
      rol: event.rol,
    );

    result.fold(
      (failure) {
        final errorInfo = _mapearErrorBackend(failure);
        emit(SolicitudesError(
          message: errorInfo.message,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
          solicitudesPrevias: solicitudesActuales,
          totalPrevio: totalActual,
        ));
      },
      (response) {
        // Removemos la solicitud de la lista local
        final solicitudesActualizadas = solicitudesActuales
            .where((s) => s.id != event.usuarioId)
            .toList();

        final rolFormateado = _formatearRol(event.rol);
        final mensajeExito =
            '${event.nombreUsuario} ha sido aprobado como $rolFormateado';

        emit(SolicitudesLoaded(
          solicitudes: solicitudesActualizadas,
          total: solicitudesActualizadas.length,
          mensajeExito: mensajeExito,
        ));
      },
    );
  }

  /// Rechaza una solicitud de usuario
  /// CA-006: Rechazar con motivo opcional
  Future<void> _onRechazarSolicitud(
    RechazarSolicitudEvent event,
    Emitter<SolicitudesState> emit,
  ) async {
    // Guardamos estado actual
    final estadoActual = state;
    List<SolicitudPendienteModel> solicitudesActuales = [];
    int totalActual = 0;

    if (estadoActual is SolicitudesLoaded) {
      solicitudesActuales = estadoActual.solicitudes;
      totalActual = estadoActual.total;
    }

    // Emitimos estado de procesamiento
    emit(SolicitudesProcesando(
      solicitudes: solicitudesActuales,
      total: totalActual,
      usuarioIdProcesando: event.usuarioId,
      accion: 'rechazar',
    ));

    final result = await repository.rechazarUsuario(
      usuarioId: event.usuarioId,
      motivo: event.motivo,
    );

    result.fold(
      (failure) {
        final errorInfo = _mapearErrorBackend(failure);
        emit(SolicitudesError(
          message: errorInfo.message,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
          solicitudesPrevias: solicitudesActuales,
          totalPrevio: totalActual,
        ));
      },
      (response) {
        // Removemos la solicitud de la lista local
        final solicitudesActualizadas = solicitudesActuales
            .where((s) => s.id != event.usuarioId)
            .toList();

        final mensajeExito =
            'La solicitud de ${event.nombreUsuario} ha sido rechazada';

        emit(SolicitudesLoaded(
          solicitudes: solicitudesActualizadas,
          total: solicitudesActualizadas.length,
          mensajeExito: mensajeExito,
        ));
      },
    );
  }

  /// Limpia el mensaje de exito
  void _onLimpiarMensaje(
    LimpiarMensajeSolicitudesEvent event,
    Emitter<SolicitudesState> emit,
  ) {
    final estadoActual = state;
    if (estadoActual is SolicitudesLoaded) {
      emit(estadoActual.copyWith(clearMensaje: true));
    }
  }

  /// Formatea nombre de rol para mostrar
  String _formatearRol(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'jugador':
        return 'Jugador';
      case 'arbitro':
        return 'Arbitro';
      case 'delegado':
        return 'Delegado';
      default:
        return rol;
    }
  }

  /// Mapea hints del backend a tipos de error y mensajes amigables
  _SolicitudesErrorInfo _mapearErrorBackend(Failure failure) {
    String mensaje = failure.message;
    SolicitudesErrorType errorType = SolicitudesErrorType.servidor;
    String? hint;

    if (failure is ServerFailure) {
      hint = failure.hint;

      switch (failure.hint) {
        case 'sin_permisos':
        case 'no_admin':
          // CA-001: No es administrador
          mensaje =
              'No tienes permisos para gestionar solicitudes. Esta funcion es solo para administradores.';
          errorType = SolicitudesErrorType.sinPermisos;
          break;

        case 'usuario_no_encontrado':
          mensaje = 'El usuario no fue encontrado o ya fue procesado.';
          errorType = SolicitudesErrorType.usuarioNoEncontrado;
          break;

        case 'rol_invalido':
          mensaje = 'El rol especificado no es valido.';
          errorType = SolicitudesErrorType.rolInvalido;
          break;

        case 'no_autenticado':
          mensaje = 'Debes iniciar sesion para acceder a esta funcion.';
          errorType = SolicitudesErrorType.sinPermisos;
          break;

        default:
          mensaje = failure.message;
          errorType = SolicitudesErrorType.servidor;
      }
    }

    return _SolicitudesErrorInfo(
      message: mensaje,
      errorType: errorType,
      hint: hint,
    );
  }
}

/// Clase auxiliar para mapeo de errores
class _SolicitudesErrorInfo {
  final String message;
  final SolicitudesErrorType errorType;
  final String? hint;

  _SolicitudesErrorInfo({
    required this.message,
    required this.errorType,
    this.hint,
  });
}
