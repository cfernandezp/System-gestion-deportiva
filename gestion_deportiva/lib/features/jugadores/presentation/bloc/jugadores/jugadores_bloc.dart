import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/jugador_model.dart';
import '../../../domain/repositories/jugadores_repository.dart';
import 'jugadores_event.dart';
import 'jugadores_state.dart';

/// BLoC para gestionar el estado de la lista de jugadores
/// E002-HU-003: Lista de Jugadores
class JugadoresBloc extends Bloc<JugadoresEvent, JugadoresState> {
  final JugadoresRepository repository;

  /// Filtros actuales
  FiltrosJugadores _filtrosActuales = const FiltrosJugadores();

  JugadoresBloc({required this.repository}) : super(const JugadoresInitial()) {
    on<CargarJugadoresEvent>(_onCargarJugadores);
    on<RefrescarJugadoresEvent>(_onRefrescarJugadores);
    on<BuscarJugadoresEvent>(_onBuscarJugadores);
    on<LimpiarBusquedaEvent>(_onLimpiarBusqueda);
    on<CambiarOrdenEvent>(_onCambiarOrden);
    on<AlternarDireccionOrdenEvent>(_onAlternarDireccion);
  }

  /// CA-001: Cargar lista de jugadores
  Future<void> _onCargarJugadores(
    CargarJugadoresEvent event,
    Emitter<JugadoresState> emit,
  ) async {
    emit(const JugadoresLoading());
    await _cargarLista(emit);
  }

  /// Refrescar lista (pull to refresh)
  Future<void> _onRefrescarJugadores(
    RefrescarJugadoresEvent event,
    Emitter<JugadoresState> emit,
  ) async {
    final jugadoresActuales = _obtenerJugadoresActuales();
    if (jugadoresActuales.isNotEmpty) {
      emit(JugadoresRefreshing(
        jugadoresActuales: jugadoresActuales,
        filtros: _filtrosActuales,
      ));
    }
    await _cargarLista(emit);
  }

  /// CA-003: Buscar jugadores
  Future<void> _onBuscarJugadores(
    BuscarJugadoresEvent event,
    Emitter<JugadoresState> emit,
  ) async {
    final busquedaLimpia = event.busqueda.trim();

    // Si la busqueda es igual a la actual, no hacer nada
    if (busquedaLimpia == (_filtrosActuales.busqueda ?? '')) {
      return;
    }

    _filtrosActuales = _filtrosActuales.copyWith(
      busqueda: busquedaLimpia.isEmpty ? null : busquedaLimpia,
      clearBusqueda: busquedaLimpia.isEmpty,
    );

    final jugadoresActuales = _obtenerJugadoresActuales();
    emit(JugadoresBuscando(
      jugadoresActuales: jugadoresActuales,
      filtros: _filtrosActuales,
    ));

    await _cargarLista(emit);
  }

  /// Limpiar busqueda
  Future<void> _onLimpiarBusqueda(
    LimpiarBusquedaEvent event,
    Emitter<JugadoresState> emit,
  ) async {
    _filtrosActuales = _filtrosActuales.copyWith(clearBusqueda: true);
    emit(const JugadoresLoading());
    await _cargarLista(emit);
  }

  /// CA-004: Cambiar ordenamiento
  Future<void> _onCambiarOrden(
    CambiarOrdenEvent event,
    Emitter<JugadoresState> emit,
  ) async {
    _filtrosActuales = _filtrosActuales.copyWith(
      ordenCampo: event.ordenCampo,
      ordenDireccion: event.ordenDireccion,
    );

    final jugadoresActuales = _obtenerJugadoresActuales();
    emit(JugadoresBuscando(
      jugadoresActuales: jugadoresActuales,
      filtros: _filtrosActuales,
    ));

    await _cargarLista(emit);
  }

  /// Alternar direccion de orden
  Future<void> _onAlternarDireccion(
    AlternarDireccionOrdenEvent event,
    Emitter<JugadoresState> emit,
  ) async {
    final nuevaDireccion = _filtrosActuales.ordenDireccion == OrdenDireccion.asc
        ? OrdenDireccion.desc
        : OrdenDireccion.asc;

    _filtrosActuales = _filtrosActuales.copyWith(
      ordenDireccion: nuevaDireccion,
    );

    final jugadoresActuales = _obtenerJugadoresActuales();
    emit(JugadoresBuscando(
      jugadoresActuales: jugadoresActuales,
      filtros: _filtrosActuales,
    ));

    await _cargarLista(emit);
  }

  /// Metodo interno para cargar lista con filtros actuales
  Future<void> _cargarLista(Emitter<JugadoresState> emit) async {
    final result = await repository.listarJugadores(
      busqueda: _filtrosActuales.busqueda,
      ordenCampo: _filtrosActuales.ordenCampo,
      ordenDireccion: _filtrosActuales.ordenDireccion,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(JugadoresError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.jugadores.isEmpty) {
          // RN-001: Lista vacia
          emit(JugadoresVacio(
            filtros: response.filtros,
            message: response.message,
          ));
        } else {
          emit(JugadoresLoaded(
            jugadores: response.jugadores,
            total: response.total,
            filtros: response.filtros,
            message: response.message,
          ));
        }
        // Actualizar filtros con la respuesta del servidor
        _filtrosActuales = response.filtros;
      },
    );
  }

  /// Obtiene los jugadores del estado actual
  List<JugadorModel> _obtenerJugadoresActuales() {
    final currentState = state;
    if (currentState is JugadoresLoaded) return currentState.jugadores;
    if (currentState is JugadoresRefreshing) return currentState.jugadoresActuales;
    if (currentState is JugadoresBuscando) return currentState.jugadoresActuales;
    return [];
  }
}
