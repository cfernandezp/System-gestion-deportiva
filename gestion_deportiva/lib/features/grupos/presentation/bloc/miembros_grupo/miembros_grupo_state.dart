import 'package:equatable/equatable.dart';

import '../../../data/models/miembro_grupo_model.dart';

/// Estados del Bloc MiembrosGrupo
/// E002-HU-005: Ver Miembros del Grupo
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
/// E002-HU-005: Incluye filtro por rol y busqueda por nombre
class MiembrosGrupoLoaded extends MiembrosGrupoState {
  final List<MiembroGrupoModel> miembros;

  /// CA-003 / RN-004: Filtro de rol activo (null = todos)
  final String? filtroRol;

  /// CA-004 / RN-005: Texto de busqueda actual
  final String busqueda;

  const MiembrosGrupoLoaded(
    this.miembros, {
    this.filtroRol,
    this.busqueda = '',
  });

  /// CA-003/CA-004: Miembros filtrados por rol y busqueda
  List<MiembroGrupoModel> get miembrosFiltrados {
    var resultado = miembros;

    // RN-004: Filtrar por rol
    if (filtroRol != null) {
      resultado = resultado.where((m) => m.rol == filtroRol).toList();
    }

    // RN-005: Buscar por nombre (parcial, case-insensitive)
    if (busqueda.isNotEmpty) {
      final q = busqueda.toLowerCase();
      resultado = resultado
          .where((m) => m.displayName.toLowerCase().contains(q))
          .toList();
    }

    return resultado;
  }

  /// Cantidad total de miembros (sin filtros)
  int get total => miembros.length;

  /// Miembros pendientes de activacion
  List<MiembroGrupoModel> get pendientes =>
      miembros.where((m) => m.estaPendiente).toList();

  /// Miembros activos
  List<MiembroGrupoModel> get activos =>
      miembros.where((m) => !m.estaPendiente).toList();

  /// CA-005: Si el admin es el unico miembro del grupo
  bool get esUnicoMiembro => miembros.length == 1;

  /// Si hay filtros o busqueda activos
  bool get tieneFiltrosActivos => filtroRol != null || busqueda.isNotEmpty;

  MiembrosGrupoLoaded copyWith({
    List<MiembroGrupoModel>? miembros,
    String? filtroRol,
    String? busqueda,
    bool clearFiltroRol = false,
  }) {
    return MiembrosGrupoLoaded(
      miembros ?? this.miembros,
      filtroRol: clearFiltroRol ? null : (filtroRol ?? this.filtroRol),
      busqueda: busqueda ?? this.busqueda,
    );
  }

  @override
  List<Object?> get props => [miembros, filtroRol, busqueda];
}

/// Error al cargar miembros
class MiembrosGrupoError extends MiembrosGrupoState {
  final String message;

  const MiembrosGrupoError(this.message);

  @override
  List<Object?> get props => [message];
}
