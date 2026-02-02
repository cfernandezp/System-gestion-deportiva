import 'package:equatable/equatable.dart';

/// Eventos del BLoC de lista de partidos
abstract class ListaPartidosEvent extends Equatable {
  const ListaPartidosEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar la lista de partidos de una fecha
class CargarPartidosEvent extends ListaPartidosEvent {
  /// ID de la fecha
  final String fechaId;

  const CargarPartidosEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para refrescar la lista de partidos de una fecha
class RefrescarPartidosEvent extends ListaPartidosEvent {
  /// ID de la fecha
  final String fechaId;

  const RefrescarPartidosEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}
