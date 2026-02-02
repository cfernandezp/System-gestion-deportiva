# E004-HU-008 - Mi Actividad en Vivo

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: Completada (COM)
- **Prioridad**: Alta
- **Story Points**: 8 pts

## Historia de Usuario
**Como** jugador inscrito en una pichanga activa
**Quiero** ver mi estado y actividad en tiempo real
**Para** saber como voy en la jornada actual (mis goles, partidos de mi equipo, resultados)

## Descripcion
Esta funcionalidad permite al jugador ver su actividad durante una pichanga en curso (`en_juego`). Incluye dos componentes:

1. **Widget en Dashboard**: Card destacada que aparece SOLO cuando hay pichanga activa donde el jugador esta inscrito. Muestra resumen rapido: estado "Jugando", goles, equipo actual.

2. **Pantalla Mi Actividad**: Vista completa con todos los partidos de la jornada, resaltando aquellos donde participo el jugador. Muestra goles individuales por partido y totales.

---

## Criterios de Aceptacion (CA)

### CA-001: Widget en Dashboard - Visible solo con pichanga activa
- **Dado** que soy jugador y hay una pichanga `en_juego` donde estoy inscrito
- **Cuando** accedo al Dashboard (Inicio)
- **Entonces** veo un widget destacado con indicador "JUGANDO" (verde pulsante)
- **Y** si no hay pichanga activa donde estoy inscrito, el widget NO aparece

### CA-002: Widget muestra resumen de mi actividad
- **Dado** que veo el widget de actividad en Dashboard
- **Cuando** observo el contenido
- **Entonces** veo:
  - Nombre de la pichanga (fecha y lugar)
  - Mi equipo asignado (color)
  - Mis goles totales en la jornada
  - Enlace "Ver actividad completa"

### CA-003: Pantalla Mi Actividad - Lista de todos los partidos
- **Dado** que accedo a "Mi Actividad" (desde widget o menu)
- **Cuando** veo la pantalla
- **Entonces** veo todos los partidos de la jornada ordenados:
  - Primero: partido en curso (si hay)
  - Luego: partidos finalizados (mas reciente primero)
  - Ultimo: partidos pendientes (si hay)

### CA-004: Partidos donde participe resaltados
- **Dado** que veo la lista de partidos
- **Cuando** un partido incluye a mi equipo (color asignado)
- **Entonces** ese partido se muestra resaltado visualmente:
  - Borde con mi color de equipo
  - Badge "Participe" o icono distintivo
  - Mis goles en ese partido especifico

### CA-005: Partidos donde NO participe visibles pero no resaltados
- **Dado** que veo la lista de partidos
- **Cuando** un partido NO incluye a mi equipo
- **Entonces** el partido se muestra normal (sin resaltar)
- **Y** puedo ver el resultado igualmente

### CA-006: Mis goles totales de la jornada
- **Dado** que veo Mi Actividad
- **Cuando** observo el encabezado/resumen
- **Entonces** veo mis goles totales sumados de todos los partidos donde anote
- **Y** el numero se actualiza en tiempo real si anoto

### CA-007: Detalle de partido muestra mis goles
- **Dado** que veo un partido donde participe
- **Cuando** expando o veo el detalle
- **Entonces** veo cuantos goles anote yo en ese partido especifico
- **Y** veo el minuto de cada gol mio

### CA-008: Estado visual del partido en curso
- **Dado** que hay un partido en curso donde estoy jugando
- **Cuando** veo ese partido en la lista
- **Entonces** tiene indicador "EN VIVO" (verde pulsante)
- **Y** muestra tiempo transcurrido o restante
- **Y** puedo acceder al score en vivo (E004-HU-004)

### CA-009: Actualizacion en tiempo real
- **Dado** que estoy viendo Mi Actividad
- **Cuando** se registra un gol en cualquier partido
- **Entonces** la informacion se actualiza automaticamente
- **Y** no necesito recargar la pagina

### CA-010: Sin pichanga activa
- **Dado** que accedo a Mi Actividad
- **Cuando** no hay ninguna pichanga `en_juego` donde este inscrito
- **Entonces** veo mensaje "No hay pichanga activa"
- **Y** opcionalmente veo enlace a proximas pichangas

---

## Reglas de Negocio (RN)

### RN-001: Pichanga Activa del Jugador
**Contexto**: Para mostrar el widget y la pantalla de actividad.
**Restriccion**: Solo se considera "mi pichanga activa" si:
  1. La fecha tiene estado = 'en_juego'
  2. Tengo inscripcion activa (estado = 'inscrito') en esa fecha
**Validacion**: Buscar fecha donde estado='en_juego' AND existe inscripcion del usuario con estado='inscrito'.
**Regla calculo**: N/A.
**Caso especial**: Si hay multiples pichangas activas (poco probable), mostrar la mas reciente.

### RN-002: Identificacion de "Mis Partidos"
**Contexto**: Para resaltar partidos donde participo.
**Restriccion**: Un partido es "mio" si mi equipo asignado participo en el.
**Validacion**: Mi color_equipo en asignaciones_equipos coincide con equipo_local O equipo_visitante del partido.
**Regla calculo**: partido.equipo_local = mi_color OR partido.equipo_visitante = mi_color.
**Caso especial**: Con rotacion de equipos (E004-HU-006), el jugador puede participar en multiples partidos de la jornada.

### RN-003: Calculo de Mis Goles
**Contexto**: Para mostrar goles del jugador.
**Restriccion**: Solo contar goles donde usuario_id = jugador actual.
**Validacion**:
  - Goles totales: SUM de goles WHERE usuario_id = yo AND partido.fecha_id = pichanga_activa AND anulado = false
  - Goles por partido: COUNT de goles WHERE usuario_id = yo AND partido_id = X AND anulado = false
**Regla calculo**: No contar autogoles como "mis goles" (es_autogol = true se excluye).
**Caso especial**: Goles sin asignar (usuario_id = NULL) no cuentan para ningun jugador.

### RN-004: Orden de Partidos
**Contexto**: Al mostrar la lista de partidos.
**Restriccion**: Orden logico para el jugador.
**Validacion**:
  1. Partido en curso primero (estado = 'en_curso')
  2. Partidos finalizados ordenados por hora_fin DESC
  3. Partidos pendientes/programados al final
**Regla calculo**: ORDER BY (estado='en_curso' DESC), hora_fin DESC NULLS LAST.
**Caso especial**: Si no hay partidos, mostrar mensaje informativo.

### RN-005: Resaltado Visual de Mis Partidos
**Contexto**: Diferenciar visualmente mis partidos de los demas.
**Restriccion**: Usar el color de mi equipo para el resaltado.
**Validacion**:
  - Borde izquierdo o fondo tenue con mi color_equipo
  - Badge "Participe" visible
  - Seccion "Mis goles: X" dentro del card
**Regla calculo**: N/A.
**Caso especial**: Si participe con ambos equipos (cambio de equipo mid-jornada, raro), resaltar ambos.

### RN-006: Tiempo Real via Supabase Realtime
**Contexto**: Actualizar informacion sin recargar.
**Restriccion**: Suscripcion a cambios en tablas relevantes.
**Validacion**:
  - Suscribirse a tabla `goles` filtrado por fecha_id
  - Suscribirse a tabla `partidos` filtrado por fecha_id
**Regla calculo**: Latencia maxima 3 segundos.
**Caso especial**: Si se pierde conexion, mostrar indicador y reintentar.

### RN-007: Widget en Dashboard - Prominencia
**Contexto**: El widget debe ser lo primero que vea el jugador.
**Restriccion**: Ubicar en la parte superior del Dashboard, antes de accesos rapidos.
**Validacion**:
  - Fondo con gradiente o color distintivo
  - Icono pulsante de "en vivo"
  - Tamaño destacado (no un card pequeño)
**Regla calculo**: N/A.
**Caso especial**: En desktop, puede ser un panel lateral o card prominente.

### RN-008: Enlace a Score en Vivo
**Contexto**: Desde Mi Actividad, acceder al partido en curso.
**Restriccion**: Si hay partido en curso, mostrar acceso directo a E004-HU-004.
**Validacion**: Boton "Ver partido en vivo" que navega a la pantalla de score.
**Regla calculo**: N/A.
**Caso especial**: Si el partido finalizo mientras veia Mi Actividad, actualizar el estado.

### RN-009: Privacidad de Goles
**Contexto**: Cada jugador ve solo sus propios goles destacados.
**Restriccion**: No mostrar goles de otros jugadores de forma individual en "Mi Actividad".
**Validacion**: En la lista de partidos, mostrar solo "Mis goles: X", no los goles de companeros.
**Regla calculo**: N/A.
**Caso especial**: El detalle general del partido (E004-HU-004) si muestra todos los goles.

---

## UI/UX Sugerido

### Widget en Dashboard (Mobile)
```
┌─────────────────────────────────────┐
│ 🟢 ESTAS JUGANDO                    │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│ 📍 Cancha Los Amigos                │
│ 📅 02/02/2026                       │
│                                     │
│ ┌─────────────┐  ┌─────────────┐   │
│ │ 🟠 NARANJA  │  │ ⚽ MIS GOLES │   │
│ │  Mi equipo  │  │      2      │   │
│ └─────────────┘  └─────────────┘   │
│                                     │
│ 🔴 EN VIVO: NARANJA 2 - 1 VERDE    │
│                                     │
│    [Ver actividad completa →]       │
└─────────────────────────────────────┘
```

### Pantalla Mi Actividad (Mobile)
```
┌─────────────────────────────────────┐
│ ← Mi Actividad                      │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ⚽ Mis Goles Hoy: 3             │ │
│ │ 🟠 Equipo: NARANJA              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ PARTIDOS DE LA JORNADA              │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔴 EN VIVO         Min 08:32   │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ 🟠 NARANJA  2 - 1  VERDE 🟢    │ │
│ │                                 │ │
│ │ ⭐ Participe │ Mis goles: 1    │ │
│ │                    [Ver →]     │ │
│ └─────────────────────────────────┘ │
│        ↑ Borde naranja (mi equipo)  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ✅ FINALIZADO                   │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ 🟠 NARANJA  3 - 2  AZUL 🔵     │ │
│ │                                 │ │
│ │ ⭐ Participe │ Mis goles: 2    │ │
│ └─────────────────────────────────┘ │
│        ↑ Borde naranja (mi equipo)  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ✅ FINALIZADO                   │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ 🟢 VERDE  1 - 1  AZUL 🔵       │ │
│ │                                 │ │
│ │ (No participe)                  │ │
│ └─────────────────────────────────┘ │
│        ↑ Sin borde (no participe)   │
│                                     │
└─────────────────────────────────────┘
```

### Indicadores Visuales
| Estado | Indicador | Color |
|--------|-----------|-------|
| En vivo | Circulo pulsante + "EN VIVO" | Verde #4CAF50 |
| Finalizado | Check + "FINALIZADO" | Gris |
| Participe | Borde lateral + badge | Mi color de equipo |
| No participe | Sin borde, card normal | Neutro |

---

## Notas Tecnicas

### Backend (supabase-expert)

**Estado**: ✅ IMPLEMENTADO

**Funcion RPC**: `obtener_mi_actividad_vivo()`

**Archivo**: `supabase/sql-cloud/2026-02-02_E004-HU-008_obtener_mi_actividad_vivo.sql`

**Parametros**: Ninguno (usa auth.uid() internamente)

**Descripcion**:
Esta función retorna la actividad en vivo del jugador autenticado. Busca si hay una pichanga activa (`estado='en_juego'`) donde el usuario tenga inscripción activa (`estado='inscrito'`). Si existe, devuelve:
- Información de la pichanga activa (fecha, lugar, estado)
- Equipo asignado al jugador (color, número)
- Goles totales del jugador en la jornada
- Lista de todos los partidos de la jornada con indicador de participación
- Detalle de goles del jugador por partido (minuto)
- Partido en curso (si existe) con indicador de si el jugador está jugando

**Logica Implementada**:
1. **RN-001**: Busca fecha con `estado='en_juego'` AND existe inscripción del usuario con `estado='inscrito'`. Si hay múltiples, toma la más reciente.
2. **RN-002**: Marca `es_mi_partido=true` si mi `color_equipo` coincide con `equipo_local` O `equipo_visitante`.
3. **RN-003**: Solo cuenta goles válidos (`anulado=false`) y NO autogoles (`es_autogol=false`).
4. **RN-004**: Ordena partidos: `en_curso` primero, `finalizados` por `hora_fin DESC`, `pendientes` al final.
5. Incluye detalle de cada gol del jugador con minuto de anotación.
6. Si no hay pichanga activa, retorna `pichanga_activa=null` con mensaje informativo.

**Response Success**:
```json
{
  "success": true,
  "data": {
    "pichanga_activa": {
      "fecha_id": "uuid",
      "fecha": "02/02/2026",
      "fecha_hora": "02/02/2026 15:30",
      "lugar": "Cancha Los Amigos",
      "estado": "en_juego",
      "iniciado_at": "2026-02-02T15:30:00-05:00"
    },
    "mi_equipo": {
      "color": "naranja",
      "color_hex": "#FF9800",
      "numero": 1
    },
    "mis_goles_totales": 3,
    "partidos": [
      {
        "partido_id": "uuid",
        "equipo_local": "naranja",
        "equipo_visitante": "verde",
        "goles_local": 2,
        "goles_visitante": 1,
        "estado": "en_curso",
        "minuto_actual": 8,
        "hora_inicio": "2026-02-02T15:45:00-05:00",
        "hora_fin": null,
        "es_mi_partido": true,
        "mis_goles": 1,
        "mis_goles_detalle": [
          {"minuto": 5, "es_autogol": false}
        ]
      },
      {
        "partido_id": "uuid",
        "equipo_local": "naranja",
        "equipo_visitante": "azul",
        "goles_local": 3,
        "goles_visitante": 2,
        "estado": "finalizado",
        "minuto_actual": null,
        "hora_inicio": "2026-02-02T15:30:00-05:00",
        "hora_fin": "2026-02-02T15:42:00-05:00",
        "es_mi_partido": true,
        "mis_goles": 2,
        "mis_goles_detalle": [
          {"minuto": 3, "es_autogol": false},
          {"minuto": 8, "es_autogol": false}
        ]
      },
      {
        "partido_id": "uuid",
        "equipo_local": "verde",
        "equipo_visitante": "azul",
        "goles_local": 1,
        "goles_visitante": 1,
        "estado": "finalizado",
        "minuto_actual": null,
        "hora_inicio": "2026-02-02T15:20:00-05:00",
        "hora_fin": "2026-02-02T15:28:00-05:00",
        "es_mi_partido": false,
        "mis_goles": 0,
        "mis_goles_detalle": []
      }
    ],
    "partido_en_curso": {
      "partido_id": "uuid",
      "estoy_jugando": true
    }
  },
  "message": "Actividad en vivo obtenida"
}
```

**Response si no hay pichanga activa**:
```json
{
  "success": true,
  "data": {
    "pichanga_activa": null,
    "mensaje": "No hay pichanga activa donde estes inscrito"
  },
  "message": "Sin actividad"
}
```

**Response Error**:
```json
{
  "success": false,
  "error": {
    "code": "SQLSTATE_CODE",
    "message": "Error message",
    "hint": "no_autenticado" | "unknown"
  }
}
```

**Permisos**: GRANT EXECUTE a `anon`, `authenticated`, `service_role`

**Colores del Design System** (incluidos en la función):
```json
{
  "naranja": "#FF9800",
  "verde": "#4CAF50",
  "azul": "#2196F3",
  "rojo": "#F44336",
  "amarillo": "#FFEB3B",
  "blanco": "#FFFFFF"
}
```

### Frontend (flutter-expert)

**Estado**: ✅ IMPLEMENTADO (Backend y arquitectura completa)

**Arquitectura**: Clean Architecture con BLoC pattern

**Estructura de archivos**:
```
lib/features/mi_actividad/
├── data/
│   ├── datasources/
│   │   └── mi_actividad_remote_datasource.dart
│   ├── models/
│   │   ├── gol_detalle_model.dart
│   │   ├── mi_equipo_actividad_model.dart
│   │   ├── pichanga_activa_model.dart
│   │   ├── partido_actividad_model.dart
│   │   ├── partido_en_curso_model.dart
│   │   ├── mi_actividad_response_model.dart
│   │   └── models.dart
│   └── repositories/
│       └── mi_actividad_repository_impl.dart
├── domain/
│   └── repositories/
│       └── mi_actividad_repository.dart
└── presentation/
    ├── bloc/
    │   └── mi_actividad/
    │       ├── mi_actividad_bloc.dart
    │       ├── mi_actividad_event.dart
    │       └── mi_actividad_state.dart
    └── pages/
        └── mi_actividad_page.dart
```

**1. Models (data/models/)**:
- `GolDetalleModel`: Gol individual con minuto y flag autogol
- `MiEquipoActividadModel`: Equipo asignado (color, hex, numero)
- `PichangaActivaModel`: Fecha en estado 'en_juego'
- `PartidoActividadModel`: Partido con indicador `es_mi_partido` y `mis_goles`
- `PartidoEnCursoModel`: Partido actualmente en curso con flag `estoy_jugando`
- `MiActividadResponseModel`: Response completo del RPC con manejo de pichanga activa/null

**2. DataSource (data/datasources/)**:
- `MiActividadRemoteDataSource`: Interface abstracta
- `MiActividadRemoteDataSourceImpl`: Implementación
  - `obtenerMiActividadVivo()`: Llama al RPC sin parámetros
  - `observarCambiosGoles(fechaId)`: Stream Realtime de tabla `goles` filtrado por fecha_id
  - `observarCambiosPartidos(fechaId)`: Stream Realtime de tabla `partidos` filtrado por fecha_id

**3. Repository**:
- `MiActividadRepository`: Interface abstracta con contratos
- `MiActividadRepositoryImpl`: Implementación con manejo de Either<Failure, Response>
  - Convierte ServerException en ServerFailure
  - Retorna streams de Realtime sin transformación

**4. BLoC (presentation/bloc/mi_actividad/)**:
- **Events**:
  - `CargarMiActividadEvent`: Carga inicial de actividad (CA-003)
  - `ActualizarActividadRealtimeEvent`: Actualización desde Realtime (CA-009)
- **States**:
  - `MiActividadInitial`: Estado inicial
  - `MiActividadLoading`: Cargando datos
  - `MiActividadLoaded`: Datos cargados con `MiActividadResponseModel`
  - `MiActividadError`: Error con mensaje y hint
- **Lógica**:
  - Al cargar actividad, suscribe a Realtime si hay pichanga activa (RN-006)
  - Al detectar cambio en goles o partidos, recarga actividad sin mostrar loading
  - Cancela suscripciones al cerrar BLoC

**5. Dependency Injection (injection_container.dart)**:
```dart
// Bloc
sl.registerFactory(() => MiActividadBloc(repository: sl(), supabase: sl()));

// Repository
sl.registerLazySingleton<MiActividadRepository>(
  () => MiActividadRepositoryImpl(remoteDataSource: sl()),
);

// DataSource
sl.registerLazySingleton<MiActividadRemoteDataSource>(
  () => MiActividadRemoteDataSourceImpl(supabase: sl()),
);
```

**6. Routing (app_router.dart)**:
- Ruta agregada: `/mi-actividad`
- Nombre: `miActividad`
- Constante: `AppRouter.miActividad`
- Instancia BLoC con evento inicial `CargarMiActividadEvent()`

**7. Pagina (presentation/pages/mi_actividad_page.dart)**:
- Responsive con Mobile y Desktop views
- Header con resumen: mis goles totales + mi equipo (CA-006)
- Lista de partidos de la jornada ordenados (CA-003, RN-004)
- Partidos con borde de color si participe (CA-004, RN-005)
- Partidos sin participacion visibles sin resaltar (CA-005)
- Detalle de mis goles por partido con minuto (CA-007)
- Badge "Participe" en partidos donde juego
- Indicador "EN VIVO" animado con circulo pulsante (CA-008)
- Boton "Ver partido en vivo" navega a score (RN-008)
- Vista "Sin Actividad" con mensaje y enlace a pichangas (CA-010)
- Vista de error con retry

**8. Widget Dashboard (presentation/widgets/mi_actividad_vivo_widget.dart)**:
- `MiActividadVivoWidget`: Widget prominente para HomePage (CA-001, RN-007)
- Solo visible si hay pichanga activa
- Indicador "ESTAS JUGANDO" con circulo verde pulsante
- Info pichanga: lugar + fecha
- Cards de mi equipo (color) + mis goles totales (CA-002)
- Mini card partido en curso con score (CA-008)
- Boton "Ver actividad completa" navega a /mi-actividad
- Gradiente y borde del color de mi equipo

**9. HomePage (home_page.dart) - Integrado**:
- Widget `MiActividadVivoWidget` agregado antes del welcome card (RN-007)
- Acceso rapido "Mi Actividad" habilitado para jugadores
- Ruta actualizada de `/mis-partidos` a `/mi-actividad`

**Realtime implementado** (RN-006):
- Suscripcion automatica a cambios en `goles` y `partidos`
- Latencia objetivo: 3 segundos
- Actualizacion sin recargar pagina (CA-009)
- Manejo de errores de suscripcion sin interrumpir UX

**Validaciones cumplidas**:
- Clean Architecture con separacion en capas
- BLoC pattern para manejo de estado
- Dependency Injection configurado
- Ruta registrada y protegida (requiere autenticacion)
- Modelos con parsing robusto de JSON
- Realtime implementado con suscripciones
- Manejo de Either<Failure, Model> en repository
- UI completa implementada (mobile + desktop)
- Widget Dashboard implementado con animaciones
- Navegacion integrada en HomePage

### UI (ux-ui-expert)

**Estado**: IMPLEMENTADO

**Archivos creados**:
- `lib/features/mi_actividad/presentation/pages/mi_actividad_page.dart`
- `lib/features/mi_actividad/presentation/widgets/mi_actividad_vivo_widget.dart`

**Componentes implementados**:

1. **MiActividadVivoWidget** (Dashboard):
   - Indicador pulsante "ESTAS JUGANDO" con animacion
   - Cards de equipo y goles con colores dinamicos
   - Mini score del partido en curso
   - Navegacion a pantalla completa

2. **MiActividadPage** (Pantalla completa):
   - Vista mobile con AppBar + body scroll
   - Vista desktop con DashboardShell
   - Header con resumen: goles + equipo
   - Lista de partidos con cards diferenciadas
   - Borde de color en partidos donde participe
   - Badge "Participe" visual
   - Seccion "Mis goles" con detalle de minutos
   - Badge "EN VIVO" con animacion pulsante
   - Vista "Sin Actividad" con call-to-action
   - Vista de error con retry

**Design System aplicado**:
- DesignTokens: spacings, radii, shadows, colors
- Colores de equipo dinamicos desde hex
- Animaciones con duration de 1000ms para pulsante
- Responsive: mobile (Scaffold) + desktop (DashboardShell)

**Routing actualizado** (app_router.dart):
- Ruta: `/mi-actividad`
- BlocProvider con MiActividadBloc
- Evento inicial: CargarMiActividadEvent

**HomePage actualizado**:
- Widget MiActividadVivoWidget agregado en vista mobile
- Acceso rapido "Mi Actividad" habilitado (enabled: true)
- Ruta cambiada a `/mi-actividad`

### QA

**Estado**: PENDIENTE VALIDACION MANUAL

**Flutter Analyze**: 0 errores, 0 warnings en archivos de mi_actividad

**Validacion tecnica completada**:
- Compilacion exitosa
- No hay errores de analisis estatico
- Estructura de archivos correcta

**Pendiente validacion funcional**:
- Usuario debe ejecutar script SQL en Supabase Cloud
- Probar con pichanga activa en estado 'en_juego'
- Verificar actualizacion en tiempo real de goles

---

## Dependencias

### Prerequisitos
- [x] E003-HU-012: Iniciar Fecha (estado en_juego)
- [x] E003-HU-005: Asignar Equipos (saber mi equipo)
- [x] E004-HU-003: Registrar Gol (tabla goles con usuario_id)
- [x] E004-HU-004: Ver Score en Vivo (para enlazar)

### Impacta
- HomePage: Agregar widget de actividad
- Navegacion: Habilitar ruta /mi-actividad

---

## Casos de Prueba Sugeridos

### Flujo Principal
1. Jugador inscrito en pichanga activa ve widget en Dashboard
2. Jugador accede a Mi Actividad y ve todos los partidos
3. Partidos donde participo estan resaltados con su color
4. Mis goles se muestran correctamente por partido y total
5. Actualizacion en tiempo real al registrar gol

### Validaciones
1. Jugador NO inscrito en pichanga activa - widget no aparece
2. No hay pichanga en_juego - mensaje "Sin actividad"
3. Jugador con 0 goles - muestra "Mis goles: 0"
4. Partido sin mi equipo - no resaltado pero visible

### Edge Cases
1. Jugador cambio de equipo durante la jornada - ambos partidos resaltados
2. Gol anulado - no cuenta en mis goles
3. Autogol propio - no cuenta como "mi gol"
4. Multiples pichangas activas - mostrar la mas reciente

---

**Creado**: 2026-02-02
**Refinado**: 2026-02-02
**Autor**: Business Analyst (@negocio-deportivo-expert)
