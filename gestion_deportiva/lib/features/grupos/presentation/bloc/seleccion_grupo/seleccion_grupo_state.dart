import 'package:equatable/equatable.dart';

import '../../../data/models/mi_grupo_model.dart';

/// Estados del BLoC SeleccionGrupo
/// E001-HU-003: Seleccion de Grupo Post-Login
abstract class SeleccionGrupoState extends Equatable {
  const SeleccionGrupoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class SeleccionGrupoInitial extends SeleccionGrupoState {
  const SeleccionGrupoInitial();
}

/// Cargando grupos
class SeleccionGrupoLoading extends SeleccionGrupoState {
  const SeleccionGrupoLoading();
}

/// CA-003 / RN-001: Solo 1 grupo, auto-seleccionado
/// La UI debe navegar directamente al home
class SeleccionGrupoAutoSeleccionado extends SeleccionGrupoState {
  final MiGrupoModel grupo;

  const SeleccionGrupoAutoSeleccionado({required this.grupo});

  @override
  List<Object?> get props => [grupo];
}

/// CA-001: Multiples grupos, mostrar lista para seleccion
/// CA-004 / RN-003: Ordenados por ultimo_acceso (el primero es el mas reciente)
class SeleccionGrupoLista extends SeleccionGrupoState {
  final List<MiGrupoModel> grupos;

  const SeleccionGrupoLista({required this.grupos});

  @override
  List<Object?> get props => [grupos];
}

/// CA-002: Grupo seleccionado exitosamente
/// La UI debe navegar al home con contexto del grupo
class SeleccionGrupoCompletada extends SeleccionGrupoState {
  final MiGrupoModel grupo;

  const SeleccionGrupoCompletada({required this.grupo});

  @override
  List<Object?> get props => [grupo];
}

/// Sin grupos: usuario no pertenece a ningun grupo
class SeleccionGrupoSinGrupos extends SeleccionGrupoState {
  const SeleccionGrupoSinGrupos();
}

/// Error al cargar grupos
class SeleccionGrupoError extends SeleccionGrupoState {
  final String message;

  const SeleccionGrupoError({required this.message});

  @override
  List<Object?> get props => [message];
}
