import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/registro/registro.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/registro_success_dialog.dart';

/// Pagina de registro de usuario
/// Implementa CA-001 a CA-005 y RN-002, RN-003, RN-009, RN-010
///
/// Layout Responsive:
/// - Mobile (<600px): Formulario ocupa ancho completo con padding
/// - Tablet/Desktop (>=600px): Card centrada con ancho maximo 420px
class RegistroPage extends StatelessWidget {
  const RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RegistroBloc>(),
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes para navegacion
  final _nombreFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Errores de validacion del servidor
  Map<String, String> _fieldErrors = {};

  // Password actual para el indicador de fuerza
  String _currentPassword = '';

  // CA-004: Error cuando contrasenas no coinciden
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // Limpiar errores previos
    setState(() {
      _fieldErrors = {};
      _confirmPasswordError = null;
    });

    context.read<RegistroBloc>().add(
          RegistroSubmitEvent(
            nombreCompleto: _nombreController.text,
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
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

    // Validar password en tiempo real (CA-003)
    context.read<RegistroBloc>().add(
          ValidarPasswordEvent(password: password),
        );
  }

  void _onConfirmPasswordChanged(String confirmPassword) {
    // CA-004: Validar coincidencia en tiempo real
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

    // Determinar si es mobile o tablet/desktop
    final isMobile = size.width < DesignTokens.breakpointMobile;
    final maxFormWidth = 420.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<RegistroBloc, RegistroState>(
        listener: (context, state) {
          if (state is RegistroSuccess) {
            // CA-005: Mostrar dialogo de exito con pendiente de aprobacion
            RegistroSuccessDialog.show(
              context,
              mensaje: state.response.mensaje,
              onDismiss: () {
                // Navegar a login
                if (context.mounted) {
                  context.go('/login');
                }
              },
            );
          } else if (state is RegistroError) {
            // CA-002: Mostrar error (email duplicado u otros)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(child: Text(state.message)),
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
          } else if (state is RegistroValidationError) {
            // Actualizar errores de campo
            setState(() {
              _fieldErrors = state.errores;
              // CA-004: Si hay error de confirmacion, mostrarlo
              if (state.errores.containsKey('confirmPassword')) {
                _confirmPasswordError = state.errores['confirmPassword'];
              }
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is RegistroLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
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

                      // CA-001: Formulario en Card
                      AppCard(
                        variant: isMobile
                            ? AppCardVariant.standard
                            : AppCardVariant.elevated,
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.all(
                          isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Titulo del formulario
                              Text(
                                'Crear cuenta',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: DesignTokens.fontWeightBold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingS),
                              Text(
                                'Tu cuenta sera revisada por un administrador',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingL),

                              // CA-001: Campo Nombre completo
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
                                onSubmitted: (_) => _emailFocus.requestFocus(),
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-001: Campo Email
                              AppTextField.email(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                errorText: _fieldErrors['email'],
                                enabled: !isLoading,
                                onSubmitted: (_) => _passwordFocus.requestFocus(),
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-001: Campo Password
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

                              // CA-003: Indicador visual de requisitos de contrasena
                              PasswordStrengthIndicator(
                                password: _currentPassword,
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-001: Campo Confirmar password
                              // CA-004: Feedback visual cuando no coinciden
                              AppTextField.password(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocus,
                                label: 'Confirmar contrasena',
                                hint: 'Repite tu contrasena',
                                errorText: _confirmPasswordError ??
                                    _fieldErrors['confirmPassword'],
                                enabled: !isLoading,
                                onChanged: _onConfirmPasswordChanged,
                                onSubmitted: (_) => _onSubmit(),
                                // Mostrar check verde si coinciden
                                showSuccessState: _confirmPasswordController
                                        .text.isNotEmpty &&
                                    _passwordController.text ==
                                        _confirmPasswordController.text,
                              ),
                              const SizedBox(height: DesignTokens.spacingXl),

                              // Boton de registro con estado de carga
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
        // Icono de la app
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
