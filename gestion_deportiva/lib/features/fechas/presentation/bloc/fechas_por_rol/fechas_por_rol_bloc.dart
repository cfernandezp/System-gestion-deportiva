import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/listar_fechas_por_rol_response_model.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'fechas_por_rol_event.dart';
import 'fechas_por_rol_state.dart';

/// BLoC para gestionar la lista de fechas segun el rol del usuario
/// E003-HU-009: Listar Fechas por Rol
///
/// Funcionalidad:
/// - Jugador: Ve fechas donde esta inscrito o puede inscribirse
/// - Admin: Ve todas las fechas con filtros opcionales
///
/// Secciones:
/// - 'proximas': Fechas futuras (default)
/// - 'pasadas': Fechas ya realizadas
/// - 'todas': Todas las fechas (admin)
class FechasPorRolBloc extends Bloc<FechasPorRolEvent, FechasPorRolState> {
  final FechasRepository repository;

  /// Seccion actualmente seleccionada
  String _seccionActual = 'proximas';

  /// Filtros actuales (solo admin)
  String? _filtroEstadoActual;
  DateTime? _fechaDesdeActual;
  DateTime? _fechaHastaActual;

  FechasPorRolBloc({required this.repository})
      : super(const FechasPorRolInitial()) {
    on<CargarFechasPorRolEvent>(_onCargarFechas);
    on<CambiarSeccionEvent>(_onCambiarSeccion);
    on<RefrescarFechasEvent>(_onRefrescarFechas);
    on<AplicarFiltrosEvent>(_onAplicarFiltros);
    on<LimpiarFiltrosEvent>(_onLimpiarFiltros);
    on<ResetFechasPorRolEvent>(_onReset);
  }

  /// Getter para seccion actual
  String get seccionActual => _seccionActual;

  /// Cargar lista de fechas segun rol
  Future<void> _onCargarFechas(
    CargarFechasPorRolEvent event,
    Emitter<FechasPorRolState> emit,
  ) async {
    // Actualizar parametros actuales
    _seccionActual = event.seccion;
    _filtroEstadoActual = event.filtroEstado;
    _fechaDesdeActual = event.fechaDesde;
    _fechaHastaActual = event.fechaHasta;

    emit(const FechasPorRolLoading());

    final result = await repository.listarFechasPorRol(
      seccion: event.seccion,
      filtroEstado: event.filtroEstado,
      fechaDesde: event.fechaDesde,
      fechaHasta: event.fechaHasta,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(FechasPorRolError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          seccion: event.seccion,
        ));
      },
      (response) {
        if (response.success) {
          if (response.fechas.isEmpty) {
            emit(FechasPorRolEmpty(
              seccion: response.seccion,
              message: response.message.isNotEmpty
                  ? response.message
                  : _getMensajeVacio(response.seccion),
              esAdmin: response.esAdmin,
            ));
          } else {
            emit(FechasPorRolLoaded(
              fechas: response.fechas,
              seccion: response.seccion,
              total: response.total,
              esAdmin: response.esAdmin,
              message: response.message,
              filtrosAplicados: response.filtrosAplicados,
            ));
          }
        } else {
          emit(FechasPorRolError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar fechas',
            seccion: event.seccion,
          ));
        }
      },
    );
  }

  /// Cambiar seccion y recargar fechas
  Future<void> _onCambiarSeccion(
    CambiarSeccionEvent event,
    Emitter<FechasPorRolState> emit,
  ) async {
    _seccionActual = event.seccion;

    emit(const FechasPorRolLoading());

    final result = await repository.listarFechasPorRol(
      seccion: event.seccion,
      filtroEstado: _filtroEstadoActual,
      fechaDesde: _fechaDesdeActual,
      fechaHasta: _fechaHastaActual,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(FechasPorRolError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          seccion: event.seccion,
        ));
      },
      (response) {
        if (response.success) {
          if (response.fechas.isEmpty) {
            emit(FechasPorRolEmpty(
              seccion: response.seccion,
              message: response.message.isNotEmpty
                  ? response.message
                  : _getMensajeVacio(response.seccion),
              esAdmin: response.esAdmin,
            ));
          } else {
            emit(FechasPorRolLoaded(
              fechas: response.fechas,
              seccion: response.seccion,
              total: response.total,
              esAdmin: response.esAdmin,
              message: response.message,
              filtrosAplicados: response.filtrosAplicados,
            ));
          }
        } else {
          emit(FechasPorRolError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cambiar seccion',
            seccion: event.seccion,
          ));
        }
      },
    );
  }

  /// Refrescar lista de fechas manteniendo datos anteriores
  Future<void> _onRefrescarFechas(
    RefrescarFechasEvent event,
    Emitter<FechasPorRolState> emit,
  ) async {
    // Obtener datos actuales para mantener UI
    final estadoActual = state;
    List<FechaPorRolModel> fechasActuales = [];
    bool esAdminActual = false;

    if (estadoActual is FechasPorRolLoaded) {
      fechasActuales = estadoActual.fechas;
      esAdminActual = estadoActual.esAdmin;
    } else if (estadoActual is FechasPorRolError &&
        estadoActual.fechasAnteriores != null) {
      fechasActuales = estadoActual.fechasAnteriores!;
    }

    if (fechasActuales.isNotEmpty) {
      emit(FechasPorRolRefreshing(
        fechasActuales: fechasActuales,
        seccion: _seccionActual,
        esAdmin: esAdminActual,
      ));
    } else {
      emit(const FechasPorRolLoading());
    }

    final result = await repository.listarFechasPorRol(
      seccion: _seccionActual,
      filtroEstado: _filtroEstadoActual,
      fechaDesde: _fechaDesdeActual,
      fechaHasta: _fechaHastaActual,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(FechasPorRolError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          seccion: _seccionActual,
          fechasAnteriores: fechasActuales.isNotEmpty ? fechasActuales : null,
        ));
      },
      (response) {
        if (response.success) {
          if (response.fechas.isEmpty) {
            emit(FechasPorRolEmpty(
              seccion: response.seccion,
              message: response.message.isNotEmpty
                  ? response.message
                  : _getMensajeVacio(response.seccion),
              esAdmin: response.esAdmin,
            ));
          } else {
            emit(FechasPorRolLoaded(
              fechas: response.fechas,
              seccion: response.seccion,
              total: response.total,
              esAdmin: response.esAdmin,
              message: response.message,
              filtrosAplicados: response.filtrosAplicados,
            ));
          }
        } else {
          emit(FechasPorRolError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al refrescar fechas',
            seccion: _seccionActual,
            fechasAnteriores: fechasActuales.isNotEmpty ? fechasActuales : null,
          ));
        }
      },
    );
  }

  /// Aplicar filtros (solo admin)
  Future<void> _onAplicarFiltros(
    AplicarFiltrosEvent event,
    Emitter<FechasPorRolState> emit,
  ) async {
    // Actualizar filtros
    _filtroEstadoActual = event.filtroEstado;
    _fechaDesdeActual = event.fechaDesde;
    _fechaHastaActual = event.fechaHasta;

    emit(const FechasPorRolLoading());

    final result = await repository.listarFechasPorRol(
      seccion: _seccionActual,
      filtroEstado: event.filtroEstado,
      fechaDesde: event.fechaDesde,
      fechaHasta: event.fechaHasta,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(FechasPorRolError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          seccion: _seccionActual,
        ));
      },
      (response) {
        if (response.success) {
          if (response.fechas.isEmpty) {
            emit(FechasPorRolEmpty(
              seccion: response.seccion,
              message: response.message.isNotEmpty
                  ? response.message
                  : 'No se encontraron fechas con los filtros aplicados',
              esAdmin: response.esAdmin,
            ));
          } else {
            emit(FechasPorRolLoaded(
              fechas: response.fechas,
              seccion: response.seccion,
              total: response.total,
              esAdmin: response.esAdmin,
              message: response.message,
              filtrosAplicados: response.filtrosAplicados,
            ));
          }
        } else {
          emit(FechasPorRolError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al aplicar filtros',
            seccion: _seccionActual,
          ));
        }
      },
    );
  }

  /// Limpiar todos los filtros
  Future<void> _onLimpiarFiltros(
    LimpiarFiltrosEvent event,
    Emitter<FechasPorRolState> emit,
  ) async {
    // Limpiar filtros
    _filtroEstadoActual = null;
    _fechaDesdeActual = null;
    _fechaHastaActual = null;

    // Recargar sin filtros
    add(CargarFechasPorRolEvent(seccion: _seccionActual));
  }

  /// Reiniciar estado del bloc
  void _onReset(
    ResetFechasPorRolEvent event,
    Emitter<FechasPorRolState> emit,
  ) {
    _seccionActual = 'proximas';
    _filtroEstadoActual = null;
    _fechaDesdeActual = null;
    _fechaHastaActual = null;
    emit(const FechasPorRolInitial());
  }

  /// Mensaje por defecto cuando no hay fechas
  String _getMensajeVacio(String seccion) {
    switch (seccion) {
      case 'proximas':
        return 'No hay fechas proximas programadas';
      case 'pasadas':
        return 'No hay fechas pasadas';
      case 'todas':
        return 'No hay fechas registradas';
      default:
        return 'No hay fechas disponibles';
    }
  }
}
