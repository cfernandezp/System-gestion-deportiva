import 'package:equatable/equatable.dart';

import '../../../data/models/mi_grupo_model.dart';

/// Estados del BLoC MisGrupos
/// E002-HU-002: Ver Mis Grupos
abstract class MisGruposState extends Equatable {
  const MisGruposState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class MisGruposInitial extends MisGruposState {
  const MisGruposInitial();
}

/// Cargando lista de grupos
class MisGruposLoading extends MisGruposState {
  const MisGruposLoading();
}

/// CA-001: Lista de grupos cargada exitosamente
class MisGruposLoaded extends MisGruposState {
  final List<MiGrupoModel> grupos;

  const MisGruposLoaded({required this.grupos});

  @override
  List<Object?> get props => [grupos];
}

/// CA-005: Usuario sin grupos
class MisGruposEmpty extends MisGruposState {
  const MisGruposEmpty();
}

/// Error al cargar grupos
class MisGruposError extends MisGruposState {
  final String message;

  const MisGruposError({required this.message});

  @override
  List<Object?> get props => [message];
}
