import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/finalizar_partido_response_model.dart';
import '../widgets/resumen_partido_card.dart';
import '../widgets/sugerencia_rotacion_card.dart';

/// Pagina de resumen post-partido
/// E004-HU-005: Finalizar Partido
/// CA-004: Sugerencia de rotacion (3 equipos)
/// CA-005: Resumen con marcador, goleadores, duracion
///
/// Se muestra despues de finalizar un partido exitosamente.
class ResumenPartidoPage extends StatelessWidget {
  /// Respuesta del partido finalizado
  final FinalizarPartidoResponseModel response;

  /// Callback cuando el usuario cierra el resumen
  final VoidCallback? onCerrar;

  /// Callback cuando el usuario quiere iniciar siguiente partido
  final VoidCallback? onIniciarSiguiente;

  const ResumenPartidoPage({
    super.key,
    required this.response,
    this.onCerrar,
    this.onIniciarSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partido Finalizado'),
        leading: IconButton(
          onPressed: onCerrar ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CA-005: Card de resumen con marcador, goleadores, duracion
              ResumenPartidoCard(response: response),

              // CA-004: Sugerencia de siguiente partido (solo 3 equipos)
              if (response.tieneSugerenciaSiguiente) ...[
                const SizedBox(height: DesignTokens.spacingM),
                SugerenciaRotacionCard(
                  sugerencia: response.sugerenciaSiguiente!,
                  onIniciarSiguiente: onIniciarSiguiente,
                ),
              ],

              const SizedBox(height: DesignTokens.spacingXl),

              // Boton de cerrar
              OutlinedButton.icon(
                onPressed: onCerrar ?? () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialogo de resumen de partido
/// Alternativa al page completo, para mostrar como modal
class ResumenPartidoDialog extends StatelessWidget {
  /// Respuesta del partido finalizado
  final FinalizarPartidoResponseModel response;

  /// Callback cuando el usuario quiere iniciar siguiente partido
  final VoidCallback? onIniciarSiguiente;

  const ResumenPartidoDialog({
    super.key,
    required this.response,
    this.onIniciarSiguiente,
  });

  /// Muestra el dialogo de resumen
  static Future<void> show(
    BuildContext context, {
    required FinalizarPartidoResponseModel response,
    VoidCallback? onIniciarSiguiente,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResumenPartidoDialog(
        response: response,
        onIniciarSiguiente: onIniciarSiguiente,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CA-005: Card de resumen
              ResumenPartidoCard(response: response),

              // CA-004: Sugerencia (solo 3 equipos)
              if (response.tieneSugerenciaSiguiente) ...[
                const SizedBox(height: DesignTokens.spacingM),
                SugerenciaRotacionCard(
                  sugerencia: response.sugerenciaSiguiente!,
                  onIniciarSiguiente: () {
                    Navigator.of(context).pop();
                    onIniciarSiguiente?.call();
                  },
                ),
              ],

              const SizedBox(height: DesignTokens.spacingM),

              // Botones de accion
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
