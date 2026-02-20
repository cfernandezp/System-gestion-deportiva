import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/registro_admin/registro_admin.dart';
import '../bloc/session/session.dart';
import '../widgets/password_strength_indicator.dart';

/// E001-HU-001: Pagina de registro de administrador
/// Registro con celular como identificador principal
///
/// Criterios de Aceptacion:
/// - CA-001: Registro exitoso con celular, nombre, contrasena
/// - CA-002: Celular ya registrado -> mensaje y sugerir login
/// - CA-003: Validacion de formato celular Peru (9 digitos, inicia con 9)
/// - CA-004: Validacion de contrasena segura
/// - CA-005: Nombre obligatorio
/// - CA-006: Pregunta de seguridad obligatoria
/// - CA-007: Email de respaldo opcional
/// - CA-008: Redireccion post-registro a crear primer grupo
class RegistroPage extends StatelessWidget {
  const RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RegistroAdminBloc>(),
      child: const _RegistroView(),
    );
  }
}

class _RegistroView extends StatefulWidget {
  const _RegistroView();

  @override
  State<_RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<_RegistroView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _celularController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _respuestaController = TextEditingController();
  final _emailRespaldoController = TextEditingController();

  // Focus nodes para navegacion
  final _nombreFocus = FocusNode();
  final _celularFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _respuestaFocus = FocusNode();
  final _emailRespaldoFocus = FocusNode();

  // Errores de validacion del servidor
  Map<String, String> _fieldErrors = {};

  // Password actual para el indicador de fuerza
  String _currentPassword = '';

  // CA-004: Error cuando contrasenas no coinciden
  String? _confirmPasswordError;

  // CA-006 / RN-004: Pregunta de seguridad seleccionada
  String? _preguntaSeleccionada;

  /// RN-004: Lista predefinida de preguntas de seguridad
  static const List<String> _preguntasSeguridad = [
    'Nombre de tu primer equipo',
    'Ciudad donde naciste',
    'Nombre de tu mejor amigo',
    'Apodo de infancia',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _celularController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _respuestaController.dispose();
    _emailRespaldoController.dispose();
    _nombreFocus.dispose();
    _celularFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _respuestaFocus.dispose();
    _emailRespaldoFocus.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // Limpiar errores previos
    setState(() {
      _fieldErrors = {};
      _confirmPasswordError = null;
    });

    context.read<RegistroAdminBloc>().add(
          RegistroAdminSubmitEvent(
            celular: _celularController.text,
            nombreCompleto: _nombreController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            preguntaSeguridad: _preguntaSeleccionada ?? '',
            respuestaSeguridad: _respuestaController.text,
            emailRespaldo: _emailRespaldoController.text.isNotEmpty
                ? _emailRespaldoController.text
                : null,
          ),
        );
  }

  void _onPasswordChanged(String password) {
    setState(() {
      _currentPassword = password;
      // CA-004: Validar coincidencia en tiempo real si ya hay confirmacion
      if (_confirmPasswordController.text.isNotEmpty) {
        _validatePasswordMatch();
      }
    });

    // CA-004: Validar password en tiempo real
    context.read<RegistroAdminBloc>().add(
          ValidarPasswordAdminEvent(password: password),
        );
  }

  void _onConfirmPasswordChanged(String confirmPassword) {
    _validatePasswordMatch();
  }

  // CA-004: Feedback visual cuando contrasenas no coinciden
  void _validatePasswordMatch() {
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = null;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Las contrasenas no coinciden';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    final isMobile = size.width < DesignTokens.breakpointMobile;
    final maxFormWidth = 420.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<RegistroAdminBloc, RegistroAdminState>(
        listener: (context, state) {
          if (state is RegistroAdminSuccess) {
            // CA-008 / RN-006: Cuenta activa inmediatamente
            // Actualizar SessionBloc y navegar
            // La sesion ya esta activa (no se cerro post-registro)
            context.read<SessionBloc>().add(
                  SessionAuthenticatedEvent(
                    usuarioId: state.response.usuarioId,
                    nombreCompleto: state.response.nombreCompleto,
                    email: '${state.response.celular}@gestiondeportiva.app',
                    rol: state.response.rol,
                  ),
                );
            // CA-008: Redirigir a home (crear grupo sera una pantalla futura)
            // El GoRouter redirige automaticamente via refreshListenable
          } else if (state is RegistroAdminError) {
            // CA-002: Mostrar error (celular duplicado u otros)
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
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(DesignTokens.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
              ),
            );
          } else if (state is RegistroAdminValidationError) {
            setState(() {
              _fieldErrors = state.errores;
              if (state.errores.containsKey('confirmPassword')) {
                _confirmPasswordError = state.errores['confirmPassword'];
              }
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is RegistroAdminLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
                  vertical: DesignTokens.spacingL,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header con logo/icono
                      _buildHeader(theme, colorScheme),
                      const SizedBox(height: DesignTokens.spacingXl),

                      // Formulario en Card
                      AppCard(
                        variant: isMobile
                            ? AppCardVariant.standard
                            : AppCardVariant.elevated,
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.all(
                          isMobile
                              ? DesignTokens.spacingM
                              : DesignTokens.spacingL,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Titulo del formulario
                              Text(
                                'Crear cuenta de administrador',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: DesignTokens.fontWeightBold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingS),
                              Text(
                                'Registrate para organizar tus partidos',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingL),

                              // CA-005: Campo Nombre completo
                              AppTextField(
                                controller: _nombreController,
                                focusNode: _nombreFocus,
                                label: 'Nombre completo',
                                hint: 'Ingresa tu nombre completo',
                                prefixIcon: Icons.person_outline,
                                textCapitalization: TextCapitalization.words,
                                errorText: _fieldErrors['nombreCompleto'],
                                enabled: !isLoading,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _celularFocus.requestFocus(),
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-003 / RN-002: Campo Celular
                              AppTextField(
                                controller: _celularController,
                                focusNode: _celularFocus,
                                label: 'Numero de celular',
                                hint: '9XX XXX XXX',
                                prefixIcon: Icons.phone_android,
                                keyboardType: TextInputType.phone,
                                errorText: _fieldErrors['celular'],
                                enabled: !isLoading,
                                textInputAction: TextInputAction.next,
                                maxLength: 9,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(9),
                                ],
                                onSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-004 / RN-003: Campo Password
                              AppTextField.password(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                label: 'Contrasena',
                                errorText: _fieldErrors['password'],
                                enabled: !isLoading,
                                onChanged: _onPasswordChanged,
                                onSubmitted: (_) =>
                                    _confirmPasswordFocus.requestFocus(),
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-004: Indicador visual de requisitos
                              PasswordStrengthIndicator(
                                password: _currentPassword,
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-004: Confirmar password
                              AppTextField.password(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocus,
                                label: 'Confirmar contrasena',
                                hint: 'Repite tu contrasena',
                                errorText: _confirmPasswordError ??
                                    _fieldErrors['confirmPassword'],
                                enabled: !isLoading,
                                onChanged: _onConfirmPasswordChanged,
                                showSuccessState: _confirmPasswordController
                                        .text.isNotEmpty &&
                                    _passwordController.text ==
                                        _confirmPasswordController.text,
                              ),
                              const SizedBox(height: DesignTokens.spacingL),

                              // Separador visual - Seguridad
                              _buildSectionDivider(
                                  theme, colorScheme, 'Seguridad'),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-006 / RN-004: Pregunta de seguridad
                              _buildPreguntaSeguridad(
                                  theme, colorScheme, isLoading),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-006 / RN-004: Respuesta de seguridad
                              AppTextField(
                                controller: _respuestaController,
                                focusNode: _respuestaFocus,
                                label: 'Respuesta',
                                hint: 'Tu respuesta a la pregunta',
                                prefixIcon: Icons.lock_outline,
                                textCapitalization: TextCapitalization.none,
                                errorText: _fieldErrors['respuestaSeguridad'],
                                enabled: !isLoading,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _emailRespaldoFocus.requestFocus(),
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-007 / RN-005: Email de respaldo (opcional)
                              AppTextField.email(
                                controller: _emailRespaldoController,
                                focusNode: _emailRespaldoFocus,
                                label: 'Email de respaldo (opcional)',
                                hint: 'tu@correo.com',
                                errorText: _fieldErrors['emailRespaldo'],
                                enabled: !isLoading,
                                onSubmitted: (_) => _onSubmit(),
                              ),
                              const SizedBox(height: DesignTokens.spacingXs),
                              Text(
                                'Solo se usara para recuperar tu contrasena si falla la pregunta de seguridad',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spacingXl),

                              // Boton de registro
                              AppButton(
                                label: 'Crear cuenta',
                                onPressed: isLoading ? null : _onSubmit,
                                isLoading: isLoading,
                                loadingLabel: 'Creando cuenta...',
                                isExpanded: true,
                                icon: Icons.person_add,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingL),

                      // Link a login
                      _buildLoginLink(theme, isLoading),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header con icono/logo de la app
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: DesignTokens.primaryGradient,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Gestion Deportiva',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Separador visual con titulo de seccion
  Widget _buildSectionDivider(
      ThemeData theme, ColorScheme colorScheme, String titulo) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: colorScheme.outlineVariant),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
          child: Text(
            titulo,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: colorScheme.outlineVariant),
        ),
      ],
    );
  }

  /// CA-006 / RN-004: Dropdown de preguntas de seguridad
  Widget _buildPreguntaSeguridad(
      ThemeData theme, ColorScheme colorScheme, bool isLoading) {
    final hasError = _fieldErrors.containsKey('preguntaSeguridad');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pregunta de seguridad',
          style: theme.textTheme.bodySmall?.copyWith(
            color: hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        DropdownButtonFormField<String>(
          initialValue: _preguntaSeleccionada,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.help_outline,
              color: hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
            ),
            hintText: 'Selecciona una pregunta',
            errorText: _fieldErrors['preguntaSeguridad'],
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
          ),
          isExpanded: true,
          items: _preguntasSeguridad.map((pregunta) {
            return DropdownMenuItem<String>(
              value: pregunta,
              child: Text(
                pregunta,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: isLoading
              ? null
              : (value) {
                  setState(() {
                    _preguntaSeleccionada = value;
                    // Limpiar error de pregunta al seleccionar
                    _fieldErrors.remove('preguntaSeguridad');
                  });
                  _respuestaFocus.requestFocus();
                },
        ),
      ],
    );
  }

  /// Link para ir a login
  Widget _buildLoginLink(ThemeData theme, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Ya tienes cuenta?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  context.go('/login');
                },
          child: Text(
            'Inicia sesion',
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    );
  }
}
