import 'package:equatable/equatable.dart';

/// Modelo de respuesta al invitar un jugador al grupo
/// E001-HU-004: Invitar Jugador al Grupo
class InvitarJugadorResponseModel extends Equatable {
  final String usuarioId;
  final String celular;
  final String nombre;
  final String estadoUsuario;
  final bool esNuevo;
  final String message;

  const InvitarJugadorResponseModel({
    required this.usuarioId,
    required this.celular,
    required this.nombre,
    required this.estadoUsuario,
    required this.esNuevo,
    required this.message,
  });

  factory InvitarJugadorResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return InvitarJugadorResponseModel(
      usuarioId: data['usuario_id'] ?? '',
      celular: data['celular'] ?? '',
      nombre: data['nombre'] ?? '',
      estadoUsuario: data['estado_usuario'] ?? '',
      esNuevo: data['es_nuevo'] ?? true,
      message: json['message'] ?? '',
    );
  }

  /// CA-005: Si esta pendiente de activacion
  bool get estaPendiente => estadoUsuario == 'pendiente_aprobacion';

  /// CA-005: Texto para mostrar en UI
  String get displayName => nombre.isNotEmpty ? nombre : celular;

  @override
  List<Object?> get props => [usuarioId, celular, nombre, estadoUsuario, esNuevo, message];
}
