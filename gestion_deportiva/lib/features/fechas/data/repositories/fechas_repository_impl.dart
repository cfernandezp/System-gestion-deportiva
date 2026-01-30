import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/fechas_repository.dart';
import '../datasources/fechas_remote_datasource.dart';
import '../models/crear_fecha_request_model.dart';
import '../models/crear_fecha_response_model.dart';
import '../models/inscripcion_model.dart';
import '../models/fecha_detalle_model.dart';
import '../models/fecha_disponible_model.dart';
import '../models/editar_fecha_response_model.dart';
import '../models/inscritos_response_model.dart';
import '../models/cerrar_inscripciones_response_model.dart';
import '../models/reabrir_inscripciones_response_model.dart';
import '../models/cancelar_inscripcion_response_model.dart';
import '../models/verificar_cancelar_response_model.dart';
import '../models/obtener_asignaciones_response_model.dart';
import '../models/asignar_equipo_response_model.dart';
import '../models/confirmar_equipos_response_model.dart';
import '../models/mi_equipo_model.dart';
import '../models/equipos_fecha_model.dart';
import '../models/listar_fechas_por_rol_response_model.dart';
import '../models/finalizar_fecha_response_model.dart';

/// Implementacion del repositorio de fechas
/// E003-HU-001: Crear Fecha
/// E003-HU-002: Inscribirse a Fecha
/// E003-HU-003: Ver Inscritos
/// E003-HU-004: Cerrar Inscripciones
/// E003-HU-005: Asignar Equipos
/// E003-HU-006: Ver Mi Equipo
/// E003-HU-007: Cancelar Inscripcion
/// E003-HU-008: Editar Fecha
/// E003-HU-009: Listar Fechas por Rol
class FechasRepositoryImpl implements FechasRepository {
  final FechasRemoteDataSource remoteDataSource;

  FechasRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CrearFechaResponseModel>> crearFecha(
      CrearFechaRequestModel request) async {
    try {
      final result = await remoteDataSource.crearFecha(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado: ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-002: Inscribirse a Fecha ====================

  @override
  Future<Either<Failure, InscripcionResponseModel>> inscribirseFecha(
      String fechaId) async {
    try {
      final result = await remoteDataSource.inscribirseFecha(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al inscribirse: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, CancelarInscripcionResponseModel>> cancelarInscripcion(
      String fechaId) async {
    try {
      final result = await remoteDataSource.cancelarInscripcion(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al cancelar: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, FechaDetalleResponseModel>> obtenerFechaDetalle(
      String fechaId) async {
    try {
      final result = await remoteDataSource.obtenerFechaDetalle(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener detalle: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, ListarFechasDisponiblesResponseModel>>
      listarFechasDisponibles() async {
    try {
      final result = await remoteDataSource.listarFechasDisponibles();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al listar fechas: ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-007: Cancelar Inscripcion ====================

  @override
  Future<Either<Failure, VerificarCancelarRpcResponseModel>>
      verificarPuedeCancelar(String fechaId) async {
    try {
      final result = await remoteDataSource.verificarPuedeCancelar(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al verificar cancelacion: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, CancelarInscripcionRpcResponseModel>>
      cancelarInscripcionCompleta(String fechaId) async {
    try {
      final result =
          await remoteDataSource.cancelarInscripcionCompleta(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al cancelar inscripcion: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, CancelarInscripcionAdminRpcResponseModel>>
      cancelarInscripcionAdmin({
    required String inscripcionId,
    required bool anularDeuda,
  }) async {
    try {
      final result = await remoteDataSource.cancelarInscripcionAdmin(
        inscripcionId: inscripcionId,
        anularDeuda: anularDeuda,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message:
            'Error inesperado al cancelar inscripcion (admin): ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-003: Ver Inscritos ====================

  @override
  Future<Either<Failure, InscritosFechaResponseModel>> obtenerInscritosFecha(
      String fechaId) async {
    try {
      final result = await remoteDataSource.obtenerInscritosFecha(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener inscritos: ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-004: Cerrar Inscripciones ====================

  @override
  Future<Either<Failure, CerrarInscripcionesRpcResponseModel>>
      cerrarInscripciones(String fechaId) async {
    try {
      final result = await remoteDataSource.cerrarInscripciones(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al cerrar inscripciones: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, ReabrirInscripcionesRpcResponseModel>>
      reabrirInscripciones(String fechaId) async {
    try {
      final result = await remoteDataSource.reabrirInscripciones(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al reabrir inscripciones: ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-008: Editar Fecha ====================

  @override
  Future<Either<Failure, EditarFechaRpcResponseModel>> editarFecha({
    required String fechaId,
    required DateTime fechaHoraInicio,
    required int duracionHoras,
    required String lugar,
  }) async {
    try {
      final result = await remoteDataSource.editarFecha(
        fechaId: fechaId,
        fechaHoraInicio: fechaHoraInicio,
        duracionHoras: duracionHoras,
        lugar: lugar,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al editar fecha: ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-005: Asignar Equipos ====================

  @override
  Future<Either<Failure, ObtenerAsignacionesResponseModel>> obtenerAsignaciones(
      String fechaId) async {
    try {
      final result = await remoteDataSource.obtenerAsignaciones(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener asignaciones: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, AsignarEquipoResponseModel>> asignarEquipo({
    required String fechaId,
    required String usuarioId,
    required String equipo,
  }) async {
    try {
      final result = await remoteDataSource.asignarEquipo(
        fechaId: fechaId,
        usuarioId: usuarioId,
        equipo: equipo,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al asignar equipo: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, ConfirmarEquiposResponseModel>> confirmarEquipos(
      String fechaId) async {
    try {
      final result = await remoteDataSource.confirmarEquipos(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al confirmar equipos: ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-006: Ver Mi Equipo ====================

  @override
  Future<Either<Failure, MiEquipoResponseModel>> obtenerMiEquipo(
      String fechaId) async {
    try {
      final result = await remoteDataSource.obtenerMiEquipo(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener mi equipo: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, EquiposFechaResponseModel>> obtenerEquiposFecha(
      String fechaId) async {
    try {
      final result = await remoteDataSource.obtenerEquiposFecha(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener equipos: ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-009: Listar Fechas por Rol ====================

  @override
  Future<Either<Failure, ListarFechasPorRolResponseModel>> listarFechasPorRol({
    String seccion = 'proximas',
    String? filtroEstado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      final result = await remoteDataSource.listarFechasPorRol(
        seccion: seccion,
        filtroEstado: filtroEstado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al listar fechas por rol: ${e.toString()}',
      ));
    }
  }

  // ==================== E003-HU-010: Finalizar Fecha ====================

  @override
  Future<Either<Failure, FinalizarFechaResponseModel>> finalizarFecha({
    required String fechaId,
    String? comentarios,
    bool huboIncidente = false,
    String? descripcionIncidente,
  }) async {
    try {
      final result = await remoteDataSource.finalizarFecha(
        fechaId: fechaId,
        comentarios: comentarios,
        huboIncidente: huboIncidente,
        descripcionIncidente: descripcionIncidente,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al finalizar fecha: ${e.toString()}',
      ));
    }
  }
}
