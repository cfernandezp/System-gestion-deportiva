import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/crear_fecha_request_model.dart';
import '../../data/models/crear_fecha_response_model.dart';
import '../../data/models/inscripcion_model.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../../data/models/fecha_disponible_model.dart';
import '../../data/models/editar_fecha_response_model.dart';
import '../../data/models/inscritos_response_model.dart';
import '../../data/models/cerrar_inscripciones_response_model.dart';
import '../../data/models/reabrir_inscripciones_response_model.dart';
import '../../data/models/cancelar_inscripcion_response_model.dart';
import '../../data/models/verificar_cancelar_response_model.dart';
import '../../data/models/obtener_asignaciones_response_model.dart';
import '../../data/models/asignar_equipo_response_model.dart';
import '../../data/models/desasignar_equipo_response_model.dart';
import '../../data/models/confirmar_equipos_response_model.dart';
import '../../data/models/mi_equipo_model.dart';
import '../../data/models/equipos_fecha_model.dart';
import '../../data/models/listar_fechas_por_rol_response_model.dart';
import '../../data/models/finalizar_fecha_response_model.dart';

/// Interface del repositorio de fechas
/// E003-HU-001: Crear Fecha
/// E003-HU-002: Inscribirse a Fecha
/// E003-HU-003: Ver Inscritos
/// E003-HU-004: Cerrar Inscripciones
/// E003-HU-005: Asignar Equipos
/// E003-HU-006: Ver Mi Equipo
/// E003-HU-007: Cancelar Inscripcion
/// E003-HU-008: Editar Fecha
/// E003-HU-009: Listar Fechas por Rol
abstract class FechasRepository {
  /// Crea una nueva fecha de pichanga
  /// CA-001 a CA-007, RN-001 a RN-007
  /// Returns: `Either<Failure, CrearFechaResponseModel>`
  Future<Either<Failure, CrearFechaResponseModel>> crearFecha(
      CrearFechaRequestModel request);

  // ==================== E003-HU-002: Inscribirse a Fecha ====================

  /// Inscribe al usuario actual a una fecha
  /// CA-002, CA-003, RN-001 a RN-004
  /// Returns: `Either<Failure, InscripcionResponseModel>`
  Future<Either<Failure, InscripcionResponseModel>> inscribirseFecha(
      String fechaId);

  /// Cancela la inscripcion del usuario a una fecha
  /// CA-004
  /// Returns: `Either<Failure, CancelarInscripcionResponseModel>`
  Future<Either<Failure, CancelarInscripcionResponseModel>> cancelarInscripcion(
      String fechaId);

  /// Obtiene el detalle de una fecha con sus inscritos
  /// CA-001, CA-004, CA-005, CA-006
  /// Returns: `Either<Failure, FechaDetalleResponseModel>`
  Future<Either<Failure, FechaDetalleResponseModel>> obtenerFechaDetalle(
      String fechaId);

  /// Lista todas las fechas disponibles (abiertas)
  /// RN-002
  /// Returns: `Either<Failure, ListarFechasDisponiblesResponseModel>`
  Future<Either<Failure, ListarFechasDisponiblesResponseModel>>
      listarFechasDisponibles();

  // ==================== E003-HU-007: Cancelar Inscripcion ====================

  /// Verifica si el usuario puede cancelar su inscripcion
  /// CA-001, CA-002, CA-005, RN-001, RN-002
  /// Returns: `Either<Failure, VerificarCancelarRpcResponseModel>`
  Future<Either<Failure, VerificarCancelarRpcResponseModel>>
      verificarPuedeCancelar(String fechaId);

  /// Cancela la inscripcion del usuario a una fecha (version completa)
  /// CA-003, CA-004, CA-007, RN-001 a RN-006
  /// Returns: `Either<Failure, CancelarInscripcionRpcResponseModel>`
  Future<Either<Failure, CancelarInscripcionRpcResponseModel>>
      cancelarInscripcionCompleta(String fechaId);

  /// Cancela la inscripcion de un jugador por parte de un admin
  /// CA-006, RN-002 a RN-006
  /// Returns: `Either<Failure, CancelarInscripcionAdminRpcResponseModel>`
  Future<Either<Failure, CancelarInscripcionAdminRpcResponseModel>>
      cancelarInscripcionAdmin({
    required String inscripcionId,
    required bool anularDeuda,
  });

  // ==================== E003-HU-003: Ver Inscritos ====================

  /// Obtiene la lista de jugadores inscritos a una fecha
  /// CA-001 a CA-006, RN-001 a RN-005
  /// Returns: `Either<Failure, InscritosFechaResponseModel>`
  Future<Either<Failure, InscritosFechaResponseModel>> obtenerInscritosFecha(
      String fechaId);

  // ==================== E003-HU-004: Cerrar Inscripciones ====================

  /// Cierra las inscripciones de una fecha
  /// CA-001 a CA-007, RN-001 a RN-006
  /// Returns: `Either<Failure, CerrarInscripcionesRpcResponseModel>`
  Future<Either<Failure, CerrarInscripcionesRpcResponseModel>>
      cerrarInscripciones(String fechaId);

  /// Reabre las inscripciones de una fecha cerrada
  /// CA-006, RN-001, RN-005, RN-006
  /// Returns: `Either<Failure, ReabrirInscripcionesRpcResponseModel>`
  Future<Either<Failure, ReabrirInscripcionesRpcResponseModel>>
      reabrirInscripciones(String fechaId);

  // ==================== E003-HU-008: Editar Fecha ====================

  /// Edita una fecha de pichanga existente
  /// CA-001 a CA-008, RN-001 a RN-008
  /// Returns: `Either<Failure, EditarFechaRpcResponseModel>`
  Future<Either<Failure, EditarFechaRpcResponseModel>> editarFecha({
    required String fechaId,
    required DateTime fechaHoraInicio,
    required int duracionHoras,
    required String lugar,
  });

  // ==================== E003-HU-005: Asignar Equipos ====================

  /// Obtiene las asignaciones de equipos de una fecha
  /// CA-001, CA-002, CA-003, RN-003, RN-004
  /// Returns: `Either<Failure, ObtenerAsignacionesResponseModel>`
  Future<Either<Failure, ObtenerAsignacionesResponseModel>> obtenerAsignaciones(
      String fechaId);

  /// Asigna un jugador a un equipo
  /// CA-004, CA-005, CA-008, RN-001, RN-002, RN-004, RN-008
  /// Returns: `Either<Failure, AsignarEquipoResponseModel>`
  Future<Either<Failure, AsignarEquipoResponseModel>> asignarEquipo({
    required String fechaId,
    required String usuarioId,
    required String equipo,
  });

  /// Desasigna un jugador de su equipo (lo devuelve a Sin Asignar)
  /// RN-001, RN-002, RN-008
  /// Returns: `Either<Failure, DesasignarEquipoResponseModel>`
  Future<Either<Failure, DesasignarEquipoResponseModel>> desasignarEquipo({
    required String fechaId,
    required String usuarioId,
  });

  /// Confirma las asignaciones de equipos de una fecha
  /// CA-006, CA-007, RN-001, RN-002, RN-005, RN-006, RN-007
  /// Returns: `Either<Failure, ConfirmarEquiposResponseModel>`
  Future<Either<Failure, ConfirmarEquiposResponseModel>> confirmarEquipos(
      String fechaId);

  // ==================== E003-HU-006: Ver Mi Equipo ====================

  /// Obtiene el equipo del usuario actual para una fecha
  /// CA-001, CA-002, CA-003, CA-005, CA-006, RN-001, RN-003
  /// Returns: `Either<Failure, MiEquipoResponseModel>`
  Future<Either<Failure, MiEquipoResponseModel>> obtenerMiEquipo(
      String fechaId);

  /// Obtiene todos los equipos de una fecha con sus jugadores
  /// CA-004, RN-002
  /// Returns: `Either<Failure, EquiposFechaResponseModel>`
  Future<Either<Failure, EquiposFechaResponseModel>> obtenerEquiposFecha(
      String fechaId);

  // ==================== E003-HU-009: Listar Fechas por Rol ====================

  /// Lista fechas filtradas segun el rol del usuario
  /// Jugador: Solo sus fechas inscritas/disponibles
  /// Admin: Todas las fechas con filtros opcionales
  /// Returns: `Either<Failure, ListarFechasPorRolResponseModel>`
  Future<Either<Failure, ListarFechasPorRolResponseModel>> listarFechasPorRol({
    String seccion = 'proximas',
    String? filtroEstado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  // ==================== E003-HU-010: Finalizar Fecha ====================

  /// Finaliza una fecha de pichanga
  /// CA-001 a CA-010, RN-001 a RN-007
  /// Returns: `Either<Failure, FinalizarFechaResponseModel>`
  Future<Either<Failure, FinalizarFechaResponseModel>> finalizarFecha({
    required String fechaId,
    String? comentarios,
    bool huboIncidente,
    String? descripcionIncidente,
  });
}
