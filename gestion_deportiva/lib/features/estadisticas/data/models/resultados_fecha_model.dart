import 'package:equatable/equatable.dart';

/// E006-HU-004: Modelos para Resultados por Fecha
/// Incluye historial de fechas y detalle de una fecha especifica

// ============================================
// === RESPUESTA HISTORIAL DE FECHAS ===
// ============================================

/// Respuesta del listado de fechas finalizadas
/// RPC: obtener_historial_fechas
class HistorialFechasResponseModel extends Equatable {
  /// RN-008: Flag de stats avanzadas segun plan
  final bool statsAvanzadas;

  /// CA-001: Lista de fechas finalizadas
  final List<FechaHistorialModel> fechas;

  /// CA-007: Filtros disponibles (Plan 5+)
  final FiltrosDisponiblesModel? filtros;

  /// Mensaje informativo
  final String message;

  const HistorialFechasResponseModel({
    required this.statsAvanzadas,
    required this.fechas,
    this.filtros,
    required this.message,
  });

  factory HistorialFechasResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final fechasList = data['fechas'] as List? ?? [];

    return HistorialFechasResponseModel(
      statsAvanzadas: data['stats_avanzadas'] as bool? ?? false,
      fechas: fechasList
          .map((e) => FechaHistorialModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      filtros: data['filtros'] != null
          ? FiltrosDisponiblesModel.fromJson(
              data['filtros'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String? ?? '',
    );
  }

  /// CA-008: Verifica si hay fechas
  bool get estaVacio => fechas.isEmpty;

  @override
  List<Object?> get props => [statsAvanzadas, fechas, filtros, message];
}

/// CA-001: Modelo de una fecha en el historial
class FechaHistorialModel extends Equatable {
  final String fechaId;
  final String fechaFormato;
  final String fechaHora;
  final String lugar;
  final int totalAsistentes;
  final int totalPartidos;

  const FechaHistorialModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.fechaHora,
    required this.lugar,
    required this.totalAsistentes,
    required this.totalPartidos,
  });

  factory FechaHistorialModel.fromJson(Map<String, dynamic> json) {
    return FechaHistorialModel(
      fechaId: json['fecha_id'] as String,
      fechaFormato: json['fecha_formato'] as String? ?? '',
      fechaHora: json['fecha_hora'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      totalAsistentes: json['total_asistentes'] as int? ?? 0,
      totalPartidos: json['total_partidos'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [fechaId, fechaFormato, fechaHora, lugar, totalAsistentes, totalPartidos];
}

/// CA-007: Filtros disponibles para el historial
class FiltrosDisponiblesModel extends Equatable {
  final List<int> anios;
  final List<int> meses;

  const FiltrosDisponiblesModel({
    required this.anios,
    required this.meses,
  });

  factory FiltrosDisponiblesModel.fromJson(Map<String, dynamic> json) {
    return FiltrosDisponiblesModel(
      anios: (json['anios'] as List?)?.map((e) => e as int).toList() ?? [],
      meses: (json['meses'] as List?)?.map((e) => e as int).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [anios, meses];
}

// ============================================
// === RESPUESTA DETALLE DE FECHA ===
// ============================================

/// Respuesta del detalle de resultados de una fecha
/// RPC: obtener_detalle_fecha_resultados
class DetalleFechaResultadosModel extends Equatable {
  /// RN-008: Flag de stats avanzadas segun plan
  final bool statsAvanzadas;

  /// Informacion de la fecha
  final FechaInfoModel fecha;

  /// CA-003: Partidos con resultados
  final List<PartidoResultadoModel> partidos;

  /// CA-004: Tabla de posiciones (Plan 5+)
  final List<PosicionTablaModel>? tablaPosiciones;

  /// CA-005: Goleadores de la fecha (Plan 5+)
  final List<GoleadorFechaModel>? goleadores;

  /// CA-006: Asistentes agrupados por equipo
  final List<EquipoAsistentesModel> asistentesPorEquipo;

  /// Mensaje informativo
  final String message;

  const DetalleFechaResultadosModel({
    required this.statsAvanzadas,
    required this.fecha,
    required this.partidos,
    this.tablaPosiciones,
    this.goleadores,
    required this.asistentesPorEquipo,
    required this.message,
  });

  factory DetalleFechaResultadosModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final partidosList = data['partidos'] as List? ?? [];
    final asistentesList = data['asistentes_por_equipo'] as List? ?? [];

    return DetalleFechaResultadosModel(
      statsAvanzadas: data['stats_avanzadas'] as bool? ?? false,
      fecha: FechaInfoModel.fromJson(data['fecha'] as Map<String, dynamic>),
      partidos: partidosList
          .map(
              (e) => PartidoResultadoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tablaPosiciones: data['tabla_posiciones'] != null
          ? (data['tabla_posiciones'] as List)
              .map((e) =>
                  PosicionTablaModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      goleadores: data['goleadores'] != null
          ? (data['goleadores'] as List)
              .map((e) =>
                  GoleadorFechaModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      asistentesPorEquipo: asistentesList
          .map((e) =>
              EquipoAsistentesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String? ?? '',
    );
  }

  /// Verifica si hay partidos jugados
  bool get tienePartidos => partidos.isNotEmpty;

  @override
  List<Object?> get props => [
        statsAvanzadas,
        fecha,
        partidos,
        tablaPosiciones,
        goleadores,
        asistentesPorEquipo,
        message,
      ];
}

/// Informacion basica de la fecha para el detalle
class FechaInfoModel extends Equatable {
  final String fechaId;
  final String fechaFormato;
  final String fechaHora;
  final String lugar;
  final int totalAsistentes;

  const FechaInfoModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.fechaHora,
    required this.lugar,
    required this.totalAsistentes,
  });

  factory FechaInfoModel.fromJson(Map<String, dynamic> json) {
    return FechaInfoModel(
      fechaId: json['fecha_id'] as String,
      fechaFormato: json['fecha_formato'] as String? ?? '',
      fechaHora: json['fecha_hora'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      totalAsistentes: json['total_asistentes'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [fechaId, fechaFormato, fechaHora, lugar, totalAsistentes];
}

/// CA-003: Resultado de un partido
class PartidoResultadoModel extends Equatable {
  final String partidoId;
  final String equipoLocal;
  final String equipoVisitante;
  final int golesLocal;
  final int golesVisitante;
  final String estado;

  const PartidoResultadoModel({
    required this.partidoId,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.golesLocal,
    required this.golesVisitante,
    required this.estado,
  });

  factory PartidoResultadoModel.fromJson(Map<String, dynamic> json) {
    return PartidoResultadoModel(
      partidoId: json['partido_id'] as String,
      equipoLocal: json['equipo_local'] as String? ?? '',
      equipoVisitante: json['equipo_visitante'] as String? ?? '',
      golesLocal: json['goles_local'] as int? ?? 0,
      golesVisitante: json['goles_visitante'] as int? ?? 0,
      estado: json['estado'] as String? ?? 'finalizado',
    );
  }

  /// Determina resultado del local
  String get resultadoLocal {
    if (golesLocal > golesVisitante) return 'Victoria';
    if (golesLocal < golesVisitante) return 'Derrota';
    return 'Empate';
  }

  @override
  List<Object?> get props => [
        partidoId,
        equipoLocal,
        equipoVisitante,
        golesLocal,
        golesVisitante,
        estado,
      ];
}

/// CA-004: Posicion en tabla de la fecha
/// RN-003, RN-004: Calculo y criterios de posicion
class PosicionTablaModel extends Equatable {
  final int posicion;
  final String equipo;
  final int pj;
  final int pg;
  final int pe;
  final int pp;
  final int gf;
  final int gc;
  final int dif;
  final int pts;

  const PosicionTablaModel({
    required this.posicion,
    required this.equipo,
    required this.pj,
    required this.pg,
    required this.pe,
    required this.pp,
    required this.gf,
    required this.gc,
    required this.dif,
    required this.pts,
  });

  factory PosicionTablaModel.fromJson(Map<String, dynamic> json) {
    return PosicionTablaModel(
      posicion: json['posicion'] as int? ?? 0,
      equipo: json['equipo'] as String? ?? '',
      pj: json['pj'] as int? ?? 0,
      pg: json['pg'] as int? ?? 0,
      pe: json['pe'] as int? ?? 0,
      pp: json['pp'] as int? ?? 0,
      gf: json['gf'] as int? ?? 0,
      gc: json['gc'] as int? ?? 0,
      dif: json['dif'] as int? ?? 0,
      pts: json['pts'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [posicion, equipo, pj, pg, pe, pp, gf, gc, dif, pts];
}

/// CA-005: Goleador de la fecha
/// RN-005, RN-006: Goleadores y maximo goleador
class GoleadorFechaModel extends Equatable {
  final String jugadorId;
  final String nombre;
  final String? apodo;
  final int goles;
  final bool esMaximoGoleador;

  const GoleadorFechaModel({
    required this.jugadorId,
    required this.nombre,
    this.apodo,
    required this.goles,
    required this.esMaximoGoleador,
  });

  factory GoleadorFechaModel.fromJson(Map<String, dynamic> json) {
    return GoleadorFechaModel(
      jugadorId: json['jugador_id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apodo: json['apodo'] as String?,
      goles: json['goles'] as int? ?? 0,
      esMaximoGoleador: json['es_maximo_goleador'] as bool? ?? false,
    );
  }

  /// Nombre para mostrar: apodo si existe, sino nombre
  String get displayName =>
      (apodo != null && apodo!.isNotEmpty) ? apodo! : nombre;

  @override
  List<Object?> get props =>
      [jugadorId, nombre, apodo, goles, esMaximoGoleador];
}

/// CA-006: Equipo con sus asistentes
/// RN-007: Asistentes por equipo
class EquipoAsistentesModel extends Equatable {
  final String equipo;
  final List<AsistenteFechaModel> jugadores;

  const EquipoAsistentesModel({
    required this.equipo,
    required this.jugadores,
  });

  factory EquipoAsistentesModel.fromJson(Map<String, dynamic> json) {
    final jugadoresList = json['jugadores'] as List? ?? [];
    return EquipoAsistentesModel(
      equipo: json['equipo'] as String? ?? '',
      jugadores: jugadoresList
          .map(
              (e) => AsistenteFechaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [equipo, jugadores];
}

/// Asistente individual de una fecha
class AsistenteFechaModel extends Equatable {
  final String jugadorId;
  final String nombre;
  final String? apodo;
  final int goles;

  const AsistenteFechaModel({
    required this.jugadorId,
    required this.nombre,
    this.apodo,
    required this.goles,
  });

  factory AsistenteFechaModel.fromJson(Map<String, dynamic> json) {
    return AsistenteFechaModel(
      jugadorId: json['jugador_id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apodo: json['apodo'] as String?,
      goles: json['goles'] as int? ?? 0,
    );
  }

  /// Nombre para mostrar: apodo si existe, sino nombre
  String get displayName =>
      (apodo != null && apodo!.isNotEmpty) ? apodo! : nombre;

  @override
  List<Object?> get props => [jugadorId, nombre, apodo, goles];
}
