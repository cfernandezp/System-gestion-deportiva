import 'package:equatable/equatable.dart';

/// Modelo de un goleador en el ranking
/// E006-HU-001: Ranking de Goleadores
/// CA-002: Informacion por jugador (posicion, foto/avatar, apodo, goles, partidos jugados, promedio)
class RankingGoleadorModel extends Equatable {
  /// Posicion en el ranking (#1, #2, #3...)
  final int posicion;

  /// ID del jugador
  final String jugadorId;

  /// Apodo del jugador
  final String apodo;

  /// URL del avatar (puede ser null)
  final String? avatarUrl;

  /// Cantidad total de goles anotados
  final int goles;

  /// Cantidad de partidos jugados
  final int partidosJugados;

  /// Promedio de goles por partido
  final double promedio;

  const RankingGoleadorModel({
    required this.posicion,
    required this.jugadorId,
    required this.apodo,
    this.avatarUrl,
    required this.goles,
    required this.partidosJugados,
    required this.promedio,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory RankingGoleadorModel.fromJson(Map<String, dynamic> json) {
    return RankingGoleadorModel(
      posicion: json['posicion'] ?? 0,
      jugadorId: json['jugador_id'] ?? '',
      apodo: json['apodo'] ?? 'Sin apodo',
      avatarUrl: json['avatar_url'],
      goles: json['goles'] ?? 0,
      partidosJugados: json['partidos_jugados'] ?? 0,
      promedio: (json['promedio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'posicion': posicion,
      'jugador_id': jugadorId,
      'apodo': apodo,
      'avatar_url': avatarUrl,
      'goles': goles,
      'partidos_jugados': partidosJugados,
      'promedio': promedio,
    };
  }

  /// Verifica si tiene avatar
  bool get tieneAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Iniciales para avatar generico
  String get iniciales {
    if (apodo.isEmpty) return '?';
    final palabras = apodo.trim().split(' ');
    if (palabras.length == 1) {
      return palabras[0].length >= 2
          ? palabras[0].substring(0, 2).toUpperCase()
          : palabras[0][0].toUpperCase();
    }
    return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
  }

  /// Texto formateado del promedio
  String get promedioFormateado => promedio.toStringAsFixed(2);

  /// Verifica si es top 3 (para mostrar en podio - CA-006)
  bool get esTop3 => posicion >= 1 && posicion <= 3;

  /// Verifica si es primer lugar
  bool get esPrimerLugar => posicion == 1;

  /// Verifica si es segundo lugar
  bool get esSegundoLugar => posicion == 2;

  /// Verifica si es tercer lugar
  bool get esTercerLugar => posicion == 3;

  @override
  List<Object?> get props => [
        posicion,
        jugadorId,
        apodo,
        avatarUrl,
        goles,
        partidosJugados,
        promedio,
      ];
}
