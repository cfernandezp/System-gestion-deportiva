import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../../data/models/fecha_model.dart';
import '../bloc/finalizar_fecha/finalizar_fecha.dart';

/// Dialog/BottomSheet para finalizar una fecha de pichanga
/// E003-HU-010: Finalizar Fecha
///
/// CA-003: Dialog de confirmacion con opciones
/// CA-004: Campo opcional para comentarios
/// CA-005: Checkbox y campo para incidentes
class FinalizarFechaDialog extends StatefulWidget {
  /// Detalle de la fecha a finalizar
  final FechaDetalleModel fechaDetalle;

  /// Callback cuando se finaliza exitosamente
  final VoidCallback? onSuccess;

  const FinalizarFechaDialog({
    super.key,
    required this.fechaDetalle,
    this.onSuccess,
  });

  /// Muestra el dialog adaptado segun el dispositivo
  /// Mobile: BottomSheet
  /// Desktop: Dialog centrado
  static Future<void> show(
    BuildContext context, {
    required FechaDetalleModel fechaDetalle,
    VoidCallback? onSuccess,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => BlocProvider(
          create: (_) => sl<FinalizarFechaBloc>(),
          child: FinalizarFechaDialog(
            fechaDetalle: fechaDetalle,
            onSuccess: onSuccess,
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => BlocProvider(
          create: (_) => sl<FinalizarFechaBloc>(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusL),
                ),
              ),
              child: FinalizarFechaDialog(
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
  State<FinalizarFechaDialog> createState() => _FinalizarFechaDialogState();
}

class _FinalizarFechaDialogState extends State<FinalizarFechaDialog> {
  final _comentariosController = TextEditingController();
  final _incidenteController = TextEditingController();
  bool _huboIncidente = false;

  @override
  void dispose() {
    _comentariosController.dispose();
    _incidenteController.dispose();
    super.dispose();
  }

  bool get _puedeConfirmar {
    // Si hay incidente, debe tener descripcion
    if (_huboIncidente && _incidenteController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  /// Verifica si la fecha tiene equipos asignados
  /// Asumimos que si el estado es 'en_juego', los equipos ya fueron asignados
  bool _tieneEquiposAsignados() {
    final estado = widget.fechaDetalle.fecha.estado;
    return estado == EstadoFecha.enJuego;
  }

  void _confirmarFinalizacion() {
    if (!_puedeConfirmar) return;

    context.read<FinalizarFechaBloc>().add(FinalizarFechaSubmitEvent(
          fechaId: widget.fechaDetalle.fecha.fechaId,
          comentarios: _comentariosController.text.trim().isEmpty
              ? null
              : _comentariosController.text.trim(),
          huboIncidente: _huboIncidente,
          descripcionIncidente: _huboIncidente
              ? _incidenteController.text.trim()
              : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return BlocListener<FinalizarFechaBloc, FinalizarFechaState>(
      listener: (context, state) {
        if (state is FinalizarFechaSuccess) {
          Navigator.of(context).pop();
          widget.onSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.successColor,
            ),
          );
        }

        if (state is FinalizarFechaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      child: BlocBuilder<FinalizarFechaBloc, FinalizarFechaState>(
        builder: (context, state) {
          final isLoading = state is FinalizarFechaLoading;

          if (isDesktop) {
            return _buildDesktopDialog(
              context,
              colorScheme,
              textTheme,
              isLoading,
            );
          } else {
            return _buildMobileContent(
              context,
              colorScheme,
              textTheme,
              isLoading,
            );
          }
        },
      ),
    );
  }

  Widget _buildDesktopDialog(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLoading,
  ) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colorScheme, textTheme, isLoading),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spacingL),
                child: _buildContent(colorScheme, textTheme),
              ),
            ),
            _buildFooter(colorScheme, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLoading,
  ) {
    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: DesignTokens.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        _buildHeader(colorScheme, textTheme, isLoading),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: _buildContent(colorScheme, textTheme),
          ),
        ),
        _buildFooter(colorScheme, isLoading),
      ],
    );
  }

  Widget _buildHeader(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: const Color(0xFF9E9E9E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF9E9E9E),
              size: 28,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finalizar Pichanga',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                Text(
                  'Esta accion es permanente',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Advertencia
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  'Una vez finalizada, la fecha no podra ser modificada ni reabierta.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Resumen de la fecha
        Text(
          'RESUMEN DE LA PICHANGA',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightSemiBold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.calendar_today,
                'Fecha',
                widget.fechaDetalle.fecha.fechaFormato,
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildInfoRow(
                Icons.access_time,
                'Hora',
                widget.fechaDetalle.fecha.horaFormato,
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildInfoRow(
                Icons.location_on,
                'Lugar',
                widget.fechaDetalle.fecha.lugar,
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildInfoRow(
                Icons.people,
                'Inscritos',
                '${widget.fechaDetalle.totalInscritos} jugadores',
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildInfoRow(
                Icons.groups,
                'Equipos',
                _tieneEquiposAsignados()
                    ? 'Asignados'
                    : 'Sin asignar',
                colorScheme,
                textTheme,
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Comentarios opcionales
        Text(
          'COMENTARIOS (OPCIONAL)',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightSemiBold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        TextField(
          controller: _comentariosController,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Observaciones sobre la pichanga...',
            helperText: 'Ej: Buen partido, todos puntuales',
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Incidente
        Text(
          'REPORTE DE INCIDENTE',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightSemiBold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        CheckboxListTile(
          value: _huboIncidente,
          onChanged: (value) {
            setState(() {
              _huboIncidente = value ?? false;
              if (!_huboIncidente) {
                _incidenteController.clear();
              }
            });
          },
          title: const Text('Hubo algun incidente'),
          subtitle: Text(
            'Lesion, pelea, dano a infraestructura, etc.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        if (_huboIncidente) ...[
          const SizedBox(height: DesignTokens.spacingS),
          TextField(
            controller: _incidenteController,
            maxLines: 3,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Descripcion del incidente *',
              hintText: 'Describe lo que ocurrio...',
              errorText: _huboIncidente && _incidenteController.text.trim().isEmpty
                  ? 'La descripcion es obligatoria'
                  : null,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colorScheme, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          FilledButton.icon(
            onPressed: isLoading || !_puedeConfirmar
                ? null
                : _confirmarFinalizacion,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: const Text('Confirmar Finalizacion'),
          ),
        ],
      ),
    );
  }
}
