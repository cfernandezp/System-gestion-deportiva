import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/login/login.dart';
import '../bloc/session/session.dart';

/// E001-HU-002: Pagina de Inicio de Sesion
///
/// Criterios de Aceptacion:
/// - CA-001: Login exitoso con un solo grupo -> home directo
/// - CA-002: Login exitoso con multiples grupos -> seleccion de grupo
/// - CA-003: Credenciales incorrectas -> mensaje generico
/// - CA-004: Proteccion contra intentos repetidos (bloqueo temporal)
/// - CA-005: Cuenta pendiente de activacion -> informar
/// - CA-006: Sin grupos -> crear grupo
///
/// Reglas de Negocio:
/// - RN-001: Autenticacion por celular y contrasena
/// - RN-002: Bloqueo temporal tras 5 intentos fallidos (15 min)
/// - RN-003: Mensaje generico para credenciales invalidas
/// - RN-004: Navegacion post-login segun cantidad de grupos
/// - RN-005: Restriccion login para cuentas pendientes de activacion
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LoginBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _celularController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes para navegacion
  final _celularFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Errores de validacion
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _celularController.dispose();
    _passwordController.dispose();
    _celularFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// RN-001: Submit con celular y contrasena
  void _onSubmit() {
    // Limpiar errores previos
    setState(() {
      _fieldErrors = {};
    });

    context.read<LoginBloc>().add(
          LoginSubmitEvent(
            celular: _celularController.text,
            password: _passwordController.text,
          ),
        );
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
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // CA-001/CA-002/CA-006: Login exitoso
            // La navegacion es automatica via GoRouter.refreshListenable
            context.read<SessionBloc>().add(
                  SessionAuthenticatedEvent(
                    usuarioId: state.response.usuarioId,
                    nombreCompleto: state.response.nombreCompleto,
                    email: state.response.email,
                    rol: state.response.rol,
                  ),
                );
          } else if (state is LoginError) {
            // CA-003/CA-005: Mostrar mensaje de error apropiado
            _mostrarErrorSnackBar(context, state);
          } else if (state is LoginValidationError) {
            // Actualizar errores de campo
            setState(() {
              _fieldErrors = state.errores;
            });
          } else if (state is LoginBloqueoInfo && state.bloqueado) {
            // RN-002/CA-004: Mostrar mensaje de bloqueo
            _mostrarBloqueoSnackBar(context, state);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

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
                                'Iniciar sesion',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: DesignTokens.fontWeightBold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingS),
                              Text(
                                'Ingresa tu celular y contrasena',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingL),

                              // RN-001: Campo Celular (9 digitos, inicia con 9)
                              AppTextField.number(
                                controller: _celularController,
                                focusNode: _celularFocus,
                                label: 'Numero de celular',
                                hint: '9XXXXXXXX',
                                prefixIcon: Icons.phone_android,
                                maxLength: 9,
                                errorText: _fieldErrors['celular'],
                                enabled: !isLoading,
                                onSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // RN-001: Campo Password
                              AppTextField.password(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                label: 'Contrasena',
                                errorText: _fieldErrors['password'],
                                enabled: !isLoading,
                                onSubmitted: (_) => _onSubmit(),
                              ),
                              const SizedBox(height: DesignTokens.spacingS),

                              // Link a recuperacion de contrasena
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          context.go('/recuperar-contrasena');
                                        },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Olvidaste tu contrasena?',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spacingL),

                              // Boton de login con estado de carga
                              AppButton(
                                label: 'Iniciar sesion',
                                onPressed: isLoading ? null : _onSubmit,
                                isLoading: isLoading,
                                loadingLabel: 'Iniciando sesion...',
                                isExpanded: true,
                                icon: Icons.login,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingL),

                      // Link a registro
                      _buildRegistroLink(theme, isLoading),
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

  /// Link para ir a registro
  Widget _buildRegistroLink(ThemeData theme, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'No tienes cuenta?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  context.go('/registro');
                },
          child: Text(
            'Registrate',
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  /// CA-003/CA-005: Muestra SnackBar con mensaje de error apropiado
  /// RN-002, RN-003, RN-005: Mensajes diferenciados segun tipo de error
  void _mostrarErrorSnackBar(BuildContext context, LoginError state) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color backgroundColor;

    switch (state.errorType) {
      case LoginErrorType.credencialesInvalidas:
        icon = Icons.lock_outline;
        backgroundColor = colorScheme.error;
        break;
      case LoginErrorType.cuentaPendienteActivacion:
        // CA-005/RN-005: Cuenta pendiente de activacion
        icon = Icons.hourglass_empty;
        backgroundColor = Colors.orange;
        break;
      case LoginErrorType.cuentaPendiente:
        icon = Icons.hourglass_empty;
        backgroundColor = Colors.orange;
        break;
      case LoginErrorType.cuentaRechazada:
        icon = Icons.cancel_outlined;
        backgroundColor = colorScheme.error;
        break;
      case LoginErrorType.cuentaBloqueada:
        icon = Icons.timer_outlined;
        backgroundColor = Colors.orange;
        break;
      case LoginErrorType.validacion:
        icon = Icons.warning_amber;
        backgroundColor = Colors.orange;
        break;
      case LoginErrorType.servidor:
        icon = Icons.cloud_off;
        backgroundColor = colorScheme.error;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        duration: state.errorType == LoginErrorType.cuentaPendienteActivacion ||
                state.errorType == LoginErrorType.cuentaPendiente ||
                state.errorType == LoginErrorType.cuentaRechazada
            ? const Duration(seconds: 5)
            : const Duration(seconds: 4),
      ),
    );
  }

  /// RN-002/CA-004: Muestra SnackBar con informacion de bloqueo
  void _mostrarBloqueoSnackBar(BuildContext context, LoginBloqueoInfo state) {
    final mensaje = state.minutosRestantes != null
        ? 'Cuenta bloqueada. Intenta en ${state.minutosRestantes} minutos.'
        : 'Cuenta bloqueada temporalmente.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
