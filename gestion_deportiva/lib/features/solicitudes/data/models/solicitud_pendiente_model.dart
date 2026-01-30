import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Modelo para solicitud de registro pendiente
/// E001-HU-006: Gestionar Solicitudes de Registro
///
/// Criterios de Aceptacion:
/// - CA-003: Mostrar nombre, email, fecha registro, dias pendiente
class SolicitudPendienteModel extends Equatable {
  /// ID del usuario (UUID)
  final String id;

  /// Nombre completo del usuario
  final String nombreCompleto;

  /// Email del usuario
  final String email;

  /// Estado de la solicitud (pendiente_aprobacion)
  final String estado;

  /// Fecha de creacion de la solicitud
  final DateTime createdAt;

  /// Dias que lleva pendiente la solicitud
  final int diasPendiente;

  const SolicitudPendienteModel({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.estado,
    required this.createdAt,
    required this.diasPendiente,
  });

  /// Factory para crear desde JSON del backend
  /// Mapping: snake_case (backend) -> camelCase (dart)
  factory SolicitudPendienteModel.fromJson(Map<String, dynamic> json) {
    return SolicitudPendienteModel(
      id: json['id'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      email: json['email'] as String,
      estado: json['estado'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      diasPendiente: json['dias_pendiente'] as int,
    );
  }

  /// Convierte a JSON para enviar al backend
  /// Mapping: camelCase (dart) -> snake_case (backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'email': email,
      'estado': estado,
      'created_at': createdAt.toUtc().toIso8601String(),
      'dias_pendiente': diasPendiente,
    };
  }

  /// Fecha de registro formateada para mostrar (Peru)
  String get fechaRegistroFormateada {
    final formato = DateFormat("dd 'de' MMMM 'de' yyyy", 'es_PE');
    return formato.format(createdAt);
  }

  /// Fecha de registro corta
  String get fechaRegistroCorta {
    final formato = DateFormat('dd/MM/yyyy', 'es_PE');
    return formato.format(createdAt);
  }

  /// Texto descriptivo de dias pendiente
  String get diasPendienteTexto {
    if (diasPendiente == 0) {
      return 'Hoy';
    } else if (diasPendiente == 1) {
      return 'Hace 1 dia';
    } else {
      return 'Hace $diasPendiente dias';
    }
  }

  /// Indica si la solicitud es urgente (mas de 3 dias)
  bool get esUrgente => diasPendiente > 3;

  /// Indica si la solicitud es muy urgente (mas de 7 dias)
  bool get esMuyUrgente => diasPendiente > 7;

  @override
  List<Object?> get props => [
        id,
        nombreCompleto,
        email,
        estado,
        createdAt,
        diasPendiente,
      ];
}

/// Modelo para la respuesta de obtener usuarios pendientes
/// RPC: obtener_usuarios_pendientes()
class ObtenerUsuariosPendientesResponseModel extends Equatable {
  final bool success;
  final List<SolicitudPendienteModel> usuarios;
  final int total;

  const ObtenerUsuariosPendientesResponseModel({
    required this.success,
    required this.usuarios,
    required this.total,
  });

  factory ObtenerUsuariosPendientesResponseModel.fromJson(
      Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final usuariosList = data['usuarios'] as List<dynamic>;

    return ObtenerUsuariosPendientesResponseModel(
      success: json['success'] as bool,
      usuarios: usuariosList
          .map((e) =>
              SolicitudPendienteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int,
    );
  }

  @override
  List<Object?> get props => [success, usuarios, total];
}

/// Modelo para la respuesta de aprobar usuario
/// RPC: aprobar_usuario(p_usuario_id, p_rol)
class AprobarUsuarioResponseModel extends Equatable {
  final bool success;
  final String? message;

  const AprobarUsuarioResponseModel({
    required this.success,
    this.message,
  });

  factory AprobarUsuarioResponseModel.fromJson(Map<String, dynamic> json) {
    return AprobarUsuarioResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [success, message];
}

/// Modelo para la respuesta de rechazar usuario
/// RPC: rechazar_usuario(p_usuario_id, p_motivo)
class RechazarUsuarioResponseModel extends Equatable {
  final bool success;
  final String? message;

  const RechazarUsuarioResponseModel({
    required this.success,
    this.message,
  });

  factory RechazarUsuarioResponseModel.fromJson(Map<String, dynamic> json) {
    return RechazarUsuarioResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [success, message];
}
