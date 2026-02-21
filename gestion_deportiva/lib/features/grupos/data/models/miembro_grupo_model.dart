import 'package:equatable/equatable.dart';

/// Modelo de un miembro del grupo
/// E001-HU-004 CA-005: Ver lista de jugadores con estado
class MiembroGrupoModel extends Equatable {
  final String miembroId;
  final String usuarioId;
  final String grupoId;
  final String rol;
  final bool activo;
  final String? nombre;
  final String celular;
  final String estadoUsuario;
  final String? apodo;
  final String? fotoUrl;
  final DateTime? createdAt;

  const MiembroGrupoModel({
    required this.miembroId,
    required this.usuarioId,
    required this.grupoId,
    required this.rol,
    required this.activo,
    this.nombre,
    required this.celular,
    required this.estadoUsuario,
    this.apodo,
    this.fotoUrl,
    this.createdAt,
  });

  factory MiembroGrupoModel.fromJson(Map<String, dynamic> json) {
    return MiembroGrupoModel(
      miembroId: json['miembro_id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      grupoId: json['grupo_id'] ?? '',
      rol: json['rol'] ?? 'jugador',
      activo: json['activo'] ?? true,
      nombre: json['nombre'],
      celular: json['celular'] ?? '',
      estadoUsuario: json['estado_usuario'] ?? '',
      apodo: json['apodo'],
      fotoUrl: json['foto_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// CA-005: Si esta pendiente de activacion
  bool get estaPendiente => estadoUsuario == 'pendiente_aprobacion';

  /// CA-005: Nombre o celular para mostrar
  String get displayName {
    if (nombre != null && nombre!.isNotEmpty) return nombre!;
    if (apodo != null && apodo!.isNotEmpty) return apodo!;
    return celular;
  }

  /// Rol formateado para UI
  String get rolFormateado {
    switch (rol) {
      case 'admin':
        return 'Admin';
      case 'coadmin':
        return 'Co-Admin';
      case 'jugador':
        return 'Jugador';
      case 'invitado':
        return 'Invitado';
      default:
        return rol;
    }
  }

  /// Estado formateado para UI
  String get estadoFormateado {
    if (estaPendiente) return 'Pendiente de activacion';
    return 'Activo';
  }

  @override
  List<Object?> get props => [
        miembroId,
        usuarioId,
        grupoId,
        rol,
        activo,
        nombre,
        celular,
        estadoUsuario,
        apodo,
        fotoUrl,
        createdAt,
      ];
}
