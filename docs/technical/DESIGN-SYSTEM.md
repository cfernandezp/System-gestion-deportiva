# Design System - Sistema de Gestion Deportiva

Version: 1.0.0
Estilo: Minimalista Profesional + Material You Deportivo

---

## Paleta de Colores

### Colores Base

| Color | Hex | Uso |
|-------|-----|-----|
| Primary | `#10B981` | Verde cesped - Acciones principales, botones, links |
| Secondary | `#1E40AF` | Azul profundo - Elementos secundarios, contraste |
| Accent | `#F59E0B` | Naranja energia - Advertencias, en curso, highlights |
| Error | `#EF4444` | Rojo - Errores, derrotas, eliminaciones |
| Success | `#22C55E` | Verde - Exito, victorias, confirmaciones |

### Colores Light Mode

| Token | Hex | Uso |
|-------|-----|-----|
| `lightBackground` | `#F8FAFC` | Fondo principal de la app |
| `lightSurface` | `#FFFFFF` | Cards, modales, sheets |
| `lightSurfaceVariant` | `#F1F5F9` | Fondos de inputs, chips |
| `lightOnBackground` | `#0F172A` | Texto principal |
| `lightOnSurface` | `#1E293B` | Texto sobre superficies |
| `lightOnSurfaceVariant` | `#64748B` | Texto secundario, hints |
| `lightOutline` | `#CBD5E1` | Bordes principales |
| `lightOutlineVariant` | `#E2E8F0` | Bordes sutiles |

### Colores Dark Mode

| Token | Hex | Uso |
|-------|-----|-----|
| `darkBackground` | `#0F172A` | Fondo principal de la app |
| `darkSurface` | `#1E293B` | Cards, modales, sheets |
| `darkSurfaceVariant` | `#334155` | Fondos de inputs, chips |
| `darkOnBackground` | `#F8FAFC` | Texto principal |
| `darkOnSurface` | `#E2E8F0` | Texto sobre superficies |
| `darkOnSurfaceVariant` | `#94A3B8` | Texto secundario, hints |
| `darkOutline` | `#475569` | Bordes principales |
| `darkOutlineVariant` | `#334155` | Bordes sutiles |

### Colores Semanticos Deportivos

| Color | Hex | Uso |
|-------|-----|-----|
| Victoria | `#22C55E` | Partidos ganados, resultados positivos |
| Derrota | `#EF4444` | Partidos perdidos, resultados negativos |
| Empate | `#64748B` | Empates, estados neutrales |
| En Curso | `#F59E0B` | Partidos en vivo, pendientes |
| Programado | `#3B82F6` | Eventos futuros |
| Cancelado | `#6B7280` | Eventos cancelados |
| Oro | `#FFD700` | Primer lugar |
| Plata | `#C0C0C0` | Segundo lugar |
| Bronce | `#CD7F32` | Tercer lugar |

---

## Sistema de Spacing (4px base)

| Token | Valor | Uso |
|-------|-------|-----|
| `spacingXxs` | 2px | Micro espacios |
| `spacingXs` | 4px | Espacios muy pequenos |
| `spacingS` | 8px | Espacios pequenos |
| `spacingM` | 16px | Espacios medianos (base) |
| `spacingL` | 24px | Espacios grandes |
| `spacingXl` | 32px | Espacios extra grandes |
| `spacingXxl` | 48px | Espacios muy grandes |
| `spacingXxxl` | 64px | Espacios maximos |

### Uso Recomendado

```dart
// Padding interno de cards
padding: EdgeInsets.all(DesignTokens.spacingM), // 16px

// Espacio entre elementos en lista
SizedBox(height: DesignTokens.spacingS), // 8px

// Margen de seccion
margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingL), // 24px
```

---

## Border Radius

| Token | Valor | Uso |
|-------|-------|-----|
| `radiusXs` | 4px | Chips, badges pequenos |
| `radiusS` | 8px | Botones, inputs |
| `radiusM` | 12px | Cards estandar |
| `radiusL` | 16px | Modales, sheets |
| `radiusXl` | 24px | Cards destacadas |
| `radiusFull` | 9999px | Pills, avatares circulares |

---

## Tipografia

### Escala Tipografica

| Estilo | Tamano | Peso | Uso |
|--------|--------|------|-----|
| `displayLarge` | 40px | Bold | Titulos hero |
| `displayMedium` | 32px | Bold | Titulos principales |
| `displaySmall` | 24px | SemiBold | Subtitulos grandes |
| `headlineLarge` | 24px | SemiBold | Titulos de seccion |
| `headlineMedium` | 20px | SemiBold | Titulos de card |
| `headlineSmall` | 18px | SemiBold | Subtitulos |
| `titleLarge` | 20px | Medium | Titulos de pagina |
| `titleMedium` | 16px | Medium | Titulos de item |
| `titleSmall` | 14px | Medium | Labels destacados |
| `bodyLarge` | 16px | Regular | Texto principal |
| `bodyMedium` | 14px | Regular | Texto secundario |
| `bodySmall` | 12px | Regular | Texto pequeno |
| `labelLarge` | 14px | Medium | Botones |
| `labelMedium` | 12px | Medium | Chips, badges |
| `labelSmall` | 10px | Medium | Captions muy pequenas |

### Uso en Codigo

```dart
Text(
  'Titulo',
  style: Theme.of(context).textTheme.headlineMedium,
)

Text(
  'Descripcion',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: AppColors.onSurfaceVariant(context),
  ),
)
```

---

## Componentes Disponibles

### AppCard

Card adaptable con variantes para diferentes contextos.

```dart
// Card estandar
AppCard(
  child: Text('Contenido'),
)

// Card destacada
AppCard(
  variant: AppCardVariant.elevated,
  onTap: () {},
  child: Text('Contenido'),
)

// Card con borde
AppCard(
  variant: AppCardVariant.outlined,
  child: Text('Contenido'),
)

// Card de partido
MatchCard(
  isHighlighted: true,
  onTap: () {},
  child: MatchContent(),
)
```

### AppButton

Boton con variantes y estados de carga.

```dart
// Boton primario
AppButton(
  label: 'Guardar',
  onPressed: () {},
)

// Boton secundario
AppButton(
  label: 'Cancelar',
  variant: AppButtonVariant.secondary,
  onPressed: () {},
)

// Boton con icono
AppButton(
  label: 'Agregar',
  icon: Icons.add,
  onPressed: () {},
)

// Boton en estado de carga
AppButton(
  label: 'Guardando...',
  isLoading: true,
  onPressed: null,
)

// Boton de peligro
AppButton(
  label: 'Eliminar',
  variant: AppButtonVariant.danger,
  onPressed: () {},
)
```

### StatusBadge

Badge para estados deportivos.

```dart
// Constructores predefinidos
StatusBadge.victoria()
StatusBadge.derrota()
StatusBadge.empate()
StatusBadge.enCurso()
StatusBadge.finalizado()
StatusBadge.programado()
StatusBadge.activo()
StatusBadge.inactivo()

// Badge personalizado
StatusBadge(
  label: 'Personalizado',
  type: StatusBadgeType.custom,
  backgroundColor: Colors.purple,
)

// Badge con borde
StatusBadge.victoria(outlined: true)

// Badge numerico para ranking
NumberBadge.ranking(number: 1) // Oro
NumberBadge.ranking(number: 2) // Plata
NumberBadge.ranking(number: 3) // Bronce
```

### StatCard

Card para estadisticas en dashboards.

```dart
// Stat card vertical
StatCard(
  value: '24',
  label: 'Partidos jugados',
  icon: Icons.sports_soccer,
)

// Stat card con tendencia
StatCard.positive(
  value: '85%',
  label: 'Efectividad',
  icon: Icons.trending_up,
  trendPercent: 12.5,
)

// Card de marcador
ScoreCard(
  homeScore: 2,
  awayScore: 1,
  homeTeam: 'Equipo A',
  awayTeam: 'Equipo B',
  isLive: true,
  minute: 67,
)
```

### EmptyStateWidget

Widget para estados vacios.

```dart
// Constructores predefinidos
EmptyStateWidget.noData()
EmptyStateWidget.noResults(onAction: () => clearSearch())
EmptyStateWidget.error(onAction: () => retry())
EmptyStateWidget.offline()
EmptyStateWidget.noMatches(onAction: () => createMatch())
EmptyStateWidget.noTeams()
EmptyStateWidget.noPlayers()

// Estado vacio personalizado
EmptyStateWidget(
  title: 'Titulo personalizado',
  description: 'Descripcion del estado',
  icon: Icons.custom_icon,
  actionLabel: 'Accion',
  onAction: () {},
)
```

### LoadingShimmer

Shimmer loading para placeholders.

```dart
// Shimmer wrapper
LoadingShimmer(
  child: ShimmerPlaceholder(height: 100),
)

// Placeholders predefinidos
ShimmerCard(hasAvatar: true)
ShimmerList(itemCount: 5)
ShimmerStatGrid(crossAxisCount: 2)
ShimmerForm(fieldCount: 4)
```

### AppTextField

Campos de texto con validacion.

```dart
// Campo basico
AppTextField(
  label: 'Nombre',
  hint: 'Ingresa tu nombre',
  onChanged: (value) {},
)

// Constructores especializados
AppTextField.email()
AppTextField.password()
AppTextField.search()
AppTextField.number()
AppTextField.multiline()

// Con validacion
AppTextField(
  label: 'Email',
  errorText: 'Email invalido',
  showSuccessState: true,
)
```

---

## Uso del Theme

### Acceder a Colores

```dart
// Via ColorScheme (recomendado)
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.onSurface
Theme.of(context).colorScheme.error

// Via AppColors helper
AppColors.primary(context)
AppColors.surface(context)
AppColors.onSurfaceVariant(context)

// Colores semanticos deportivos (estaticos)
AppColors.victoria
AppColors.derrota
AppColors.enCurso
AppColors.estadoPartido('en_curso')
AppColors.resultado('victoria')
```

### Verificar Modo Oscuro

```dart
final isDark = AppColors.isDarkMode(context);

// O directamente
final isDark = Theme.of(context).brightness == Brightness.dark;
```

### Sombras Segun Theme

```dart
Container(
  decoration: BoxDecoration(
    boxShadow: AppColors.shadow(context, size: 'md'),
  ),
)
```

---

## Breakpoints

| Token | Valor | Descripcion |
|-------|-------|-------------|
| `breakpointMobile` | 600px | Ancho maximo mobile |
| `breakpointTablet` | 900px | Ancho maximo tablet |
| `breakpointDesktop` | 1200px | Ancho minimo desktop |
| `maxContentWidth` | 1440px | Ancho maximo de contenido |

### Ejemplo de Uso

```dart
Widget build(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width < DesignTokens.breakpointMobile) {
    return MobileLayout();
  } else if (width < DesignTokens.breakpointTablet) {
    return TabletLayout();
  } else {
    return DesktopLayout();
  }
}
```

---

## Animaciones

| Token | Duracion | Uso |
|-------|----------|-----|
| `animFast` | 150ms | Hovers, toggles |
| `animNormal` | 300ms | Transiciones estandar |
| `animSlow` | 500ms | Modales, overlays |
| `animVerySlow` | 800ms | Splash, hero |

### Curvas

- `animCurve`: `Curves.easeInOut` (default)
- `animCurveIn`: `Curves.easeIn`
- `animCurveOut`: `Curves.easeOut`
- `animCurveBounce`: `Curves.elasticOut`

---

## Archivos del Design System

```
lib/core/
  theme/
    design_tokens.dart   # Constantes y tokens
    app_theme.dart       # ThemeData Light/Dark
    app_colors.dart      # Helper de colores
    theme.dart           # Barrel export
  widgets/
    app_button.dart      # Botones
    app_card.dart        # Cards
    app_text_field.dart  # Inputs
    empty_state_widget.dart
    loading_shimmer.dart
    stat_card.dart
    status_badge.dart
    widgets.dart         # Barrel export
```

---

## Importacion Rapida

```dart
// Importar todo el tema
import 'package:gestion_deportiva/core/theme/theme.dart';

// Importar todos los widgets
import 'package:gestion_deportiva/core/widgets/widgets.dart';
```
