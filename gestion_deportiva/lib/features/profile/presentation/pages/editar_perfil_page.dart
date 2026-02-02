import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../data/models/perfil_model.dart';
import '../bloc/perfil/perfil.dart';
import '../widgets/widgets.dart';

/// Pagina de edicion de perfil
/// E002-HU-002: Editar Perfil Propio
/// CA-001: Acceso a edicion desde perfil con boton "Editar"
class EditarPerfilPage extends StatefulWidget {
  final PerfilModel perfilInicial;

  const EditarPerfilPage({
    super.key,
    required this.perfilInicial,
  });

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para campos editables (CA-002 - actualizado 2026-01-16)
  late TextEditingController _nombreCompletoController;
  late TextEditingController _apodoController;
  late TextEditingController _telefonoController;
  late TextEditingController _fotoUrlController;

  // Posicion preferida seleccionada
  PosicionJugador? _posicionSeleccionada;

  // Control de cambios para RN-005
  bool _hayCambios = false;

  @override
  void initState() {
    super.initState();
    _nombreCompletoController = TextEditingController(text: widget.perfilInicial.nombreCompleto);
    _apodoController = TextEditingController(text: widget.perfilInicial.apodo);
    _telefonoController = TextEditingController(text: widget.perfilInicial.telefono ?? '');
    _fotoUrlController = TextEditingController(text: widget.perfilInicial.fotoUrl ?? '');
    _posicionSeleccionada = widget.perfilInicial.posicionPreferida;

    _nombreCompletoController.addListener(_onCambio);
    _apodoController.addListener(_onCambio);
    _telefonoController.addListener(_onCambio);
    _fotoUrlController.addListener(_onCambio);
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _apodoController.dispose();
    _telefonoController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  void _onCambio() {
    final cambio = _verificarCambios();
    if (cambio != _hayCambios) {
      setState(() => _hayCambios = cambio);
    }
  }

  bool _verificarCambios() {
    return _nombreCompletoController.text != widget.perfilInicial.nombreCompleto ||
        _apodoController.text != widget.perfilInicial.apodo ||
        _telefonoController.text != (widget.perfilInicial.telefono ?? '') ||
        _fotoUrlController.text != (widget.perfilInicial.fotoUrl ?? '') ||
        _posicionSeleccionada != widget.perfilInicial.posicionPreferida;
  }

  void _cancelar() {
    if (_hayCambios) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descartar cambios?'),
          content: const Text(
            'Tienes cambios sin guardar. Si sales ahora, se perderan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir editando'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _guardar() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PerfilBloc>().add(ActualizarPerfilEvent(
        nombreCompleto: _nombreCompletoController.text.trim(),
        apodo: _apodoController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        posicionPreferida: _posicionSeleccionada,
        fotoUrl: _fotoUrlController.text.trim().isEmpty
            ? null
            : _fotoUrlController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PerfilBloc, PerfilState>(
      listener: (context, state) {
        if (state is PerfilUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.successColor,
            ),
          );
          Navigator.of(context).pop();
        }

        if (state is PerfilUpdateError) {
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
      child: PopScope(
        canPop: !_hayCambios,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _hayCambios) {
            _cancelar();
          }
        },
        child: ResponsiveLayout(
          mobileBody: _MobileEditView(
            formKey: _formKey,
            nombreCompletoController: _nombreCompletoController,
            apodoController: _apodoController,
            telefonoController: _telefonoController,
            fotoUrlController: _fotoUrlController,
            posicionSeleccionada: _posicionSeleccionada,
            perfilInicial: widget.perfilInicial,
            hayCambios: _hayCambios,
            onPosicionChanged: (value) {
              setState(() {
                _posicionSeleccionada = value;
                _hayCambios = _verificarCambios();
              });
            },
            onCancelar: _cancelar,
            onGuardar: _guardar,
          ),
          desktopBody: _DesktopEditView(
            formKey: _formKey,
            nombreCompletoController: _nombreCompletoController,
            apodoController: _apodoController,
            telefonoController: _telefonoController,
            fotoUrlController: _fotoUrlController,
            posicionSeleccionada: _posicionSeleccionada,
            perfilInicial: widget.perfilInicial,
            hayCambios: _hayCambios,
            onPosicionChanged: (value) {
              setState(() {
                _posicionSeleccionada = value;
                _hayCambios = _verificarCambios();
              });
            },
            onCancelar: _cancelar,
            onGuardar: _guardar,
          ),
        ),
      ),
    );
  }
}

// ============================================
// VISTA MOBILE - App Style
// ============================================

class _MobileEditView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCompletoController;
  final TextEditingController apodoController;
  final TextEditingController telefonoController;
  final TextEditingController fotoUrlController;
  final PosicionJugador? posicionSeleccionada;
  final PerfilModel perfilInicial;
  final bool hayCambios;
  final ValueChanged<PosicionJugador?> onPosicionChanged;
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;

  const _MobileEditView({
    required this.formKey,
    required this.nombreCompletoController,
    required this.apodoController,
    required this.telefonoController,
    required this.fotoUrlController,
    required this.posicionSeleccionada,
    required this.perfilInicial,
    required this.hayCambios,
    required this.onPosicionChanged,
    required this.onCancelar,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onCancelar,
        ),
        actions: [
          BlocBuilder<PerfilBloc, PerfilState>(
            builder: (context, state) {
              final isLoading = state is PerfilSaving;
              return TextButton(
                onPressed: isLoading || !hayCambios ? null : onGuardar,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              );
            },
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
              // Avatar
              _buildAvatarSection(colorScheme),
              const SizedBox(height: DesignTokens.spacingL),

              // Campos no editables
              _buildReadOnlySection(context),
              const SizedBox(height: DesignTokens.spacingL),

              // Campos editables
              _buildEditableSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ColorScheme colorScheme) {
    return Center(
      child: Column(
        children: [
          PerfilAvatar(
            fotoUrl: fotoUrlController.text.isEmpty ? null : fotoUrlController.text,
            nombreCompleto: perfilInicial.nombreCompleto,
            size: 100,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Toca para cambiar la foto',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: DesignTokens.fontSizeS,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: DesignTokens.iconSizeS,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'Dato no editable',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Para modificar el email, contacta a un administrador.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          TextFormField(
            initialValue: perfilInicial.email,
            decoration: const InputDecoration(
              labelText: 'Correo electronico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos editables',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Nombre completo (editable desde 2026-01-16)
        TextFormField(
          controller: nombreCompletoController,
          decoration: const InputDecoration(
            labelText: 'Nombre completo *',
            hintText: 'Tu nombre completo',
            prefixIcon: Icon(Icons.person_outline),
            helperText: 'Entre 2 y 100 caracteres',
          ),
          maxLength: 100,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) return 'El nombre es obligatorio';
            if (trimmed.length < 2) return 'El nombre debe tener al menos 2 caracteres';
            return null;
          },
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Apodo
        TextFormField(
          controller: apodoController,
          decoration: const InputDecoration(
            labelText: 'Apodo *',
            hintText: 'Tu apodo o alias',
            prefixIcon: Icon(Icons.badge_outlined),
            helperText: 'Entre 2 y 30 caracteres',
          ),
          maxLength: 30,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) return 'El apodo es obligatorio';
            if (trimmed.length < 2) return 'El apodo debe tener al menos 2 caracteres';
            return null;
          },
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Telefono
        TextFormField(
          controller: telefonoController,
          decoration: const InputDecoration(
            labelText: 'Telefono',
            hintText: 'Ej: +51 999 999 999',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          maxLength: 20,
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Posicion
        DropdownButtonFormField<PosicionJugador?>(
          value: posicionSeleccionada,
          decoration: const InputDecoration(
            labelText: 'Posicion preferida',
            prefixIcon: Icon(Icons.sports_soccer_outlined),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Sin especificar'),
            ),
            ...PosicionJugador.values.map((posicion) => DropdownMenuItem(
              value: posicion,
              child: Text(posicion.displayName),
            )),
          ],
          onChanged: onPosicionChanged,
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // URL de foto
        TextFormField(
          controller: fotoUrlController,
          decoration: const InputDecoration(
            labelText: 'URL de foto',
            hintText: 'https://ejemplo.com/mi-foto.jpg',
            prefixIcon: Icon(Icons.image_outlined),
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style (Modal/Panel)
// ============================================

class _DesktopEditView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCompletoController;
  final TextEditingController apodoController;
  final TextEditingController telefonoController;
  final TextEditingController fotoUrlController;
  final PosicionJugador? posicionSeleccionada;
  final PerfilModel perfilInicial;
  final bool hayCambios;
  final ValueChanged<PosicionJugador?> onPosicionChanged;
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;

  const _DesktopEditView({
    required this.formKey,
    required this.nombreCompletoController,
    required this.apodoController,
    required this.telefonoController,
    required this.fotoUrlController,
    required this.posicionSeleccionada,
    required this.perfilInicial,
    required this.hayCambios,
    required this.onPosicionChanged,
    required this.onCancelar,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingXl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacingXl),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                boxShadow: DesignTokens.shadowMd,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onCancelar,
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                        Expanded(
                          child: Text(
                            'Editar Perfil',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                          ),
                        ),
                        BlocBuilder<PerfilBloc, PerfilState>(
                          builder: (context, state) {
                            final isLoading = state is PerfilSaving;
                            return FilledButton(
                              onPressed: isLoading || !hayCambios ? null : onGuardar,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Guardar cambios'),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: DesignTokens.spacingL),
                    const Divider(),
                    const SizedBox(height: DesignTokens.spacingL),

                    // Avatar centrado
                    Center(
                      child: Column(
                        children: [
                          PerfilAvatar(
                            fotoUrl: fotoUrlController.text.isEmpty
                                ? null
                                : fotoUrlController.text,
                            nombreCompleto: perfilInicial.nombreCompleto,
                            size: 100,
                          ),
                          const SizedBox(height: DesignTokens.spacingS),
                          Text(
                            'Toca para cambiar la foto',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacingXl),

                    // Campos no editables
                    _buildReadOnlySection(context, textTheme, colorScheme),

                    const SizedBox(height: DesignTokens.spacingXl),

                    // Campos editables en grid de 2 columnas
                    _buildEditableSection(context, textTheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlySection(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: DesignTokens.iconSizeS,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'Dato no editable',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Contacta a un administrador para modificar el email',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Solo email no editable
          TextFormField(
            initialValue: perfilInicial.email,
            decoration: const InputDecoration(
              labelText: 'Correo electronico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos editables',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Grid de 2 columnas - Nombre y Apodo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: nombreCompletoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  hintText: 'Tu nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                  helperText: 'Entre 2 y 100 caracteres',
                ),
                maxLength: 100,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'El nombre es obligatorio';
                  if (trimmed.length < 2) return 'Minimo 2 caracteres';
                  return null;
                },
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: TextFormField(
                controller: apodoController,
                decoration: const InputDecoration(
                  labelText: 'Apodo *',
                  hintText: 'Tu apodo o alias',
                  prefixIcon: Icon(Icons.badge_outlined),
                  helperText: 'Entre 2 y 30 caracteres',
                ),
                maxLength: 30,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'El apodo es obligatorio';
                  if (trimmed.length < 2) return 'Minimo 2 caracteres';
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingM),

        // Grid de 2 columnas - Telefono y Posicion
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                  hintText: 'Ej: +51 999 999 999',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: DropdownButtonFormField<PosicionJugador?>(
                value: posicionSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Posicion preferida',
                  prefixIcon: Icon(Icons.sports_soccer_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin especificar'),
                  ),
                  ...PosicionJugador.values.map((posicion) => DropdownMenuItem(
                    value: posicion,
                    child: Text(posicion.displayName),
                  )),
                ],
                onChanged: onPosicionChanged,
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingM),

        // URL de foto (ancho completo)
        TextFormField(
          controller: fotoUrlController,
          decoration: const InputDecoration(
            labelText: 'URL de foto',
            hintText: 'https://ejemplo.com/mi-foto.jpg',
            prefixIcon: Icon(Icons.image_outlined),
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

// ============================================
// DIALOG DESKTOP - Modal para editar perfil
// Patron Dashboard/CRM: Edicion como popup modal
// ============================================

/// Dialog modal para editar perfil en desktop
/// Se abre sobre la pagina de perfil sin perder el contexto
class EditarPerfilDialog extends StatefulWidget {
  final PerfilModel perfilInicial;

  const EditarPerfilDialog({
    super.key,
    required this.perfilInicial,
  });

  @override
  State<EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<EditarPerfilDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCompletoController;
  late TextEditingController _apodoController;
  late TextEditingController _telefonoController;
  late TextEditingController _fotoUrlController;

  PosicionJugador? _posicionSeleccionada;
  bool _hayCambios = false;

  @override
  void initState() {
    super.initState();
    _nombreCompletoController =
        TextEditingController(text: widget.perfilInicial.nombreCompleto);
    _apodoController =
        TextEditingController(text: widget.perfilInicial.apodo);
    _telefonoController =
        TextEditingController(text: widget.perfilInicial.telefono ?? '');
    _fotoUrlController =
        TextEditingController(text: widget.perfilInicial.fotoUrl ?? '');
    _posicionSeleccionada = widget.perfilInicial.posicionPreferida;

    _nombreCompletoController.addListener(_onCambio);
    _apodoController.addListener(_onCambio);
    _telefonoController.addListener(_onCambio);
    _fotoUrlController.addListener(_onCambio);
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _apodoController.dispose();
    _telefonoController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  void _onCambio() {
    final cambio = _verificarCambios();
    if (cambio != _hayCambios) {
      setState(() => _hayCambios = cambio);
    }
  }

  bool _verificarCambios() {
    return _nombreCompletoController.text !=
            widget.perfilInicial.nombreCompleto ||
        _apodoController.text != widget.perfilInicial.apodo ||
        _telefonoController.text != (widget.perfilInicial.telefono ?? '') ||
        _fotoUrlController.text != (widget.perfilInicial.fotoUrl ?? '') ||
        _posicionSeleccionada != widget.perfilInicial.posicionPreferida;
  }

  void _cancelar() {
    if (_hayCambios) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descartar cambios?'),
          content: const Text(
            'Tienes cambios sin guardar. Si sales ahora, se perderan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir editando'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra AlertDialog
                Navigator.of(context).pop(); // Cierra EditarPerfilDialog
              },
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _guardar() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PerfilBloc>().add(ActualizarPerfilEvent(
            nombreCompleto: _nombreCompletoController.text.trim(),
            apodo: _apodoController.text.trim(),
            telefono: _telefonoController.text.trim().isEmpty
                ? null
                : _telefonoController.text.trim(),
            posicionPreferida: _posicionSeleccionada,
            fotoUrl: _fotoUrlController.text.trim().isEmpty
                ? null
                : _fotoUrlController.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<PerfilBloc, PerfilState>(
      listener: (context, state) {
        if (state is PerfilUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.successColor,
            ),
          );
          Navigator.of(context).pop(); // Cierra el dialog
        }

        if (state is PerfilUpdateError) {
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
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              boxShadow: DesignTokens.shadowLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del dialog
                _buildDialogHeader(textTheme, colorScheme),

                // Contenido scrolleable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignTokens.spacingL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          _buildAvatarSection(colorScheme, textTheme),
                          const SizedBox(height: DesignTokens.spacingL),

                          // Email no editable
                          _buildReadOnlySection(colorScheme, textTheme),
                          const SizedBox(height: DesignTokens.spacingL),

                          // Campos editables
                          _buildEditableSection(textTheme),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelar,
            tooltip: 'Cerrar',
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              'Editar Perfil',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
          ),
          BlocBuilder<PerfilBloc, PerfilState>(
            builder: (context, state) {
              final isLoading = state is PerfilSaving;
              return FilledButton(
                onPressed: isLoading || !_hayCambios ? null : _guardar,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        children: [
          PerfilAvatar(
            fotoUrl:
                _fotoUrlController.text.isEmpty ? null : _fotoUrlController.text,
            nombreCompleto: widget.perfilInicial.nombreCompleto,
            size: 80,
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Cambia la URL de foto abajo',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlySection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: DesignTokens.iconSizeS,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correo electronico',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  widget.perfilInicial.email,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre y Apodo en 2 columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _nombreCompletoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                maxLength: 100,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Obligatorio';
                  if (trimmed.length < 2) return 'Minimo 2 caracteres';
                  return null;
                },
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: TextFormField(
                controller: _apodoController,
                decoration: const InputDecoration(
                  labelText: 'Apodo *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                maxLength: 30,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Obligatorio';
                  if (trimmed.length < 2) return 'Minimo 2 caracteres';
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingS),

        // Telefono y Posicion en 2 columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: DropdownButtonFormField<PosicionJugador?>(
                value: _posicionSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Posicion preferida',
                  prefixIcon: Icon(Icons.sports_soccer_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin especificar'),
                  ),
                  ...PosicionJugador.values.map(
                    (posicion) => DropdownMenuItem(
                      value: posicion,
                      child: Text(posicion.displayName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _posicionSeleccionada = value;
                    _hayCambios = _verificarCambios();
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingS),

        // URL de foto
        TextFormField(
          controller: _fotoUrlController,
          decoration: const InputDecoration(
            labelText: 'URL de foto',
            hintText: 'https://ejemplo.com/mi-foto.jpg',
            prefixIcon: Icon(Icons.image_outlined),
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}
