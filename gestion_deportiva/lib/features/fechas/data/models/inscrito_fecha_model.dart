import 'package:equatable/equatable.dart';

/// Modelo de un jugador inscrito a una fecha
/// E003-HU-003: Ver Inscritos
/// Representa cada miembro inscrito segun respuesta del RPC obtener_inscritos_fecha
///
/// CA-002: Informacion de cada inscrito (foto, apodo, posicion)
/// CA-005: es_usuario_actual para destacar inscripcion propia
/// RN-002: Solo campos publicos
/// RN-003: Orden por inscripcion (usar campo orden)
class InscritoFechaModel extends Equatable {
  /// ID del usuario inscrito
  final String usuarioId;

  /// URL de la foto de perfil (si tiene)
  /// RN-002: Campo publico permitido
  final String? fotoUrl;

  /// Apodo del jugador
  /// RN-002: Campo publico permitido
  final String apodo;

  /// Nombre completo del jugador
  /// RN-002: Campo publico permitido
  final String nombreCompleto;

  /// Posicion preferida del jugador (si tiene)
  /// RN-002: Campo publico permitido
  final String? posicionPreferida;

  /// CA-005: Indica si es el usuario actual logueado
  /// Se usa para destacar "(Tu)" en la lista
  final bool esUsuarioActual;

  /// Fecha/hora de inscripcion (timestamp)
  final DateTime? inscritoAt;

  /// Fecha de inscripcion formateada (DD/MM/YYYY HH:MI)
  final String? inscritoFormato;

  const InscritoFechaModel({
    required this.usuarioId,
    this.fotoUrl,
    required this.apodo,
    required this.nombreCompleto,
    this.posicionPreferida,
    required this.esUsuarioActual,
    this.inscritoAt,
    this.inscritoFormato,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  /// JSON esperado del RPC obtener_inscritos_fecha:
  /// {
  ///   "usuario_id": "uuid",
  ///   "foto_url": "string|null",
  ///   "apodo": "string",
  ///   "nombre_completo": "string",
  ///   "posicion_preferida": "string|null",
  ///   "es_usuario_actual": true|false,
  ///   "inscrito_at": "timestamp",
  ///   "inscrito_formato": "DD/MM/YYYY HH:MI"
  /// }
  factory InscritoFechaModel.fromJson(Map<String, dynamic> json) {
    return InscritoFechaModel(
      usuarioId: json['usuario_id'] ?? '',
      fotoUrl: json['foto_url'],
      apodo: json['apodo'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      posicionPreferida: json['posicion_preferida'],
      esUsuarioActual: json['es_usuario_actual'] ?? false,
      inscritoAt: json['inscrito_at'] != null
          ? DateTime.parse(json['inscrito_at']).toLocal()
          : null,
      inscritoFormato: json['inscrito_formato'],
    );
  }

  /// Convierte a JSON (para posibles envios)
  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'foto_url': fotoUrl,
      'apodo': apodo,
      'nombre_completo': nombreCompleto,
      'posicion_preferida': posicionPreferida,
      'es_usuario_actual': esUsuarioActual,
      'inscrito_at': inscritoAt?.toUtc().toIso8601String(),
      'inscrito_formato': inscritoFormato,
    };
  }

  /// Nombre para mostrar:
  /// Si es usuario actual, agregar "(Tu)"
  /// CA-005: Mi inscripcion destacada
  String get nombreDisplay {
    final nombre = apodo.isNotEmpty ? apodo : nombreCompleto;
    return esUsuarioActual ? '$nombre (Tu)' : nombre;
  }

  /// Nombre sin indicador de usuario actual
  String get nombreSinIndicador {
    return apodo.isNotEmpty ? apodo : nombreCompleto;
  }

  @override
  List<Object?> get props => [
        usuarioId,
        fotoUrl,
        apodo,
        nombreCompleto,
        posicionPreferida,
        esUsuarioActual,
        inscritoAt,
        inscritoFormato,
      ];
}
