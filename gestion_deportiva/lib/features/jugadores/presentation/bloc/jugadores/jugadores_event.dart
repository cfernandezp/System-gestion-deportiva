import 'package:equatable/equatable.dart';

import '../../../data/models/jugador_model.dart';

/// Eventos del BLoC de jugadores
/// E002-HU-003: Lista de Jugadores
abstract class JugadoresEvent extends Equatable {
  const JugadoresEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Cargar lista de jugadores
class CargarJugadoresEvent extends JugadoresEvent {
  const CargarJugadoresEvent();
}

/// Refrescar lista (pull to refresh)
class RefrescarJugadoresEvent extends JugadoresEvent {
  const RefrescarJugadoresEvent();
}

/// CA-003: Buscar jugadores por nombre/apodo
class BuscarJugadoresEvent extends JugadoresEvent {
  final String busqueda;

  const BuscarJugadoresEvent(this.busqueda);

  @override
  List<Object?> get props => [busqueda];
}

/// Limpiar busqueda
class LimpiarBusquedaEvent extends JugadoresEvent {
  const LimpiarBusquedaEvent();
}

/// CA-004: Cambiar ordenamiento
class CambiarOrdenEvent extends JugadoresEvent {
  final OrdenCampo? ordenCampo;
  final OrdenDireccion? ordenDireccion;

  const CambiarOrdenEvent({
    this.ordenCampo,
    this.ordenDireccion,
  });

  @override
  List<Object?> get props => [ordenCampo, ordenDireccion];
}

/// Alternar direccion de orden (asc <-> desc)
class AlternarDireccionOrdenEvent extends JugadoresEvent {
  const AlternarDireccionOrdenEvent();
}
