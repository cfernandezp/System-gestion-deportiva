import 'package:equatable/equatable.dart';

/// Modelo de respuesta al crear un grupo
/// E002-HU-001: Mapea la respuesta JSON de la RPC crear_grupo
class CrearGrupoResponseModel extends Equatable {
  final String grupoId;
  final String nombre;
  final String mensaje;

  const CrearGrupoResponseModel({
    required this.grupoId,
    required this.nombre,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  factory CrearGrupoResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return CrearGrupoResponseModel(
      grupoId: data['grupo_id'] ?? '',
      nombre: data['nombre'] ?? '',
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [grupoId, nombre, mensaje];
}
