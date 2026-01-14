import 'package:equatable/equatable.dart';

/// Modelo de respuesta de validacion de password
/// Mapea la respuesta JSON de la funcion RPC validar_password
class ValidacionPasswordModel extends Equatable {
  final bool esValido;
  final List<String> errores;

  const ValidacionPasswordModel({
    required this.esValido,
    required this.errores,
  });

  /// Crea instancia desde JSON del backend
  factory ValidacionPasswordModel.fromJson(Map<String, dynamic> json) {
    return ValidacionPasswordModel(
      esValido: json['valid'] ?? false,
      errores: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [esValido, errores];
}
