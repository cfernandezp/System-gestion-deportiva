import 'package:equatable/equatable.dart';

/// Modelo de gol individual
/// E004-HU-003: Registrar Gol
/// Representa un gol registrado en un partido
class GolModel extends Equatable {
  /// ID unico del gol
  final String id;

  /// Color del equipo que anoto (recibe el punto)
  final String equipoAnotador;

  /// ID del jugador que anoto (null si no se asigno)
  final String? jugadorId;

  /// Nombre del jugador que anoto (null si no se asigno)
  final String? jugadorNombre;

  /// Minuto del partido en que se anoto
  final int minuto;

  /// Si es autogol (gol en contra)
  final bool esAutogol;

  /// Timestamp de cuando se registro el gol
  final DateTime? createdAt;

  const GolModel({
    required this.id,
    required this.equipoAnotador,
    this.jugadorId,
    this.jugadorNombre,
    required this.minuto,
    this.esAutogol = false,
    this.createdAt,
  });

  /// Factory desde JSON del backend
  /// Mapea snake_case a camelCase
  /// Response de registrar_gol y obtener_goles_partido
  factory GolModel.fromJson(Map<String, dynamic> json) {
    return GolModel(
      id: json['gol_id'] as String? ?? json['id'] as String,
      equipoAnotador: json['equipo_anotador'] as String,
      jugadorId: json['jugador_id'] as String?,
      jugadorNombre: json['jugador_nombre'] as String?,
      minuto: json['minuto'] as int,
      esAutogol: json['es_autogol'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipo_anotador': equipoAnotador,
      'jugador_id': jugadorId,
      'jugador_nombre': jugadorNombre,
      'minuto': minuto,
      'es_autogol': esAutogol,
    };
  }

  /// Descripcion del gol para mostrar en UI
  /// Ejemplo: "Juan Perez (min 5)" o "Gol sin asignar (min 5)"
  String get descripcion {
    final autor = jugadorNombre ?? 'Gol sin asignar';
    final autogolTag = esAutogol ? ' (autogol)' : '';
    return '$autor (min $minuto)$autogolTag';
  }

  /// Nombre del equipo anotador en mayusculas para mostrar
  String get equipoAnotadorDisplay => equipoAnotador.toUpperCase();

  @override
  List<Object?> get props => [
        id,
        equipoAnotador,
        jugadorId,
        jugadorNombre,
        minuto,
        esAutogol,
        createdAt,
      ];
}
