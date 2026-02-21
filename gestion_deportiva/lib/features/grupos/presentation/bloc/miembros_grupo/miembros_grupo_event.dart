import 'package:equatable/equatable.dart';

/// Eventos del Bloc MiembrosGrupo
/// E001-HU-004 CA-005: Ver lista de miembros
abstract class MiembrosGrupoEvent extends Equatable {
  const MiembrosGrupoEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar miembros del grupo
class CargarMiembrosGrupoEvent extends MiembrosGrupoEvent {
  final String grupoId;

  const CargarMiembrosGrupoEvent({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}
