import 'package:equatable/equatable.dart';

/// E006-HU-003: Modelo de respuesta de Mis Estadisticas
/// Contiene metricas personales del jugador logueado
class MisEstadisticasResponseModel extends Equatable {
  final JugadorInfoModel jugador;
  final bool statsAvanzadas;
  final MetricasModel metricas;
  final RankingsModel? rankings;
  final PromedioModel? promedio;
  final int? rachaAsistencia;
  final MejorFechaModel? mejorFecha;
  final List<HistorialFechaModel>? historial;
  final String message;

  const MisEstadisticasResponseModel({
    required this.jugador,
    required this.statsAvanzadas,
    required this.metricas,
    this.rankings,
    this.promedio,
    this.rachaAsistencia,
    this.mejorFecha,
    this.historial,
    required this.message,
  });

  factory MisEstadisticasResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MisEstadisticasResponseModel(
      jugador: JugadorInfoModel.fromJson(data['jugador'] as Map<String, dynamic>),
      statsAvanzadas: data['stats_avanzadas'] as bool? ?? false,
      metricas: MetricasModel.fromJson(data['metricas'] as Map<String, dynamic>),
      rankings: data['rankings'] != null
          ? RankingsModel.fromJson(data['rankings'] as Map<String, dynamic>)
          : null,
      promedio: data['promedio'] != null
          ? PromedioModel.fromJson(data['promedio'] as Map<String, dynamic>)
          : null,
      rachaAsistencia: data['racha_asistencia'] as int?,
      mejorFecha: data['mejor_fecha'] != null
          ? MejorFechaModel.fromJson(data['mejor_fecha'] as Map<String, dynamic>)
          : null,
      historial: data['historial'] != null
          ? (data['historial'] as List)
              .map((e) => HistorialFechaModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      message: json['message'] as String? ?? '',
    );
  }

  /// CA-008: Verifica si tiene datos
  bool get tieneDatos =>
      metricas.golesTotales > 0 ||
      metricas.fechasAsistidas > 0 ||
      metricas.partidosJugados > 0;

  @override
  List<Object?> get props => [
        jugador,
        statsAvanzadas,
        metricas,
        rankings,
        promedio,
        rachaAsistencia,
        mejorFecha,
        historial,
        message,
      ];
}

/// Informacion basica del jugador
class JugadorInfoModel extends Equatable {
  final String id;
  final String nombre;
  final String? apodo;
  final String? fotoUrl;

  const JugadorInfoModel({
    required this.id,
    required this.nombre,
    this.apodo,
    this.fotoUrl,
  });

  factory JugadorInfoModel.fromJson(Map<String, dynamic> json) {
    return JugadorInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apodo: json['apodo'] as String?,
      fotoUrl: json['foto_url'] as String?,
    );
  }

  /// Nombre para mostrar: apodo si existe, sino nombre
  String get displayName => (apodo != null && apodo!.isNotEmpty) ? apodo! : nombre;

  @override
  List<Object?> get props => [id, nombre, apodo, fotoUrl];
}

/// CA-002: Metricas principales
class MetricasModel extends Equatable {
  final int golesTotales;
  final int fechasAsistidas;
  final int partidosJugados;
  final int puntosAcumulados;

  const MetricasModel({
    required this.golesTotales,
    required this.fechasAsistidas,
    required this.partidosJugados,
    required this.puntosAcumulados,
  });

  factory MetricasModel.fromJson(Map<String, dynamic> json) {
    return MetricasModel(
      golesTotales: json['goles_totales'] as int? ?? 0,
      fechasAsistidas: json['fechas_asistidas'] as int? ?? 0,
      partidosJugados: json['partidos_jugados'] as int? ?? 0,
      puntosAcumulados: json['puntos_acumulados'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [golesTotales, fechasAsistidas, partidosJugados, puntosAcumulados];
}

/// CA-003: Posicion en rankings
class RankingsModel extends Equatable {
  final RankingPosicionModel goleadores;
  final RankingPosicionModel puntos;

  const RankingsModel({
    required this.goleadores,
    required this.puntos,
  });

  factory RankingsModel.fromJson(Map<String, dynamic> json) {
    return RankingsModel(
      goleadores: RankingPosicionModel.fromJson(json['goleadores'] as Map<String, dynamic>),
      puntos: RankingPosicionModel.fromJson(json['puntos'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [goleadores, puntos];
}

/// Posicion en un ranking especifico
class RankingPosicionModel extends Equatable {
  final int? posicion;
  final int total;

  const RankingPosicionModel({
    this.posicion,
    required this.total,
  });

  factory RankingPosicionModel.fromJson(Map<String, dynamic> json) {
    return RankingPosicionModel(
      posicion: json['posicion'] as int?,
      total: json['total'] as int? ?? 0,
    );
  }

  /// RN-007: Sin clasificar si posicion es null
  bool get sinClasificar => posicion == null;

  /// Formato: "#X de Y" o "Sin clasificar"
  String get displayText =>
      sinClasificar ? 'Sin clasificar' : '#$posicion de $total';

  @override
  List<Object?> get props => [posicion, total];
}

/// CA-004: Promedio de goles
class PromedioModel extends Equatable {
  final double golesPorPartido;
  final double promedioGrupo;

  const PromedioModel({
    required this.golesPorPartido,
    required this.promedioGrupo,
  });

  factory PromedioModel.fromJson(Map<String, dynamic> json) {
    return PromedioModel(
      golesPorPartido: (json['goles_por_partido'] as num?)?.toDouble() ?? 0.0,
      promedioGrupo: (json['promedio_grupo'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Comparativa: positiva = mejor que el grupo
  double get diferencia => golesPorPartido - promedioGrupo;
  bool get mejorQueGrupo => diferencia > 0;

  @override
  List<Object?> get props => [golesPorPartido, promedioGrupo];
}

/// CA-006: Mejor fecha destacada
class MejorFechaModel extends Equatable {
  final String fechaId;
  final String fechaFormato;
  final String lugar;
  final int goles;
  final String equipo;
  final String resultado;

  const MejorFechaModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    required this.goles,
    required this.equipo,
    required this.resultado,
  });

  factory MejorFechaModel.fromJson(Map<String, dynamic> json) {
    return MejorFechaModel(
      fechaId: json['fecha_id'] as String,
      fechaFormato: json['fecha_formato'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      goles: json['goles'] as int? ?? 0,
      equipo: json['equipo'] as String? ?? '',
      resultado: json['resultado'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [fechaId, fechaFormato, lugar, goles, equipo, resultado];
}

/// CA-005: Item del historial por fecha
class HistorialFechaModel extends Equatable {
  final String fechaId;
  final String fechaFormato;
  final String lugar;
  final String? equipo;
  final int goles;
  final int puntos;
  final String resultado;

  const HistorialFechaModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    this.equipo,
    required this.goles,
    required this.puntos,
    required this.resultado,
  });

  factory HistorialFechaModel.fromJson(Map<String, dynamic> json) {
    return HistorialFechaModel(
      fechaId: json['fecha_id'] as String,
      fechaFormato: json['fecha_formato'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      equipo: json['equipo'] as String?,
      goles: json['goles'] as int? ?? 0,
      puntos: json['puntos'] as int? ?? 0,
      resultado: json['resultado'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [fechaId, fechaFormato, lugar, equipo, goles, puntos, resultado];
}
