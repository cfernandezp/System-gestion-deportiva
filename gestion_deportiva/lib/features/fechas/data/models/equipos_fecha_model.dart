import 'color_equipo.dart';
import 'mi_equipo_model.dart';

/// Modelo para la respuesta de obtener_equipos_fecha RPC
/// E003-HU-006: Ver Mi Equipo
/// CA-004: Ver todos los equipos
/// RN-002: Visibilidad de Todos los Equipos
class EquiposFechaResponseModel {
  final bool success;
  final EquiposFechaDataModel? data;
  final String message;

  EquiposFechaResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  factory EquiposFechaResponseModel.fromJson(Map<String, dynamic> json) {
    return EquiposFechaResponseModel(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? EquiposFechaDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String? ?? '',
    );
  }
}

/// Modelo con los datos de todos los equipos de una fecha
class EquiposFechaDataModel {
  final bool equiposAsignados;
  final List<EquipoCompletoModel> equipos;
  final int totalEquipos;
  final int? miEquipoNumero;
  final String? miColorEquipo;
  final bool estaInscrito;
  final FechaResumenModel? fecha;

  EquiposFechaDataModel({
    required this.equiposAsignados,
    this.equipos = const [],
    this.totalEquipos = 0,
    this.miEquipoNumero,
    this.miColorEquipo,
    this.estaInscrito = false,
    this.fecha,
  });

  factory EquiposFechaDataModel.fromJson(Map<String, dynamic> json) {
    return EquiposFechaDataModel(
      equiposAsignados: json['equipos_asignados'] as bool? ?? false,
      equipos: (json['equipos'] as List<dynamic>?)
              ?.map((e) =>
                  EquipoCompletoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalEquipos: json['total_equipos'] as int? ?? 0,
      miEquipoNumero: json['mi_equipo_numero'] as int?,
      miColorEquipo: json['mi_color_equipo'] as String?,
      estaInscrito: json['esta_inscrito'] as bool? ?? false,
      fecha: json['fecha'] != null
          ? FechaResumenModel.fromJson(json['fecha'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Modelo de un equipo completo con todos sus jugadores
/// CA-004: Muestra los 2 o 3 equipos con sus jugadores
class EquipoCompletoModel {
  final int numeroEquipo;
  final String colorEquipo;
  final String nombreEquipo;
  final String colorHex;
  final bool esMiEquipo;
  final List<CompaneroModel> jugadores;
  final int totalJugadores;

  EquipoCompletoModel({
    required this.numeroEquipo,
    required this.colorEquipo,
    required this.nombreEquipo,
    required this.colorHex,
    this.esMiEquipo = false,
    this.jugadores = const [],
    this.totalJugadores = 0,
  });

  factory EquipoCompletoModel.fromJson(Map<String, dynamic> json) {
    return EquipoCompletoModel(
      numeroEquipo: json['numero_equipo'] as int? ?? 0,
      colorEquipo: json['color_equipo'] as String? ?? '',
      nombreEquipo: json['nombre_equipo'] as String? ?? '',
      colorHex: json['color_hex'] as String? ?? '#9E9E9E',
      esMiEquipo: json['es_mi_equipo'] as bool? ?? false,
      jugadores: (json['jugadores'] as List<dynamic>?)
              ?.map((e) => CompaneroModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalJugadores: json['total_jugadores'] as int? ?? 0,
    );
  }

  /// Obtiene el ColorEquipo enum
  ColorEquipo? get colorEquipoEnum => ColorEquipo.fromString(colorEquipo);
}

/// Modelo resumen de fecha para contexto
class FechaResumenModel {
  final String id;
  final DateTime? fechaHoraInicio;
  final String fechaFormato;
  final String horaFormato;
  final String lugar;
  final int numEquipos;
  final String estado;

  FechaResumenModel({
    required this.id,
    this.fechaHoraInicio,
    required this.fechaFormato,
    required this.horaFormato,
    required this.lugar,
    required this.numEquipos,
    required this.estado,
  });

  factory FechaResumenModel.fromJson(Map<String, dynamic> json) {
    return FechaResumenModel(
      id: json['id'] as String? ?? '',
      fechaHoraInicio: json['fecha_hora_inicio'] != null
          ? DateTime.tryParse(json['fecha_hora_inicio'].toString())
          : null,
      fechaFormato: json['fecha_formato'] as String? ?? '',
      horaFormato: json['hora_formato'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      numEquipos: json['num_equipos'] as int? ?? 2,
      estado: json['estado'] as String? ?? '',
    );
  }
}
