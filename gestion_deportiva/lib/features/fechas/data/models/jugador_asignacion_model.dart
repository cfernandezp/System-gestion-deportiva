import 'package:equatable/equatable.dart';

import 'color_equipo.dart';

/// Modelo de un jugador con su asignacion de equipo
/// E003-HU-005: Asignar Equipos
/// CA-001: Veo la lista de inscritos a la izquierda
/// CA-004, CA-005: Jugador puede asignarse a equipo
///
/// JSON esperado del RPC obtener_asignaciones:
/// {
///   "usuario_id": "uuid",
///   "nombre_completo": "string",
///   "apodo": "string|null",
///   "foto_url": "string|null",
///   "equipo": "naranja|verde|azul|null",
///   "asignado": true|false,
///   "inscripcion_id": "uuid",
///   "inscripcion_tardia": false
/// }
class JugadorAsignacionModel extends Equatable {
  /// ID del usuario inscrito
  final String usuarioId;

  /// Nombre completo del jugador
  final String nombreCompleto;

  /// Apodo del jugador (opcional)
  final String? apodo;

  /// URL de la foto de perfil (opcional)
  final String? fotoUrl;

  /// Equipo asignado (null si no tiene equipo)
  final ColorEquipo? equipo;

  /// Indica si el jugador ya tiene equipo asignado
  final bool asignado;

  /// ID de la inscripcion (para marcar ausente)
  final String? inscripcionId;

  /// Indica si fue inscripcion tardia (durante en_juego)
  final bool inscripcionTardia;

  const JugadorAsignacionModel({
    required this.usuarioId,
    required this.nombreCompleto,
    this.apodo,
    this.fotoUrl,
    this.equipo,
    required this.asignado,
    this.inscripcionId,
    this.inscripcionTardia = false,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory JugadorAsignacionModel.fromJson(Map<String, dynamic> json) {
    return JugadorAsignacionModel(
      usuarioId: json['usuario_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      apodo: json['apodo'],
      fotoUrl: json['foto_url'],
      equipo: ColorEquipo.fromString(json['equipo']),
      asignado: json['asignado'] ?? false,
      inscripcionId: json['inscripcion_id'],
      inscripcionTardia: json['inscripcion_tardia'] ?? false,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'nombre_completo': nombreCompleto,
      'apodo': apodo,
      'foto_url': fotoUrl,
      'equipo': equipo?.toBackend(),
      'asignado': asignado,
      'inscripcion_id': inscripcionId,
      'inscripcion_tardia': inscripcionTardia,
    };
  }

  /// Nombre para mostrar en la UI
  /// Prioriza apodo si existe
  String get displayName {
    if (apodo != null && apodo!.isNotEmpty) {
      return apodo!;
    }
    return nombreCompleto;
  }

  /// Copia con nuevo equipo asignado
  JugadorAsignacionModel copyWithEquipo(ColorEquipo? nuevoEquipo) {
    return JugadorAsignacionModel(
      usuarioId: usuarioId,
      nombreCompleto: nombreCompleto,
      apodo: apodo,
      fotoUrl: fotoUrl,
      equipo: nuevoEquipo,
      asignado: nuevoEquipo != null,
      inscripcionId: inscripcionId,
      inscripcionTardia: inscripcionTardia,
    );
  }

  @override
  List<Object?> get props => [
        usuarioId,
        nombreCompleto,
        apodo,
        fotoUrl,
        equipo,
        asignado,
        inscripcionId,
        inscripcionTardia,
      ];
}

/// Modelo de un jugador ausente
/// JSON esperado del RPC obtener_asignaciones (seccion ausentes):
/// {
///   "usuario_id": "uuid",
///   "nombre_completo": "string",
///   "apodo": "string|null",
///   "inscripcion_id": "uuid"
/// }
class JugadorAusenteModel extends Equatable {
  final String usuarioId;
  final String nombreCompleto;
  final String? apodo;
  final String inscripcionId;

  const JugadorAusenteModel({
    required this.usuarioId,
    required this.nombreCompleto,
    this.apodo,
    required this.inscripcionId,
  });

  factory JugadorAusenteModel.fromJson(Map<String, dynamic> json) {
    return JugadorAusenteModel(
      usuarioId: json['usuario_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      apodo: json['apodo'],
      inscripcionId: json['inscripcion_id'] ?? '',
    );
  }

  String get displayName {
    if (apodo != null && apodo!.isNotEmpty) {
      return apodo!;
    }
    return nombreCompleto;
  }

  @override
  List<Object?> get props => [usuarioId, nombreCompleto, apodo, inscripcionId];
}
