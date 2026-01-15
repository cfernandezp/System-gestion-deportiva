import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
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

  // Controladores para campos editables (CA-002)
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
    // Inicializar controladores con valores actuales
    _apodoController = TextEditingController(text: widget.perfilInicial.apodo);
    _telefonoController = TextEditingController(text: widget.perfilInicial.telefono ?? '');
    _fotoUrlController = TextEditingController(text: widget.perfilInicial.fotoUrl ?? '');
    _posicionSeleccionada = widget.perfilInicial.posicionPreferida;

    // Escuchar cambios para detectar modificaciones
    _apodoController.addListener(_onCambio);
    _telefonoController.addListener(_onCambio);
    _fotoUrlController.addListener(_onCambio);
  }

  @override
  void dispose() {
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
    return _apodoController.text != widget.perfilInicial.apodo ||
        _telefonoController.text != (widget.perfilInicial.telefono ?? '') ||
        _fotoUrlController.text != (widget.perfilInicial.fotoUrl ?? '') ||
        _posicionSeleccionada != widget.perfilInicial.posicionPreferida;
  }

  /// CA-006: Cancelar edicion mantiene datos originales
  /// RN-005: Los cambios no confirmados no afectan datos originales
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
                Navigator.of(context).pop(); // Cierra dialogo
                Navigator.of(context).pop(); // Cierra pagina edicion
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

  /// CA-004: Guardar cambios con confirmacion
  void _guardar() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PerfilBloc>().add(ActualizarPerfilEvent(
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
        // CA-004: Mostrar confirmacion al guardar exitosamente
        if (state is PerfilUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.successColor,
            ),
          );
          Navigator.of(context).pop();
        }

        // CA-005: Mostrar error si apodo duplicado
        if (state is PerfilUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
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
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Editar Perfil'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelar,
            ),
            actions: [
              BlocBuilder<PerfilBloc, PerfilState>(
                builder: (context, state) {
                  final isLoading = state is PerfilSaving;
                  return TextButton(
                    onPressed: isLoading || !_hayCambios ? null : _guardar,
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
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar con opcion de cambiar foto
                  _buildAvatarSection(colorScheme),

                  const SizedBox(height: DesignTokens.spacingL),

                  // CA-003: Campos NO editables (solo lectura)
                  _buildReadOnlySection(colorScheme, textTheme),

                  const SizedBox(height: DesignTokens.spacingL),

                  // CA-002: Campos editables
                  _buildEditableSection(colorScheme, textTheme),
                ],
              ),
            ),
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
            fotoUrl: _fotoUrlController.text.isEmpty ? null : _fotoUrlController.text,
            nombreCompleto: widget.perfilInicial.nombreCompleto,
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

  /// CA-003: Campos no editables - nombre completo y email
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
                'Datos no editables',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Para modificar estos datos, contacta a un administrador.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Nombre completo (no editable)
          TextFormField(
            initialValue: widget.perfilInicial.nombreCompleto,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
            enabled: false,
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Email (no editable)
          TextFormField(
            initialValue: widget.perfilInicial.email,
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

  /// CA-002: Campos editables
  Widget _buildEditableSection(ColorScheme colorScheme, TextTheme textTheme) {
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

        // Apodo (RN-004: 2-30 caracteres)
        TextFormField(
          controller: _apodoController,
          decoration: const InputDecoration(
            labelText: 'Apodo *',
            hintText: 'Tu apodo o alias',
            prefixIcon: Icon(Icons.badge_outlined),
            helperText: 'Entre 2 y 30 caracteres',
          ),
          maxLength: 30,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'El apodo es obligatorio';
            }
            if (trimmed.length < 2) {
              return 'El apodo debe tener al menos 2 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Telefono (opcional)
        TextFormField(
          controller: _telefonoController,
          decoration: const InputDecoration(
            labelText: 'Telefono',
            hintText: 'Ej: +51 999 999 999',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          maxLength: 20,
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Posicion preferida (opcional)
        DropdownButtonFormField<PosicionJugador?>(
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
            ...PosicionJugador.values.map((posicion) => DropdownMenuItem(
              value: posicion,
              child: Text(posicion.displayName),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _posicionSeleccionada = value;
              _hayCambios = _verificarCambios();
            });
          },
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // URL de foto (opcional)
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
