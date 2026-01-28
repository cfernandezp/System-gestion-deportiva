import 'package:equatable/equatable.dart';

import '../../../data/models/mi_equipo_model.dart';
import '../../../data/models/equipos_fecha_model.dart';

/// Estados del BLoC de Mi Equipo
/// E003-HU-006: Ver Mi Equipo
abstract class MiEquipoState extends Equatable {
  const MiEquipoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class MiEquipoInitial extends MiEquipoState {
  const MiEquipoInitial();
}

/// Estado de carga
class MiEquipoLoading extends MiEquipoState {
  const MiEquipoLoading();
}

/// Estado con mi equipo cargado exitosamente
/// CA-001, CA-002, CA-003
class MiEquipoCargado extends MiEquipoState {
  final MiEquipoDataModel data;
  final bool actualizadoRealtime;

  const MiEquipoCargado({
    required this.data,
    this.actualizadoRealtime = false,
  });

  @override
  List<Object?> get props => [data, actualizadoRealtime];

  /// Copia con nuevos valores
  MiEquipoCargado copyWith({
    MiEquipoDataModel? data,
    bool? actualizadoRealtime,
  }) {
    return MiEquipoCargado(
      data: data ?? this.data,
      actualizadoRealtime: actualizadoRealtime ?? false,
    );
  }
}

/// Estado con todos los equipos de la fecha cargados
/// CA-004
class EquiposFechaCargados extends MiEquipoState {
  final EquiposFechaDataModel data;
  final bool actualizadoRealtime;

  const EquiposFechaCargados({
    required this.data,
    this.actualizadoRealtime = false,
  });

  @override
  List<Object?> get props => [data, actualizadoRealtime];

  /// Copia con nuevos valores
  EquiposFechaCargados copyWith({
    EquiposFechaDataModel? data,
    bool? actualizadoRealtime,
  }) {
    return EquiposFechaCargados(
      data: data ?? this.data,
      actualizadoRealtime: actualizadoRealtime ?? false,
    );
  }
}

/// Estado cuando no hay equipos asignados
/// CA-005
class EquiposPendientes extends MiEquipoState {
  final bool estaInscrito;
  final String mensaje;

  const EquiposPendientes({
    required this.estaInscrito,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [estaInscrito, mensaje];
}

/// Estado cuando el usuario no esta inscrito
/// CA-006
class NoInscrito extends MiEquipoState {
  final String mensaje;

  const NoInscrito({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

/// Estado de error
class MiEquipoError extends MiEquipoState {
  final String message;

  const MiEquipoError({required this.message});

  @override
  List<Object?> get props => [message];
}
