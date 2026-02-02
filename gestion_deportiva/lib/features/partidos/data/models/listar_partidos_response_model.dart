import 'package:equatable/equatable.dart';

import '../../../fechas/data/models/color_equipo.dart';

/// Modelo de partido en lista
/// Representa un partido dentro de la lista de partidos de una fecha
class PartidoListaModel extends Equatable {
  /// ID del partido
  final String id;

  /// Estado del partido (pendiente, en_curso, pausado, finalizado, cancelado)
  final String estado;

  /// Color del equipo local
  final ColorEquipo equipoLocal;

  /// Color del equipo visitante
  final ColorEquipo equipoVisitante;

  /// Goles del equipo local
  final int golesLocal;

  /// Goles del equipo visitante
  final int golesVisitante;

  /// Duracion del partido en minutos
  final int duracionMinutos;

  /// Hora de inicio del partido (formato HH:MM)
  final String? horaInicio;

  /// Hora de fin estimada (formato HH:MM)
  final String? horaFinEstimada;

  /// Fecha de creacion del partido
  final String? createdAt;

  /// Resultado descriptivo (ej: "Victoria Naranja", "Empate")
  final String? resultado;

  const PartidoListaModel({
    required this.id,
    required this.estado,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.golesLocal,
    required this.golesVisitante,
    required this.duracionMinutos,
    this.horaInicio,
    this.horaFinEstimada,
    this.createdAt,
    this.resultado,
  });

  /// Factory desde JSON del backend
  factory PartidoListaModel.fromJson(Map<String, dynamic> json) {
    // Extraer color del equipo local (puede ser string o objeto JSON)
    String? equipoLocalColor;
    final equipoLocalRaw = json['equipo_local'];
    if (equipoLocalRaw is String) {
      equipoLocalColor = equipoLocalRaw;
    } else if (equipoLocalRaw is Map<String, dynamic>) {
      equipoLocalColor = equipoLocalRaw['color'] as String?;
    }

    // Extraer color del equipo visitante (puede ser string o objeto JSON)
    String? equipoVisitanteColor;
    final equipoVisitanteRaw = json['equipo_visitante'];
    if (equipoVisitanteRaw is String) {
      equipoVisitanteColor = equipoVisitanteRaw;
    } else if (equipoVisitanteRaw is Map<String, dynamic>) {
      equipoVisitanteColor = equipoVisitanteRaw['color'] as String?;
    }

    return PartidoListaModel(
      id: json['id'] as String? ?? json['partido_id'] as String? ?? '',
      estado: json['estado'] as String? ?? 'pendiente',
      equipoLocal:
          ColorEquipo.fromString(equipoLocalColor) ?? ColorEquipo.blanco,
      equipoVisitante:
          ColorEquipo.fromString(equipoVisitanteColor) ?? ColorEquipo.blanco,
      golesLocal: json['goles_local'] as int? ?? 0,
      golesVisitante: json['goles_visitante'] as int? ?? 0,
      duracionMinutos: json['duracion_minutos'] as int? ?? 0,
      horaInicio: json['hora_inicio'] as String?,
      horaFinEstimada: json['hora_fin_estimada'] as String?,
      createdAt: json['created_at'] as String?,
      resultado: json['resultado'] as String?,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estado': estado,
      'equipo_local': equipoLocal.toBackend(),
      'equipo_visitante': equipoVisitante.toBackend(),
      'goles_local': golesLocal,
      'goles_visitante': golesVisitante,
      'duracion_minutos': duracionMinutos,
      if (horaInicio != null) 'hora_inicio': horaInicio,
      if (horaFinEstimada != null) 'hora_fin_estimada': horaFinEstimada,
      if (createdAt != null) 'created_at': createdAt,
      if (resultado != null) 'resultado': resultado,
    };
  }

  /// Marcador formateado (ej: "2 - 1")
  String get marcador => '$golesLocal - $golesVisitante';

  /// Enfrentamiento descriptivo (ej: "Naranja vs Verde")
  String get enfrentamiento =>
      '${equipoLocal.displayName} vs ${equipoVisitante.displayName}';

  /// Indica si el partido esta activo (en_curso o pausado)
  bool get estaActivo => estado == 'en_curso' || estado == 'pausado';

  /// Indica si el partido esta finalizado
  bool get estaFinalizado => estado == 'finalizado';

  /// Indica si el partido esta en curso
  bool get estaEnCurso => estado == 'en_curso';

  /// Indica si el partido esta pausado
  bool get estaPausado => estado == 'pausado';

  /// Indica si el partido esta pendiente
  bool get estaPendiente => estado == 'pendiente';

  @override
  List<Object?> get props => [
        id,
        estado,
        equipoLocal,
        equipoVisitante,
        golesLocal,
        golesVisitante,
        duracionMinutos,
        horaInicio,
        horaFinEstimada,
        createdAt,
        resultado,
      ];
}

/// Response del RPC listar_partidos_fecha
class ListarPartidosResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Lista de partidos de la fecha
  final List<PartidoListaModel> partidos;

  /// Total de partidos en la fecha
  final int total;

  /// Indica si se puede crear un nuevo partido
  final bool puedeCrearPartido;

  /// Mensaje informativo
  final String message;

  const ListarPartidosResponseModel({
    required this.success,
    required this.partidos,
    required this.total,
    required this.puedeCrearPartido,
    required this.message,
  });

  /// Factory desde JSON del backend
  factory ListarPartidosResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final partidosList = data['partidos'] as List<dynamic>? ?? [];

    return ListarPartidosResponseModel(
      success: json['success'] as bool? ?? false,
      partidos: partidosList
          .map((p) => PartidoListaModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
      puedeCrearPartido: data['puede_crear_partido'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': {
        'partidos': partidos.map((p) => p.toJson()).toList(),
        'total': total,
        'puede_crear_partido': puedeCrearPartido,
      },
      'message': message,
    };
  }

  /// Indica si hay partidos en la lista
  bool get tienePartidos => partidos.isNotEmpty;

  /// Obtiene el partido activo (en_curso o pausado) si existe
  PartidoListaModel? get partidoActivo {
    try {
      return partidos.firstWhere((p) => p.estaActivo);
    } catch (_) {
      return null;
    }
  }

  /// Indica si hay un partido activo
  bool get hayPartidoActivo => partidoActivo != null;

  @override
  List<Object?> get props => [
        success,
        partidos,
        total,
        puedeCrearPartido,
        message,
      ];
}
