import 'package:equatable/equatable.dart';

import '../../../fechas/data/models/color_equipo.dart';

/// Modelo de resultado del partido
/// E004-HU-005: Finalizar Partido
/// CA-005: Resumen con marcador final y resultado
class ResultadoPartidoModel extends Equatable {
  /// Codigo del resultado: 'local', 'visitante', 'empate'
  final String codigo;

  /// Descripcion del resultado
  final String descripcion;

  /// Color del equipo ganador (null si empate)
  final String? equipoGanador;

  /// Indica si es empate
  final bool esEmpate;

  const ResultadoPartidoModel({
    required this.codigo,
    required this.descripcion,
    this.equipoGanador,
    this.esEmpate = false,
  });

  /// Factory desde JSON del backend
  factory ResultadoPartidoModel.fromJson(Map<String, dynamic> json) {
    return ResultadoPartidoModel(
      codigo: json['codigo'] as String? ?? 'empate',
      descripcion: json['descripcion'] as String? ?? '',
      equipoGanador: json['equipo_ganador'] as String?,
      esEmpate: json['es_empate'] as bool? ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'descripcion': descripcion,
      'equipo_ganador': equipoGanador,
      'es_empate': esEmpate,
    };
  }

  /// Obtiene el ColorEquipo del ganador
  ColorEquipo? get colorGanador {
    if (equipoGanador == null) return null;
    return ColorEquipo.fromString(equipoGanador);
  }

  @override
  List<Object?> get props => [codigo, descripcion, equipoGanador, esEmpate];
}

/// Modelo de marcador final
/// E004-HU-005: Finalizar Partido
/// CA-005: Resumen con marcador final
class MarcadorFinalModel extends Equatable {
  /// Goles del equipo local
  final int golesLocal;

  /// Goles del equipo visitante
  final int golesVisitante;

  /// Color del equipo local
  final String equipoLocal;

  /// Color del equipo visitante
  final String equipoVisitante;

  const MarcadorFinalModel({
    required this.golesLocal,
    required this.golesVisitante,
    required this.equipoLocal,
    required this.equipoVisitante,
  });

  /// Factory desde JSON del backend
  factory MarcadorFinalModel.fromJson(Map<String, dynamic> json) {
    return MarcadorFinalModel(
      golesLocal: json['goles_local'] as int? ?? 0,
      golesVisitante: json['goles_visitante'] as int? ?? 0,
      equipoLocal: json['equipo_local'] as String? ?? '',
      equipoVisitante: json['equipo_visitante'] as String? ?? '',
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'goles_local': golesLocal,
      'goles_visitante': golesVisitante,
      'equipo_local': equipoLocal,
      'equipo_visitante': equipoVisitante,
    };
  }

  /// Total de goles
  int get totalGoles => golesLocal + golesVisitante;

  /// Marcador formateado: "2 - 1"
  String get textoCorto => '$golesLocal - $golesVisitante';

  /// Marcador completo: "NARANJA 2 - 1 VERDE"
  String get textoCompleto =>
      '${equipoLocal.toUpperCase()} $golesLocal - $golesVisitante ${equipoVisitante.toUpperCase()}';

  @override
  List<Object?> get props =>
      [golesLocal, golesVisitante, equipoLocal, equipoVisitante];
}

/// Modelo de goleador en el resumen
/// E004-HU-005: Finalizar Partido
/// CA-005: Lista de goles con jugador y minuto
class GoleadorResumenModel extends Equatable {
  /// Nombre del jugador
  final String jugadorNombre;

  /// Minuto del gol
  final int minuto;

  /// Si es autogol
  final bool esAutogol;

  /// Color del equipo que recibe el punto
  final String equipo;

  const GoleadorResumenModel({
    required this.jugadorNombre,
    required this.minuto,
    this.esAutogol = false,
    required this.equipo,
  });

  /// Factory desde JSON del backend
  factory GoleadorResumenModel.fromJson(Map<String, dynamic> json) {
    return GoleadorResumenModel(
      jugadorNombre: json['jugador_nombre'] as String? ?? 'Sin asignar',
      minuto: json['minuto'] as int? ?? 0,
      esAutogol: json['es_autogol'] as bool? ?? false,
      equipo: json['equipo'] as String? ?? json['equipo_anotador'] as String? ?? '',
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'jugador_nombre': jugadorNombre,
      'minuto': minuto,
      'es_autogol': esAutogol,
      'equipo': equipo,
    };
  }

  /// Descripcion del gol para mostrar
  /// Ejemplo: "Juan Perez (min 5)" o "Juan Perez (min 5) - Autogol"
  String get descripcion {
    final autogolTag = esAutogol ? ' - Autogol' : '';
    return "$jugadorNombre (min $minuto)$autogolTag";
  }

  @override
  List<Object?> get props => [jugadorNombre, minuto, esAutogol, equipo];
}

/// Modelo de duracion del partido
/// E004-HU-005: Finalizar Partido
/// CA-005: Duracion real del partido
class DuracionPartidoModel extends Equatable {
  /// Duracion real en segundos
  final int realSegundos;

  /// Duracion real formateada "MM:SS"
  final String realFormato;

  /// Duracion programada en minutos
  final int programadaMinutos;

  /// Tiempo en pausa total (segundos)
  final int tiempoPausaSegundos;

  const DuracionPartidoModel({
    required this.realSegundos,
    required this.realFormato,
    required this.programadaMinutos,
    this.tiempoPausaSegundos = 0,
  });

  /// Factory desde JSON del backend
  factory DuracionPartidoModel.fromJson(Map<String, dynamic> json) {
    return DuracionPartidoModel(
      realSegundos: json['real_segundos'] as int? ?? 0,
      realFormato: json['real_formato'] as String? ?? '00:00',
      programadaMinutos: json['programada_minutos'] as int? ?? 10,
      tiempoPausaSegundos: json['tiempo_pausa_segundos'] as int? ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'real_segundos': realSegundos,
      'real_formato': realFormato,
      'programada_minutos': programadaMinutos,
      'tiempo_pausa_segundos': tiempoPausaSegundos,
    };
  }

  /// Duracion programada formateada
  String get programadaFormato => '$programadaMinutos:00';

  @override
  List<Object?> get props =>
      [realSegundos, realFormato, programadaMinutos, tiempoPausaSegundos];
}

/// Modelo de sugerencia para siguiente partido (3 equipos)
/// E004-HU-005: Finalizar Partido
/// CA-004: Sugerencia de rotacion para 3 equipos
class SugerenciaSiguienteModel extends Equatable {
  /// Color del equipo que entra a jugar
  final String equipoEntra;

  /// Color del equipo que continua jugando (ganador o perdedor segun regla)
  final String equipoContinua;

  /// Texto descriptivo de la sugerencia
  final String sugerenciaTexto;

  const SugerenciaSiguienteModel({
    required this.equipoEntra,
    required this.equipoContinua,
    required this.sugerenciaTexto,
  });

  /// Factory desde JSON del backend
  factory SugerenciaSiguienteModel.fromJson(Map<String, dynamic> json) {
    return SugerenciaSiguienteModel(
      equipoEntra: json['equipo_entra'] as String? ?? '',
      equipoContinua: json['equipo_continua'] as String? ?? '',
      sugerenciaTexto: json['sugerencia_texto'] as String? ?? '',
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'equipo_entra': equipoEntra,
      'equipo_continua': equipoContinua,
      'sugerencia_texto': sugerenciaTexto,
    };
  }

  /// ColorEquipo del equipo que entra
  ColorEquipo? get colorEquipoEntra => ColorEquipo.fromString(equipoEntra);

  /// ColorEquipo del equipo que continua
  ColorEquipo? get colorEquipoContinua =>
      ColorEquipo.fromString(equipoContinua);

  @override
  List<Object?> get props => [equipoEntra, equipoContinua, sugerenciaTexto];
}

/// Modelo de goleadores agrupado
/// E004-HU-005: Finalizar Partido
class GoleadoresModel extends Equatable {
  /// Lista completa de goles
  final List<GoleadorResumenModel> listaCompleta;

  /// Total de goles
  final int totalGoles;

  const GoleadoresModel({
    required this.listaCompleta,
    required this.totalGoles,
  });

  /// Factory desde JSON del backend
  factory GoleadoresModel.fromJson(Map<String, dynamic> json) {
    final lista = json['lista_completa'] as List<dynamic>? ?? [];
    return GoleadoresModel(
      listaCompleta: lista
          .map((g) => GoleadorResumenModel.fromJson(g as Map<String, dynamic>))
          .toList(),
      totalGoles: json['total_goles'] as int? ?? lista.length,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'lista_completa': listaCompleta.map((g) => g.toJson()).toList(),
      'total_goles': totalGoles,
    };
  }

  @override
  List<Object?> get props => [listaCompleta, totalGoles];
}

/// Modelo de respuesta de finalizar partido
/// E004-HU-005: Finalizar Partido
/// Response completo del RPC finalizar_partido
class FinalizarPartidoResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Mensaje informativo
  final String message;

  /// ID del partido finalizado
  final String? partidoId;

  /// Resultado del partido
  final ResultadoPartidoModel? resultado;

  /// Marcador final
  final MarcadorFinalModel? marcador;

  /// Lista de goleadores
  final GoleadoresModel? goleadores;

  /// Duracion del partido
  final DuracionPartidoModel? duracion;

  /// Sugerencia de siguiente partido (solo para 3 equipos)
  final SugerenciaSiguienteModel? sugerenciaSiguiente;

  /// Indica si se finalizo anticipadamente
  final bool finalizadoAnticipado;

  const FinalizarPartidoResponseModel({
    required this.success,
    required this.message,
    this.partidoId,
    this.resultado,
    this.marcador,
    this.goleadores,
    this.duracion,
    this.sugerenciaSiguiente,
    this.finalizadoAnticipado = false,
  });

  /// Factory desde JSON del backend
  factory FinalizarPartidoResponseModel.fromJson(Map<String, dynamic> json) {
    // Manejo defensivo: verificar que data sea Map, no List
    final rawData = json['data'];
    final Map<String, dynamic>? data =
        rawData is Map<String, dynamic> ? rawData : null;

    // Helper para obtener un Map de forma segura
    Map<String, dynamic>? safeMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    return FinalizarPartidoResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      partidoId: data?['partido_id'] as String?,
      resultado: safeMap(data?['resultado']) != null
          ? ResultadoPartidoModel.fromJson(safeMap(data!['resultado'])!)
          : null,
      marcador: safeMap(data?['marcador']) != null
          ? MarcadorFinalModel.fromJson(safeMap(data!['marcador'])!)
          : null,
      goleadores: safeMap(data?['goleadores']) != null
          ? GoleadoresModel.fromJson(safeMap(data!['goleadores'])!)
          : null,
      duracion: safeMap(data?['duracion']) != null
          ? DuracionPartidoModel.fromJson(safeMap(data!['duracion'])!)
          : null,
      sugerenciaSiguiente: safeMap(data?['sugerencia_siguiente']) != null
          ? SugerenciaSiguienteModel.fromJson(safeMap(data!['sugerencia_siguiente'])!)
          : null,
      finalizadoAnticipado: data?['finalizado_anticipado'] as bool? ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'partido_id': partidoId,
        'resultado': resultado?.toJson(),
        'marcador': marcador?.toJson(),
        'goleadores': goleadores?.toJson(),
        'duracion': duracion?.toJson(),
        'sugerencia_siguiente': sugerenciaSiguiente?.toJson(),
        'finalizado_anticipado': finalizadoAnticipado,
      },
    };
  }

  /// Indica si hay sugerencia de siguiente partido
  bool get tieneSugerenciaSiguiente => sugerenciaSiguiente != null;

  /// Indica si el partido termino en empate
  bool get esEmpate => resultado?.esEmpate ?? false;

  @override
  List<Object?> get props => [
        success,
        message,
        partidoId,
        resultado,
        marcador,
        goleadores,
        duracion,
        sugerenciaSiguiente,
        finalizadoAnticipado,
      ];
}
