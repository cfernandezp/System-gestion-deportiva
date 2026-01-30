import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../bloc/cerrar_inscripciones/cerrar_inscripciones.dart';

/// Dialog de confirmacion para reabrir inscripciones de una fecha cerrada
/// E003-HU-004: Cerrar Inscripciones
/// CA-006: Reabrir inscripciones (solo admin)
/// RN-005: Solo fechas con estado 'cerrada' se pueden reabrir
/// RN-006: Inscripciones y deudas se mantienen intactas
class ReabrirInscripcionesDialog extends StatelessWidget {
  /// Detalle de la fecha a reabrir inscripciones
  final FechaDetalleModel fechaDetalle;

  /// Callback cuando se reabre exitosamente
  final VoidCallback? onSuccess;

  const ReabrirInscripcionesDialog({
    super.key,
    required this.fechaDetalle,
    this.onSuccess,
  });

  /// Muestra el dialog de reabrir inscripciones
  /// Mobile: BottomSheet
  /// Desktop: Dialog centrado
  static Future<void> show(
    BuildContext context, {
    required FechaDetalleModel fechaDetalle,
    VoidCallback? onSuccess,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // Mobile: BottomSheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BlocProvider(
          create: (context) => sl<CerrarInscripcionesBloc>(),
          child: ReabrirInscripcionesDialog(
            fechaDetalle: fechaDetalle,
            onSuccess: onSuccess,
          ),
        ),
      );
    } else {
      // Desktop: Dialog centrado
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BlocProvider(
          create: (context) => sl<CerrarInscripcionesBloc>(),
          child: Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
                maxHeight: 500,
              ),
              child: ReabrirInscripcionesDialog(
                fechaDetalle: fechaDetalle,
                onSuccess: onSuccess,
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return BlocConsumer<CerrarInscripcionesBloc, CerrarInscripcionesState>(
      listener: (context, state) {
        if (state is ReabrirInscripcionesSuccess) {
          // Cerrar el dialog
          Navigator.of(context).pop();

          // Mostrar mensaje de exito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Callback de exito
          onSuccess?.call();
        }

        if (state is ReabrirInscripcionesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ReabrirInscripcionesLoading;

        if (isMobile) {
          return _buildBottomSheetContent(context, colorScheme, isLoading);
        } else {
          return _buildDialogContent(context, colorScheme, isLoading);
        }
      },
    );
  }

  /// Contenido para BottomSheet (Mobile)
  Widget _buildBottomSheetContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: [
                Icon(
                  Icons.lock_open,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'Reabrir Inscripciones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              child: _buildContent(context, colorScheme),
            ),
          ),

          // Botones de accion
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : () => _confirmarReapertura(context),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_open),
                      label: const Text('Reabrir'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido para Dialog (Desktop)
  Widget _buildDialogContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    Icons.lock_open,
                    color: colorScheme.onPrimaryContainer,
                    size: DesignTokens.iconSizeL,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reabrir Inscripciones',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        'Permitir nuevas inscripciones',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              child: _buildContent(context, colorScheme),
            ),
          ),

          const Divider(height: 1),

          // Botones de accion
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                FilledButton.icon(
                  onPressed: isLoading ? null : () => _confirmarReapertura(context),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_open),
                  label: const Text('Reabrir Inscripciones'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido compartido del dialog
  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final fecha = fechaDetalle.fecha;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descripcion
        Text(
          'Al reabrir las inscripciones:',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: DesignTokens.spacingM),

        // Lista de consecuencias
        _buildConsequenceItem(
          context,
          icon: Icons.person_add,
          text: 'Se podran anotar nuevos jugadores',
          isPositive: true,
        ),
        _buildConsequenceItem(
          context,
          icon: Icons.people,
          text: 'Las inscripciones actuales se mantienen',
          isPositive: true,
        ),
        _buildConsequenceItem(
          context,
          icon: Icons.attach_money,
          text: 'Las deudas pendientes se conservan',
          isPositive: true,
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Resumen actual
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Column(
            children: [
              _buildResumenRow(
                context,
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: '${fecha.fechaFormato} - ${fecha.horaFormato}',
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildResumenRow(
                context,
                icon: Icons.people,
                label: 'Inscritos actuales',
                value: '${fechaDetalle.totalInscritos} jugador${fechaDetalle.totalInscritos != 1 ? 'es' : ''}',
                destacado: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Item de consecuencia
  Widget _buildConsequenceItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    bool isPositive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isPositive ? DesignTokens.successColor : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: iconColor,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fila del resumen
  Widget _buildResumenRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool destacado = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: destacado
                      ? DesignTokens.fontWeightBold
                      : DesignTokens.fontWeightMedium,
                  color: destacado ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Envia la solicitud de reapertura
  void _confirmarReapertura(BuildContext context) {
    context.read<CerrarInscripcionesBloc>().add(
      ReabrirInscripcionesSubmitEvent(fechaId: fechaDetalle.fecha.fechaId),
    );
  }
}
