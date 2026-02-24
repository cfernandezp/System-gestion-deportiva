import 'package:equatable/equatable.dart';

/// Eventos del BLoC MisGrupos
/// E002-HU-002: Ver Mis Grupos
abstract class MisGruposEvent extends Equatable {
  const MisGruposEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Cargar lista de mis grupos
class CargarMisGruposEvent extends MisGruposEvent {
  const CargarMisGruposEvent();
}

/// CA-004: Seleccionar grupo para acceder
/// RN-003: Registra ultimo_acceso al entrar
class SeleccionarGrupoEvent extends MisGruposEvent {
  final String grupoId;

  const SeleccionarGrupoEvent({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}
