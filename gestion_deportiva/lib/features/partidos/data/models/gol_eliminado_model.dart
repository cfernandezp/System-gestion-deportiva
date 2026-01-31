import 'package:equatable/equatable.dart';

/// Modelo de gol eliminado
/// E004-HU-003: Registrar Gol - CA-005: Deshacer gol
/// Representa la informacion de un gol que fue eliminado
class GolEliminadoModel extends Equatable {
  /// ID del gol eliminado
  final String id;

  /// Color del equipo que habia anotado
  final String equipoAnotador;

  /// Nombre del jugador que habia anotado
  final String? jugadorNombre;

  /// Minuto en que se habia anotado
  final int minuto;

  /// Si era autogol
  final bool esAutogol;

  /// Segundos desde que se registro (para RN-005)
  final int segundosDesdeRegistro;

  const GolEliminadoModel({
    required this.id,
    required this.equipoAnotador,
    this.jugadorNombre,
    required this.minuto,
    this.esAutogol = false,
    required this.segundosDesdeRegistro,
  });

  /// Factory desde JSON del backend
  /// Mapea snake_case a camelCase
  factory GolEliminadoModel.fromJson(Map<String, dynamic> json) {
    return GolEliminadoModel(
      id: json['id'] as String,
      equipoAnotador: json['equipo_anotador'] as String,
      jugadorNombre: json['jugador_nombre'] as String?,
      minuto: json['minuto'] as int,
      esAutogol: json['es_autogol'] as bool? ?? false,
      segundosDesdeRegistro: json['segundos_desde_registro'] as int? ?? 0,
    );
  }

  /// RN-005: Si esta dentro de la ventana de 30 segundos
  bool get dentroDeVentana => segundosDesdeRegistro <= 30;

  /// Descripcion del gol eliminado
  String get descripcion {
    final autor = jugadorNombre ?? 'Gol sin asignar';
    final autogolTag = esAutogol ? ' (autogol)' : '';
    return '$autor (min $minuto)$autogolTag';
  }

  @override
  List<Object?> get props => [
        id,
        equipoAnotador,
        jugadorNombre,
        minuto,
        esAutogol,
        segundosDesdeRegistro,
      ];
}
