import 'package:equatable/equatable.dart';

/// Modelo de un jugador inscrito a una fecha
/// E003-HU-002: CA-001, CA-006
/// Representa cada miembro inscrito en la lista de inscritos
class InscritoModel extends Equatable {
  /// ID del miembro inscrito
  final String miembroId;

  /// Nombre completo del jugador
  final String nombreCompleto;

  /// Apodo del jugador (si tiene)
  final String? apodo;

  /// Posicion preferida del jugador
  final String? posicion;

  /// URL de la foto de perfil (si tiene)
  final String? fotoUrl;

  /// Fecha de inscripcion
  final DateTime fechaInscripcion;

  /// Estado de la inscripcion
  final String estado;

  const InscritoModel({
    required this.miembroId,
    required this.nombreCompleto,
    this.apodo,
    this.posicion,
    this.fotoUrl,
    required this.fechaInscripcion,
    required this.estado,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory InscritoModel.fromJson(Map<String, dynamic> json) {
    return InscritoModel(
      miembroId: json['miembro_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      apodo: json['apodo'],
      posicion: json['posicion'],
      fotoUrl: json['foto_url'],
      fechaInscripcion: json['fecha_inscripcion'] != null
          ? DateTime.parse(json['fecha_inscripcion']).toLocal()
          : DateTime.now(),
      estado: json['estado'] ?? 'confirmada',
    );
  }

  /// Nombre para mostrar (apodo si existe, sino nombre)
  String get nombreDisplay => apodo ?? nombreCompleto;

  /// Verifica si la inscripcion esta activa
  bool get estaActivo => estado == 'confirmada';

  @override
  List<Object?> get props => [
        miembroId,
        nombreCompleto,
        apodo,
        posicion,
        fotoUrl,
        fechaInscripcion,
        estado,
      ];
}
