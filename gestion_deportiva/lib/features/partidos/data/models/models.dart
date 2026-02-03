/// Barrel file para modelos de partidos
/// E004-HU-001: Iniciar Partido
/// E004-HU-003: Registrar Gol
/// E004-HU-004: Ver Score en Vivo
library;

export 'estado_partido.dart';
export 'jugador_partido_model.dart';
export 'equipo_partido_model.dart';
export 'partido_model.dart';
export 'iniciar_partido_response_model.dart';
export 'pausar_partido_response_model.dart';
export 'reanudar_partido_response_model.dart';
export 'obtener_partido_activo_response_model.dart';

// E004-HU-003: Registrar Gol
export 'gol_model.dart';
export 'marcador_model.dart';
export 'gol_eliminado_model.dart';
export 'partido_info_model.dart';
export 'registrar_gol_response_model.dart';
export 'eliminar_gol_response_model.dart';
export 'obtener_goles_response_model.dart';

// E004-HU-004: Ver Score en Vivo
export 'equipo_score_model.dart';
export 'score_partido_model.dart';
export 'score_partido_response_model.dart';

// E004-HU-005: Finalizar Partido
export 'finalizar_partido_response_model.dart';

// Lista de partidos
export 'listar_partidos_response_model.dart';

// E004-HU-007: Resumen de Jornada
export 'resumen_jornada_model.dart';
