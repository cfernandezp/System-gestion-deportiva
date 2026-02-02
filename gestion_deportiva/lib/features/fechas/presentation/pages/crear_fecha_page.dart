import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../bloc/crear_fecha/crear_fecha.dart';

/// Pagina para crear una nueva fecha de pichanga
/// E003-HU-001: Crear Fecha
/// CA-001: Solo accesible para administradores (validado en backend)
/// Usa ResponsiveLayout: Mobile con Scaffold + Desktop con DashboardShell
class CrearFechaPage extends StatefulWidget {
  const CrearFechaPage({super.key});

  @override
  State<CrearFechaPage> createState() => _CrearFechaPageState();
}

class _CrearFechaPageState extends State<CrearFechaPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de campos (CA-002)
  late TextEditingController _lugarController;
  late TextEditingController _costoController;

  // Valores seleccionados
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 20, minute: 0);
  int _duracionHoras = 2; // Default: 2 horas
  int _numEquipos = 2; // Default: 2 equipos

  @override
  void initState() {
    super.initState();
    _lugarController = TextEditingController();
    _costoController = TextEditingController(text: '8.00');

    // Agregar listeners para actualizar el estado del boton
    _lugarController.addListener(_onFieldChanged);
    _costoController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _lugarController.removeListener(_onFieldChanged);
    _costoController.removeListener(_onFieldChanged);
    _lugarController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  /// Callback para actualizar UI cuando cambian los campos
  void _onFieldChanged() {
    setState(() {});
  }

  /// Combina fecha y hora en DateTime (CA-004)
  DateTime get _fechaHoraInicio {
    return DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      _horaSeleccionada.hour,
      _horaSeleccionada.minute,
    );
  }

  /// Valida que la fecha/hora sea futura (CA-004)
  bool get _esFechaFutura {
    return _fechaHoraInicio.isAfter(DateTime.now());
  }

  /// Obtiene costo parseado del controller
  double get _costoPorJugador {
    return double.tryParse(_costoController.text) ?? 8.00;
  }

  /// Obtiene info de formato basado en valores seleccionados
  String get _formatoInfo {
    if (_numEquipos == 2) {
      return '$_numEquipos equipos - S/ ${_costoPorJugador.toStringAsFixed(2)} por jugador';
    } else {
      return '$_numEquipos equipos con rotacion - S/ ${_costoPorJugador.toStringAsFixed(2)} por jugador';
    }
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

  /// Abre DatePicker para seleccionar fecha
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

  /// Abre TimePicker para seleccionar hora
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

  /// Valida el formulario completo
  bool get _formularioValido {
    final lugar = _lugarController.text.trim();
    final costo = double.tryParse(_costoController.text) ?? 0;
    return _esFechaFutura && lugar.length >= 3 && costo > 0;
  }

  /// Cancela y vuelve atras
  void _cancelar() {
    if (_lugarController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descartar cambios?'),
          content: const Text(
            'Si sales ahora, se perdera la informacion ingresada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir editando'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  /// Envia el formulario (CA-006)
  void _crearFecha() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_esFechaFutura) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La fecha y hora deben ser futuras',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: DesignTokens.errorColor,
          ),
        );
        return;
      }

      context.read<CrearFechaBloc>().add(CrearFechaSubmitEvent(
            fechaHoraInicio: _fechaHoraInicio,
            duracionHoras: _duracionHoras,
            lugar: _lugarController.text.trim(),
            numEquipos: _numEquipos,
            costoPorJugador: _costoPorJugador,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CrearFechaBloc, CrearFechaState>(
      listener: (context, state) {
        // CA-006: Mensaje de exito con resumen
        if (state is CrearFechaSuccess) {
          _mostrarExito(context, state);
        }

        // Error
        if (state is CrearFechaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      child: BlocBuilder<CrearFechaBloc, CrearFechaState>(
        builder: (context, state) {
          final isLoading = state is CrearFechaLoading;

          return ResponsiveLayout(
            mobileBody: _MobileView(
              formKey: _formKey,
              lugarController: _lugarController,
              costoController: _costoController,
              fechaFormateada: _fechaFormateada,
              horaFormateada: _horaFormateada,
              duracionHoras: _duracionHoras,
              numEquipos: _numEquipos,
              formatoInfo: _formatoInfo,
              esFechaFutura: _esFechaFutura,
              formularioValido: _formularioValido,
              isLoading: isLoading,
              onSeleccionarFecha: () => _seleccionarFecha(context),
              onSeleccionarHora: () => _seleccionarHora(context),
              onDuracionChanged: (value) {
                if (value != null) setState(() => _duracionHoras = value);
              },
              onEquiposChanged: (value) {
                if (value != null) setState(() => _numEquipos = value);
              },
              onCancelar: _cancelar,
              onCrear: _crearFecha,
            ),
            desktopBody: _DesktopView(
              formKey: _formKey,
              lugarController: _lugarController,
              costoController: _costoController,
              fechaFormateada: _fechaFormateada,
              horaFormateada: _horaFormateada,
              duracionHoras: _duracionHoras,
              numEquipos: _numEquipos,
              formatoInfo: _formatoInfo,
              esFechaFutura: _esFechaFutura,
              formularioValido: _formularioValido,
              isLoading: isLoading,
              onSeleccionarFecha: () => _seleccionarFecha(context),
              onSeleccionarHora: () => _seleccionarHora(context),
              onDuracionChanged: (value) {
                if (value != null) setState(() => _duracionHoras = value);
              },
              onEquiposChanged: (value) {
                if (value != null) setState(() => _numEquipos = value);
              },
              onCancelar: _cancelar,
              onCrear: _crearFecha,
            ),
          );
        },
      ),
    );
  }

  /// Muestra dialog de exito con resumen (CA-006)
  void _mostrarExito(BuildContext context, CrearFechaSuccess state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: DesignTokens.successColor,
          size: 48,
        ),
        title: const Text('Fecha creada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.message),
            const SizedBox(height: DesignTokens.spacingM),
            const Divider(),
            const SizedBox(height: DesignTokens.spacingS),
            _ResumenItem(
              icon: Icons.calendar_today,
              label: 'Fecha',
              value: state.fecha.fechaFormato,
            ),
            _ResumenItem(
              icon: Icons.location_on,
              label: 'Lugar',
              value: state.fecha.lugar,
            ),
            _ResumenItem(
              icon: Icons.groups,
              label: 'Formato',
              value: state.fecha.formatoJuego,
            ),
            _ResumenItem(
              icon: Icons.attach_money,
              label: 'Costo',
              value: state.fecha.costoFormato,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// VISTA MOBILE - App Style (Formulario/Modal)
// ============================================

class _MobileView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController lugarController;
  final TextEditingController costoController;
  final String fechaFormateada;
  final String horaFormateada;
  final int duracionHoras;
  final int numEquipos;
  final String formatoInfo;
  final bool esFechaFutura;
  final bool formularioValido;
  final bool isLoading;
  final VoidCallback onSeleccionarFecha;
  final VoidCallback onSeleccionarHora;
  final ValueChanged<int?> onDuracionChanged;
  final ValueChanged<int?> onEquiposChanged;
  final VoidCallback onCancelar;
  final VoidCallback onCrear;

  const _MobileView({
    required this.formKey,
    required this.lugarController,
    required this.costoController,
    required this.fechaFormateada,
    required this.horaFormateada,
    required this.duracionHoras,
    required this.numEquipos,
    required this.formatoInfo,
    required this.esFechaFutura,
    required this.formularioValido,
    required this.isLoading,
    required this.onSeleccionarFecha,
    required this.onSeleccionarHora,
    required this.onDuracionChanged,
    required this.onEquiposChanged,
    required this.onCancelar,
    required this.onCrear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Fecha'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onCancelar,
        ),
        actions: [
          TextButton(
            onPressed: isLoading || !formularioValido ? null : onCrear,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Crear'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header informativo
              _buildHeader(colorScheme),
              const SizedBox(height: DesignTokens.spacingL),

              // Selector de fecha (CA-002, CA-004)
              _buildFechaSelector(context, colorScheme),
              const SizedBox(height: DesignTokens.spacingM),

              // Selector de hora (CA-002)
              _buildHoraSelector(context, colorScheme),
              const SizedBox(height: DesignTokens.spacingM),

              // Selector de duracion (CA-002)
              _buildDuracionSelector(colorScheme),
              const SizedBox(height: DesignTokens.spacingM),

              // Selector de numero de equipos
              _buildEquiposSelector(colorScheme),
              const SizedBox(height: DesignTokens.spacingM),

              // Campo de costo por jugador
              _buildCostoField(),
              const SizedBox(height: DesignTokens.spacingM),

              // Info resumen de formato
              _buildFormatoInfo(colorScheme),
              const SizedBox(height: DesignTokens.spacingM),

              // Campo de lugar (CA-005)
              _buildLugarField(),
              const SizedBox(height: DesignTokens.spacingL),

              // Boton crear (para mobile tambien en body)
              FilledButton.icon(
                onPressed: isLoading || !formularioValido ? null : onCrear,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text('Crear Fecha de Pichanga'),
              ),
            ],
          ),
        ),
      ),
      // NOTA: No usamos bottomNavigationBar porque es una pagina de formulario/modal
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
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
          Icon(
            Icons.sports_soccer,
            color: colorScheme.primary,
            size: DesignTokens.iconSizeL,
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva fecha de pichanga',
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  'Los jugadores seran notificados automaticamente',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFechaSelector(BuildContext context, ColorScheme colorScheme) {
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
          onTap: onSeleccionarFecha,
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
                  Icons.calendar_today,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    fechaFormateada,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                    ),
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
        if (!esFechaFutura) ...[
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

  Widget _buildHoraSelector(BuildContext context, ColorScheme colorScheme) {
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
          onTap: onSeleccionarHora,
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
                    horaFormateada,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                    ),
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

  Widget _buildDuracionSelector(ColorScheme colorScheme) {
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
          selected: {duracionHoras},
          onSelectionChanged: (values) => onDuracionChanged(values.first),
        ),
      ],
    );
  }

  Widget _buildEquiposSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad de equipos *',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 2,
              label: Text('2'),
              icon: Icon(Icons.group),
            ),
            ButtonSegment(
              value: 3,
              label: Text('3'),
              icon: Icon(Icons.groups),
            ),
            ButtonSegment(
              value: 4,
              label: Text('4'),
              icon: Icon(Icons.groups),
            ),
          ],
          selected: {numEquipos},
          onSelectionChanged: (values) => onEquiposChanged(values.first),
        ),
      ],
    );
  }

  Widget _buildCostoField() {
    return TextFormField(
      controller: costoController,
      decoration: const InputDecoration(
        labelText: 'Costo por jugador (S/) *',
        hintText: 'Ej: 8.00',
        prefixIcon: Icon(Icons.attach_money),
        helperText: 'Monto que pagara cada jugador',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final costo = double.tryParse(value ?? '');
        if (costo == null || costo <= 0) {
          return 'Ingrese un monto valido mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildFormatoInfo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
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
                  'Resumen del formato',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  formatoInfo,
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
    );
  }

  Widget _buildLugarField() {
    return TextFormField(
      controller: lugarController,
      decoration: const InputDecoration(
        labelText: 'Lugar de la cancha *',
        hintText: 'Ej: Cancha Los Olivos, Av. Principal 123',
        prefixIcon: Icon(Icons.location_on),
        helperText: 'Minimo 3 caracteres',
      ),
      maxLength: 200,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return 'El lugar es obligatorio';
        if (trimmed.length < 3) return 'El lugar debe tener al menos 3 caracteres';
        return null;
      },
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style
// ============================================

class _DesktopView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController lugarController;
  final TextEditingController costoController;
  final String fechaFormateada;
  final String horaFormateada;
  final int duracionHoras;
  final int numEquipos;
  final String formatoInfo;
  final bool esFechaFutura;
  final bool formularioValido;
  final bool isLoading;
  final VoidCallback onSeleccionarFecha;
  final VoidCallback onSeleccionarHora;
  final ValueChanged<int?> onDuracionChanged;
  final ValueChanged<int?> onEquiposChanged;
  final VoidCallback onCancelar;
  final VoidCallback onCrear;

  const _DesktopView({
    required this.formKey,
    required this.lugarController,
    required this.costoController,
    required this.fechaFormateada,
    required this.horaFormateada,
    required this.duracionHoras,
    required this.numEquipos,
    required this.formatoInfo,
    required this.esFechaFutura,
    required this.formularioValido,
    required this.isLoading,
    required this.onSeleccionarFecha,
    required this.onSeleccionarHora,
    required this.onDuracionChanged,
    required this.onEquiposChanged,
    required this.onCancelar,
    required this.onCrear,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/fechas/crear',
      title: 'Crear Fecha',
      breadcrumbs: const ['Inicio', 'Fechas', 'Crear'],
      actions: [
        OutlinedButton.icon(
          onPressed: onCancelar,
          icon: const Icon(Icons.close),
          label: const Text('Cancelar'),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        FilledButton.icon(
          onPressed: isLoading || !formularioValido ? null : onCrear,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add),
          label: const Text('Crear Fecha'),
        ),
      ],
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildDesktopHeader(colorScheme, textTheme),
            const SizedBox(height: DesignTokens.spacingL),

            // Card del formulario - alineado a izquierda, usa espacio disponible
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grid de 2 columnas para fecha y hora
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFechaSelectorDesktop(colorScheme),
                      ),
                      const SizedBox(width: DesignTokens.spacingL),
                      Expanded(
                        child: _buildHoraSelectorDesktop(colorScheme),
                      ),
                    ],
                  ),

                  const SizedBox(height: DesignTokens.spacingL),

                  // Duracion y equipos en 2 columnas
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duracion
                      Expanded(
                        child: _buildDuracionSelectorDesktop(colorScheme),
                      ),
                      const SizedBox(width: DesignTokens.spacingL),
                      // Equipos
                      Expanded(
                        child: _buildEquiposSelectorDesktop(colorScheme),
                      ),
                    ],
                  ),

                  const SizedBox(height: DesignTokens.spacingL),

                  // Costo y resumen formato en 2 columnas
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Costo por jugador
                      Expanded(
                        child: _buildCostoFieldDesktop(),
                      ),
                      const SizedBox(width: DesignTokens.spacingL),
                      // Info de formato
                      Expanded(
                        child: _buildFormatoInfoDesktop(colorScheme),
                      ),
                    ],
                  ),

                  const SizedBox(height: DesignTokens.spacingL),

                  // Lugar (full width)
                  _buildLugarFieldDesktop(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.sports_soccer,
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
                'Nueva fecha de pichanga',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                'Complete los datos para crear una nueva jornada. Los jugadores seran notificados automaticamente.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFechaSelectorDesktop(ColorScheme colorScheme) {
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
          onTap: onSeleccionarFecha,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: !esFechaFutura ? colorScheme.error : colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: !esFechaFutura ? colorScheme.error : colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    fechaFormateada,
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
        if (!esFechaFutura) ...[
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

  Widget _buildHoraSelectorDesktop(ColorScheme colorScheme) {
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
          onTap: onSeleccionarHora,
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
                    horaFormateada,
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

  Widget _buildDuracionSelectorDesktop(ColorScheme colorScheme) {
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
          selected: {duracionHoras},
          onSelectionChanged: (values) => onDuracionChanged(values.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.comfortable,
          ),
        ),
      ],
    );
  }

  Widget _buildEquiposSelectorDesktop(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad de equipos *',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 2,
              label: Text('2 equipos'),
              icon: Icon(Icons.group),
            ),
            ButtonSegment(
              value: 3,
              label: Text('3 equipos'),
              icon: Icon(Icons.groups),
            ),
            ButtonSegment(
              value: 4,
              label: Text('4 equipos'),
              icon: Icon(Icons.groups),
            ),
          ],
          selected: {numEquipos},
          onSelectionChanged: (values) => onEquiposChanged(values.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.comfortable,
          ),
        ),
      ],
    );
  }

  Widget _buildCostoFieldDesktop() {
    return TextFormField(
      controller: costoController,
      decoration: const InputDecoration(
        labelText: 'Costo por jugador (S/) *',
        hintText: 'Ej: 8.00',
        prefixIcon: Icon(Icons.attach_money),
        helperText: 'Monto que pagara cada jugador',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final costo = double.tryParse(value ?? '');
        if (costo == null || costo <= 0) {
          return 'Ingrese un monto valido mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildFormatoInfoDesktop(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Icon(
              numEquipos == 2 ? Icons.group : Icons.groups,
              color: colorScheme.secondary,
              size: DesignTokens.iconSizeL,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del formato',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  formatoInfo,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeL,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  numEquipos == 2
                      ? 'Partido continuo entre 2 equipos'
                      : 'Rotacion: ganador continua, perdedor descansa',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLugarFieldDesktop() {
    return TextFormField(
      controller: lugarController,
      decoration: const InputDecoration(
        labelText: 'Lugar de la cancha *',
        hintText: 'Ej: Cancha Los Olivos, Av. Principal 123',
        prefixIcon: Icon(Icons.location_on),
        helperText: 'Ingrese el nombre de la cancha o direccion completa (minimo 3 caracteres)',
      ),
      maxLength: 200,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return 'El lugar es obligatorio';
        if (trimmed.length < 3) return 'El lugar debe tener al menos 3 caracteres';
        return null;
      },
    );
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Widget para mostrar items del resumen de exito
class _ResumenItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ResumenItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            '$label:',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: DesignTokens.fontSizeS,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
