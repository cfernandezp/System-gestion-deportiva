import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../upgrade/presentation/models/upgrade_reason.dart';
import '../bloc/crear_grupo/crear_grupo_bloc.dart';
import '../bloc/crear_grupo/crear_grupo_event.dart';
import '../bloc/crear_grupo/crear_grupo_state.dart';

/// Pantalla para crear un grupo deportivo
/// E002-HU-001: CA-001 a CA-007, RN-001 a RN-008
class CrearGrupoPage extends StatefulWidget {
  const CrearGrupoPage({super.key});

  @override
  State<CrearGrupoPage> createState() => _CrearGrupoPageState();
}

class _CrearGrupoPageState extends State<CrearGrupoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _lemaController = TextEditingController();
  final _reglasController = TextEditingController();
  File? _imagenLogo;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nombreController.dispose();
    _lemaController.dispose();
    _reglasController.dispose();
    super.dispose();
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

  void _submitForm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<CrearGrupoBloc>().add(CrearGrupoSubmitEvent(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Grupo'),
        centerTitle: true,
      ),
      body: BlocListener<CrearGrupoBloc, CrearGrupoState>(
        listener: (context, state) {
          if (state is CrearGrupoSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Grupo "${state.response.nombre}" creado exitosamente',
                ),
                backgroundColor: DesignTokens.successColor,
              ),
            );
            // Navegar al home
            context.go('/');
          } else if (state is CrearGrupoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: DesignTokens.errorColor,
              ),
            );
          } else if (state is CrearGrupoLimiteAlcanzado) {
            // CA-006: Mostrar mensaje y sugerir upgrade
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: DesignTokens.accentColor,
                action: SnackBarAction(
                  label: 'Ver planes',
                  textColor: Colors.white,
                  onPressed: () {
                    context.go(
                      '/upgrade',
                      extra: UpgradeReason.limite(
                        recurso: 'grupos',
                        actual: state.limiteActual,
                        superior: state.limiteActual * 5,
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
        child: SafeArea(
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

                  // CA-001: Nombre del grupo (obligatorio)
                  AppTextField(
                    controller: _nombreController,
                    label: 'Nombre del grupo',
                    hint: 'Ej: Los Halcones FC',
                    prefixIcon: Icons.group_outlined,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre del grupo es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // RN-004: Lema del grupo (opcional)
                  AppTextField(
                    controller: _lemaController,
                    label: 'Lema del grupo',
                    hint: 'Ej: Juntos somos mas fuertes',
                    prefixIcon: Icons.format_quote_outlined,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // RN-005: Reglas del grupo (opcional)
                  AppTextField(
                    controller: _reglasController,
                    label: 'Reglas del grupo',
                    hint: 'Describe las normas internas del grupo...',
                    prefixIcon: Icons.rule_outlined,
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // CA-005 / RN-006: Tipo de deporte fijo
                  _buildDeporteChip(colorScheme, textTheme),
                  const SizedBox(height: DesignTokens.spacingXl),

                  // Boton de crear
                  BlocBuilder<CrearGrupoBloc, CrearGrupoState>(
                    builder: (context, state) {
                      final isLoading = state is CrearGrupoLoading ||
                          state is CrearGrupoSubiendoLogo;

                      return FilledButton.icon(
                        onPressed: isLoading ? null : _submitForm,
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
                        label: Text(
                          state is CrearGrupoSubiendoLogo
                              ? 'Subiendo logo...'
                              : isLoading
                                  ? 'Creando grupo...'
                                  : 'Crear Grupo',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.spacingM,
                          ),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget para seleccionar el logo del grupo
  /// CA-003: Tap para seleccionar imagen
  /// RN-003: Placeholder con inicial del nombre si no hay logo
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
              image: _imagenLogo != null
                  ? DecorationImage(
                      image: FileImage(_imagenLogo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imagenLogo == null
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

  /// CA-005 / RN-006: Chip de tipo de deporte fijo
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
