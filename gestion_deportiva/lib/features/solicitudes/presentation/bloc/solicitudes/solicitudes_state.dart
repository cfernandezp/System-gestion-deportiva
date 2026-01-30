import 'package:equatable/equatable.dart';

import '../../../data/models/solicitud_pendiente_model.dart';

/// Estados del Bloc de Solicitudes
/// E001-HU-006: Gestionar Solicitudes de Registro
abstract class SolicitudesState extends Equatable {
  const SolicitudesState();

  @override
  List<Object?> get props => [];
}

/// Estado: Inicial (sin cargar)
class SolicitudesInitial extends SolicitudesState {
  const SolicitudesInitial();
}

/// Estado: Cargando lista de solicitudes
class SolicitudesLoading extends SolicitudesState {
  const SolicitudesLoading();
}

/// Estado: Lista de solicitudes cargada exitosamente
/// CA-003: Lista con nombre, email, fecha registro, dias pendiente
class SolicitudesLoaded extends SolicitudesState {
  final List<SolicitudPendienteModel> solicitudes;
  final int total;
  final String? mensajeExito;

  const SolicitudesLoaded({
    required this.solicitudes,
    required this.total,
    this.mensajeExito,
  });

  /// Crea copia con campos modificados
  SolicitudesLoaded copyWith({
    List<SolicitudPendienteModel>? solicitudes,
    int? total,
    String? mensajeExito,
    bool clearMensaje = false,
  }) {
    return SolicitudesLoaded(
      solicitudes: solicitudes ?? this.solicitudes,
      total: total ?? this.total,
      mensajeExito: clearMensaje ? null : (mensajeExito ?? this.mensajeExito),
    );
  }

  @override
  List<Object?> get props => [solicitudes, total, mensajeExito];
}

/// Estado: Procesando accion (aprobar/rechazar) sobre una solicitud
class SolicitudesProcesando extends SolicitudesState {
  final List<SolicitudPendienteModel> solicitudes;
  final int total;
  final String usuarioIdProcesando;
  final String accion; // 'aprobar' o 'rechazar'

  const SolicitudesProcesando({
    required this.solicitudes,
    required this.total,
    required this.usuarioIdProcesando,
    required this.accion,
  });

  @override
  List<Object?> get props => [solicitudes, total, usuarioIdProcesando, accion];
}

/// Tipos de error para la gestion de solicitudes
/// Mapean a hints del backend
enum SolicitudesErrorType {
  /// Sin permisos de administrador
  /// CA-001
  sinPermisos,

  /// Usuario no encontrado
  usuarioNoEncontrado,

  /// Rol especificado no es valido
  rolInvalido,

  /// Error de conexion/servidor
  servidor,
}

/// Estado: Error al cargar o procesar solicitudes
class SolicitudesError extends SolicitudesState {
  final String message;
  final SolicitudesErrorType errorType;
  final String? hint;
  final List<SolicitudPendienteModel>? solicitudesPrevias;
  final int? totalPrevio;

  const SolicitudesError({
    required this.message,
    required this.errorType,
    this.hint,
    this.solicitudesPrevias,
    this.totalPrevio,
  });

  @override
  List<Object?> get props => [
        message,
        errorType,
        hint,
        solicitudesPrevias,
        totalPrevio,
      ];
}
