import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';

/// Tema principal de la aplicacion
/// Usa Material 3 con colores personalizados para Gestion Deportiva
/// Soporte completo para Light y Dark mode
class AppTheme {
  AppTheme._();

  // ============================================
  // === COLOR SCHEMES ===
  // ============================================

  /// ColorScheme para Light Mode
  static ColorScheme get _lightColorScheme => const ColorScheme(
    brightness: Brightness.light,
    // Colores primarios
    primary: DesignTokens.primaryColor,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD1FAE5),
    onPrimaryContainer: Color(0xFF064E3B),
    // Colores secundarios
    secondary: DesignTokens.secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFDBEAFE),
    onSecondaryContainer: Color(0xFF1E3A8A),
    // Colores terciarios (accent)
    tertiary: DesignTokens.accentColor,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF92400E),
    // Error
    error: DesignTokens.errorColor,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    // Superficie
    surface: DesignTokens.lightSurface,
    onSurface: DesignTokens.lightOnSurface,
    surfaceContainerHighest: DesignTokens.lightSurfaceVariant,
    onSurfaceVariant: DesignTokens.lightOnSurfaceVariant,
    // Bordes
    outline: DesignTokens.lightOutline,
    outlineVariant: DesignTokens.lightOutlineVariant,
    // Otros
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: DesignTokens.darkSurface,
    onInverseSurface: DesignTokens.darkOnSurface,
    inversePrimary: Color(0xFF6EE7B7),
  );

  /// ColorScheme para Dark Mode
  static ColorScheme get _darkColorScheme => const ColorScheme(
    brightness: Brightness.dark,
    // Colores primarios
    primary: Color(0xFF34D399),
    onPrimary: Color(0xFF064E3B),
    primaryContainer: Color(0xFF065F46),
    onPrimaryContainer: Color(0xFFD1FAE5),
    // Colores secundarios
    secondary: Color(0xFF60A5FA),
    onSecondary: Color(0xFF1E3A8A),
    secondaryContainer: Color(0xFF1E40AF),
    onSecondaryContainer: Color(0xFFDBEAFE),
    // Colores terciarios (accent)
    tertiary: Color(0xFFFBBF24),
    onTertiary: Color(0xFF78350F),
    tertiaryContainer: Color(0xFFB45309),
    onTertiaryContainer: Color(0xFFFEF3C7),
    // Error
    error: Color(0xFFF87171),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFFB91C1C),
    onErrorContainer: Color(0xFFFEE2E2),
    // Superficie
    surface: DesignTokens.darkSurface,
    onSurface: DesignTokens.darkOnSurface,
    surfaceContainerHighest: DesignTokens.darkSurfaceVariant,
    onSurfaceVariant: DesignTokens.darkOnSurfaceVariant,
    // Bordes
    outline: DesignTokens.darkOutline,
    outlineVariant: DesignTokens.darkOutlineVariant,
    // Otros
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: DesignTokens.lightSurface,
    onInverseSurface: DesignTokens.lightOnSurface,
    inversePrimary: Color(0xFF059669),
  );

  // ============================================
  // === TEXT THEME ===
  // ============================================

  /// TextTheme base personalizado
  static TextTheme get _textTheme => const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontSize: DesignTokens.fontSizeHero,
      fontWeight: DesignTokens.fontWeightBold,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: DesignTokens.fontSizeDisplay,
      fontWeight: DesignTokens.fontWeightBold,
      letterSpacing: -0.25,
      height: 1.25,
    ),
    displaySmall: TextStyle(
      fontSize: DesignTokens.fontSizeXxl,
      fontWeight: DesignTokens.fontWeightSemiBold,
      letterSpacing: 0,
      height: 1.3,
    ),
    // Headlines
    headlineLarge: TextStyle(
      fontSize: DesignTokens.fontSizeXxl,
      fontWeight: DesignTokens.fontWeightSemiBold,
      letterSpacing: 0,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontSize: DesignTokens.fontSizeXl,
      fontWeight: DesignTokens.fontWeightSemiBold,
      letterSpacing: 0,
      height: 1.35,
    ),
    headlineSmall: TextStyle(
      fontSize: DesignTokens.fontSizeL,
      fontWeight: DesignTokens.fontWeightSemiBold,
      letterSpacing: 0,
      height: 1.4,
    ),
    // Titles
    titleLarge: TextStyle(
      fontSize: DesignTokens.fontSizeXl,
      fontWeight: DesignTokens.fontWeightMedium,
      letterSpacing: 0,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: DesignTokens.fontSizeM,
      fontWeight: DesignTokens.fontWeightMedium,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontSize: DesignTokens.fontSizeS,
      fontWeight: DesignTokens.fontWeightMedium,
      letterSpacing: 0.1,
      height: 1.5,
    ),
    // Body
    bodyLarge: TextStyle(
      fontSize: DesignTokens.fontSizeM,
      fontWeight: DesignTokens.fontWeightRegular,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: DesignTokens.fontSizeS,
      fontWeight: DesignTokens.fontWeightRegular,
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: DesignTokens.fontSizeXs,
      fontWeight: DesignTokens.fontWeightRegular,
      letterSpacing: 0.4,
      height: 1.5,
    ),
    // Labels
    labelLarge: TextStyle(
      fontSize: DesignTokens.fontSizeS,
      fontWeight: DesignTokens.fontWeightMedium,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: DesignTokens.fontSizeXs,
      fontWeight: DesignTokens.fontWeightMedium,
      letterSpacing: 0.5,
      height: 1.4,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: DesignTokens.fontWeightMedium,
      letterSpacing: 0.5,
      height: 1.4,
    ),
  );

  // ============================================
  // === LIGHT THEME ===
  // ============================================

  /// Tema Light completo
  static ThemeData get lightTheme {
    final colorScheme = _lightColorScheme;
    final textTheme = _textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: DesignTokens.lightBackground,

      // === AppBar ===
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.primary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: DesignTokens.iconSizeM,
        ),
      ),

      // === Card ===
      cardTheme: CardTheme(
        elevation: DesignTokens.elevationS,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        margin: const EdgeInsets.all(DesignTokens.spacingS),
      ),

      // === Elevated Button ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: DesignTokens.elevationS,
          shadowColor: DesignTokens.primaryColor.withValues(alpha: 0.3),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(
            alpha: DesignTokens.opacityDisabled,
          ),
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: DesignTokens.opacityDisabled,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ),

      // === Filled Button ===
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ),

      // === Outlined Button ===
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ),

      // === Text Button ===
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          minimumSize: const Size(48, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ),

      // === Icon Button ===
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(DesignTokens.spacingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
        ),
      ),

      // === Input Decoration ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(
              alpha: DesignTokens.opacityDisabled,
            ),
          ),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // === Floating Action Button ===
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: DesignTokens.elevationM,
        focusElevation: DesignTokens.elevationL,
        hoverElevation: DesignTokens.elevationL,
        highlightElevation: DesignTokens.elevationL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
      ),

      // === Chip ===
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: DesignTokens.opacityDisabled,
        ),
        deleteIconColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        side: BorderSide.none,
      ),

      // === Dialog ===
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // === Bottom Sheet ===
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationL,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusL),
          ),
        ),
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(32, 4),
      ),

      // === Snack Bar ===
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        insetPadding: const EdgeInsets.all(DesignTokens.spacingM),
      ),

      // === Navigation Bar (Bottom) ===
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationS,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: DesignTokens.fontWeightSemiBold,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.primary,
              size: DesignTokens.iconSizeM,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeM,
          );
        }),
      ),

      // === Navigation Rail ===
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        elevation: DesignTokens.elevationS,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: DesignTokens.iconSizeM,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: DesignTokens.iconSizeM,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // === Drawer ===
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationL,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(DesignTokens.radiusL),
          ),
        ),
      ),

      // === List Tile ===
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
        selectedColor: colorScheme.primary,
      ),

      // === Divider ===
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: DesignTokens.spacingM,
      ),

      // === Progress Indicator ===
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),

      // === Switch ===
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // === Checkbox ===
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        ),
        side: BorderSide(color: colorScheme.outline, width: 2),
      ),

      // === Radio ===
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),

      // === Tab Bar ===
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colorScheme.outlineVariant,
      ),

      // === Tooltip ===
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingXs,
        ),
      ),

      // === Badge ===
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        textStyle: textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingXs,
        ),
      ),
    );
  }

  // ============================================
  // === DARK THEME ===
  // ============================================

  /// Tema Dark completo
  static ThemeData get darkTheme {
    final colorScheme = _darkColorScheme;
    final textTheme = _textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: DesignTokens.darkBackground,

      // === AppBar ===
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: DesignTokens.iconSizeM,
        ),
      ),

      // === Card ===
      cardTheme: CardTheme(
        elevation: DesignTokens.elevationS,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        margin: const EdgeInsets.all(DesignTokens.spacingS),
      ),

      // === Elevated Button ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: DesignTokens.elevationS,
          shadowColor: DesignTokens.primaryColor.withValues(alpha: 0.3),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(
            alpha: DesignTokens.opacityDisabled,
          ),
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: DesignTokens.opacityDisabled,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ),

      // === Filled Button ===
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ),

      // === Outlined Button ===
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ),

      // === Text Button ===
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          minimumSize: const Size(48, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ),

      // === Icon Button ===
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(DesignTokens.spacingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
        ),
      ),

      // === Input Decoration ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(
              alpha: DesignTokens.opacityDisabled,
            ),
          ),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // === Floating Action Button ===
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: DesignTokens.elevationM,
        focusElevation: DesignTokens.elevationL,
        hoverElevation: DesignTokens.elevationL,
        highlightElevation: DesignTokens.elevationL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
      ),

      // === Chip ===
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: DesignTokens.opacityDisabled,
        ),
        deleteIconColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        side: BorderSide.none,
      ),

      // === Dialog ===
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // === Bottom Sheet ===
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationL,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusL),
          ),
        ),
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(32, 4),
      ),

      // === Snack Bar ===
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        insetPadding: const EdgeInsets.all(DesignTokens.spacingM),
      ),

      // === Navigation Bar (Bottom) ===
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationS,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: DesignTokens.fontWeightSemiBold,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.primary,
              size: DesignTokens.iconSizeM,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeM,
          );
        }),
      ),

      // === Navigation Rail ===
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        elevation: DesignTokens.elevationS,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: DesignTokens.iconSizeM,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: DesignTokens.iconSizeM,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // === Drawer ===
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationL,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(DesignTokens.radiusL),
          ),
        ),
      ),

      // === List Tile ===
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
        selectedColor: colorScheme.primary,
      ),

      // === Divider ===
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: DesignTokens.spacingM,
      ),

      // === Progress Indicator ===
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),

      // === Switch ===
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // === Checkbox ===
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        ),
        side: BorderSide(color: colorScheme.outline, width: 2),
      ),

      // === Radio ===
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),

      // === Tab Bar ===
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colorScheme.outlineVariant,
      ),

      // === Tooltip ===
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingXs,
        ),
      ),

      // === Badge ===
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        textStyle: textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingXs,
        ),
      ),
    );
  }
}
