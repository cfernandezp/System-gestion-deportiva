import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/solicitud_pendiente_model.dart';

/// Interface del repositorio de solicitudes
/// E001-HU-006: Gestionar Solicitudes de Registro
///
/// Criterios de Aceptacion:
/// - CA-001: Acceso exclusivo admin
/// - CA-003: Lista con nombre, email, fecha registro, dias pendiente
/// - CA-004: Ordenar por antiguedad
/// - CA-005: Aprobar con seleccion de rol
/// - CA-006: Rechazar con motivo opcional
abstract class SolicitudesRepository {
  /// Obtiene la lista de usuarios pendientes de aprobacion
  /// CA-003, CA-004
  /// Returns: `Either<Failure, ObtenerUsuariosPendientesResponseModel>`
  Future<Either<Failure, ObtenerUsuariosPendientesResponseModel>>
      obtenerUsuariosPendientes();

  /// Aprueba un usuario pendiente asignandole un rol
  /// CA-005: rol puede ser 'jugador', 'admin', 'arbitro', 'delegado'
  /// Returns: `Either<Failure, AprobarUsuarioResponseModel>`
  Future<Either<Failure, AprobarUsuarioResponseModel>> aprobarUsuario({
    required String usuarioId,
    required String rol,
  });

  /// Rechaza un usuario pendiente con motivo opcional
  /// CA-006: motivo es opcional
  /// Returns: `Either<Failure, RechazarUsuarioResponseModel>`
  Future<Either<Failure, RechazarUsuarioResponseModel>> rechazarUsuario({
    required String usuarioId,
    String? motivo,
  });
}
