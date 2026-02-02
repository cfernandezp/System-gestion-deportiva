import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../bloc/cancelar_inscripcion/cancelar_inscripcion.dart';

/// Dialog de confirmacion para que admin cancele inscripcion de un jugador
/// E003-HU-007: Cancelar Inscripcion
///
/// Criterios de Aceptacion:
/// - CA-006: Admin puede cancelar inscripcion de cualquier jugador
///
/// Reglas de Negocio:
/// - RN-002: Admin puede cancelar en cualquier estado pre-partido
/// - RN-003: Admin decide si anular deuda pendiente
/// - RN-004: Asignacion de equipo se elimina
/// - RN-005: Jugador recibe notificacion
/// - RN-006: Soft delete con auditoria
class CancelarInscripcionAdminDialog extends StatefulWidget {
  /// Detalle de la fecha
  final FechaDetalleModel fechaDetalle;

  /// ID de la inscripcion a cancelar
  final String inscripcionId;

  /// Nombre del jugador afectado
  final String nombreJugador;

  /// Callback cuando se cancela exitosamente
  final VoidCallback? onSuccess;

  const CancelarInscripcionAdminDialog({
    super.key,
    required this.fechaDetalle,
    required this.inscripcionId,
    required this.nombreJugador,
    this.onSuccess,
  });

  /// Muestra el dialog de cancelar inscripcion por admin
  /// Mobile: BottomSheet
  /// Desktop: Dialog centrado
  static Future<void> show(
    BuildContext context, {
    required FechaDetalleModel fechaDetalle,
    required String inscripcionId,
    required String nombreJugador,
    VoidCallback? onSuccess,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < DesignTokens.breakpointMobile;

    if (isMobile) {
      // Mobile: BottomSheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BlocProvider(
          create: (context) => sl<CancelarInscripcionBloc>(),
          child: CancelarInscripcionAdminDialog(
            fechaDetalle: fechaDetalle,
            inscripcionId: inscripcionId,
            nombreJugador: nombreJugador,
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
          create: (context) => sl<CancelarInscripcionBloc>(),
          child: Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
                maxHeight: 600,
              ),
              child: CancelarInscripcionAdminDialog(
                fechaDetalle: fechaDetalle,
                inscripcionId: inscripcionId,
                nombreJugador: nombreJugador,
                onSuccess: onSuccess,
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  State<CancelarInscripcionAdminDialog> createState() =>
      _CancelarInscripcionAdminDialogState();
}

class _CancelarInscripcionAdminDialogState
    extends State<CancelarInscripcionAdminDialog> {
  /// RN-003: Checkbox para anular deuda
  bool _anularDeuda = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < DesignTokens.breakpointMobile;

    return BlocConsumer<CancelarInscripcionBloc, CancelarInscripcionState>(
      listener: (context, state) {
        if (state is CancelacionAdminExitosa) {
          // Cerrar el dialog
          Navigator.of(context).pop();

          // Mostrar mensaje de exito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      'Inscripcion de ${state.nombreJugador} cancelada${state.deudaAnulada ? '. Deuda anulada.' : '.'}',
                    ),
                  ),
                ],
              ),
              backgroundColor: DesignTokens.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Callback de exito
          widget.onSuccess?.call();
        }

        if (state is CancelarInscripcionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: DesignTokens.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is CancelarInscripcionLoading;

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
                  Icons.admin_panel_settings,
                  color: colorScheme.error,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'Cancelar Inscripcion (Admin)',
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
                      onPressed:
                          isLoading ? null : () => _confirmarCancelacion(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cancel),
                      label: const Text('Confirmar'),
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
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: colorScheme.onErrorContainer,
                    size: DesignTokens.iconSizeL,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancelar Inscripcion (Admin)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                      ),
                      Text(
                        'Accion administrativa',
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
                  onPressed:
                      isLoading ? null : () => _confirmarCancelacion(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cancel),
                  label: const Text('Confirmar Cancelacion'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido compartido
  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final fecha = widget.fechaDetalle.fecha;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Advertencia
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: DesignTokens.accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber,
                color: DesignTokens.accentColor,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accion administrativa',
                      style: TextStyle(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: DesignTokens.accentColor,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      'Vas a cancelar la inscripcion de otro jugador. Esta accion enviara una notificacion al jugador afectado.',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: DesignTokens.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Jugador afectado
        Text(
          'Jugador afectado',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),

        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Text(
                  widget.nombreJugador.isNotEmpty
                      ? widget.nombreJugador[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Text(
                  widget.nombreJugador,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Detalles de la fecha
        Text(
          'Detalles de la pichanga',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),

        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
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
                icon: Icons.location_on,
                label: 'Lugar',
                value: fecha.lugar,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildResumenRow(
                context,
                icon: Icons.attach_money,
                label: 'Costo',
                value: fecha.costoFormato,
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // RN-003: Checkbox para anular deuda
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _anularDeuda,
                onChanged: (value) {
                  setState(() {
                    _anularDeuda = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anular deuda pendiente',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                    Text(
                      'Si esta marcado, la deuda de ${fecha.costoFormato} sera anulada.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingM),

        // Consecuencias
        Text(
          'Al confirmar:',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        _buildConsequenceItem(
          context,
          icon: Icons.person_remove,
          text: '${widget.nombreJugador} sera eliminado de la lista de inscritos',
        ),
        if (_anularDeuda)
          _buildConsequenceItem(
            context,
            icon: Icons.money_off,
            text: 'La deuda de ${fecha.costoFormato} sera anulada',
          )
        else
          _buildConsequenceItem(
            context,
            icon: Icons.attach_money,
            text: 'La deuda de ${fecha.costoFormato} se mantendra pendiente',
            isWarning: true,
          ),
        _buildConsequenceItem(
          context,
          icon: Icons.notifications,
          text: '${widget.nombreJugador} recibira una notificacion de la cancelacion',
        ),
      ],
    );
  }

  /// Fila del resumen
  Widget _buildResumenRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: colorScheme.onSurfaceVariant,
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
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
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
    bool isWarning = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color:
                isWarning ? DesignTokens.accentColor : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isWarning
                        ? DesignTokens.accentColor
                        : colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Envia la solicitud de cancelacion por admin
  void _confirmarCancelacion(BuildContext context) {
    context.read<CancelarInscripcionBloc>().add(
          CancelarInscripcionAdminEvent(
            inscripcionId: widget.inscripcionId,
            anularDeuda: _anularDeuda,
          ),
        );
  }
}
