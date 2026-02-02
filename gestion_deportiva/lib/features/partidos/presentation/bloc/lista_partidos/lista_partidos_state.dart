import 'package:equatable/equatable.dart';

import '../../../data/models/listar_partidos_response_model.dart';

/// Estados del BLoC de lista de partidos
abstract class ListaPartidosState extends Equatable {
  const ListaPartidosState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class ListaPartidosInitial extends ListaPartidosState {
  const ListaPartidosInitial();
}

/// Estado de carga - Obteniendo datos del servidor
class ListaPartidosLoading extends ListaPartidosState {
  const ListaPartidosLoading();
}

/// Estado exitoso - Lista de partidos cargada
class ListaPartidosLoaded extends ListaPartidosState {
  /// Lista de partidos
  final List<PartidoListaModel> partidos;

  /// Total de partidos en la fecha
  final int total;

  /// Indica si se puede crear un nuevo partido
  final bool puedeCrearPartido;

  /// Mensaje informativo
  final String message;

  const ListaPartidosLoaded({
    required this.partidos,
    required this.total,
    required this.puedeCrearPartido,
    this.message = '',
  });

  /// Indica si hay partidos en la lista
  bool get tienePartidos => partidos.isNotEmpty;

  /// Indica si hay un partido activo (en_curso o pausado)
  bool get hayPartidoActivo => partidos.any((p) => p.estaActivo);

  /// Obtiene el partido activo si existe
  PartidoListaModel? get partidoActivo {
    try {
      return partidos.firstWhere((p) => p.estaActivo);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [partidos, total, puedeCrearPartido, message];
}

/// Estado de error
class ListaPartidosError extends ListaPartidosState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  final String? hint;

  const ListaPartidosError({
    required this.message,
    this.code,
    this.hint,
  });

  @override
  List<Object?> get props => [message, code, hint];
}
