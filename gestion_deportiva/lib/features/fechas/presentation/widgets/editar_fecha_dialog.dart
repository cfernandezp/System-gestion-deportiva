import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../bloc/editar_fecha/editar_fecha.dart';

/// Dialog/BottomSheet para editar una fecha de pichanga
/// E003-HU-008: Editar Fecha
/// CA-003: Formulario precargado con valores actuales
/// CA-004: Muestra calculo automatico de formato y costo
/// CA-005: Validacion de fecha futura
/// CA-006: Confirmacion con resumen de cambios
class EditarFechaDialog extends StatefulWidget {
  /// Detalle de la fecha a editar
  final FechaDetalleModel fechaDetalle;

  /// Callback cuando se edita exitosamente
  final VoidCallback? onSuccess;

  const EditarFechaDialog({
    super.key,
    required this.fechaDetalle,
    this.onSuccess,
  });

  /// Muestra el dialog de edicion
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
          create: (context) => sl<EditarFechaBloc>()
            ..add(EditarFechaInicializarEvent(
              fechaId: fechaDetalle.fecha.fechaId,
              fechaHoraInicio: fechaDetalle.fecha.fechaHoraInicio,
              duracionHoras: fechaDetalle.fecha.duracionHoras,
              lugar: fechaDetalle.fecha.lugar,
              costoActual: fechaDetalle.fecha.costoPorJugador,
              totalInscritos: fechaDetalle.totalInscritos,
            )),
          child: EditarFechaDialog(
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
          create: (context) => sl<EditarFechaBloc>()
            ..add(EditarFechaInicializarEvent(
              fechaId: fechaDetalle.fecha.fechaId,
              fechaHoraInicio: fechaDetalle.fecha.fechaHoraInicio,
              duracionHoras: fechaDetalle.fecha.duracionHoras,
              lugar: fechaDetalle.fecha.lugar,
              costoActual: fechaDetalle.fecha.costoPorJugador,
              totalInscritos: fechaDetalle.totalInscritos,
            )),
          child: Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
                maxHeight: 700,
              ),
              child: EditarFechaDialog(
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
  State<EditarFechaDialog> createState() => _EditarFechaDialogState();
}

class _EditarFechaDialogState extends State<EditarFechaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lugarController;

  // Valores editables
  late DateTime _fechaSeleccionada;
  late TimeOfDay _horaSeleccionada;
  late int _duracionHoras;

  // Valores originales para comparar
  late DateTime _fechaOriginal;
  late int _duracionOriginal;
  late String _lugarOriginal;

  @override
  void initState() {
    super.initState();
    final fecha = widget.fechaDetalle.fecha;

    // Inicializar con valores actuales (CA-003)
    _fechaSeleccionada = DateTime(
      fecha.fechaHoraInicio.year,
      fecha.fechaHoraInicio.month,
      fecha.fechaHoraInicio.day,
    );
    _horaSeleccionada = TimeOfDay(
      hour: fecha.fechaHoraInicio.hour,
      minute: fecha.fechaHoraInicio.minute,
    );
    _duracionHoras = fecha.duracionHoras;
    _lugarController = TextEditingController(text: fecha.lugar);

    // Guardar originales
    _fechaOriginal = fecha.fechaHoraInicio;
    _duracionOriginal = fecha.duracionHoras;
    _lugarOriginal = fecha.lugar;
  }

  @override
  void dispose() {
    _lugarController.dispose();
    super.dispose();
  }

  /// Combina fecha y hora en DateTime
  DateTime get _fechaHoraInicio {
    return DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      _horaSeleccionada.hour,
      _horaSeleccionada.minute,
    );
  }

  /// CA-005: Valida que la fecha/hora sea futura
  bool get _esFechaFutura {
    return _fechaHoraInicio.isAfter(DateTime.now());
  }

  /// CA-004: Calcula el nuevo costo segun duracion (RN-003)
  double get _nuevoCosto {
    return _duracionHoras == 1 ? 8.00 : 10.00;
  }

  /// Verifica si el costo cambiaria
  bool get _costoCambiaria {
    return _nuevoCosto != widget.fechaDetalle.fecha.costoPorJugador;
  }

  /// Verifica si hay cambios
  bool get _hayCambios {
    final fechaCambio = _fechaHoraInicio != _fechaOriginal;
    final duracionCambio = _duracionHoras != _duracionOriginal;
    final lugarCambio = _lugarController.text.trim() != _lugarOriginal;
    return fechaCambio || duracionCambio || lugarCambio;
  }

  /// Valida el formulario completo
  bool get _formularioValido {
    final lugar = _lugarController.text.trim();
    return _esFechaFutura && lugar.length >= 3 && _hayCambios;
  }

  /// Formatea fecha para mostrar (Peru)
  String get _fechaFormateada {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${_fechaSeleccionada.day} de ${meses[_fechaSeleccionada.month - 1]} de ${_fechaSeleccionada.year}';
  }

  /// Formatea hora para mostrar (formato 24h)
  String get _horaFormateada {
    return '${_horaSeleccionada.hour.toString().padLeft(2, '0')}:${_horaSeleccionada.minute.toString().padLeft(2, '0')}';
  }

  /// Abre DatePicker
  Future<void> _seleccionarFecha(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'PE'),
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  /// Abre TimePicker
  Future<void> _seleccionarHora(BuildContext context) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() => _horaSeleccionada = hora);
    }
  }

  /// CA-006: Muestra dialogo de confirmacion con resumen de cambios
  void _mostrarConfirmacion(BuildContext context) {
    final totalInscritos = widget.fechaDetalle.totalInscritos;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.edit_calendar,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Confirmar cambios'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de cambios:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),

            // Mostrar cambios
            if (_fechaHoraInicio != _fechaOriginal)
              _ConfirmacionItem(
                icon: Icons.calendar_today,
                label: 'Fecha/Hora',
                oldValue: _formatearFechaHora(_fechaOriginal),
                newValue: '$_fechaFormateada - $_horaFormateada',
              ),

            if (_duracionHoras != _duracionOriginal)
              _ConfirmacionItem(
                icon: Icons.timer,
                label: 'Duracion',
                oldValue: '$_duracionOriginal hora${_duracionOriginal != 1 ? 's' : ''}',
                newValue: '$_duracionHoras hora${_duracionHoras != 1 ? 's' : ''}',
              ),

            if (_lugarController.text.trim() != _lugarOriginal)
              _ConfirmacionItem(
                icon: Icons.location_on,
                label: 'Lugar',
                oldValue: _lugarOriginal,
                newValue: _lugarController.text.trim(),
              ),

            // CA-004: Advertencia de cambio de costo
            if (_costoCambiaria) ...[
              const SizedBox(height: DesignTokens.spacingM),
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
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: DesignTokens.accentColor,
                      size: DesignTokens.iconSizeM,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'El costo cambiara de S/ ${widget.fechaDetalle.fecha.costoPorJugador.toStringAsFixed(2)} a S/ ${_nuevoCosto.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: DesignTokens.accentColor,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Mostrar cantidad de inscritos a notificar
            if (totalInscritos > 0) ...[
              const SizedBox(height: DesignTokens.spacingM),
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Theme.of(context).colorScheme.primary,
                      size: DesignTokens.iconSizeM,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'Se notificara a $totalInscritos jugador${totalInscritos != 1 ? 'es' : ''} inscrito${totalInscritos != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _guardarCambios();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  /// Formatea fecha/hora para mostrar
  String _formatearFechaHora(DateTime dt) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${dt.day} de ${meses[dt.month - 1]} de ${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Envia los cambios al backend
  void _guardarCambios() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<EditarFechaBloc>().add(EditarFechaSubmitEvent(
        fechaId: widget.fechaDetalle.fecha.fechaId,
        fechaHoraInicio: _fechaHoraInicio,
        duracionHoras: _duracionHoras,
        lugar: _lugarController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return BlocConsumer<EditarFechaBloc, EditarFechaState>(
      listener: (context, state) {
        if (state is EditarFechaSuccess) {
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
          widget.onSuccess?.call();
        }

        if (state is EditarFechaError) {
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
        final isLoading = state is EditarFechaLoading;

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
                  Icons.edit_calendar,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'Editar Fecha',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Formulario scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              child: _buildFormulario(context, colorScheme),
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
                      onPressed: isLoading || !_formularioValido
                          ? null
                          : () => _mostrarConfirmacion(context),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Guardar Cambios'),
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
                    Icons.edit_calendar,
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
                        'Editar Fecha de Pichanga',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        'Modifica los datos de la fecha',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Formulario scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              child: _buildFormulario(context, colorScheme),
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
                  onPressed: isLoading || !_formularioValido
                      ? null
                      : () => _mostrarConfirmacion(context),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formulario de edicion compartido
  Widget _buildFormulario(BuildContext context, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de fecha
          _buildCampoFecha(context, colorScheme),
          const SizedBox(height: DesignTokens.spacingM),

          // Selector de hora
          _buildCampoHora(context, colorScheme),
          const SizedBox(height: DesignTokens.spacingM),

          // Selector de duracion
          _buildCampoDuracion(colorScheme),
          const SizedBox(height: DesignTokens.spacingM),

          // Campo de lugar
          _buildCampoLugar(),
          const SizedBox(height: DesignTokens.spacingM),

          // CA-004: Preview de formato y costo
          _buildPreviewFormato(colorScheme),
        ],
      ),
    );
  }

  Widget _buildCampoFecha(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha *',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        InkWell(
          onTap: () => _seleccionarFecha(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: !_esFechaFutura ? colorScheme.error : colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: !_esFechaFutura ? colorScheme.error : colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    _fechaFormateada,
                    style: const TextStyle(fontSize: DesignTokens.fontSizeM),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        // CA-005: Error de fecha pasada
        if (!_esFechaFutura) ...[
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'La fecha debe ser futura',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCampoHora(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hora de inicio *',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        InkWell(
          onTap: () => _seleccionarHora(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    _horaFormateada,
                    style: const TextStyle(fontSize: DesignTokens.fontSizeM),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoDuracion(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duracion *',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 1,
              label: Text('1 hora'),
              icon: Icon(Icons.timer),
            ),
            ButtonSegment(
              value: 2,
              label: Text('2 horas'),
              icon: Icon(Icons.timer),
            ),
          ],
          selected: {_duracionHoras},
          onSelectionChanged: (values) {
            setState(() => _duracionHoras = values.first);
          },
        ),
        // CA-004: Advertencia de cambio de costo si hay inscritos
        if (_costoCambiaria && widget.fechaDetalle.totalInscritos > 0) ...[
          const SizedBox(height: DesignTokens.spacingS),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: DesignTokens.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(
                color: DesignTokens.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: DesignTokens.accentColor,
                  size: DesignTokens.iconSizeS,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    'Hay ${widget.fechaDetalle.totalInscritos} inscrito${widget.fechaDetalle.totalInscritos != 1 ? 's' : ''}. El costo cambiara.',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: DesignTokens.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCampoLugar() {
    return TextFormField(
      controller: _lugarController,
      decoration: const InputDecoration(
        labelText: 'Lugar de la cancha *',
        hintText: 'Ej: Cancha Los Olivos, Av. Principal 123',
        prefixIcon: Icon(Icons.location_on),
        helperText: 'Minimo 3 caracteres',
      ),
      maxLength: 200,
      onChanged: (_) => setState(() {}),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return 'El lugar es obligatorio';
        if (trimmed.length < 3) return 'El lugar debe tener al menos 3 caracteres';
        return null;
      },
    );
  }

  /// CA-004: Preview de formato y costo actualizado
  Widget _buildPreviewFormato(ColorScheme colorScheme) {
    final numEquipos = _duracionHoras == 1 ? 2 : 3;
    final formatoDescripcion = _duracionHoras == 1
        ? '2 equipos - Partido continuo'
        : '3 equipos con rotacion';

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                numEquipos == 2 ? Icons.group : Icons.groups,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formato resultante',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      formatoDescripcion,
                      style: TextStyle(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Costo por jugador',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Row(
                      children: [
                        Text(
                          'S/ ${_nuevoCosto.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: DesignTokens.fontWeightBold,
                            fontSize: DesignTokens.fontSizeL,
                            color: _costoCambiaria
                                ? DesignTokens.accentColor
                                : colorScheme.onSecondaryContainer,
                          ),
                        ),
                        if (_costoCambiaria) ...[
                          const SizedBox(width: DesignTokens.spacingS),
                          Text(
                            '(antes: S/ ${widget.fechaDetalle.fecha.costoPorJugador.toStringAsFixed(2)})',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeS,
                              color: colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget para item en dialogo de confirmacion
class _ConfirmacionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String oldValue;
  final String newValue;

  const _ConfirmacionItem({
    required this.icon,
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        oldValue,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          color: colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingXs,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: DesignTokens.iconSizeS,
                        color: colorScheme.primary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        newValue,
                        style: TextStyle(
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
