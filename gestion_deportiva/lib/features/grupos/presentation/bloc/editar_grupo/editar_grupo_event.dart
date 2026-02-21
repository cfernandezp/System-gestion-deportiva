import 'dart:io';

import 'package:equatable/equatable.dart';

/// Eventos del BLoC EditarGrupo
/// E002-HU-003: Editar Grupo Deportivo
abstract class EditarGrupoEvent extends Equatable {
  const EditarGrupoEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Cargar detalle del grupo para precargar formulario
class CargarDetalleGrupoEvent extends EditarGrupoEvent {
  final String grupoId;

  const CargarDetalleGrupoEvent({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}

/// CA-002: Enviar formulario de edicion del grupo
class EditarGrupoSubmitEvent extends EditarGrupoEvent {
  final String grupoId;
  final String nombre;
  final String? lema;
  final String? reglas;
  final File? imagenLogo;

  const EditarGrupoSubmitEvent({
    required this.grupoId,
    required this.nombre,
    this.lema,
    this.reglas,
    this.imagenLogo,
  });

  @override
  List<Object?> get props => [grupoId, nombre, lema, reglas, imagenLogo];
}
