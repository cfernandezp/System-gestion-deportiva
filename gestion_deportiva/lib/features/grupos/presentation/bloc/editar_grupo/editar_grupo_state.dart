import 'package:equatable/equatable.dart';

import '../../../data/models/editar_grupo_response_model.dart';
import '../../../data/models/grupo_model.dart';

/// Estados del BLoC EditarGrupo
/// E002-HU-003: Editar Grupo Deportivo
abstract class EditarGrupoState extends Equatable {
  const EditarGrupoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class EditarGrupoInitial extends EditarGrupoState {
  const EditarGrupoInitial();
}

/// Cargando detalle del grupo
class EditarGrupoLoading extends EditarGrupoState {
  const EditarGrupoLoading();
}

/// Detalle del grupo cargado exitosamente
/// CA-001: Pre-cargar formulario con datos actuales
class EditarGrupoDetalleCargado extends EditarGrupoState {
  final GrupoModel grupo;

  const EditarGrupoDetalleCargado({required this.grupo});

  @override
  List<Object?> get props => [grupo];
}

/// Subiendo logo (loading parcial)
class EditarGrupoSubiendoLogo extends EditarGrupoState {
  const EditarGrupoSubiendoLogo();
}

/// Guardando cambios
class EditarGrupoGuardando extends EditarGrupoState {
  const EditarGrupoGuardando();
}

/// Grupo editado exitosamente
class EditarGrupoSuccess extends EditarGrupoState {
  final EditarGrupoResponseModel response;

  const EditarGrupoSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// Error al editar grupo
class EditarGrupoError extends EditarGrupoState {
  final String message;
  final String? hint;

  const EditarGrupoError({required this.message, this.hint});

  @override
  List<Object?> get props => [message, hint];
}
