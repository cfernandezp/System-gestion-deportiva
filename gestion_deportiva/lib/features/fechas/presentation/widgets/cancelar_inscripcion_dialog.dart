import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../bloc/cancelar_inscripcion/cancelar_inscripcion.dart';

/// Dialog de confirmacion para cancelar inscripcion de una fecha
/// E003-HU-007: Cancelar Inscripcion
///
/// Criterios de Aceptacion:
/// - CA-001: Opcion de cancelar visible solo si usuario esta inscrito
/// - CA-002: Mensaje de confirmacion "Estas seguro de cancelar tu inscripcion?"
/// - CA-003: Cancelacion exitosa con deuda anulada
/// - CA-004: Re-inscripcion permitida
/// - CA-005: Si fecha cerrada, mostrar mensaje y deshabilitar boton
///
/// Reglas de Negocio:
/// - RN-001: Cancelacion libre si fecha abierta
/// - RN-002: Bloqueo si fecha cerrada
/// - RN-003: Deuda se anula automaticamente si fecha abierta
class CancelarInscripcionDialog extends StatefulWidget {
  /// Detalle de la fecha de la cual cancelar inscripcion
  final FechaDetalleModel fechaDetalle;

  /// Callback cuando se cancela exitosamente
  final VoidCallback? onSuccess;

  const CancelarInscripcionDialog({
    super.key,
    required this.fechaDetalle,
    this.onSuccess,
  });

  /// Muestra el dialog de cancelar inscripcion
  /// Mobile: BottomSheet
  /// Desktop: Dialog centrado
  static Future<void> show(
    BuildContext context, {
    required FechaDetalleModel fechaDetalle,
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
          create: (context) => sl<CancelarInscripcionBloc>()
            ..add(VerificarPuedeCancelarEvent(
                fechaId: fechaDetalle.fecha.fechaId)),
          child: CancelarInscripcionDialog(
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
          create: (context) => sl<CancelarInscripcionBloc>()
            ..add(VerificarPuedeCancelarEvent(
                fechaId: fechaDetalle.fecha.fechaId)),
          child: Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
                maxHeight: 600,
              ),
              child: CancelarInscripcionDialog(
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
  State<CancelarInscripcionDialog> createState() =>
      _CancelarInscripcionDialogState();
}

class _CancelarInscripcionDialogState extends State<CancelarInscripcionDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < DesignTokens.breakpointMobile;

    return BlocConsumer<CancelarInscripcionBloc, CancelarInscripcionState>(
      listener: (context, state) {
        if (state is CancelacionUsuarioExitosa) {
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
                      state.deudaAnulada
                          ? 'Inscripcion cancelada. Tu deuda ha sido anulada.'
                          : state.message,
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
          // Si es error por fecha cerrada, no cerrar dialog, mostrar el mensaje
          if (!state.esFechaCerrada) {
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
        }
      },
      builder: (context, state) {
        final isLoading = state is CancelarInscripcionLoading;
        final verificacion =
            state is VerificacionCargada ? state.verificacion : null;
        final error = state is CancelarInscripcionError ? state : null;

        if (isMobile) {
          return _buildBottomSheetContent(
            context,
            colorScheme,
            isLoading,
            verificacion,
            error,
          );
        } else {
          return _buildDialogContent(
            context,
            colorScheme,
            isLoading,
            verificacion,
            error,
          );
        }
      },
    );
  }

  /// Contenido para BottomSheet (Mobile)
  Widget _buildBottomSheetContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLoading,
    dynamic verificacion,
    CancelarInscripcionError? error,
  ) {
    // Determinar si puede cancelar
    final puedeCancelar = verificacion?.puedeCancelar ?? false;
    final fechaCerrada = verificacion?.fechaCerrada ?? error?.esFechaCerrada ?? false;

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
                  Icons.cancel_outlined,
                  color: colorScheme.error,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'Cancelar Inscripcion',
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
              child: _buildContent(
                context,
                colorScheme,
                isLoading,
                verificacion,
                error,
              ),
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
                      child: const Text('No, mantenerme'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: (isLoading || !puedeCancelar || fechaCerrada)
                          ? null
                          : () => _confirmarCancelacion(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        disabledBackgroundColor:
                            colorScheme.error.withValues(alpha: 0.3),
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
                      label: const Text('Si, cancelar'),
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
    dynamic verificacion,
    CancelarInscripcionError? error,
  ) {
    // Determinar si puede cancelar
    final puedeCancelar = verificacion?.puedeCancelar ?? false;
    final fechaCerrada = verificacion?.fechaCerrada ?? error?.esFechaCerrada ?? false;

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
                    Icons.cancel_outlined,
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
                        'Cancelar Inscripcion',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                      ),
                      Text(
                        'Dejaras de asistir a esta pichanga',
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
              child: _buildContent(
                context,
                colorScheme,
                isLoading,
                verificacion,
                error,
              ),
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
                  child: const Text('No, mantenerme'),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                FilledButton.icon(
                  onPressed: (isLoading || !puedeCancelar || fechaCerrada)
                      ? null
                      : () => _confirmarCancelacion(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    disabledBackgroundColor:
                        colorScheme.error.withValues(alpha: 0.3),
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
                  label: const Text('Si, cancelar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido compartido del mensaje de confirmacion
  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLoading,
    dynamic verificacion,
    CancelarInscripcionError? error,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final fecha = widget.fechaDetalle.fecha;

    // Si esta cargando la verificacion
    if (isLoading && verificacion == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Determinar estado
    final puedeCancelar = verificacion?.puedeCancelar ?? false;
    final fechaCerrada =
        verificacion?.fechaCerrada ?? error?.esFechaCerrada ?? false;
    final deudaSeraAnulada = verificacion?.deudaSeraAnulada ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CA-005: Mensaje si fecha cerrada
        if (fechaCerrada) ...[
          _buildFechaCerradaWarning(context, colorScheme),
          const SizedBox(height: DesignTokens.spacingL),
        ],

        // CA-002: Mensaje de confirmacion
        if (puedeCancelar && !fechaCerrada) ...[
          Text(
            verificacion?.mensajeConfirmacion ??
                'Estas seguro de cancelar tu inscripcion?',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
        ],

        // Resumen de la fecha
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

        // RN-003: Mensaje sobre deuda anulada (solo si puede cancelar)
        if (puedeCancelar && !fechaCerrada && deudaSeraAnulada) ...[
          const SizedBox(height: DesignTokens.spacingM),
          _buildDeudaAnuladaInfo(context, colorScheme),
        ],

        // Consecuencias de cancelar
        if (puedeCancelar && !fechaCerrada) ...[
          const SizedBox(height: DesignTokens.spacingL),
          Text(
            'Al cancelar:',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _buildConsequenceItem(
            context,
            icon: Icons.person_remove,
            text: 'Tu nombre se eliminara de la lista de inscritos',
          ),
          if (deudaSeraAnulada)
            _buildConsequenceItem(
              context,
              icon: Icons.money_off,
              text: 'La deuda de ${fecha.costoFormato} sera anulada',
            ),
          _buildConsequenceItem(
            context,
            icon: Icons.restore,
            text: 'Podras volver a anotarte mientras las inscripciones sigan abiertas',
          ),
        ],
      ],
    );
  }

  /// CA-005: Banner de advertencia por fecha cerrada
  Widget _buildFechaCerradaWarning(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock,
            color: colorScheme.error,
            size: DesignTokens.iconSizeM,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inscripciones cerradas',
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  'Las inscripciones estan cerradas. Contacta al administrador para cancelar tu participacion.',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// RN-003: Informacion sobre deuda anulada
  Widget _buildDeudaAnuladaInfo(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: DesignTokens.successColor,
            size: DesignTokens.iconSizeM,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              'Tu deuda pendiente sera anulada automaticamente.',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: DesignTokens.successColor,
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
            color: colorScheme.onSurfaceVariant,
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

  /// Envia la solicitud de cancelacion
  void _confirmarCancelacion(BuildContext context) {
    context.read<CancelarInscripcionBloc>().add(
          CancelarInscripcionUsuarioEvent(
              fechaId: widget.fechaDetalle.fecha.fechaId),
        );
  }
}
