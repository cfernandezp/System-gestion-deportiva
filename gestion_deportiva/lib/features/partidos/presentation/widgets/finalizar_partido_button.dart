import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../bloc/finalizar_partido/finalizar_partido.dart';

/// Boton para finalizar partido
/// E004-HU-005: Finalizar Partido
/// CA-001: Boton "Finalizar Partido" visible cuando partido activo
///
/// Solo visible para admin. Muestra estado de carga mientras procesa.
class FinalizarPartidoButton extends StatelessWidget {
  /// ID del partido a finalizar
  final String partidoId;

  /// Indica si el tiempo del partido ya termino
  final bool tiempoTerminado;

  /// Callback cuando el partido se finaliza exitosamente
  final VoidCallback? onFinalizadoExitosamente;

  /// Si mostrar version compacta (solo icono)
  final bool compacto;

  const FinalizarPartidoButton({
    super.key,
    required this.partidoId,
    required this.tiempoTerminado,
    this.onFinalizadoExitosamente,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinalizarPartidoBloc, FinalizarPartidoState>(
      listener: (context, state) {
        if (state is FinalizarPartidoSuccess) {
          onFinalizadoExitosamente?.call();
        } else if (state is FinalizarPartidoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is FinalizarPartidoLoading;

        if (compacto) {
          return IconButton(
            onPressed: isLoading ? null : () => _onPressed(context),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.stop_circle_outlined),
            tooltip: 'Finalizar Partido',
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }

        return FilledButton.icon(
          onPressed: isLoading ? null : () => _onPressed(context),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
          ),
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                )
              : const Icon(Icons.stop_circle_outlined),
          label: Text(isLoading ? 'Finalizando...' : 'Finalizar Partido'),
        );
      },
    );
  }

  void _onPressed(BuildContext context) {
    context.read<FinalizarPartidoBloc>().add(
          FinalizarPartidoRequested(
            partidoId: partidoId,
            tiempoTerminado: tiempoTerminado,
          ),
        );
  }
}
