import 'package:equatable/equatable.dart';

/// Modelo de jugador dentro de un equipo de partido
/// E004-HU-001: Iniciar Partido
/// Representa un jugador asignado a un equipo en el partido
class JugadorPartidoModel extends Equatable {
  final String id;
  final String nombreCompleto;
  final String? apodo;

  const JugadorPartidoModel({
    required this.id,
    required this.nombreCompleto,
    this.apodo,
  });

  /// Factory desde JSON del backend
  /// Mapea snake_case a camelCase
  factory JugadorPartidoModel.fromJson(Map<String, dynamic> json) {
    return JugadorPartidoModel(
      id: json['id'] as String? ?? '',
      nombreCompleto: json['nombre_completo'] as String? ?? 'Sin nombre',
      apodo: json['apodo'] as String?,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'apodo': apodo,
    };
  }

  /// Nombre para mostrar (apodo si existe, sino nombre completo)
  String get displayName => apodo ?? nombreCompleto;

  @override
  List<Object?> get props => [id, nombreCompleto, apodo];
}
