import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/crear_fecha_request_model.dart';
import '../models/crear_fecha_response_model.dart';
import '../models/inscripcion_model.dart';
import '../models/fecha_detalle_model.dart';
import '../models/fecha_disponible_model.dart';

/// Interface del DataSource remoto de fechas
/// E003-HU-001: Crear Fecha
/// E003-HU-002: Inscribirse a Fecha
abstract class FechasRemoteDataSource {
  /// Crea una nueva fecha de pichanga
  /// RPC: crear_fecha(p_fecha_hora_inicio, p_duracion_horas, p_lugar)
  /// CA-001 a CA-007, RN-001 a RN-007
  Future<CrearFechaResponseModel> crearFecha(CrearFechaRequestModel request);

  // ==================== E003-HU-002: Inscribirse a Fecha ====================

  /// Inscribe al usuario actual a una fecha
  /// RPC: inscribirse_fecha(p_fecha_id)
  /// CA-002, CA-003, RN-001 a RN-004
  Future<InscripcionResponseModel> inscribirseFecha(String fechaId);

  /// Cancela la inscripcion del usuario a una fecha
  /// RPC: cancelar_inscripcion(p_fecha_id)
  /// CA-004
  Future<CancelarInscripcionResponseModel> cancelarInscripcion(String fechaId);

  /// Obtiene el detalle de una fecha con sus inscritos
  /// RPC: obtener_fecha_detalle(p_fecha_id)
  /// CA-001, CA-004, CA-005, CA-006
  Future<FechaDetalleResponseModel> obtenerFechaDetalle(String fechaId);

  /// Lista todas las fechas disponibles (abiertas)
  /// RPC: listar_fechas_disponibles()
  /// RN-002
  Future<ListarFechasDisponiblesResponseModel> listarFechasDisponibles();
}

/// Implementacion del DataSource remoto de fechas
/// Llama a las funciones RPC de Supabase
class FechasRemoteDataSourceImpl implements FechasRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  FechasRemoteDataSourceImpl({required this.supabase});

  @override
  Future<CrearFechaResponseModel> crearFecha(
      CrearFechaRequestModel request) async {
    try {
      // RPC: crear_fecha
      // Parametros: p_fecha_hora_inicio, p_duracion_horas, p_lugar
      final response = await supabase.rpc(
        'crear_fecha',
        params: request.toParams(),
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return CrearFechaResponseModel.fromJson(responseMap);
      } else {
        // Extraer error del response
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al crear la fecha',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al crear fecha: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-002: Inscribirse a Fecha ====================

  @override
  Future<InscripcionResponseModel> inscribirseFecha(String fechaId) async {
    try {
      // RPC: inscribirse_fecha(p_fecha_id)
      // CA-002, CA-003, RN-001 a RN-004
      final response = await supabase.rpc(
        'inscribirse_fecha',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return InscripcionResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al inscribirse a la fecha',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al inscribirse: ${e.toString()}',
      );
    }
  }

  @override
  Future<CancelarInscripcionResponseModel> cancelarInscripcion(
      String fechaId) async {
    try {
      // RPC: cancelar_inscripcion(p_fecha_id)
      // CA-004
      final response = await supabase.rpc(
        'cancelar_inscripcion',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return CancelarInscripcionResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al cancelar inscripcion',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al cancelar: ${e.toString()}',
      );
    }
  }

  @override
  Future<FechaDetalleResponseModel> obtenerFechaDetalle(String fechaId) async {
    try {
      // RPC: obtener_fecha_detalle(p_fecha_id)
      // CA-001, CA-004, CA-005, CA-006
      final response = await supabase.rpc(
        'obtener_fecha_detalle',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return FechaDetalleResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener detalle de fecha',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener detalle: ${e.toString()}',
      );
    }
  }

  @override
  Future<ListarFechasDisponiblesResponseModel> listarFechasDisponibles() async {
    try {
      // RPC: listar_fechas_disponibles()
      // RN-002: Solo retorna fechas con estado 'abierta'
      final response = await supabase.rpc('listar_fechas_disponibles');

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ListarFechasDisponiblesResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al listar fechas disponibles',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al listar fechas: ${e.toString()}',
      );
    }
  }
}
