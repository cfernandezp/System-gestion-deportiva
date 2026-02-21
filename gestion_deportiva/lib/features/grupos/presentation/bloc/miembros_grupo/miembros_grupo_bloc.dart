import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/grupos_repository.dart';
import 'miembros_grupo_event.dart';
import 'miembros_grupo_state.dart';

/// Bloc para ver miembros del grupo
/// E001-HU-004 CA-005: Ver lista de jugadores con estado
class MiembrosGrupoBloc extends Bloc<MiembrosGrupoEvent, MiembrosGrupoState> {
  final GruposRepository repository;

  MiembrosGrupoBloc({required this.repository}) : super(MiembrosGrupoInitial()) {
    on<CargarMiembrosGrupoEvent>(_onCargarMiembros);
  }

  Future<void> _onCargarMiembros(
    CargarMiembrosGrupoEvent event,
    Emitter<MiembrosGrupoState> emit,
  ) async {
    emit(MiembrosGrupoLoading());

    final result = await repository.obtenerMiembrosGrupo(event.grupoId);

    result.fold(
      (failure) => emit(MiembrosGrupoError(failure.message)),
      (miembros) => emit(MiembrosGrupoLoaded(miembros)),
    );
  }
}
