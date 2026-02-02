import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/recuperacion/recuperacion.dart';

/// Pagina de solicitud de recuperacion de contrasena
/// Implementa HU-003: Recuperacion de Contrasena
///
/// Criterios de Aceptacion:
/// - CA-001: Formulario con campo email para solicitar recuperacion
/// - CA-002: Email de recuperacion enviado (estado RecuperacionEmailEnviado)
/// - CA-003: Mensaje uniforme (no revela si email existe) - RN-001
///
/// Layout Responsive:
/// - Mobile (<600px): Formulario ocupa ancho completo con padding
/// - Tablet/Desktop (>=600px): Card centrada con ancho maximo 420px
class SolicitarRecuperacionPage extends StatelessWidget {
  const SolicitarRecuperacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecuperacionBloc>(),
      child: const _SolicitarRecuperacionView(),
    );
  }
}

class _SolicitarRecuperacionView extends StatefulWidget {
  const _SolicitarRecuperacionView();

  @override
  State<_SolicitarRecuperacionView> createState() =>
      _SolicitarRecuperacionViewState();
}

class _SolicitarRecuperacionViewState
    extends State<_SolicitarRecuperacionView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  // Errores de validacion
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // Limpiar errores previos
    setState(() {
      _fieldErrors = {};
    });

    context.read<RecuperacionBloc>().add(
          SolicitarRecuperacionEvent(email: _emailController.text),
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
      body: BlocConsumer<RecuperacionBloc, RecuperacionState>(
        listener: (context, state) {
          if (state is RecuperacionEmailEnviado) {
            // CA-002, CA-003: Mostrar mensaje de exito (RN-001: siempre igual)
            _mostrarExitoSnackBar(context, state.mensaje);
          } else if (state is RecuperacionError) {
            // Mostrar error de servidor
            _mostrarErrorSnackBar(context, state.mensaje);
          } else if (state is RecuperacionValidationError) {
            // Actualizar errores de campo
            setState(() {
              _fieldErrors = state.errores;
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is RecuperacionLoading;
          final emailEnviado = state is RecuperacionEmailEnviado;

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
                      // Header con icono
                      _buildHeader(theme, colorScheme),
                      const SizedBox(height: DesignTokens.spacingXl),

                      // Contenido principal
                      if (emailEnviado)
                        _buildSuccessCard(
                            theme, colorScheme, isMobile, state.mensaje)
                      else
                        _buildFormCard(
                            theme, colorScheme, isMobile, isLoading),

                      const SizedBox(height: DesignTokens.spacingL),

                      // Link a login
                      _buildLoginLink(theme, isLoading || emailEnviado),
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

  /// Header con icono de recuperacion
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Icono de recuperacion
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
            Icons.lock_reset,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Recuperar contrasena',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// CA-001: Card con formulario de email
  Widget _buildFormCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    bool isLoading,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Descripcion
            Text(
              'Ingresa tu email y te enviaremos instrucciones para restablecer tu contrasena.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),

            // CA-001: Campo Email
            AppTextField.email(
              controller: _emailController,
              focusNode: _emailFocus,
              errorText: _fieldErrors['email'],
              enabled: !isLoading,
              onSubmitted: (_) => _onSubmit(),
            ),
            const SizedBox(height: DesignTokens.spacingL),

            // Boton de enviar
            AppButton(
              label: 'Enviar instrucciones',
              onPressed: isLoading ? null : _onSubmit,
              isLoading: isLoading,
              loadingLabel: 'Enviando...',
              isExpanded: true,
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }

  /// CA-002: Card de confirmacion de email enviado
  Widget _buildSuccessCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    String mensaje,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        children: [
          // Icono de exito
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DesignTokens.successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read,
              size: 32,
              color: DesignTokens.successColor,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Titulo
          Text(
            'Revisa tu correo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Mensaje (RN-001: siempre igual por seguridad)
          Text(
            mensaje,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Boton para volver a intentar
          TextButton.icon(
            onPressed: () {
              context.read<RecuperacionBloc>().add(
                    const RecuperacionResetEvent(),
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Enviar nuevamente'),
          ),
        ],
      ),
    );
  }

  /// Link para volver al login
  Widget _buildLoginLink(ThemeData theme, bool disabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.arrow_back,
          size: DesignTokens.iconSizeS,
          color: disabled
              ? theme.colorScheme.outline
              : theme.colorScheme.primary,
        ),
        TextButton(
          onPressed: disabled
              ? null
              : () {
                  context.go('/login');
                },
          child: Text(
            'Volver al login',
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  /// Muestra SnackBar con mensaje de exito
  void _mostrarExitoSnackBar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: DesignTokens.successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Muestra SnackBar con mensaje de error
  void _mostrarErrorSnackBar(BuildContext context, String mensaje) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                mensaje,
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
  }
}
