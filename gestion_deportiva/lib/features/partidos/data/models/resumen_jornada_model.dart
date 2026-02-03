import 'package:equatable/equatable.dart';

/// Modelo de informacion de la fecha para el resumen de jornada
/// E004-HU-007: Resumen de Jornada
class FechaResumenModel extends Equatable {
  /// ID de la fecha
  final String id;

  /// Lugar donde se juega
  final String lugar;

  /// Fecha programada (timestamp)
  final DateTime fechaProgramada;

  /// Fecha formateada para mostrar
  final String fechaFormato;

  /// Estado de la fecha
  final String estado;

  /// Numero de equipos
  final int numEquipos;

  const FechaResumenModel({
    required this.id,
    required this.lugar,
    required this.fechaProgramada,
    required this.fechaFormato,
    required this.estado,
    required this.numEquipos,
  });

  /// Factory desde JSON del backend
  factory FechaResumenModel.fromJson(Map<String, dynamic> json) {
    return FechaResumenModel(
      id: json['id'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      fechaProgramada: json['fecha_programada'] != null
          ? DateTime.parse(json['fecha_programada'] as String).toLocal()
          : DateTime.now(),
      fechaFormato: json['fecha_formato'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      numEquipos: json['num_equipos'] as int? ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lugar': lugar,
      'fecha_programada': fechaProgramada.toUtc().toIso8601String(),
      'fecha_formato': fechaFormato,
      'estado': estado,
      'num_equipos': numEquipos,
    };
  }

  @override
  List<Object?> get props => [
        id,
        lugar,
        fechaProgramada,
        fechaFormato,
        estado,
        numEquipos,
      ];
}

/// Modelo de goleador individual dentro de un partido
/// E004-HU-007: Resumen de Jornada
class GoleadorPartidoModel extends Equatable {
  /// Nombre del jugador
  final String jugadorNombre;

  /// Cantidad de goles en el partido
  final int goles;

  /// Minuto del gol (puede ser null si son multiples)
  final int? minuto;

  /// Si es autogol
  final bool esAutogol;

  const GoleadorPartidoModel({
    required this.jugadorNombre,
    required this.goles,
    this.minuto,
    this.esAutogol = false,
  });

  /// Factory desde JSON del backend
  factory GoleadorPartidoModel.fromJson(Map<String, dynamic> json) {
    return GoleadorPartidoModel(
      jugadorNombre: json['jugador_nombre'] as String? ?? 'Desconocido',
      goles: json['goles'] as int? ?? 1,
      minuto: json['minuto'] as int?,
      esAutogol: json['es_autogol'] as bool? ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'jugador_nombre': jugadorNombre,
      'goles': goles,
      'minuto': minuto,
      'es_autogol': esAutogol,
    };
  }

  @override
  List<Object?> get props => [jugadorNombre, goles, minuto, esAutogol];
}

/// Modelo de partido en el resumen de jornada
/// E004-HU-007: Resumen de Jornada
class PartidoResumenModel extends Equatable {
  /// ID del partido
  final String id;

  /// Color del equipo local
  final String equipoLocal;

  /// Color del equipo visitante
  final String equipoVisitante;

  /// Goles del equipo local
  final int golesLocal;

  /// Goles del equipo visitante
  final int golesVisitante;

  /// Estado del partido
  final String estado;

  /// Lista de goleadores del partido
  final List<GoleadorPartidoModel> goleadores;

  const PartidoResumenModel({
    required this.id,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.golesLocal,
    required this.golesVisitante,
    required this.estado,
    required this.goleadores,
  });

  /// Factory desde JSON del backend
  factory PartidoResumenModel.fromJson(Map<String, dynamic> json) {
    final goleadoresList = json['goleadores'] as List<dynamic>? ?? [];
    return PartidoResumenModel(
      id: json['id'] as String? ?? '',
      equipoLocal: json['equipo_local'] as String? ?? '',
      equipoVisitante: json['equipo_visitante'] as String? ?? '',
      golesLocal: json['goles_local'] as int? ?? 0,
      golesVisitante: json['goles_visitante'] as int? ?? 0,
      estado: json['estado'] as String? ?? '',
      goleadores: goleadoresList
          .map((g) => GoleadorPartidoModel.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipo_local': equipoLocal,
      'equipo_visitante': equipoVisitante,
      'goles_local': golesLocal,
      'goles_visitante': golesVisitante,
      'estado': estado,
      'goleadores': goleadores.map((g) => g.toJson()).toList(),
    };
  }

  /// Marcador formateado
  String get marcador => '$golesLocal - $golesVisitante';

  /// Total de goles
  int get totalGoles => golesLocal + golesVisitante;

  /// Indica si el partido esta finalizado
  bool get estaFinalizado => estado == 'finalizado';

  @override
  List<Object?> get props => [
        id,
        equipoLocal,
        equipoVisitante,
        golesLocal,
        golesVisitante,
        estado,
        goleadores,
      ];
}

/// Modelo de posicion en tabla de la jornada
/// E004-HU-007: Resumen de Jornada
/// CA-002: Tabla con PJ, PG, PE, PP, GF, GC, DIF, PTS
class TablaPosicionModel extends Equatable {
  /// Color del equipo
  final String equipo;

  /// Partidos jugados
  final int pj;

  /// Partidos ganados
  final int pg;

  /// Partidos empatados
  final int pe;

  /// Partidos perdidos
  final int pp;

  /// Goles a favor
  final int gf;

  /// Goles en contra
  final int gc;

  /// Diferencia de goles
  final int dif;

  /// Puntos totales
  final int pts;

  /// Posicion en la tabla
  final int posicion;

  const TablaPosicionModel({
    required this.equipo,
    required this.pj,
    required this.pg,
    required this.pe,
    required this.pp,
    required this.gf,
    required this.gc,
    required this.dif,
    required this.pts,
    required this.posicion,
  });

  /// Factory desde JSON del backend
  factory TablaPosicionModel.fromJson(Map<String, dynamic> json) {
    return TablaPosicionModel(
      equipo: json['equipo'] as String? ?? '',
      pj: json['pj'] as int? ?? 0,
      pg: json['pg'] as int? ?? 0,
      pe: json['pe'] as int? ?? 0,
      pp: json['pp'] as int? ?? 0,
      gf: json['gf'] as int? ?? 0,
      gc: json['gc'] as int? ?? 0,
      dif: json['dif'] as int? ?? 0,
      pts: json['pts'] as int? ?? 0,
      posicion: json['posicion'] as int? ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'equipo': equipo,
      'pj': pj,
      'pg': pg,
      'pe': pe,
      'pp': pp,
      'gf': gf,
      'gc': gc,
      'dif': dif,
      'pts': pts,
      'posicion': posicion,
    };
  }

  @override
  List<Object?> get props => [
        equipo,
        pj,
        pg,
        pe,
        pp,
        gf,
        gc,
        dif,
        pts,
        posicion,
      ];
}

/// Modelo de goleador de la jornada
/// E004-HU-007: Resumen de Jornada
/// CA-003: Lista de goleadores
class GoleadorJornadaModel extends Equatable {
  /// ID del jugador
  final String jugadorId;

  /// Nombre del jugador
  final String jugadorNombre;

  /// Color del equipo
  final String equipo;

  /// Total de goles
  final int goles;

  /// Posicion en la tabla de goleadores
  final int posicion;

  const GoleadorJornadaModel({
    required this.jugadorId,
    required this.jugadorNombre,
    required this.equipo,
    required this.goles,
    required this.posicion,
  });

  /// Factory desde JSON del backend
  factory GoleadorJornadaModel.fromJson(Map<String, dynamic> json) {
    return GoleadorJornadaModel(
      jugadorId: json['jugador_id'] as String? ?? '',
      jugadorNombre: json['jugador_nombre'] as String? ?? 'Desconocido',
      equipo: json['equipo'] as String? ?? '',
      goles: json['goles'] as int? ?? 0,
      posicion: json['posicion'] as int? ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'jugador_id': jugadorId,
      'jugador_nombre': jugadorNombre,
      'equipo': equipo,
      'goles': goles,
      'posicion': posicion,
    };
  }

  @override
  List<Object?> get props => [
        jugadorId,
        jugadorNombre,
        equipo,
        goles,
        posicion,
      ];
}

/// Modelo de goleador de la fecha (maximo goleador del dia)
/// E004-HU-007: Resumen de Jornada
class GoleadorFechaModel extends Equatable {
  /// ID del jugador
  final String jugadorId;

  /// Nombre del jugador
  final String jugadorNombre;

  /// Color del equipo
  final String equipo;

  /// Total de goles en la fecha
  final int goles;

  const GoleadorFechaModel({
    required this.jugadorId,
    required this.jugadorNombre,
    required this.equipo,
    required this.goles,
  });

  /// Factory desde JSON del backend
  factory GoleadorFechaModel.fromJson(Map<String, dynamic> json) {
    return GoleadorFechaModel(
      jugadorId: json['jugador_id'] as String? ?? '',
      jugadorNombre: json['jugador_nombre'] as String? ?? 'Desconocido',
      equipo: json['equipo'] as String? ?? '',
      goles: json['goles'] as int? ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'jugador_id': jugadorId,
      'jugador_nombre': jugadorNombre,
      'equipo': equipo,
      'goles': goles,
    };
  }

  @override
  List<Object?> get props => [jugadorId, jugadorNombre, equipo, goles];
}

/// Modelo de estadisticas generales de la jornada
/// E004-HU-007: Resumen de Jornada
class EstadisticasJornadaModel extends Equatable {
  /// Total de partidos programados/jugados
  final int totalPartidos;

  /// Partidos finalizados
  final int partidosFinalizados;

  /// Total de goles anotados
  final int totalGoles;

  /// Promedio de goles por partido
  final double promedioGolesPartido;

  /// Partido con mas goles (descripcion)
  final String? partidoMasGoles;

  const EstadisticasJornadaModel({
    required this.totalPartidos,
    required this.partidosFinalizados,
    required this.totalGoles,
    required this.promedioGolesPartido,
    this.partidoMasGoles,
  });

  /// Factory desde JSON del backend
  factory EstadisticasJornadaModel.fromJson(Map<String, dynamic> json) {
    // Manejar promedio_goles_partido que puede venir como int o double
    final promedioRaw = json['promedio_goles_partido'];
    double promedio = 0.0;
    if (promedioRaw is num) {
      promedio = promedioRaw.toDouble();
    }

    return EstadisticasJornadaModel(
      totalPartidos: json['total_partidos'] as int? ?? 0,
      partidosFinalizados: json['partidos_finalizados'] as int? ?? 0,
      totalGoles: json['total_goles'] as int? ?? 0,
      promedioGolesPartido: promedio,
      partidoMasGoles: json['partido_mas_goles'] as String?,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'total_partidos': totalPartidos,
      'partidos_finalizados': partidosFinalizados,
      'total_goles': totalGoles,
      'promedio_goles_partido': promedioGolesPartido,
      'partido_mas_goles': partidoMasGoles,
    };
  }

  /// Porcentaje de partidos completados
  double get porcentajeCompletado {
    if (totalPartidos == 0) return 0.0;
    return (partidosFinalizados / totalPartidos) * 100;
  }

  @override
  List<Object?> get props => [
        totalPartidos,
        partidosFinalizados,
        totalGoles,
        promedioGolesPartido,
        partidoMasGoles,
      ];
}

/// Modelo de respuesta del resumen de jornada
/// E004-HU-007: Resumen de Jornada
/// Response completo del RPC obtener_resumen_jornada
class ResumenJornadaModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Mensaje informativo
  final String message;

  /// Informacion de la fecha
  final FechaResumenModel? fecha;

  /// Lista de partidos jugados
  final List<PartidoResumenModel> partidos;

  /// Tabla de posiciones
  final List<TablaPosicionModel> tablaPosiciones;

  /// Lista de goleadores de la jornada
  final List<GoleadorJornadaModel> goleadores;

  /// Goleador de la fecha (maximo anotador del dia)
  final List<GoleadorFechaModel>? goleadorFecha;

  /// Estadisticas generales
  final EstadisticasJornadaModel? estadisticas;

  /// Indica si hay partidos en la fecha
  final bool hayPartidos;

  const ResumenJornadaModel({
    required this.success,
    required this.message,
    this.fecha,
    required this.partidos,
    required this.tablaPosiciones,
    required this.goleadores,
    this.goleadorFecha,
    this.estadisticas,
    required this.hayPartidos,
  });

  /// Factory desde JSON del backend
  factory ResumenJornadaModel.fromJson(Map<String, dynamic> json) {
    // Manejar defensivamente el campo data
    final rawData = json['data'];
    final Map<String, dynamic>? data =
        rawData is Map<String, dynamic> ? rawData : null;

    // Helper para obtener un Map de forma segura
    Map<String, dynamic>? safeMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    // Parsear lista de partidos
    final partidosList = data?['partidos'] as List<dynamic>? ?? [];
    final partidos = partidosList
        .map((p) => PartidoResumenModel.fromJson(p as Map<String, dynamic>))
        .toList();

    // Parsear tabla de posiciones
    final tablaList = data?['tabla_posiciones'] as List<dynamic>? ?? [];
    final tablaPosiciones = tablaList
        .map((t) => TablaPosicionModel.fromJson(t as Map<String, dynamic>))
        .toList();

    // Parsear goleadores
    final goleadoresList = data?['goleadores'] as List<dynamic>? ?? [];
    final goleadores = goleadoresList
        .map((g) => GoleadorJornadaModel.fromJson(g as Map<String, dynamic>))
        .toList();

    // Parsear goleador de la fecha (puede ser null o lista)
    List<GoleadorFechaModel>? goleadorFecha;
    final goleadorFechaRaw = data?['goleador_fecha'];
    if (goleadorFechaRaw != null && goleadorFechaRaw is List) {
      final goleadorFechaList = goleadorFechaRaw;
      goleadorFecha = goleadorFechaList
          .map((g) => GoleadorFechaModel.fromJson(g as Map<String, dynamic>))
          .toList();
    }

    return ResumenJornadaModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      fecha: safeMap(data?['fecha']) != null
          ? FechaResumenModel.fromJson(safeMap(data!['fecha'])!)
          : null,
      partidos: partidos,
      tablaPosiciones: tablaPosiciones,
      goleadores: goleadores,
      goleadorFecha: goleadorFecha,
      estadisticas: safeMap(data?['estadisticas']) != null
          ? EstadisticasJornadaModel.fromJson(safeMap(data!['estadisticas'])!)
          : null,
      hayPartidos: data?['hay_partidos'] as bool? ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'fecha': fecha?.toJson(),
        'partidos': partidos.map((p) => p.toJson()).toList(),
        'tabla_posiciones': tablaPosiciones.map((t) => t.toJson()).toList(),
        'goleadores': goleadores.map((g) => g.toJson()).toList(),
        'goleador_fecha': goleadorFecha?.map((g) => g.toJson()).toList(),
        'estadisticas': estadisticas?.toJson(),
        'hay_partidos': hayPartidos,
      },
    };
  }

  /// Indica si hay tabla de posiciones disponible
  bool get tieneTabla => tablaPosiciones.isNotEmpty;

  /// Indica si hay goleadores
  bool get tieneGoleadores => goleadores.isNotEmpty;

  /// Indica si hay goleador de la fecha
  bool get tieneGoleadorFecha =>
      goleadorFecha != null && goleadorFecha!.isNotEmpty;

  /// Indica si hay estadisticas
  bool get tieneEstadisticas => estadisticas != null;

  @override
  List<Object?> get props => [
        success,
        message,
        fecha,
        partidos,
        tablaPosiciones,
        goleadores,
        goleadorFecha,
        estadisticas,
        hayPartidos,
      ];
}
