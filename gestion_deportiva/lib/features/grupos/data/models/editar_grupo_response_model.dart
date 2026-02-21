import 'package:equatable/equatable.dart';

/// Modelo de respuesta al editar un grupo
/// E002-HU-003: Mapea la respuesta JSON de la RPC editar_grupo
class EditarGrupoResponseModel extends Equatable {
  final String grupoId;
  final String nombre;
  final String? logoUrl;
  final String? lema;
  final String? reglas;
  final String mensaje;

  const EditarGrupoResponseModel({
    required this.grupoId,
    required this.nombre,
    this.logoUrl,
    this.lema,
    this.reglas,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Response format: { success: true, message: '...', data: { grupo_id, nombre, logo_url, lema, reglas } }
  factory EditarGrupoResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return EditarGrupoResponseModel(
      grupoId: data['grupo_id'] ?? '',
      nombre: data['nombre'] ?? '',
      logoUrl: data['logo_url'],
      lema: data['lema'],
      reglas: data['reglas'],
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [grupoId, nombre, logoUrl, lema, reglas, mensaje];
}
