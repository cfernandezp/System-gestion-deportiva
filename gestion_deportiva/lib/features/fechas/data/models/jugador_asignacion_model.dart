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
///   "asignado": true|false
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

  const JugadorAsignacionModel({
    required this.usuarioId,
    required this.nombreCompleto,
    this.apodo,
    this.fotoUrl,
    this.equipo,
    required this.asignado,
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
      ];
}
