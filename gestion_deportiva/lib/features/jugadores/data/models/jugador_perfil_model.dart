import 'package:equatable/equatable.dart';

import '../../../profile/data/models/perfil_model.dart';

/// Modelo de estadisticas del jugador
/// E002-HU-004: CA-004, RN-003
class EstadisticasJugador extends Equatable {
  final int golesTotales;
  final int partidosJugados;
  final int puntosAcumulados;

  const EstadisticasJugador({
    required this.golesTotales,
    required this.partidosJugados,
    required this.puntosAcumulados,
  });

  /// Crea instancia desde JSON del backend
  factory EstadisticasJugador.fromJson(Map<String, dynamic> json) {
    return EstadisticasJugador(
      golesTotales: json['goles_totales'] ?? 0,
      partidosJugados: json['partidos_jugados'] ?? 0,
      puntosAcumulados: json['puntos_acumulados'] ?? 0,
    );
  }

  /// RN-003: Verifica si tiene estadisticas (al menos un partido)
  bool get tieneEstadisticas => partidosJugados > 0;

  /// Promedio de goles por partido
  double get promedioGoles =>
      partidosJugados > 0 ? golesTotales / partidosJugados : 0.0;

  @override
  List<Object?> get props => [golesTotales, partidosJugados, puntosAcumulados];
}

/// Modelo de perfil publico de jugador
/// E002-HU-004: Ver Perfil de Otro Jugador
/// RN-001: Solo datos publicos (foto, apodo, posicion, fecha ingreso)
/// RN-002: NO incluye email ni telefono
class JugadorPerfilModel extends Equatable {
  final String jugadorId;
  final String nombreCompleto;
  final String apodo;
  final PosicionJugador? posicionPreferida;
  final String? fotoUrl;
  final DateTime fechaIngreso;
  final String fechaIngresoFormato;
  final EstadisticasJugador estadisticas;

  const JugadorPerfilModel({
    required this.jugadorId,
    required this.nombreCompleto,
    required this.apodo,
    this.posicionPreferida,
    this.fotoUrl,
    required this.fechaIngreso,
    required this.fechaIngresoFormato,
    required this.estadisticas,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory JugadorPerfilModel.fromJson(Map<String, dynamic> json) {
    return JugadorPerfilModel(
      jugadorId: json['jugador_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      apodo: json['apodo'] ?? 'Sin apodo',
      posicionPreferida: json['posicion_preferida'] != null
          ? PosicionJugador.fromString(json['posicion_preferida'])
          : null,
      fotoUrl: json['foto_url'],
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso']).toLocal()
          : DateTime.now(),
      fechaIngresoFormato: json['fecha_ingreso_formato'] ?? '',
      estadisticas: json['estadisticas'] != null
          ? EstadisticasJugador.fromJson(
              json['estadisticas'] as Map<String, dynamic>)
          : const EstadisticasJugador(
              golesTotales: 0,
              partidosJugados: 0,
              puntosAcumulados: 0,
            ),
    );
  }

  /// Verifica si tiene foto (RN-001)
  bool get tieneFoto => fotoUrl != null && fotoUrl!.isNotEmpty;

  /// Verifica si tiene posicion (RN-001)
  bool get tienePosicion => posicionPreferida != null;

  /// Texto para mostrar posicion (CA-002, RN-001)
  String get posicionDisplay =>
      posicionPreferida?.displayName ?? 'Sin definir';

  /// Iniciales para avatar generico
  String get iniciales {
    final palabras = nombreCompleto.trim().split(' ');
    if (palabras.isEmpty) return '?';
    if (palabras.length == 1) return palabras[0][0].toUpperCase();
    return '${palabras[0][0]}${palabras[palabras.length - 1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        jugadorId,
        nombreCompleto,
        apodo,
        posicionPreferida,
        fotoUrl,
        fechaIngreso,
        fechaIngresoFormato,
        estadisticas,
      ];
}

/// Modelo de respuesta para obtener_perfil_jugador
class JugadorPerfilResponseModel extends Equatable {
  final bool success;
  final JugadorPerfilModel? data;
  final String message;

  const JugadorPerfilResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  factory JugadorPerfilResponseModel.fromJson(Map<String, dynamic> json) {
    return JugadorPerfilResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? JugadorPerfilModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
