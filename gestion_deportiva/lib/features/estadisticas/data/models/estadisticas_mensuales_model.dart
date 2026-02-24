import 'package:equatable/equatable.dart';

/// E006-HU-005: Modelo de respuesta de Estadisticas Mensuales
/// Contiene estadisticas agregadas por mes del grupo
class EstadisticasMensualesResponseModel extends Equatable {
  final ResumenMensualModel resumen;
  final List<GoleadorMesModel> goleadorMes;
  final JugadorConstanteModel? jugadorConstante;
  final List<RankingMensualItemModel> rankingGoleadores;
  final List<RankingMensualItemModel> rankingPuntos;
  final ComparativaMesModel? comparativa;
  final List<FechaMesModel> fechasMes;
  final List<MesDisponibleModel> mesesDisponibles;
  final String message;

  const EstadisticasMensualesResponseModel({
    required this.resumen,
    required this.goleadorMes,
    this.jugadorConstante,
    required this.rankingGoleadores,
    required this.rankingPuntos,
    this.comparativa,
    required this.fechasMes,
    required this.mesesDisponibles,
    required this.message,
  });

  factory EstadisticasMensualesResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return EstadisticasMensualesResponseModel(
      resumen: ResumenMensualModel.fromJson(data['resumen'] as Map<String, dynamic>),
      goleadorMes: (data['goleador_mes'] as List?)
              ?.map((e) => GoleadorMesModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      jugadorConstante: data['jugador_constante'] != null
          ? JugadorConstanteModel.fromJson(data['jugador_constante'] as Map<String, dynamic>)
          : null,
      rankingGoleadores: (data['ranking_goleadores'] as List?)
              ?.map((e) => RankingMensualItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rankingPuntos: (data['ranking_puntos'] as List?)
              ?.map((e) => RankingMensualItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comparativa: data['comparativa'] != null
          ? ComparativaMesModel.fromJson(data['comparativa'] as Map<String, dynamic>)
          : null,
      fechasMes: (data['fechas_mes'] as List?)
              ?.map((e) => FechaMesModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mesesDisponibles: (data['meses_disponibles'] as List?)
              ?.map((e) => MesDisponibleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String? ?? '',
    );
  }

  /// CA-008: Verifica si hubo actividad en el mes
  bool get tieneActividad => resumen.fechasJugadas > 0;

  @override
  List<Object?> get props => [
        resumen,
        goleadorMes,
        jugadorConstante,
        rankingGoleadores,
        rankingPuntos,
        comparativa,
        fechasMes,
        mesesDisponibles,
        message,
      ];
}

/// CA-002: Resumen del mes
class ResumenMensualModel extends Equatable {
  final int fechasJugadas;
  final int totalPartidos;
  final int totalGoles;
  final int asistentesUnicos;

  const ResumenMensualModel({
    required this.fechasJugadas,
    required this.totalPartidos,
    required this.totalGoles,
    required this.asistentesUnicos,
  });

  factory ResumenMensualModel.fromJson(Map<String, dynamic> json) {
    return ResumenMensualModel(
      fechasJugadas: json['fechas_jugadas'] as int? ?? 0,
      totalPartidos: json['total_partidos'] as int? ?? 0,
      totalGoles: json['total_goles'] as int? ?? 0,
      asistentesUnicos: json['asistentes_unicos'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [fechasJugadas, totalPartidos, totalGoles, asistentesUnicos];
}

/// CA-003: Goleador del mes (puede haber co-goleadores)
class GoleadorMesModel extends Equatable {
  final String jugadorId;
  final String nombre;
  final String? apodo;
  final String? fotoUrl;
  final int goles;
  final double promedioPorFecha;

  const GoleadorMesModel({
    required this.jugadorId,
    required this.nombre,
    this.apodo,
    this.fotoUrl,
    required this.goles,
    required this.promedioPorFecha,
  });

  factory GoleadorMesModel.fromJson(Map<String, dynamic> json) {
    return GoleadorMesModel(
      jugadorId: json['jugador_id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apodo: json['apodo'] as String?,
      fotoUrl: json['foto_url'] as String?,
      goles: json['goles'] as int? ?? 0,
      promedioPorFecha: (json['promedio_por_fecha'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Nombre para mostrar: apodo si existe, sino nombre
  String get displayName => (apodo != null && apodo!.isNotEmpty) ? apodo! : nombre;

  @override
  List<Object?> get props => [jugadorId, nombre, apodo, fotoUrl, goles, promedioPorFecha];
}

/// CA-006: Jugador mas constante del mes
class JugadorConstanteModel extends Equatable {
  final String jugadorId;
  final String nombre;
  final String? apodo;
  final int fechasAsistidas;

  const JugadorConstanteModel({
    required this.jugadorId,
    required this.nombre,
    this.apodo,
    required this.fechasAsistidas,
  });

  factory JugadorConstanteModel.fromJson(Map<String, dynamic> json) {
    return JugadorConstanteModel(
      jugadorId: json['jugador_id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apodo: json['apodo'] as String?,
      fechasAsistidas: json['fechas_asistidas'] as int? ?? 0,
    );
  }

  /// Nombre para mostrar: apodo si existe, sino nombre
  String get displayName => (apodo != null && apodo!.isNotEmpty) ? apodo! : nombre;

  @override
  List<Object?> get props => [jugadorId, nombre, apodo, fechasAsistidas];
}

/// CA-004: Item de ranking mensual (goleadores o puntos)
class RankingMensualItemModel extends Equatable {
  final String jugadorId;
  final String nombre;
  final String? apodo;
  final int? goles;
  final int? puntos;

  const RankingMensualItemModel({
    required this.jugadorId,
    required this.nombre,
    this.apodo,
    this.goles,
    this.puntos,
  });

  factory RankingMensualItemModel.fromJson(Map<String, dynamic> json) {
    return RankingMensualItemModel(
      jugadorId: json['jugador_id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apodo: json['apodo'] as String?,
      goles: json['goles'] as int?,
      puntos: json['puntos'] as int?,
    );
  }

  /// Nombre para mostrar: apodo si existe, sino nombre
  String get displayName => (apodo != null && apodo!.isNotEmpty) ? apodo! : nombre;

  /// Valor principal a mostrar (goles o puntos, segun contexto)
  int get valorPrincipal => goles ?? puntos ?? 0;

  @override
  List<Object?> get props => [jugadorId, nombre, apodo, goles, puntos];
}

/// CA-005: Comparativa con mes anterior
class ComparativaMesModel extends Equatable {
  final int fechasActual;
  final int fechasAnterior;
  final int difFechas;
  final int golesActual;
  final int golesAnterior;
  final int difGoles;
  final int asistentesActual;
  final int asistentesAnterior;
  final int difAsistentes;
  final double porcentajeFechas;
  final double porcentajeGoles;
  final double porcentajeAsistentes;

  const ComparativaMesModel({
    required this.fechasActual,
    required this.fechasAnterior,
    required this.difFechas,
    required this.golesActual,
    required this.golesAnterior,
    required this.difGoles,
    required this.asistentesActual,
    required this.asistentesAnterior,
    required this.difAsistentes,
    required this.porcentajeFechas,
    required this.porcentajeGoles,
    required this.porcentajeAsistentes,
  });

  factory ComparativaMesModel.fromJson(Map<String, dynamic> json) {
    return ComparativaMesModel(
      fechasActual: json['fechas_actual'] as int? ?? 0,
      fechasAnterior: json['fechas_anterior'] as int? ?? 0,
      difFechas: json['dif_fechas'] as int? ?? 0,
      golesActual: json['goles_actual'] as int? ?? 0,
      golesAnterior: json['goles_anterior'] as int? ?? 0,
      difGoles: json['dif_goles'] as int? ?? 0,
      asistentesActual: json['asistentes_actual'] as int? ?? 0,
      asistentesAnterior: json['asistentes_anterior'] as int? ?? 0,
      difAsistentes: json['dif_asistentes'] as int? ?? 0,
      porcentajeFechas: (json['porcentaje_fechas'] as num?)?.toDouble() ?? 0.0,
      porcentajeGoles: (json['porcentaje_goles'] as num?)?.toDouble() ?? 0.0,
      porcentajeAsistentes: (json['porcentaje_asistentes'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// RN-006: Indicador visual para fechas
  bool get fechasSubieron => difFechas > 0;
  bool get fechasBajaron => difFechas < 0;

  /// RN-006: Indicador visual para goles
  bool get golesSubieron => difGoles > 0;
  bool get golesBajaron => difGoles < 0;

  /// RN-006: Indicador visual para asistentes
  bool get asistentesSubieron => difAsistentes > 0;
  bool get asistentesBajaron => difAsistentes < 0;

  @override
  List<Object?> get props => [
        fechasActual,
        fechasAnterior,
        difFechas,
        golesActual,
        golesAnterior,
        difGoles,
        asistentesActual,
        asistentesAnterior,
        difAsistentes,
        porcentajeFechas,
        porcentajeGoles,
        porcentajeAsistentes,
      ];
}

/// CA-007: Fecha del mes con resultados resumidos
class FechaMesModel extends Equatable {
  final String fechaId;
  final String fechaFormato;
  final String lugar;
  final int totalPartidos;
  final int totalGoles;

  const FechaMesModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    required this.totalPartidos,
    required this.totalGoles,
  });

  factory FechaMesModel.fromJson(Map<String, dynamic> json) {
    return FechaMesModel(
      fechaId: json['fecha_id'] as String,
      fechaFormato: json['fecha_formato'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      totalPartidos: json['total_partidos'] as int? ?? 0,
      totalGoles: json['total_goles'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [fechaId, fechaFormato, lugar, totalPartidos, totalGoles];
}

/// CA-001: Mes disponible para seleccionar
class MesDisponibleModel extends Equatable {
  final int anio;
  final int mes;
  final String nombreMes;

  const MesDisponibleModel({
    required this.anio,
    required this.mes,
    required this.nombreMes,
  });

  factory MesDisponibleModel.fromJson(Map<String, dynamic> json) {
    return MesDisponibleModel(
      anio: json['anio'] as int,
      mes: json['mes'] as int,
      nombreMes: json['nombre_mes'] as String? ?? '',
    );
  }

  /// Formato para mostrar: "Febrero 2026"
  String get displayText => '$nombreMes $anio';

  @override
  List<Object?> get props => [anio, mes, nombreMes];
}
