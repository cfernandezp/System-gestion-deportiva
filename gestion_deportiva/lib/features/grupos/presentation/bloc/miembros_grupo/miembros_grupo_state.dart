import 'package:equatable/equatable.dart';

import '../../../data/models/miembro_grupo_model.dart';

/// Estados del Bloc MiembrosGrupo
/// E001-HU-004 CA-005: Ver lista de miembros
abstract class MiembrosGrupoState extends Equatable {
  const MiembrosGrupoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class MiembrosGrupoInitial extends MiembrosGrupoState {}

/// Cargando miembros
class MiembrosGrupoLoading extends MiembrosGrupoState {}

/// Miembros cargados exitosamente
class MiembrosGrupoLoaded extends MiembrosGrupoState {
  final List<MiembroGrupoModel> miembros;

  const MiembrosGrupoLoaded(this.miembros);

  /// Cantidad total de miembros
  int get total => miembros.length;

  /// Miembros pendientes de activacion
  List<MiembroGrupoModel> get pendientes =>
      miembros.where((m) => m.estaPendiente).toList();

  /// Miembros activos
  List<MiembroGrupoModel> get activos =>
      miembros.where((m) => !m.estaPendiente).toList();

  @override
  List<Object?> get props => [miembros];
}

/// Error al cargar miembros
class MiembrosGrupoError extends MiembrosGrupoState {
  final String message;

  const MiembrosGrupoError(this.message);

  @override
  List<Object?> get props => [message];
}
