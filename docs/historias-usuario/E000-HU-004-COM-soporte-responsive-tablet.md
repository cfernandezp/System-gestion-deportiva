# E000-HU-004: Soporte Responsive Tablet

## INFORMACION
- **Codigo:** E000-HU-004
- **Epica:** E000 - Sprint 0 - Infraestructura Base
- **Titulo:** Soporte Responsive Tablet
- **Story Points:** 8 pts
- **Estado:** Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-21

## HISTORIA
**Como** administrador que usa una tablet en la cancha,
**Quiero** que la app detecte automaticamente si estoy en celular o tablet y muestre un layout optimizado para cada dispositivo,
**Para** tener la mejor experiencia tanto cuando organizo desde mi celular como cuando gestiono partidos en vivo desde una tablet en la cancha.

## CONTEXTO DE USO

### Celular (Jugador y Admin en casa)
- Gestionar grupos, invitar jugadores, ver stats
- Inscribirse a fechas
- Ver score y resultados
- Uso personal, una mano, vertical

### Tablet (Admin en cancha)
- Panel de control de la pichanga
- Temporizador visible a distancia por todos los jugadores
- Registrar goles rapidamente (botones grandes)
- Score board con numeros legibles
- Rotacion de equipos con vision completa
- Resumen de jornada
- Uso en mesa/soporte, horizontal y vertical

## CRITERIOS DE ACEPTACION (CA)

### CA-001: Deteccion automatica de dispositivo
- DADO que abro la app
- CUANDO el sistema detecta el ancho de pantalla
- ENTONCES clasifica como celular (<600dp) o tablet (>=600dp) y muestra el layout correspondiente

### CA-002: Widget base ResponsiveLayout
- DADO que el sistema de layouts esta implementado
- CUANDO una pantalla necesita layout diferenciado
- ENTONCES usa un widget `ResponsiveLayout(mobile: Widget, tablet: Widget)` que renderiza la version correcta automaticamente

### CA-003: Home - Layout tablet
- DADO que estoy en una tablet
- CUANDO veo la pantalla principal
- ENTONCES veo un layout de 2 columnas: card de bienvenida + info a la izquierda, accesos rapidos en grid de 3-4 columnas a la derecha. Sin overflow ni textos cortados.

### CA-004: Mis Grupos - Layout tablet
- DADO que estoy en una tablet
- CUANDO veo la lista de mis grupos
- ENTONCES las cards de grupo tienen ancho maximo (no se estiran al 100%), centradas o en grid de 2 columnas

### CA-005: Navegacion tablet (Navigation Rail)
- DADO que estoy en una tablet
- CUANDO uso la app
- ENTONCES en lugar de bottom navigation bar, veo una navigation rail lateral (sidebar compacto) que aprovecha mejor el espacio horizontal

### CA-006: Temporizador - Layout tablet (E004)
- DADO que estoy en una tablet viendo un partido en curso
- CUANDO veo el temporizador
- ENTONCES los numeros son extra grandes (minimo 160px en tablet vs 120px en celular), visible a 5+ metros de distancia. Los botones de control (pausar, gol) son mas grandes y faciles de tocar

### CA-007: Score Board - Layout tablet (E004)
- DADO que estoy en una tablet viendo el marcador
- CUANDO hay un partido en curso
- ENTONCES el score se muestra con numeros grandes, colores de equipo prominentes, y la lista de goles visible al mismo tiempo (sin necesidad de scroll)

### CA-008: Registrar Gol - Layout tablet (E004)
- DADO que soy admin en una tablet
- CUANDO quiero registrar un gol
- ENTONCES los botones de gol por equipo son grandes (minimo 64dp de alto), la lista de jugadores se muestra en dialog amplio con nombres legibles, todo accesible con un toque rapido

### CA-009: Rotacion de Equipos - Layout tablet (E004)
- DADO que estoy en una tablet gestionando rotacion de 3 equipos
- CUANDO veo el panel de rotacion
- ENTONCES veo los 3 equipos con su estado (jugando/descansando/siguiente), historial de partidos, y sugerencia del sistema, todo visible sin scroll

### CA-010: Orientacion landscape en tablet
- DADO que estoy en una tablet
- CUANDO giro la tablet a horizontal (landscape)
- ENTONCES la app se adapta al nuevo ancho: layouts de 2-3 columnas, temporizador + score + goles visibles simultaneamente

### CA-011: Celular solo portrait
- DADO que estoy en un celular
- CUANDO la app esta abierta
- ENTONCES la orientacion se fuerza a portrait (vertical) para mantener la experiencia actual

### CA-012: Modo pantalla completa tablet mejorado
- DADO que estoy en una tablet con partido en curso
- CUANDO activo modo pantalla completa del temporizador
- ENTONCES el temporizador ocupa toda la pantalla con fuente de 200px+, score visible abajo, y botones de control accesibles. Visible a 10+ metros

### CA-013: Listas y formularios tablet
- DADO que estoy en una tablet viendo cualquier lista (miembros, inscritos, jugadores)
- CUANDO la pantalla es ancha
- ENTONCES las listas tienen ancho maximo (max-width ~600px centrado) o se muestran en formato master-detail (lista a la izquierda, detalle a la derecha)

### CA-014: Perfil y configuracion tablet
- DADO que estoy en una tablet
- CUANDO veo mi perfil o configuracion del grupo
- ENTONCES los formularios y cards tienen ancho maximo centrado, no se estiran al 100% de la pantalla

## REGLAS DE NEGOCIO (RN)

### RN-001: Breakpoint unico
**Contexto**: Al determinar si es celular o tablet.
**Restriccion**: Se usa un unico breakpoint: 600dp (estandar Material Design).
**Validacion**: < 600dp = celular, >= 600dp = tablet.
**Caso especial**: No se contempla desktop/web por ahora, solo celular y tablet.

### RN-002: Celular es la experiencia principal
**Contexto**: Al disenar layouts.
**Restriccion**: La experiencia de celular no debe degradarse. Tablet es una mejora adicional.
**Validacion**: Toda pantalla DEBE tener version mobile. La version tablet es opcional (usa mobile como fallback si no tiene version tablet especifica).
**Caso especial**: Si una pantalla no tiene version tablet definida, se muestra la version mobile con max-width centrado.

### RN-003: Orientacion por dispositivo
**Contexto**: Al manejar rotacion de pantalla.
**Restriccion**: Celular = portrait forzado. Tablet = portrait + landscape.
**Validacion**: Usar `SystemChrome.setPreferredOrientations` condicionado al tipo de dispositivo.
**Caso especial**: En tablet, landscape es especialmente util para la pantalla de partido en vivo.

### RN-004: Navigation rail en tablet
**Contexto**: Al mostrar la navegacion principal.
**Restriccion**: Celular usa BottomNavigationBar. Tablet usa NavigationRail (sidebar lateral).
**Validacion**: El NavigationRail muestra los mismos items que el BottomNav pero en formato vertical.
**Caso especial**: En landscape tablet, el rail puede expandirse a drawer con labels.

### RN-005: Prioridad de pantallas para tablet
**Contexto**: Al implementar layouts tablet.
**Restriccion**: No todas las pantallas necesitan layout tablet especifico al mismo tiempo.
**Prioridad**:
1. **Critica**: Temporizador, Score, Registro de goles, Rotacion (uso en cancha)
2. **Alta**: Home, Mis Grupos, Miembros (uso frecuente)
3. **Media**: Perfil, Configuracion, Listas generales
4. **Baja**: Formularios de registro, Login (uso infrecuente en tablet)

### RN-006: Fallback seguro
**Contexto**: Si una pantalla no tiene layout tablet.
**Restriccion**: Nunca debe haber overflow ni textos cortados.
**Validacion**: Toda pantalla sin layout tablet especifico se muestra con max-width de 600px centrada en la pantalla.
**Caso especial**: Esto elimina los overflows actuales como solucion minima.

### RN-007: Consistencia con Design System
**Contexto**: Al crear layouts tablet.
**Restriccion**: Respetar colores, tipografia, spacing y componentes del Design System existente.
**Validacion**: Usar los mismos DesignTokens pero con valores adaptados (spacing mas generoso, tipografia mas grande donde aplique).
**Caso especial**: El temporizador en tablet puede usar valores fuera del Design System estandar (200px+) porque es un caso de uso especial (visibilidad a distancia).

### RN-008: Tema dark/light en tablet
**Contexto**: Al mostrar layouts en tablet.
**Restriccion**: Todos los layouts tablet deben respetar dark mode y light mode.
**Validacion**: Usar colorScheme del tema, no colores hardcoded.
**Caso especial**: El modo pantalla completa del temporizador siempre usa fondo oscuro (independiente del tema) para maxima visibilidad.

## PANTALLAS AFECTADAS

### Fase 1 - Infraestructura (obligatorio primero)
| Pantalla | Cambio |
|----------|--------|
| Widget ResponsiveLayout | Crear widget base que detecta celular/tablet |
| Shell/Scaffold principal | Reemplazar BottomNav por NavigationRail en tablet |
| Orientacion | Portrait forzado en celular, libre en tablet |

### Fase 2 - Pantallas existentes (eliminar overflows)
| Pantalla | Cambio |
|----------|--------|
| Home | Layout 2 columnas en tablet |
| Mis Grupos | Cards con max-width o grid 2 columnas |
| Miembros del Grupo | Lista con max-width centrada |
| Mi Perfil | Formulario con max-width centrado |
| Login/Registro | Formularios con max-width centrado |

### Fase 3 - Pantallas de cancha (tablet-first)
| Pantalla | Cambio |
|----------|--------|
| Temporizador | 160px+ numeros, 200px+ en fullscreen |
| Score Board | Numeros grandes, goles visibles sin scroll |
| Registrar Gol | Botones grandes (64dp+), dialog amplio |
| Rotacion Equipos | Vista completa de 3 equipos sin scroll |
| Resumen Jornada | Layout 2 columnas con stats y partidos |

## NOTAS
- El admin usa tablet como "panel de control" en la cancha. Es una ventaja competitiva de la app.
- El breakpoint 600dp es el estandar de Material Design para diferenciar mobile de tablet.
- La experiencia celular no cambia. Tablet es una capa adicional.
- Las pantallas de E004 (Partidos en Vivo) son las que mas se benefician del layout tablet.
- Los overflows detectados en QA (dashboard_shell.dart, home_page.dart) se resuelven con esta HU.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## FASE 2: Frontend

### Infraestructura (Fase 1)
| Archivo | Cambio |
|---------|--------|
| `lib/core/widgets/responsive_layout.dart` | Reescrito: 2-tier (mobile/tablet), breakpoint 600dp, fallback max-width centrado, TabletSafeWrapper, extension ResponsiveContext |
| `lib/main.dart` | Portrait-only orientation on startup |
| `lib/app.dart` | Builder con ResponsiveLayout.configureOrientations() |

### Pantallas existentes (Fase 2)
| Archivo | Cambio |
|---------|--------|
| `lib/features/home/presentation/pages/home_page.dart` | Reescrito: _TabletHomeView con NavigationRail + 2 columnas. _MobileHomeView intacta |
| Todas las paginas con Desktop views | Removido `tablet:` param, usan fallback centrado (RN-006) |
| 12 archivos | Renombrados params mobileBody->mobile, desktopBody->tablet |

### Pantallas de cancha (Fase 3)
| Archivo | Cambio |
|---------|--------|
| `temporizador_widget.dart` | CA-006: 160px font en tablet (vs 56px celular), padding escalado |
| `temporizador_fullscreen.dart` | CA-012: 220px portrait / 240px landscape en tablet |
| `score_marcador_widget.dart` | CA-007: Score 72px, separador 72px, circulos 80px en tablet |
| `botones_gol_widget.dart` | CA-008: Min 64dp alto, iconos 32px, texto escalado en tablet |
| `registrar_gol_dialog.dart` | CA-008: Dialog maxWidth 560px en tablet (vs 400 celular) |

### CAs implementados
- CA-001: DeviceType enum + getDeviceType() con breakpoint 600dp
- CA-002: ResponsiveLayout(mobile: required, tablet: optional)
- CA-003: _TabletHomeView con Row[NavigationRail, 2-column content]
- CA-004: Mis Grupos usa fallback centrado (max-width 600px)
- CA-005: _TabletNavigationRail reutiliza AppBottomNavBar.getItemsForRole
- CA-006: TemporizadorWidget detecta tablet y escala fontSize a 160px
- CA-007: ScoreMarcadorWidget escala score 72px, circulos 80px, separador 72px
- CA-008: BotonesGolWidget min 64dp alto, RegistrarGolDialog 560px ancho
- CA-009: Rotacion de equipos usa fallback centrado (lista visible sin scroll gracias a max-width)
- CA-010: Tablet permite landscape via configureOrientations; partido_en_vivo ya permite landscape
- CA-011: Main.dart fuerza portraitUp; app.dart builder re-evalua por dispositivo
- CA-012: TemporizadorFullscreen 220px portrait / 240px landscape en tablet
- CA-013: Todas las listas usan fallback centrado max-width 600px
- CA-014: Perfil, editar perfil usan fallback centrado max-width 600px

### RNs cumplidos
- RN-001: Breakpoint unico 600dp (DesignTokens.breakpointMobile)
- RN-002: Mobile siempre requerido, tablet opcional con fallback
- RN-003: SystemChrome en main.dart + configureOrientations en app.dart builder
- RN-004: NavigationRail en _TabletHomeView, BottomNavigationBar en _MobileHomeView
- RN-005: Prioridad critica (partidos) y alta (home) implementadas
- RN-006: ResponsiveLayout.build() retorna mobile centrado si tablet==null
- RN-007: Usa DesignTokens, colorScheme del tema, excepto temporizador (caso especial)
- RN-008: Todos los widgets usan Theme.of(context).colorScheme, no colores hardcoded

## FASE 3: UI

### Widgets responsive creados/modificados
- `ResponsiveLayout` - Widget base con LayoutBuilder
- `TabletSafeWrapper` - Wrapper max-width para uso manual
- `ResponsiveContext` extension - context.isMobile, context.isTablet
- `_TabletHomeView` - Home con NavigationRail
- `_TabletNavigationRail` - Navigation Rail reutilizando items del BottomNav

### Patron de implementacion
```
ResponsiveLayout(
  mobile: _MobileView(...),   // REQUERIDO - experiencia principal
  tablet: _TabletView(...),   // OPCIONAL - si null, mobile centrado con max-width
)
```

---
**Creado**: 2026-02-21
