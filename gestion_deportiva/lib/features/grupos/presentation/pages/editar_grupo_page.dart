import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/grupo_model.dart';
import '../bloc/editar_grupo/editar_grupo_bloc.dart';
import '../bloc/editar_grupo/editar_grupo_event.dart';
import '../bloc/editar_grupo/editar_grupo_state.dart';

/// Pantalla para editar un grupo deportivo
/// E002-HU-003: CA-001 a CA-005, RN-001 a RN-004
class EditarGrupoPage extends StatefulWidget {
  final String grupoId;

  const EditarGrupoPage({super.key, required this.grupoId});

  @override
  State<EditarGrupoPage> createState() => _EditarGrupoPageState();
}

class _EditarGrupoPageState extends State<EditarGrupoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _lemaController = TextEditingController();
  final _reglasController = TextEditingController();
  File? _imagenLogo;
  final _imagePicker = ImagePicker();

  // Valores originales para detectar cambios
  GrupoModel? _grupoOriginal;
  bool _formularioPrecargado = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _lemaController.dispose();
    _reglasController.dispose();
    super.dispose();
  }

  /// Pre-carga los campos del formulario con los datos del grupo
  void _precargarFormulario(GrupoModel grupo) {
    if (_formularioPrecargado) return;
    _grupoOriginal = grupo;
    _nombreController.text = grupo.nombre;
    _lemaController.text = grupo.lema ?? '';
    _reglasController.text = grupo.reglas ?? '';
    _formularioPrecargado = true;
  }

  /// Verifica si hay cambios respecto al grupo original
  bool get _hayCambios {
    if (_grupoOriginal == null) return false;
    if (_imagenLogo != null) return true;
    if (_nombreController.text.trim() != _grupoOriginal!.nombre) return true;
    if (_lemaController.text.trim() != (_grupoOriginal!.lema ?? '')) return true;
    if (_reglasController.text.trim() != (_grupoOriginal!.reglas ?? '')) return true;
    return false;
  }

  /// CA-003 / RN-003: Seleccionar imagen del logo
  Future<void> _seleccionarLogo() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileSize = await file.length();
    final extension = pickedFile.path.split('.').last.toLowerCase();

    // RN-003: Validar formato (JPG/PNG)
    if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo se aceptan imagenes JPG o PNG'),
            backgroundColor: DesignTokens.errorColor,
          ),
        );
      }
      return;
    }

    // RN-003: Validar tamano (max 2MB)
    if (fileSize > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen no debe superar los 2MB'),
            backgroundColor: DesignTokens.errorColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _imagenLogo = file;
    });
  }

  /// CA-003 / RN-004: Muestra dialogo de confirmacion con resumen de cambios
  void _mostrarConfirmacion() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cambios = <String>[];
    if (_nombreController.text.trim() != _grupoOriginal!.nombre) {
      cambios.add('Nombre: "${_grupoOriginal!.nombre}" -> "${_nombreController.text.trim()}"');
    }
    if (_lemaController.text.trim() != (_grupoOriginal!.lema ?? '')) {
      final lemaAnterior = _grupoOriginal!.lema ?? '(sin lema)';
      final lemaNuevo = _lemaController.text.trim().isEmpty
          ? '(sin lema)'
          : _lemaController.text.trim();
      cambios.add('Lema: "$lemaAnterior" -> "$lemaNuevo"');
    }
    if (_reglasController.text.trim() != (_grupoOriginal!.reglas ?? '')) {
      cambios.add('Reglas: actualizadas');
    }
    if (_imagenLogo != null) {
      cambios.add('Logo: nueva imagen seleccionada');
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar cambios'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se realizaran los siguientes cambios:'),
            const SizedBox(height: DesignTokens.spacingS),
            ...cambios.map((cambio) => Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('- ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(cambio)),
                    ],
                  ),
                )),
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
              _submitForm();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    context.read<EditarGrupoBloc>().add(EditarGrupoSubmitEvent(
          grupoId: widget.grupoId,
          nombre: _nombreController.text,
          lema: _lemaController.text.isNotEmpty ? _lemaController.text : null,
          reglas:
              _reglasController.text.isNotEmpty ? _reglasController.text : null,
          imagenLogo: _imagenLogo,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<EditarGrupoBloc, EditarGrupoState>(
      listener: (context, state) {
        if (state is EditarGrupoSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Grupo "${state.response.nombre}" actualizado exitosamente',
              ),
              backgroundColor: DesignTokens.successColor,
            ),
          );
          context.pop();
        } else if (state is EditarGrupoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        // Pre-cargar formulario cuando se cargue el detalle
        if (state is EditarGrupoDetalleCargado) {
          _precargarFormulario(state.grupo);
        }

        final isLoading = state is EditarGrupoLoading;
        final isGuardando = state is EditarGrupoGuardando ||
            state is EditarGrupoSubiendoLogo;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Editar Grupo'),
            centerTitle: true,
          ),
          body: _buildBody(
            state,
            colorScheme,
            textTheme,
            isLoading,
            isGuardando,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    EditarGrupoState state,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLoading,
    bool isGuardando,
  ) {
    // Estado de carga inicial
    if (isLoading && !_formularioPrecargado) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error al cargar el detalle (sin datos previos)
    if (state is EditarGrupoError && !_formularioPrecargado) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: DesignTokens.spacingL),
              FilledButton.icon(
                onPressed: () {
                  context.read<EditarGrupoBloc>().add(
                        CargarDetalleGrupoEvent(grupoId: widget.grupoId),
                      );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Formulario de edicion
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo circular
              Center(
                child: _buildLogoSelector(colorScheme, textTheme),
              ),
              const SizedBox(height: DesignTokens.spacingXl),

              // CA-002: Nombre del grupo (obligatorio)
              AppTextField(
                controller: _nombreController,
                label: 'Nombre del grupo',
                hint: 'Ej: Los Halcones FC',
                prefixIcon: Icons.group_outlined,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre del grupo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // RN-003: Lema del grupo (opcional)
              AppTextField(
                controller: _lemaController,
                label: 'Lema del grupo',
                hint: 'Ej: Juntos somos mas fuertes',
                prefixIcon: Icons.format_quote_outlined,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // RN-003: Reglas del grupo (opcional)
              AppTextField(
                controller: _reglasController,
                label: 'Reglas del grupo',
                hint: 'Describe las normas internas del grupo...',
                prefixIcon: Icons.rule_outlined,
                maxLines: 4,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Tipo de deporte fijo
              _buildDeporteChip(colorScheme, textTheme),
              const SizedBox(height: DesignTokens.spacingXl),

              // RN-004: Boton guardar - deshabilitado si no hay cambios
              FilledButton.icon(
                onPressed: isGuardando || !_hayCambios
                    ? null
                    : _mostrarConfirmacion,
                icon: isGuardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  state is EditarGrupoSubiendoLogo
                      ? 'Subiendo logo...'
                      : isGuardando
                          ? 'Guardando cambios...'
                          : 'Guardar Cambios',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spacingM,
                  ),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para seleccionar/editar el logo del grupo
  /// Si hay logoUrl existente: mostrar NetworkImage
  /// Si selecciona nuevo: mostrar FileImage
  /// Icono de camara overlay siempre visible
  Widget _buildLogoSelector(ColorScheme colorScheme, TextTheme textTheme) {
    return GestureDetector(
      onTap: _seleccionarLogo,
      child: Stack(
        children: [
          // Circulo del logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              image: _buildDecorationImage(),
            ),
            child: _imagenLogo == null && _grupoOriginal?.logoUrl == null
                ? Icon(
                    Icons.groups_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  )
                : null,
          ),
          // Icono de camara
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la imagen de decoracion segun el estado
  DecorationImage? _buildDecorationImage() {
    // Si se selecciono nueva imagen, usar FileImage
    if (_imagenLogo != null) {
      return DecorationImage(
        image: FileImage(_imagenLogo!),
        fit: BoxFit.cover,
      );
    }

    // Si hay logo existente del grupo, usar NetworkImage
    if (_grupoOriginal?.logoUrl != null &&
        _grupoOriginal!.logoUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_grupoOriginal!.logoUrl!),
        fit: BoxFit.cover,
      );
    }

    return null;
  }

  /// Chip de tipo de deporte fijo
  Widget _buildDeporteChip(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de deporte',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Chip(
          avatar: const Icon(Icons.sports_soccer, size: 18),
          label: const Text('Futbol'),
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
