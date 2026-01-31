import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../bloc/finalizar_partido/finalizar_partido.dart';

/// Dialogo de confirmacion para finalizacion anticipada
/// E004-HU-005: Finalizar Partido
/// CA-006: Confirmacion si tiempo no ha terminado
///
/// Muestra advertencia cuando el admin intenta finalizar
/// un partido cuyo tiempo aun no ha terminado.
class ConfirmacionAnticipadaDialog extends StatelessWidget {
  /// ID del partido a finalizar
  final String partidoId;

  /// Mensaje descriptivo
  final String mensaje;

  const ConfirmacionAnticipadaDialog({
    super.key,
    required this.partidoId,
    required this.mensaje,
  });

  /// Muestra el dialogo de confirmacion
  static Future<bool?> show(
    BuildContext context, {
    required String partidoId,
    required String mensaje,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<FinalizarPartidoBloc>(),
        child: ConfirmacionAnticipadaDialog(
          partidoId: partidoId,
          mensaje: mensaje,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: DesignTokens.iconSizeXl,
        color: colorScheme.error,
      ),
      title: const Text('Finalizar Partido Anticipadamente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mensaje,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.error,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    'Esta accion no se puede deshacer.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<FinalizarPartidoBloc>().add(
                  const CancelarFinalizacion(),
                );
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            context.read<FinalizarPartidoBloc>().add(
                  ConfirmarFinalizacionAnticipada(partidoId: partidoId),
                );
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('Si, Finalizar'),
        ),
      ],
    );
  }
}
