import 'package:equatable/equatable.dart';

import '../../../data/models/models.dart';

/// Estados del bloc de Mi Actividad
/// E004-HU-008: Mi Actividad en Vivo
abstract class MiActividadState extends Equatable {
  const MiActividadState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class MiActividadInitial extends MiActividadState {
  const MiActividadInitial();
}

/// Estado cargando
class MiActividadLoading extends MiActividadState {
  const MiActividadLoading();
}

/// Estado con datos cargados
/// CA-002: Widget muestra resumen de mi actividad
/// CA-003: Lista de todos los partidos
/// CA-006: Mis goles totales de la jornada
class MiActividadLoaded extends MiActividadState {
  final MiActividadResponseModel actividad;

  const MiActividadLoaded({required this.actividad});

  @override
  List<Object?> get props => [actividad];
}

/// Estado de error
class MiActividadError extends MiActividadState {
  final String message;
  final String? hint;

  const MiActividadError({
    required this.message,
    this.hint,
  });

  @override
  List<Object?> get props => [message, hint];
}
