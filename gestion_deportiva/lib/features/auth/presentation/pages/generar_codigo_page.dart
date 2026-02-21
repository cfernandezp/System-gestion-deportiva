import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/generar_codigo/generar_codigo.dart';

/// E001-HU-007: Pagina para que admin/coadmin genere codigo de recuperacion
///
/// Accesible para admin/coadmin autenticados
/// Permite generar un codigo de recuperacion para un jugador del grupo
class GenerarCodigoPage extends StatelessWidget {
  const GenerarCodigoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<GenerarCodigoBloc>(),
      child: const _GenerarCodigoView(),
    );
  }
}

class _GenerarCodigoView extends StatefulWidget {
  const _GenerarCodigoView();

  @override
  State<_GenerarCodigoView> createState() => _GenerarCodigoViewState();
}

class _GenerarCodigoViewState extends State<_GenerarCodigoView> {
  final _celularController = TextEditingController();
  final _celularFocus = FocusNode();

  @override
  void dispose() {
    _celularController.dispose();
    _celularFocus.dispose();
    super.dispose();
  }

  void _onGenerar() {
    final celular = _celularController.text.trim();
    if (celular.isEmpty) {
      _mostrarSnackBar('Ingresa el celular del jugador', Icons.warning_amber, Colors.orange);
      return;
    }
    if (celular.length != 9 || !celular.startsWith('9')) {
      _mostrarSnackBar('El celular debe tener 9 digitos y empezar con 9',
          Icons.warning_amber, Colors.orange);
      return;
    }
    context.read<GenerarCodigoBloc>().add(
          GenerarCodigoRecuperacionEvent(celularJugador: celular),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < DesignTokens.breakpointMobile;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Generar Codigo'),
        centerTitle: true,
      ),
      body: BlocConsumer<GenerarCodigoBloc, GenerarCodigoState>(
        listener: (context, state) {
          if (state is GenerarCodigoError) {
            _mostrarSnackBar(state.mensaje, Icons.error_outline, colorScheme.error);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
                  vertical: DesignTokens.spacingL,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(theme, colorScheme),
                      const SizedBox(height: DesignTokens.spacingXl),

                      if (state is CodigoGenerado)
                        _buildCodigoGenerado(theme, colorScheme, isMobile, state)
                      else
                        _buildFormulario(theme, colorScheme, isMobile, state),
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

  /// Header con icono
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
            Icons.admin_panel_settings,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Recuperacion de Jugador',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          'Genera un codigo para que un jugador pueda restablecer su contrasena',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Formulario para ingresar celular del jugador
  Widget _buildFormulario(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    GenerarCodigoState state,
  ) {
    final isLoading = state is GenerarCodigoLoading;

    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Celular del jugador',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Ingresa el numero de celular del jugador que necesita recuperar su contrasena',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),

          AppTextField.number(
            controller: _celularController,
            focusNode: _celularFocus,
            label: 'Numero de celular',
            hint: '9XXXXXXXX',
            prefixIcon: Icons.phone_android,
            maxLength: 9,
            enabled: !isLoading,
            onSubmitted: (_) => _onGenerar(),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          AppButton(
            label: 'Generar codigo',
            onPressed: isLoading ? null : _onGenerar,
            isLoading: isLoading,
            loadingLabel: 'Generando...',
            isExpanded: true,
            icon: Icons.vpn_key,
          ),
        ],
      ),
    );
  }

  /// Muestra el codigo generado con opciones de copiar
  Widget _buildCodigoGenerado(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    CodigoGenerado state,
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
              Icons.check_circle,
              size: 32,
              color: DesignTokens.successColor,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          Text(
            'Codigo generado',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),

          Text(
            'Para el celular ${state.celularJugador}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Codigo grande
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.spacingL,
              horizontal: DesignTokens.spacingM,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  state.codigo,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.primary,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: DesignTokens.iconSizeS,
                      color: DesignTokens.accentColor,
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Text(
                      'Expira en ${state.expiraEnMinutos} minutos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.accentColor,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Botones de copiar
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Copiar codigo',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.codigo));
                    _mostrarSnackBar(
                      'Codigo copiado al portapapeles',
                      Icons.check,
                      DesignTokens.successColor,
                    );
                  },
                  variant: AppButtonVariant.secondary,
                  icon: Icons.copy,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: AppButton(
                  label: 'Copiar mensaje',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.mensajeParaJugador));
                    _mostrarSnackBar(
                      'Mensaje copiado al portapapeles',
                      Icons.check,
                      DesignTokens.successColor,
                    );
                  },
                  variant: AppButtonVariant.secondary,
                  icon: Icons.message,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Mensaje sugerido para enviar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mensaje sugerido:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  state.mensajeParaJugador,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Boton para generar otro
          AppButton(
            label: 'Generar otro codigo',
            onPressed: () {
              _celularController.clear();
              context.read<GenerarCodigoBloc>().add(const ResetGenerarCodigoEvent());
            },
            variant: AppButtonVariant.tertiary,
            icon: Icons.refresh,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  /// Muestra SnackBar generico
  void _mostrarSnackBar(String mensaje, IconData icon, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                mensaje,
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
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
