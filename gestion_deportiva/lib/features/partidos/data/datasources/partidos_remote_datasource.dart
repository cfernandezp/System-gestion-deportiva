import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/iniciar_partido_response_model.dart';
import '../models/pausar_partido_response_model.dart';
import '../models/reanudar_partido_response_model.dart';
import '../models/obtener_partido_activo_response_model.dart';
// E004-HU-003: Registrar Gol
import '../models/registrar_gol_response_model.dart';
import '../models/eliminar_gol_response_model.dart';
import '../models/obtener_goles_response_model.dart';
// E004-HU-004: Ver Score en Vivo
import '../models/score_partido_response_model.dart';
// E004-HU-005: Finalizar Partido
import '../models/finalizar_partido_response_model.dart';

/// Interface del DataSource remoto de partidos
/// E004-HU-001: Iniciar Partido
/// E004-HU-003: Registrar Gol
/// E004-HU-004: Ver Score en Vivo
/// E004-HU-005: Finalizar Partido
abstract class PartidosRemoteDataSource {
  /// Inicia un nuevo partido seleccionando 2 equipos
  /// RPC: iniciar_partido(p_fecha_id, p_equipo_local, p_equipo_visitante)
  /// CA-001, CA-002, CA-003, CA-006
  /// RN-001, RN-002, RN-003, RN-004, RN-005, RN-006
  Future<IniciarPartidoResponseModel> iniciarPartido({
    required String fechaId,
    required String equipoLocal,
    required String equipoVisitante,
  });

  /// Pausa un partido en curso
  /// RPC: pausar_partido(p_partido_id)
  /// CA-005, RN-001, RN-007
  Future<PausarPartidoResponseModel> pausarPartido(String partidoId);

  /// Reanuda un partido pausado
  /// RPC: reanudar_partido(p_partido_id)
  /// CA-005, RN-001, RN-007
  Future<ReanudarPartidoResponseModel> reanudarPartido(String partidoId);

  /// Obtiene el partido activo de una fecha con tiempo restante calculado
  /// RPC: obtener_partido_activo(p_fecha_id)
  /// CA-004
  Future<ObtenerPartidoActivoResponseModel> obtenerPartidoActivo(
      String fechaId);

  // ==================== E004-HU-003: Registrar Gol ====================

  /// Registra un gol en un partido en curso
  /// RPC: registrar_gol(p_partido_id, p_equipo_anotador, p_jugador_id, p_es_autogol)
  /// CA-001, CA-002, CA-003, CA-004, CA-006, CA-007
  /// RN-001, RN-002, RN-003, RN-004, RN-006, RN-007, RN-008
  Future<RegistrarGolResponseModel> registrarGol({
    required String partidoId,
    required String equipoAnotador,
    String? jugadorId,
    bool esAutogol = false,
  });

  /// Elimina un gol para deshacer errores
  /// RPC: eliminar_gol(p_gol_id)
  /// CA-005, RN-001, RN-005
  Future<EliminarGolResponseModel> eliminarGol(String golId);

  /// Obtiene lista de goles y marcador de un partido
  /// RPC: obtener_goles_partido(p_partido_id)
  Future<ObtenerGolesResponseModel> obtenerGolesPartido(String partidoId);

  // ==================== E004-HU-004: Ver Score en Vivo ====================

  /// Obtiene el score completo de un partido con lista de goles
  /// RPC: obtener_score_partido(p_partido_id)
  /// CA-001: Marcador visible
  /// CA-002: Colores de equipo
  /// CA-004: Lista de goles
  /// CA-005: Tiempo restante
  /// CA-006: Indicador equipo ganando
  /// CA-007: Empate visible
  Future<ScorePartidoResponseModel> obtenerScorePartido(String partidoId);

  // ==================== E004-HU-005: Finalizar Partido ====================

  /// Finaliza un partido en curso
  /// RPC: finalizar_partido(p_partido_id, p_confirmar_anticipado)
  /// CA-001: Boton "Finalizar Partido" visible
  /// CA-004: Sugerencia de rotacion (3 equipos)
  /// CA-005: Resumen con marcador, goleadores, duracion
  /// CA-006: Confirmacion si tiempo no termino
  Future<FinalizarPartidoResponseModel> finalizarPartido(
    String partidoId, {
    bool confirmarAnticipado = false,
  });
}

/// Implementacion del DataSource remoto de partidos
/// Llama a las funciones RPC de Supabase
/// E004-HU-001: Iniciar Partido
/// E004-HU-003: Registrar Gol
/// E004-HU-005: Finalizar Partido
class PartidosRemoteDataSourceImpl implements PartidosRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  PartidosRemoteDataSourceImpl({required this.supabase});

  @override
  Future<IniciarPartidoResponseModel> iniciarPartido({
    required String fechaId,
    required String equipoLocal,
    required String equipoVisitante,
  }) async {
    try {
      // RPC: iniciar_partido(p_fecha_id, p_equipo_local, p_equipo_visitante)
      // CA-001, CA-002, CA-003, CA-006
      // RN-001 a RN-006
      final response = await supabase.rpc(
        'iniciar_partido',
        params: {
          'p_fecha_id': fechaId,
          'p_equipo_local': equipoLocal,
          'p_equipo_visitante': equipoVisitante,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return IniciarPartidoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] as String? ?? 'Error al iniciar partido',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al iniciar partido: ${e.toString()}',
      );
    }
  }

  @override
  Future<PausarPartidoResponseModel> pausarPartido(String partidoId) async {
    try {
      // RPC: pausar_partido(p_partido_id)
      // CA-005, RN-001, RN-007
      final response = await supabase.rpc(
        'pausar_partido',
        params: {'p_partido_id': partidoId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return PausarPartidoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] as String? ?? 'Error al pausar partido',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al pausar partido: ${e.toString()}',
      );
    }
  }

  @override
  Future<ReanudarPartidoResponseModel> reanudarPartido(String partidoId) async {
    try {
      // RPC: reanudar_partido(p_partido_id)
      // CA-005, RN-001, RN-007
      final response = await supabase.rpc(
        'reanudar_partido',
        params: {'p_partido_id': partidoId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ReanudarPartidoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] as String? ?? 'Error al reanudar partido',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al reanudar partido: ${e.toString()}',
      );
    }
  }

  @override
  Future<ObtenerPartidoActivoResponseModel> obtenerPartidoActivo(
      String fechaId) async {
    try {
      // RPC: obtener_partido_activo(p_fecha_id)
      // CA-004: Partido en curso visible con tiempo restante
      final response = await supabase.rpc(
        'obtener_partido_activo',
        params: {'p_fecha_id': fechaId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ObtenerPartidoActivoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message:
              error['message'] as String? ?? 'Error al obtener partido activo',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener partido activo: ${e.toString()}',
      );
    }
  }

  // ==================== E004-HU-003: Registrar Gol ====================

  @override
  Future<RegistrarGolResponseModel> registrarGol({
    required String partidoId,
    required String equipoAnotador,
    String? jugadorId,
    bool esAutogol = false,
  }) async {
    try {
      // RPC: registrar_gol(p_partido_id, p_equipo_anotador, p_jugador_id, p_es_autogol)
      // CA-001 a CA-007, RN-001 a RN-008
      final response = await supabase.rpc(
        'registrar_gol',
        params: {
          'p_partido_id': partidoId,
          'p_equipo_anotador': equipoAnotador,
          'p_jugador_id': jugadorId,
          'p_es_autogol': esAutogol,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return RegistrarGolResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] as String? ?? 'Error al registrar gol',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al registrar gol: ${e.toString()}',
      );
    }
  }

  @override
  Future<EliminarGolResponseModel> eliminarGol(String golId) async {
    try {
      // RPC: eliminar_gol(p_gol_id)
      // CA-005, RN-001, RN-005
      final response = await supabase.rpc(
        'eliminar_gol',
        params: {'p_gol_id': golId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return EliminarGolResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] as String? ?? 'Error al eliminar gol',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al eliminar gol: ${e.toString()}',
      );
    }
  }

  @override
  Future<ObtenerGolesResponseModel> obtenerGolesPartido(
      String partidoId) async {
    try {
      // RPC: obtener_goles_partido(p_partido_id)
      final response = await supabase.rpc(
        'obtener_goles_partido',
        params: {'p_partido_id': partidoId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ObtenerGolesResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message:
              error['message'] as String? ?? 'Error al obtener goles del partido',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener goles: ${e.toString()}',
      );
    }
  }

  // ==================== E004-HU-004: Ver Score en Vivo ====================

  @override
  Future<ScorePartidoResponseModel> obtenerScorePartido(
      String partidoId) async {
    try {
      // RPC: obtener_score_partido(p_partido_id)
      // CA-001: Marcador visible
      // CA-002: Colores de equipo
      // CA-004: Lista de goles
      // CA-005: Tiempo restante
      // CA-006: Indicador equipo ganando
      // CA-007: Empate visible
      final response = await supabase.rpc(
        'obtener_score_partido',
        params: {'p_partido_id': partidoId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ScorePartidoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message:
              error['message'] as String? ?? 'Error al obtener score del partido',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener score: ${e.toString()}',
      );
    }
  }

  // ==================== E004-HU-005: Finalizar Partido ====================

  @override
  Future<FinalizarPartidoResponseModel> finalizarPartido(
    String partidoId, {
    bool confirmarAnticipado = false,
  }) async {
    try {
      // RPC: finalizar_partido(p_partido_id, p_confirmar_anticipado)
      // CA-001: Boton "Finalizar Partido" visible
      // CA-004: Sugerencia de rotacion (3 equipos)
      // CA-005: Resumen con marcador, goleadores, duracion
      // CA-006: Confirmacion si tiempo no termino
      final response = await supabase.rpc(
        'finalizar_partido',
        params: {
          'p_partido_id': partidoId,
          'p_confirmar_anticipado': confirmarAnticipado,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return FinalizarPartidoResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message:
              error['message'] as String? ?? 'Error al finalizar partido',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al finalizar partido: ${e.toString()}',
      );
    }
  }
}
