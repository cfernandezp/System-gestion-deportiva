import 'package:equatable/equatable.dart';

/// Modelo de usuario para lista de administracion
/// HU-005: Gestion de Roles
/// Convierte snake_case (BD) a camelCase (Dart)
class UsuarioAdminModel extends Equatable {
  final String id;
  final String nombreCompleto;
  final String email;
  final String rol;
  final String estado;
  final DateTime? createdAt;

  const UsuarioAdminModel({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.rol,
    required this.estado,
    this.createdAt,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  /// Response de listar_usuarios()
  factory UsuarioAdminModel.fromJson(Map<String, dynamic> json) {
    return UsuarioAdminModel(
      id: json['id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'jugador',
      estado: json['estado'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
    );
  }

  /// Convierte a JSON para enviar al backend
  /// Mapeo: camelCase -> snake_case
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'email': email,
      'rol': rol,
      'estado': estado,
      'created_at': createdAt?.toUtc().toIso8601String(),
    };
  }

  /// Crea copia con campos modificados
  UsuarioAdminModel copyWith({
    String? id,
    String? nombreCompleto,
    String? email,
    String? rol,
    String? estado,
    DateTime? createdAt,
  }) {
    return UsuarioAdminModel(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Obtiene nombre de rol formateado para mostrar
  /// RN-001: Roles validos del sistema
  String get rolFormateado {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'entrenador':
        return 'Entrenador';
      case 'jugador':
        return 'Jugador';
      case 'arbitro':
        return 'Arbitro';
      default:
        return rol;
    }
  }

  /// Obtiene nombre de estado formateado para mostrar
  String get estadoFormateado {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return estado;
    }
  }

  @override
  List<Object?> get props => [
        id,
        nombreCompleto,
        email,
        rol,
        estado,
        createdAt,
      ];
}

/// Modelo de respuesta de listar_usuarios()
/// HU-005: CA-001, RN-006
class ListarUsuariosResponseModel extends Equatable {
  final List<UsuarioAdminModel> usuarios;
  final int total;
  final String message;

  const ListarUsuariosResponseModel({
    required this.usuarios,
    required this.total,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  factory ListarUsuariosResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final usuariosList = data['usuarios'] as List<dynamic>? ?? [];

    return ListarUsuariosResponseModel(
      usuarios: usuariosList
          .map((u) => UsuarioAdminModel.fromJson(u as Map<String, dynamic>))
          .toList(),
      total: data['total'] ?? 0,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [usuarios, total, message];
}

/// Modelo de respuesta de cambiar_rol_usuario()
/// HU-005: CA-002, RN-005
class CambiarRolResponseModel extends Equatable {
  final String usuarioId;
  final String nombreCompleto;
  final String rolAnterior;
  final String rolNuevo;
  final bool sinCambios;
  final String message;

  const CambiarRolResponseModel({
    required this.usuarioId,
    required this.nombreCompleto,
    required this.rolAnterior,
    required this.rolNuevo,
    required this.sinCambios,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  factory CambiarRolResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return CambiarRolResponseModel(
      usuarioId: data['usuario_id'] ?? '',
      nombreCompleto: data['nombre_completo'] ?? '',
      rolAnterior: data['rol_anterior'] ?? '',
      rolNuevo: data['rol_nuevo'] ?? '',
      sinCambios: data['sin_cambios'] ?? false,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        usuarioId,
        nombreCompleto,
        rolAnterior,
        rolNuevo,
        sinCambios,
        message,
      ];
}
