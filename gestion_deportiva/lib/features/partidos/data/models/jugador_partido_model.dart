import 'package:equatable/equatable.dart';

/// Modelo de Jugador dentro de un equipo de partido
/// E004-HU-001: Iniciar Partido
class JugadorPartidoModel extends Equatable {
  final String id;
  final String nombre;
  final String? urlFoto;

  const JugadorPartidoModel({
    required this.id,
    required this.nombre,
    this.urlFoto,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory JugadorPartidoModel.fromJson(Map<String, dynamic> json) {
    return JugadorPartidoModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      urlFoto: json['url_foto'],
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'url_foto': urlFoto,
    };
  }

  @override
  List<Object?> get props => [id, nombre, urlFoto];
}
