import 'package:equatable/equatable.dart';

/// Enum para estados del ciclo de vida de una fecha
/// E003-HU-001: RN-006
/// Estados: abierta -> cerrada -> en_juego -> finalizada
/// Alternativo: abierta -> cancelada
enum EstadoFecha {
  abierta,
  cerrada,
  enJuego,
  finalizada,
  cancelada;

  /// Convierte string de BD a enum
  /// BD usa: 'abierta', 'cerrada', 'en_juego', 'finalizada', 'cancelada'
  static EstadoFecha fromString(String value) {
    switch (value) {
      case 'abierta':
        return EstadoFecha.abierta;
      case 'cerrada':
        return EstadoFecha.cerrada;
      case 'en_juego':
        return EstadoFecha.enJuego;
      case 'finalizada':
        return EstadoFecha.finalizada;
      case 'cancelada':
        return EstadoFecha.cancelada;
      default:
        return EstadoFecha.abierta;
    }
  }

  /// Convierte enum a string para BD
  String get valor {
    switch (this) {
      case EstadoFecha.abierta:
        return 'abierta';
      case EstadoFecha.cerrada:
        return 'cerrada';
      case EstadoFecha.enJuego:
        return 'en_juego';
      case EstadoFecha.finalizada:
        return 'finalizada';
      case EstadoFecha.cancelada:
        return 'cancelada';
    }
  }

  /// Nombre para mostrar en UI
  String get displayName {
    switch (this) {
      case EstadoFecha.abierta:
        return 'Abierta';
      case EstadoFecha.cerrada:
        return 'Cerrada';
      case EstadoFecha.enJuego:
        return 'En juego';
      case EstadoFecha.finalizada:
        return 'Finalizada';
      case EstadoFecha.cancelada:
        return 'Cancelada';
    }
  }

  /// Color para UI (nombre del color, se usara con Theme)
  bool get esActiva => this == EstadoFecha.abierta || this == EstadoFecha.cerrada;
  bool get esJugando => this == EstadoFecha.enJuego;
  bool get esTerminada => this == EstadoFecha.finalizada || this == EstadoFecha.cancelada;
}

/// Modelo de Fecha de Pichanga
/// E003-HU-001: Crear Fecha
class FechaModel extends Equatable {
  final String fechaId;
  final DateTime fechaHoraInicio;
  final DateTime? fechaHoraLocal;
  final String fechaFormato;
  final String horaFormato;
  final int duracionHoras;
  final String lugar;
  final int numEquipos;
  final double costoPorJugador;
  final String costoFormato;
  final EstadoFecha estado;
  final String formatoJuego;
  final String createdBy;
  final String createdByNombre;
  final DateTime? createdAt;

  const FechaModel({
    required this.fechaId,
    required this.fechaHoraInicio,
    this.fechaHoraLocal,
    required this.fechaFormato,
    required this.horaFormato,
    required this.duracionHoras,
    required this.lugar,
    required this.numEquipos,
    required this.costoPorJugador,
    required this.costoFormato,
    required this.estado,
    required this.formatoJuego,
    required this.createdBy,
    required this.createdByNombre,
    this.createdAt,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  /// Nota: El backend puede devolver 'id' o 'fecha_id' segun el contexto
  factory FechaModel.fromJson(Map<String, dynamic> json) {
    // Obtener creador (puede venir como objeto o como strings separados)
    final creador = json['creador'] as Map<String, dynamic>?;
    final createdBy = creador?['id'] ?? json['created_by'] ?? '';
    final createdByNombre = creador?['nombre'] ?? json['created_by_nombre'] ?? '';

    return FechaModel(
      fechaId: json['id'] ?? json['fecha_id'] ?? '',
      fechaHoraInicio: json['fecha_hora_inicio'] != null
          ? DateTime.parse(json['fecha_hora_inicio']).toLocal()
          : DateTime.now(),
      fechaHoraLocal: json['fecha_hora_local'] != null
          ? DateTime.parse(json['fecha_hora_local'])
          : null,
      fechaFormato: json['fecha_formato'] ?? '',
      horaFormato: json['hora_formato'] ?? '',
      duracionHoras: json['duracion_horas'] ?? 1,
      lugar: json['lugar'] ?? '',
      numEquipos: json['num_equipos'] ?? 2,
      costoPorJugador: (json['costo_por_jugador'] ?? 0).toDouble(),
      costoFormato: json['costo_formato'] ?? 'S/ 0.00',
      estado: EstadoFecha.fromString(json['estado'] ?? 'abierta'),
      formatoJuego: json['formato_juego'] ?? '',
      createdBy: createdBy,
      createdByNombre: createdByNombre,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'fecha_id': fechaId,
      'fecha_hora_inicio': fechaHoraInicio.toUtc().toIso8601String(),
      'duracion_horas': duracionHoras,
      'lugar': lugar,
      'num_equipos': numEquipos,
      'costo_por_jugador': costoPorJugador,
      'estado': estado.valor,
    };
  }

  /// Descripcion del formato segun RN-002
  String get descripcionFormato {
    if (duracionHoras == 1) {
      return '2 equipos - Partido continuo';
    } else {
      return '3 equipos - Rotacion (ganador continua)';
    }
  }

  /// Verifica si las inscripciones estan abiertas (CA-006)
  bool get inscripcionesAbiertas => estado == EstadoFecha.abierta;

  @override
  List<Object?> get props => [
        fechaId,
        fechaHoraInicio,
        fechaHoraLocal,
        fechaFormato,
        horaFormato,
        duracionHoras,
        lugar,
        numEquipos,
        costoPorJugador,
        costoFormato,
        estado,
        formatoJuego,
        createdBy,
        createdByNombre,
        createdAt,
      ];
}
