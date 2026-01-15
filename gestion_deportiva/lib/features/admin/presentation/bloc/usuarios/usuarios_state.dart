import 'package:equatable/equatable.dart';

import '../../../data/models/usuario_admin_model.dart';

/// Estados del Bloc de Usuarios
/// HU-005: Gestion de Roles
abstract class UsuariosState extends Equatable {
  const UsuariosState();

  @override
  List<Object?> get props => [];
}

/// Estado: Inicial (sin cargar)
class UsuariosInitial extends UsuariosState {
  const UsuariosInitial();
}

/// Estado: Cargando lista de usuarios
class UsuariosLoading extends UsuariosState {
  const UsuariosLoading();
}

/// Estado: Lista de usuarios cargada exitosamente
/// CA-001: Lista de usuarios con rol actual
class UsuariosLoaded extends UsuariosState {
  final List<UsuarioAdminModel> usuarios;
  final int total;
  final String? busquedaActual;
  final String? mensajeExito;

  const UsuariosLoaded({
    required this.usuarios,
    required this.total,
    this.busquedaActual,
    this.mensajeExito,
  });

  /// Crea copia con campos modificados
  UsuariosLoaded copyWith({
    List<UsuarioAdminModel>? usuarios,
    int? total,
    String? busquedaActual,
    String? mensajeExito,
    bool clearMensaje = false,
  }) {
    return UsuariosLoaded(
      usuarios: usuarios ?? this.usuarios,
      total: total ?? this.total,
      busquedaActual: busquedaActual ?? this.busquedaActual,
      mensajeExito: clearMensaje ? null : (mensajeExito ?? this.mensajeExito),
    );
  }

  @override
  List<Object?> get props => [usuarios, total, busquedaActual, mensajeExito];
}

/// Estado: Cambiando rol de usuario (loading parcial)
class UsuariosCambiandoRol extends UsuariosState {
  final List<UsuarioAdminModel> usuarios;
  final int total;
  final String? busquedaActual;
  final String usuarioIdCambiando;

  const UsuariosCambiandoRol({
    required this.usuarios,
    required this.total,
    this.busquedaActual,
    required this.usuarioIdCambiando,
  });

  @override
  List<Object?> get props => [usuarios, total, busquedaActual, usuarioIdCambiando];
}

/// Tipos de error para la gestion de usuarios
/// Mapean a hints del backend
enum UsuariosErrorType {
  /// Sin permisos de administrador
  /// CA-006, RN-002
  sinPermisos,

  /// Usuario intenta degradarse a si mismo
  /// CA-004, RN-003
  autoDegradacion,

  /// Es el ultimo administrador del sistema
  /// RN-004
  ultimoAdmin,

  /// Rol especificado no es valido
  /// RN-001
  rolInvalido,

  /// Usuario a modificar no existe
  usuarioNoEncontrado,

  /// Error de conexion/servidor
  servidor,
}

/// Estado: Error al cargar o modificar usuarios
class UsuariosError extends UsuariosState {
  final String message;
  final UsuariosErrorType errorType;
  final String? hint;
  final List<UsuarioAdminModel>? usuariosPrevios;
  final int? totalPrevio;
  final String? busquedaActual;

  const UsuariosError({
    required this.message,
    required this.errorType,
    this.hint,
    this.usuariosPrevios,
    this.totalPrevio,
    this.busquedaActual,
  });

  @override
  List<Object?> get props => [
        message,
        errorType,
        hint,
        usuariosPrevios,
        totalPrevio,
        busquedaActual,
      ];
}
