import 'package:equatable/equatable.dart';

import '../../../data/models/perfil_model.dart';

/// Estados del BLoC de Perfil
/// E002-HU-001: Ver Perfil Propio
abstract class PerfilState extends Equatable {
  const PerfilState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - sin datos cargados
class PerfilInitial extends PerfilState {
  const PerfilInitial();
}

/// Estado de carga - obteniendo perfil del servidor
class PerfilLoading extends PerfilState {
  const PerfilLoading();
}

/// Estado de exito - perfil cargado correctamente
/// CA-002: Datos visibles del perfil
class PerfilLoaded extends PerfilState {
  final PerfilModel perfil;

  const PerfilLoaded({required this.perfil});

  @override
  List<Object?> get props => [perfil];
}

/// Estado de error - fallo al obtener perfil
class PerfilError extends PerfilState {
  final String message;
  final String? code;
  final String? hint;

  const PerfilError({
    required this.message,
    this.code,
    this.hint,
  });

  @override
  List<Object?> get props => [message, code, hint];
}

/// Estado de recarga - actualizando perfil (pull to refresh)
class PerfilRefreshing extends PerfilState {
  final PerfilModel perfilActual;

  const PerfilRefreshing({required this.perfilActual});

  @override
  List<Object?> get props => [perfilActual];
}

/// E002-HU-002: Estado de guardado - actualizando perfil
class PerfilSaving extends PerfilState {
  final PerfilModel perfilActual;

  const PerfilSaving({required this.perfilActual});

  @override
  List<Object?> get props => [perfilActual];
}

/// E002-HU-002: Estado de exito al actualizar - CA-004
class PerfilUpdateSuccess extends PerfilState {
  final PerfilModel perfil;
  final String message;

  const PerfilUpdateSuccess({
    required this.perfil,
    required this.message,
  });

  @override
  List<Object?> get props => [perfil, message];
}

/// E002-HU-002: Estado de error al actualizar - CA-005
class PerfilUpdateError extends PerfilState {
  final PerfilModel perfilActual;
  final String message;
  final String? code;
  final String? hint;

  const PerfilUpdateError({
    required this.perfilActual,
    required this.message,
    this.code,
    this.hint,
  });

  /// Verifica si es error de apodo duplicado (CA-005)
  bool get isApodoDuplicado => hint == 'apodo_duplicado';

  @override
  List<Object?> get props => [perfilActual, message, code, hint];
}
