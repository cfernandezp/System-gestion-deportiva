import 'package:equatable/equatable.dart';

import '../../../data/models/crear_grupo_response_model.dart';

/// Estados del BLoC CrearGrupo
/// E002-HU-001: Crear Grupo Deportivo
abstract class CrearGrupoState extends Equatable {
  const CrearGrupoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CrearGrupoInitial extends CrearGrupoState {
  const CrearGrupoInitial();
}

/// Creando grupo (loading)
class CrearGrupoLoading extends CrearGrupoState {
  const CrearGrupoLoading();
}

/// Subiendo logo (loading parcial)
class CrearGrupoSubiendoLogo extends CrearGrupoState {
  const CrearGrupoSubiendoLogo();
}

/// Grupo creado exitosamente
/// CA-001: Redirigir a gestion del grupo
class CrearGrupoSuccess extends CrearGrupoState {
  final CrearGrupoResponseModel response;

  const CrearGrupoSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// Error al crear grupo
class CrearGrupoError extends CrearGrupoState {
  final String message;
  final String? hint;

  const CrearGrupoError({required this.message, this.hint});

  @override
  List<Object?> get props => [message, hint];
}

/// CA-006: Limite de grupos alcanzado segun plan
/// Debe sugerir actualizar plan
class CrearGrupoLimiteAlcanzado extends CrearGrupoState {
  final String message;
  final int limiteActual;

  const CrearGrupoLimiteAlcanzado({
    required this.message,
    required this.limiteActual,
  });

  @override
  List<Object?> get props => [message, limiteActual];
}
