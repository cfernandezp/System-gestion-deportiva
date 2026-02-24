import 'dart:io';

import 'package:equatable/equatable.dart';

/// Eventos del BLoC CrearGrupo
/// E002-HU-001: Crear Grupo Deportivo
abstract class CrearGrupoEvent extends Equatable {
  const CrearGrupoEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Enviar formulario de creacion de grupo
class CrearGrupoSubmitEvent extends CrearGrupoEvent {
  final String nombre;
  final String? lema;
  final String? reglas;
  final File? imagenLogo;

  const CrearGrupoSubmitEvent({
    required this.nombre,
    this.lema,
    this.reglas,
    this.imagenLogo,
  });

  @override
  List<Object?> get props => [nombre, lema, reglas, imagenLogo];
}
