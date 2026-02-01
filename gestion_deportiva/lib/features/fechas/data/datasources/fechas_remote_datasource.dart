import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
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
import '../models/desasignar_equipo_response_model.dart';
import '../models/confirmar_equipos_response_model.dart';
import '../models/mi_equipo_model.dart';
import '../models/equipos_fecha_model.dart';
import '../models/listar_fechas_por_rol_response_model.dart';
import '../models/finalizar_fecha_response_model.dart';
import '../models/inscribir_jugador_admin_response_model.dart';
import '../models/iniciar_fecha_response_model.dart';

/// Interface del DataSource remoto de fechas
/// E003-HU-001: Crear Fecha
/// E003-HU-002: Inscribirse a Fecha
/// E003-HU-003: Ver Inscritos
/// E003-HU-004: Cerrar Inscripciones
/// E003-HU-005: Asignar Equipos
/// E003-HU-006: Ver Mi Equipo
/// E003-HU-007: Cancelar Inscripcion
/// E003-HU-008: Editar Fecha
/// E003-HU-009: Listar Fechas por Rol
/// E003-HU-011: Inscribir Jugador como Admin
/// E003-HU-012: Iniciar Fecha
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

  /// Cancela la inscripcion del usuario a una fecha (version simple)
  /// RPC: cancelar_inscripcion(p_fecha_id)
  /// CA-004
  Future<CancelarInscripcionResponseModel> cancelarInscripcion(String fechaId);

  // ==================== E003-HU-007: Cancelar Inscripcion ====================

  /// Verifica si el usuario puede cancelar su inscripcion
  /// RPC: verificar_puede_cancelar(p_fecha_id)
  /// CA-001, CA-002, CA-005, RN-001, RN-002
  Future<VerificarCancelarRpcResponseModel> verificarPuedeCancelar(
      String fechaId);

  /// Cancela la inscripcion del usuario a una fecha (version completa)
  /// RPC: cancelar_inscripcion(p_fecha_id)
  /// CA-003, CA-004, CA-007, RN-001 a RN-006
  Future<CancelarInscripcionRpcResponseModel> cancelarInscripcionCompleta(
      String fechaId);

  /// Cancela la inscripcion de un jugador por parte de un admin
  /// RPC: cancelar_inscripcion_admin(p_inscripcion_id, p_anular_deuda)
  /// CA-006, RN-002 a RN-006
  Future<CancelarInscripcionAdminRpcResponseModel> cancelarInscripcionAdmin({
    required String inscripcionId,
    required bool anularDeuda,
  });

  /// Obtiene el detalle de una fecha con sus inscritos
  /// RPC: obtener_fecha_detalle(p_fecha_id)
  /// CA-001, CA-004, CA-005, CA-006
  Future<FechaDetalleResponseModel> obtenerFechaDetalle(String fechaId);

  /// Lista todas las fechas disponibles (abiertas)
  /// RPC: listar_fechas_disponibles()
  /// RN-002
  Future<ListarFechasDisponiblesResponseModel> listarFechasDisponibles();

  // ==================== E003-HU-003: Ver Inscritos ====================

  /// Obtiene la lista de jugadores inscritos a una fecha
  /// RPC: obtener_inscritos_fecha(p_fecha_id)
  /// CA-001 a CA-006, RN-001 a RN-005
  Future<InscritosFechaResponseModel> obtenerInscritosFecha(String fechaId);

  // ==================== E003-HU-004: Cerrar Inscripciones ====================

  /// Cierra las inscripciones de una fecha
  /// RPC: cerrar_inscripciones(p_fecha_id)
  /// CA-001 a CA-007, RN-001 a RN-006
  Future<CerrarInscripcionesRpcResponseModel> cerrarInscripciones(
      String fechaId);

  /// Reabre las inscripciones de una fecha cerrada
  /// RPC: reabrir_inscripciones(p_fecha_id)
  /// CA-006, RN-001, RN-005, RN-006
  Future<ReabrirInscripcionesRpcResponseModel> reabrirInscripciones(
      String fechaId);

  // ==================== E003-HU-008: Editar Fecha ====================

  /// Edita una fecha de pichanga existente
  /// RPC: editar_fecha(p_fecha_id, p_fecha_hora_inicio, p_duracion_horas, p_lugar)
  /// CA-001 a CA-008, RN-001 a RN-008
  Future<EditarFechaRpcResponseModel> editarFecha({
    required String fechaId,
    required DateTime fechaHoraInicio,
    required int duracionHoras,
    required String lugar,
  });

  // ==================== E003-HU-005: Asignar Equipos ====================

  /// Obtiene las asignaciones de equipos de una fecha
  /// RPC: obtener_asignaciones(p_fecha_id)
  /// CA-001, CA-002, CA-003, RN-003, RN-004
  Future<ObtenerAsignacionesResponseModel> obtenerAsignaciones(String fechaId);

  /// Asigna un jugador a un equipo
  /// RPC: asignar_equipo(p_fecha_id, p_usuario_id, p_equipo)
  /// CA-004, CA-005, CA-008, RN-001, RN-002, RN-004, RN-008
  Future<AsignarEquipoResponseModel> asignarEquipo({
    required String fechaId,
    required String usuarioId,
    required String equipo,
  });

  /// Desasigna un jugador de su equipo (lo devuelve a Sin Asignar)
  /// RPC: desasignar_equipo(p_fecha_id, p_usuario_id)
  /// RN-001, RN-002, RN-008
  Future<DesasignarEquipoResponseModel> desasignarEquipo({
    required String fechaId,
    required String usuarioId,
  });

  /// Confirma las asignaciones de equipos de una fecha
  /// RPC: confirmar_equipos(p_fecha_id)
  /// CA-006, CA-007, RN-001, RN-002, RN-005, RN-006, RN-007
  Future<ConfirmarEquiposResponseModel> confirmarEquipos(String fechaId);

  // ==================== E003-HU-006: Ver Mi Equipo ====================

  /// Obtiene el equipo del usuario actual para una fecha
  /// RPC: obtener_mi_equipo(p_fecha_id)
  /// CA-001, CA-002, CA-003, CA-005, CA-006, RN-001, RN-003
  Future<MiEquipoResponseModel> obtenerMiEquipo(String fechaId);

  /// Obtiene todos los equipos de una fecha con sus jugadores
  /// RPC: obtener_equipos_fecha(p_fecha_id)
  /// CA-004, RN-002
  Future<EquiposFechaResponseModel> obtenerEquiposFecha(String fechaId);

  // ==================== E003-HU-009: Listar Fechas por Rol ====================

  /// Lista fechas filtradas segun el rol del usuario
  /// RPC: listar_fechas_por_rol(p_seccion, p_filtro_estado, p_fecha_desde, p_fecha_hasta)
  /// Jugador: Solo sus fechas inscritas/disponibles
  /// Admin: Todas las fechas con filtros opcionales
  Future<ListarFechasPorRolResponseModel> listarFechasPorRol({
    String seccion = 'proximas',
    String? filtroEstado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  // ==================== E003-HU-010: Finalizar Fecha ====================

  /// Finaliza una fecha de pichanga
  /// RPC: finalizar_fecha(p_fecha_id, p_comentarios, p_hubo_incidente, p_descripcion_incidente)
  /// CA-001 a CA-010, RN-001 a RN-007
  Future<FinalizarFechaResponseModel> finalizarFecha({
    required String fechaId,
    String? comentarios,
    bool huboIncidente = false,
    String? descripcionIncidente,
  });

  // ==================== E003-HU-011: Inscribir Jugador como Admin ====================

  /// Lista jugadores disponibles para inscripcion (aprobados, no inscritos a esta fecha)
  /// RPC: listar_jugadores_disponibles_inscripcion(p_fecha_id)
  /// CA-002: Selector de jugadores con busqueda
  Future<ListarJugadoresDisponiblesResponseModel> listarJugadoresDisponiblesInscripcion(
      String fechaId);

  /// Inscribe un jugador a una fecha como admin/organizador
  /// RPC: inscribir_jugador_admin(p_fecha_id, p_jugador_id)
  /// CA-001 a CA-008, RN-001 a RN-008
  Future<InscribirJugadorAdminResponseModel> inscribirJugadorAdmin({
    required String fechaId,
    required String jugadorId,
  });

  // ==================== E003-HU-012: Iniciar Fecha ====================

  /// Inicia una fecha de pichanga (cambia estado de cerrada a en_juego)
  /// RPC: iniciar_fecha(p_fecha_id)
  /// CA-001 a CA-007, RN-001 a RN-007
  Future<IniciarFechaResponseModel> iniciarFecha(String fechaId);
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

  // ==================== E003-HU-007: Cancelar Inscripcion ====================

  @override
  Future<VerificarCancelarRpcResponseModel> verificarPuedeCancelar(
      String fechaId) async {
    try {
      // RPC: verificar_puede_cancelar(p_fecha_id)
      // CA-001, CA-002, CA-005, RN-001, RN-002
      final response = await supabase.rpc(
        'verificar_puede_cancelar',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return VerificarCancelarRpcResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al verificar cancelacion',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al verificar cancelacion: ${e.toString()}',
      );
    }
  }

  @override
  Future<CancelarInscripcionRpcResponseModel> cancelarInscripcionCompleta(
      String fechaId) async {
    try {
      // RPC: cancelar_inscripcion(p_fecha_id)
      // CA-003, CA-004, CA-007, RN-001 a RN-006
      final response = await supabase.rpc(
        'cancelar_inscripcion',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return CancelarInscripcionRpcResponseModel.fromJson(responseMap);
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
        message: 'Error de conexion al cancelar inscripcion: ${e.toString()}',
      );
    }
  }

  @override
  Future<CancelarInscripcionAdminRpcResponseModel> cancelarInscripcionAdmin({
    required String inscripcionId,
    required bool anularDeuda,
  }) async {
    try {
      // RPC: cancelar_inscripcion_admin(p_inscripcion_id, p_anular_deuda)
      // CA-006, RN-002 a RN-006
      final response = await supabase.rpc(
        'cancelar_inscripcion_admin',
        params: {
          'p_inscripcion_id': inscripcionId,
          'p_anular_deuda': anularDeuda,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return CancelarInscripcionAdminRpcResponseModel.fromJson(responseMap);
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
        message:
            'Error de conexion al cancelar inscripcion admin: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-003: Ver Inscritos ====================

  @override
  Future<InscritosFechaResponseModel> obtenerInscritosFecha(
      String fechaId) async {
    try {
      // RPC: obtener_inscritos_fecha(p_fecha_id)
      // CA-001 a CA-006, RN-001 a RN-005
      final response = await supabase.rpc(
        'obtener_inscritos_fecha',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return InscritosFechaResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener inscritos',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener inscritos: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-004: Cerrar Inscripciones ====================

  @override
  Future<CerrarInscripcionesRpcResponseModel> cerrarInscripciones(
      String fechaId) async {
    try {
      // RPC: cerrar_inscripciones(p_fecha_id)
      // CA-001 a CA-007, RN-001 a RN-006
      final response = await supabase.rpc(
        'cerrar_inscripciones',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return CerrarInscripcionesRpcResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al cerrar inscripciones',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al cerrar inscripciones: ${e.toString()}',
      );
    }
  }

  @override
  Future<ReabrirInscripcionesRpcResponseModel> reabrirInscripciones(
      String fechaId) async {
    try {
      // RPC: reabrir_inscripciones(p_fecha_id)
      // CA-006, RN-001, RN-005, RN-006
      final response = await supabase.rpc(
        'reabrir_inscripciones',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ReabrirInscripcionesRpcResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al reabrir inscripciones',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al reabrir inscripciones: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-008: Editar Fecha ====================

  @override
  Future<EditarFechaRpcResponseModel> editarFecha({
    required String fechaId,
    required DateTime fechaHoraInicio,
    required int duracionHoras,
    required String lugar,
  }) async {
    try {
      // RPC: editar_fecha(p_fecha_id, p_fecha_hora_inicio, p_duracion_horas, p_lugar)
      // CA-001 a CA-008, RN-001 a RN-008
      final response = await supabase.rpc(
        'editar_fecha',
        params: {
          'p_fecha_id': fechaId,
          'p_fecha_hora_inicio': fechaHoraInicio.toUtc().toIso8601String(),
          'p_duracion_horas': duracionHoras,
          'p_lugar': lugar,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return EditarFechaRpcResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al editar la fecha',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al editar fecha: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-005: Asignar Equipos ====================

  @override
  Future<ObtenerAsignacionesResponseModel> obtenerAsignaciones(
      String fechaId) async {
    try {
      // RPC: obtener_asignaciones(p_fecha_id)
      // CA-001, CA-002, CA-003, RN-003, RN-004
      final response = await supabase.rpc(
        'obtener_asignaciones',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ObtenerAsignacionesResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener asignaciones',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener asignaciones: ${e.toString()}',
      );
    }
  }

  @override
  Future<AsignarEquipoResponseModel> asignarEquipo({
    required String fechaId,
    required String usuarioId,
    required String equipo,
  }) async {
    try {
      // RPC: asignar_equipo(p_fecha_id, p_usuario_id, p_equipo)
      // CA-004, CA-005, CA-008, RN-001, RN-002, RN-004, RN-008
      final response = await supabase.rpc(
        'asignar_equipo',
        params: {
          'p_fecha_id': fechaId,
          'p_usuario_id': usuarioId,
          'p_equipo': equipo,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return AsignarEquipoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al asignar equipo',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al asignar equipo: ${e.toString()}',
      );
    }
  }

  @override
  Future<DesasignarEquipoResponseModel> desasignarEquipo({
    required String fechaId,
    required String usuarioId,
  }) async {
    try {
      // RPC: desasignar_equipo(p_fecha_id, p_usuario_id)
      // Devuelve jugador a "Sin Asignar"
      final response = await supabase.rpc(
        'desasignar_equipo',
        params: {
          'p_fecha_id': fechaId,
          'p_usuario_id': usuarioId,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return DesasignarEquipoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al desasignar equipo',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al desasignar equipo: ${e.toString()}',
      );
    }
  }

  @override
  Future<ConfirmarEquiposResponseModel> confirmarEquipos(String fechaId) async {
    try {
      // RPC: confirmar_equipos(p_fecha_id)
      // CA-006, CA-007, RN-001, RN-002, RN-005, RN-006, RN-007
      final response = await supabase.rpc(
        'confirmar_equipos',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ConfirmarEquiposResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al confirmar equipos',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al confirmar equipos: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-006: Ver Mi Equipo ====================

  @override
  Future<MiEquipoResponseModel> obtenerMiEquipo(String fechaId) async {
    try {
      // RPC: obtener_mi_equipo(p_fecha_id)
      // CA-001, CA-002, CA-003, CA-005, CA-006, RN-001, RN-003
      final response = await supabase.rpc(
        'obtener_mi_equipo',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return MiEquipoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener mi equipo',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener mi equipo: ${e.toString()}',
      );
    }
  }

  @override
  Future<EquiposFechaResponseModel> obtenerEquiposFecha(String fechaId) async {
    try {
      // RPC: obtener_equipos_fecha(p_fecha_id)
      // CA-004, RN-002
      final response = await supabase.rpc(
        'obtener_equipos_fecha',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return EquiposFechaResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener equipos de la fecha',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener equipos: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-009: Listar Fechas por Rol ====================

  @override
  Future<ListarFechasPorRolResponseModel> listarFechasPorRol({
    String seccion = 'proximas',
    String? filtroEstado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      // DEBUG: Verificar estado de autenticacion antes de llamar RPC
      final currentUser = supabase.auth.currentUser;
      final session = supabase.auth.currentSession;
      debugPrint('[listarFechasPorRol] currentUser: ${currentUser?.id}');
      debugPrint('[listarFechasPorRol] session: ${session != null ? "ACTIVA" : "NULL"}');
      debugPrint('[listarFechasPorRol] accessToken: ${session?.accessToken != null ? "PRESENTE (${session!.accessToken.length} chars)" : "NULL"}');

      // RPC: listar_fechas_por_rol(p_seccion, p_filtro_estado, p_fecha_desde, p_fecha_hasta)
      // Construir parametros (solo enviar los que tienen valor)
      final params = <String, dynamic>{
        'p_seccion': seccion,
      };

      if (filtroEstado != null) {
        params['p_filtro_estado'] = filtroEstado;
      }
      if (fechaDesde != null) {
        params['p_fecha_desde'] = fechaDesde.toUtc().toIso8601String();
      }
      if (fechaHasta != null) {
        params['p_fecha_hasta'] = fechaHasta.toUtc().toIso8601String();
      }

      final response = await supabase.rpc(
        'listar_fechas_por_rol',
        params: params,
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ListarFechasPorRolResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al listar fechas',
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

  // ==================== E003-HU-010: Finalizar Fecha ====================

  @override
  Future<FinalizarFechaResponseModel> finalizarFecha({
    required String fechaId,
    String? comentarios,
    bool huboIncidente = false,
    String? descripcionIncidente,
  }) async {
    try {
      // RPC: finalizar_fecha(p_fecha_id, p_comentarios, p_hubo_incidente, p_descripcion_incidente)
      // CA-001 a CA-010, RN-001 a RN-007
      final response = await supabase.rpc(
        'finalizar_fecha',
        params: {
          'p_fecha_id': fechaId,
          'p_comentarios': comentarios,
          'p_hubo_incidente': huboIncidente,
          'p_descripcion_incidente': descripcionIncidente,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return FinalizarFechaResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al finalizar la fecha',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al finalizar fecha: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-011: Inscribir Jugador como Admin ====================

  @override
  Future<ListarJugadoresDisponiblesResponseModel>
      listarJugadoresDisponiblesInscripcion(String fechaId) async {
    try {
      // RPC: listar_jugadores_disponibles_inscripcion(p_fecha_id)
      // CA-002: Lista de jugadores aprobados no inscritos
      final response = await supabase.rpc(
        'listar_jugadores_disponibles_inscripcion',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ListarJugadoresDisponiblesResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al listar jugadores disponibles',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message:
            'Error de conexion al listar jugadores disponibles: ${e.toString()}',
      );
    }
  }

  @override
  Future<InscribirJugadorAdminResponseModel> inscribirJugadorAdmin({
    required String fechaId,
    required String jugadorId,
  }) async {
    try {
      // RPC: inscribir_jugador_admin(p_fecha_id, p_jugador_id)
      // CA-001 a CA-008, RN-001 a RN-008
      final response = await supabase.rpc(
        'inscribir_jugador_admin',
        params: {
          'p_fecha_id': fechaId,
          'p_jugador_id': jugadorId,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return InscribirJugadorAdminResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al inscribir jugador',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al inscribir jugador: ${e.toString()}',
      );
    }
  }

  // ==================== E003-HU-012: Iniciar Fecha ====================

  @override
  Future<IniciarFechaResponseModel> iniciarFecha(String fechaId) async {
    try {
      // RPC: iniciar_fecha(p_fecha_id)
      // CA-001 a CA-007, RN-001 a RN-007
      final response = await supabase.rpc(
        'iniciar_fecha',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return IniciarFechaResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al iniciar la pichanga',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al iniciar pichanga: ${e.toString()}',
      );
    }
  }
}
