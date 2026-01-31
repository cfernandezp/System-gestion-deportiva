import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/iniciar_partido_response_model.dart';
import '../../data/models/pausar_partido_response_model.dart';
import '../../data/models/reanudar_partido_response_model.dart';
import '../../data/models/obtener_partido_activo_response_model.dart';
// E004-HU-003: Registrar Gol
import '../../data/models/registrar_gol_response_model.dart';
import '../../data/models/eliminar_gol_response_model.dart';
import '../../data/models/obtener_goles_response_model.dart';
// E004-HU-004: Ver Score en Vivo
import '../../data/models/score_partido_response_model.dart';
// E004-HU-005: Finalizar Partido
import '../../data/models/finalizar_partido_response_model.dart';

/// Interface del repositorio de partidos
/// E004-HU-001: Iniciar Partido
/// E004-HU-003: Registrar Gol
/// E004-HU-004: Ver Score en Vivo
/// E004-HU-005: Finalizar Partido
abstract class PartidosRepository {
  /// Inicia un nuevo partido seleccionando 2 equipos
  /// CA-001, CA-002, CA-003, CA-006
  /// RN-001, RN-002, RN-003, RN-004, RN-005, RN-006
  /// Returns: `Either<Failure, IniciarPartidoResponseModel>`
  Future<Either<Failure, IniciarPartidoResponseModel>> iniciarPartido({
    required String fechaId,
    required String equipoLocal,
    required String equipoVisitante,
  });

  /// Pausa un partido en curso
  /// CA-005, RN-001, RN-007
  /// Returns: `Either<Failure, PausarPartidoResponseModel>`
  Future<Either<Failure, PausarPartidoResponseModel>> pausarPartido(
      String partidoId);

  /// Reanuda un partido pausado
  /// CA-005, RN-001, RN-007
  /// Returns: `Either<Failure, ReanudarPartidoResponseModel>`
  Future<Either<Failure, ReanudarPartidoResponseModel>> reanudarPartido(
      String partidoId);

  /// Obtiene el partido activo de una fecha con tiempo restante calculado
  /// CA-004
  /// Returns: `Either<Failure, ObtenerPartidoActivoResponseModel>`
  Future<Either<Failure, ObtenerPartidoActivoResponseModel>>
      obtenerPartidoActivo(String fechaId);

  // ==================== E004-HU-003: Registrar Gol ====================

  /// Registra un gol en un partido en curso
  /// CA-001 a CA-007, RN-001 a RN-008
  /// Returns: `Either<Failure, RegistrarGolResponseModel>`
  Future<Either<Failure, RegistrarGolResponseModel>> registrarGol({
    required String partidoId,
    required String equipoAnotador,
    String? jugadorId,
    bool esAutogol = false,
  });

  /// Elimina un gol para deshacer errores
  /// CA-005, RN-001, RN-005
  /// Returns: `Either<Failure, EliminarGolResponseModel>`
  Future<Either<Failure, EliminarGolResponseModel>> eliminarGol(String golId);

  /// Obtiene lista de goles y marcador de un partido
  /// Returns: `Either<Failure, ObtenerGolesResponseModel>`
  Future<Either<Failure, ObtenerGolesResponseModel>> obtenerGolesPartido(
      String partidoId);

  // ==================== E004-HU-004: Ver Score en Vivo ====================

  /// Obtiene el score completo de un partido con lista de goles
  /// CA-001: Marcador visible
  /// CA-002: Colores de equipo
  /// CA-004: Lista de goles
  /// CA-005: Tiempo restante
  /// CA-006: Indicador equipo ganando
  /// CA-007: Empate visible
  /// Returns: `Either<Failure, ScorePartidoResponseModel>`
  Future<Either<Failure, ScorePartidoResponseModel>> obtenerScorePartido(
      String partidoId);

  // ==================== E004-HU-005: Finalizar Partido ====================

  /// Finaliza un partido en curso
  /// CA-001: Boton "Finalizar Partido" visible
  /// CA-004: Sugerencia de rotacion (3 equipos)
  /// CA-005: Resumen con marcador, goleadores, duracion
  /// CA-006: Confirmacion si tiempo no termino
  /// Returns: `Either<Failure, FinalizarPartidoResponseModel>`
  Future<Either<Failure, FinalizarPartidoResponseModel>> finalizarPartido(
    String partidoId, {
    bool confirmarAnticipado = false,
  });
}
