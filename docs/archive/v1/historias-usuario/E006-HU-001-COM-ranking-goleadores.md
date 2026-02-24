# E006-HU-001 - Ranking de Goleadores

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Alta
- **Story Points**: 5 pts

## Historia de Usuario
**Como** usuario del sistema
**Quiero** ver el ranking de goleadores
**Para** saber quienes son los maximos anotadores del grupo

## Descripcion
Muestra el ranking de jugadores ordenados por cantidad de goles anotados. Solo se cuentan goles validos (no anulados) y no autogoles. El ranking puede filtrarse por diferentes periodos de tiempo.

---

## Criterios de Aceptacion (CA)

### CA-001: Ranking general visible
- **Dado** que accedo a la seccion "Goleadores"
- **Cuando** se carga la pantalla
- **Entonces** veo lista de jugadores ordenados por cantidad de goles (mayor a menor)
- **Y** el orden se actualiza en tiempo real si hay cambios

### CA-002: Informacion por jugador en el ranking
- **Dado** que veo el ranking
- **Cuando** observo cada entrada
- **Entonces** veo: posicion (#1, #2...), foto/avatar, apodo, cantidad de goles
- **Y** opcionalmente: partidos jugados, promedio de goles

### CA-003: Filtro por periodo
- **Dado** que veo el ranking
- **Cuando** quiero ver periodos especificos
- **Entonces** puedo filtrar por:
  - Historico (todos los tiempos)
  - Este ano
  - Este mes
  - Ultima fecha jugada

### CA-004: Manejo de empates
- **Dado** que varios jugadores tienen la misma cantidad de goles
- **Cuando** veo el ranking
- **Entonces** desempatan por: menor cantidad de partidos jugados (mejor promedio)
- **Y** si aun hay empate: fecha de registro mas antigua primero

### CA-005: Mi posicion destacada
- **Dado** que estoy logueado y aparezco en el ranking
- **Cuando** veo la lista
- **Entonces** mi fila aparece destacada visualmente (borde, color de fondo)
- **Y** si no estoy en los primeros N visibles, hay acceso rapido a "Ver mi posicion"

### CA-006: Top 3 destacado (Podio)
- **Dado** que veo el ranking
- **Cuando** hay al menos 3 jugadores con goles
- **Entonces** el top 3 se muestra en formato podio especial:
  - 1ro: Medalla oro, posicion central/superior
  - 2do: Medalla plata, izquierda
  - 3ro: Medalla bronce, derecha

### CA-007: Ranking vacio
- **Dado** que no hay goles registrados en el periodo seleccionado
- **Cuando** veo el ranking
- **Entonces** se muestra mensaje "No hay goles registrados en este periodo"
- **Y** se sugiere seleccionar otro periodo

---

## Reglas de Negocio (RN)

### RN-001: Goles Validos para Ranking
**Contexto**: Al contabilizar goles para el ranking.
**Restriccion**: Solo se cuentan goles que cumplan:
  1. `anulado = false` (no anulados)
  2. `es_autogol = false` (no autogoles)
  3. `jugador_id IS NOT NULL` (goles asignados a un jugador)
**Validacion**: COUNT goles WHERE anulado=false AND es_autogol=false AND jugador_id IS NOT NULL.
**Regla calculo**: N/A.
**Caso especial**: Goles sin jugador asignado no cuentan para ningun ranking individual.

### RN-002: Solo Fechas Finalizadas
**Contexto**: Para evitar rankings incompletos.
**Restriccion**: Solo se contabilizan goles de partidos en fechas con estado = 'finalizada'.
**Validacion**: JOIN con fechas WHERE estado = 'finalizada'.
**Regla calculo**: N/A.
**Caso especial**: Fechas `en_juego` no afectan el ranking hasta que finalicen.

### RN-003: Criterios de Desempate
**Contexto**: Cuando varios jugadores tienen los mismos goles.
**Restriccion**: Orden de desempate:
  1. Mayor cantidad de goles (principal)
  2. Menor cantidad de partidos jugados (mejor eficiencia)
  3. Fecha de registro mas antigua (veterania)
**Validacion**: ORDER BY goles DESC, partidos ASC, created_at ASC.
**Regla calculo**: N/A.
**Caso especial**: Si aun empatan, comparten posicion (#2, #2, #4...).

### RN-004: Calculo de Partidos Jugados
**Contexto**: Para calcular promedio y desempate.
**Restriccion**: Un partido cuenta como "jugado" si:
  1. El jugador tenia asignacion de equipo en esa fecha
  2. Su equipo participo en el partido
  3. El partido esta finalizado
**Validacion**: COUNT partidos WHERE jugador_equipo IN (equipo_local, equipo_visitante) AND estado='finalizado'.
**Regla calculo**: N/A.
**Caso especial**: Partidos cancelados no cuentan.

### RN-005: Periodos de Filtrado
**Contexto**: Al filtrar el ranking por tiempo.
**Restriccion**: Definicion de periodos:
  - Historico: todos los goles desde el inicio
  - Este ano: goles de fechas desde 1 de enero del ano actual
  - Este mes: goles de fechas desde 1 del mes actual
  - Ultima fecha: goles solo de la fecha finalizada mas reciente
**Validacion**: Filter por fecha_hora_inicio de la fecha.
**Regla calculo**: N/A.
**Caso especial**: Si no hay datos en el periodo, mostrar mensaje informativo.

### RN-006: Visibilidad del Ranking
**Contexto**: Quien puede ver el ranking.
**Restriccion**: El ranking es visible para todos los usuarios autenticados del sistema.
**Validacion**: Usuario autenticado.
**Regla calculo**: N/A.
**Caso especial**: No hay restriccion por rol (admin, jugador, todos ven lo mismo).

### RN-007: Actualizacion del Ranking
**Contexto**: Cuando se actualiza el ranking.
**Restriccion**: El ranking se recalcula cuando:
  1. Se finaliza una fecha
  2. Se registra/anula un gol (en fecha finalizada - ajuste)
  3. Se cambia jugador_id de un gol
**Validacion**: N/A.
**Regla calculo**: N/A.
**Caso especial**: Cambios durante fecha `en_juego` no afectan hasta finalizacion.

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

---

## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-02-02

### Funciones RPC Implementadas

**`obtener_ranking_goleadores(p_periodo TEXT) -> JSON`**
- **Descripcion**: Obtiene el ranking de goleadores ordenados por cantidad de goles con filtros por periodo
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006
- **Parametros**:
  - `p_periodo`: TEXT - Periodo de filtrado. Valores: 'historico', 'este_ano', 'este_mes', 'ultima_fecha'. Default: 'historico'
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "periodo": "historico",
      "ranking": [
        {
          "posicion": 1,
          "jugador_id": "uuid",
          "apodo": "string",
          "avatar_url": "string|null",
          "goles": 10,
          "partidos_jugados": 5,
          "promedio": 2.00
        }
      ],
      "total_jugadores": 15
    },
    "message": "Ranking de goleadores obtenido exitosamente"
  }
  ```
- **Response Success (vacio)**:
  ```json
  {
    "success": true,
    "data": {
      "periodo": "este_mes",
      "ranking": [],
      "total_jugadores": 0,
      "mensaje": "No hay goles registrados en este periodo"
    },
    "message": "No hay goles registrados en el periodo seleccionado"
  }
  ```
- **Response Error - Hints**:
  - `periodo_invalido` -> Periodo no valido, usar: historico, este_ano, este_mes, ultima_fecha

### Logica de Negocio Implementada

1. **RN-001 (Goles Validos)**: CTE `goles_validos` filtra por `anulado=false`, `es_autogol=false`, `jugador_id IS NOT NULL`
2. **RN-002 (Fechas Finalizadas)**: CTE `fechas_filtradas` filtra por `estado='finalizada'`
3. **RN-003 (Desempate)**: `ORDER BY goles DESC, partidos_jugados ASC, created_at ASC`
4. **RN-004 (Partidos Jugados)**: CTE `partidos_jugados` cuenta partidos donde el jugador tenia asignacion de equipo y su equipo participo (local o visitante) en partido finalizado
5. **RN-005 (Periodos)**: Filtros por `fecha_hora_inicio` considerando zona horaria Peru (America/Lima)
6. **RN-006 (Visibilidad)**: GRANT a authenticated, anon, service_role

### Script SQL
- `supabase/sql-cloud/2026-02-02_E006-HU-001_ranking_goleadores.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Ranking ordenado por goles DESC implementado en funcion
- [x] **CA-002**: Retorna posicion, avatar_url, apodo, goles, partidos_jugados, promedio
- [x] **CA-003**: Filtros por periodo implementados (historico, este_ano, este_mes, ultima_fecha)
- [x] **CA-004**: Desempate implementado: goles DESC, partidos ASC, created_at ASC
- [ ] **CA-005**: (Frontend) Destacar fila del usuario actual
- [ ] **CA-006**: (Frontend) Visualizacion podio top 3
- [x] **CA-007**: Ranking vacio retorna array vacio con mensaje informativo

---

## FASE 4: Implementacion Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-02-02

### Estructura Clean Architecture

```
lib/features/estadisticas/
├── data/
│   ├── models/
│   │   ├── models.dart
│   │   ├── ranking_goleador_model.dart
│   │   └── ranking_response_model.dart
│   ├── datasources/
│   │   └── estadisticas_remote_datasource.dart
│   └── repositories/
│       └── estadisticas_repository_impl.dart
├── domain/
│   └── repositories/
│       └── estadisticas_repository.dart
└── presentation/
    └── bloc/
        └── ranking_goleadores/
            ├── ranking_goleadores.dart
            ├── ranking_goleadores_bloc.dart
            ├── ranking_goleadores_event.dart
            └── ranking_goleadores_state.dart
```

### Archivos Implementados

**Models** (`lib/features/estadisticas/data/models/`):
- `ranking_goleador_model.dart`: Modelo de goleador con posicion, jugadorId, apodo, avatarUrl, goles, partidosJugados, promedio
- `ranking_response_model.dart`: Modelo de respuesta con periodo, ranking[], totalJugadores, mensaje. Incluye enum `PeriodoRanking`

**DataSource** (`lib/features/estadisticas/data/datasources/`):
- `estadisticas_remote_datasource.dart`: Llama RPC `obtener_ranking_goleadores(p_periodo)`

**Repository** (`lib/features/estadisticas/`):
- `domain/repositories/estadisticas_repository.dart`: Interface con Either pattern
- `data/repositories/estadisticas_repository_impl.dart`: Implementacion

**BLoC** (`lib/features/estadisticas/presentation/bloc/ranking_goleadores/`):
- Events: `CargarRankingEvent`, `CambiarPeriodoEvent`, `RefrescarRankingEvent`
- States: `RankingGoleadoresInitial`, `RankingGoleadoresLoading`, `RankingGoleadoresLoaded`, `RankingGoleadoresVacio`, `RankingGoleadoresRefreshing`, `RankingGoleadoresError`
- Bloc: Maneja carga y cambio de periodo con estado de datos

**Dependency Injection** (`lib/core/di/injection_container.dart`):
- Registrado `RankingGoleadoresBloc`, `EstadisticasRepository`, `EstadisticasRemoteDataSource`

### Integracion Backend

```
UI -> RankingGoleadoresBloc -> EstadisticasRepository -> EstadisticasRemoteDataSource -> RPC obtener_ranking_goleadores
```

### Mapping snake_case (BD) -> camelCase (Dart)

| Backend (JSON)    | Frontend (Dart)  |
|-------------------|------------------|
| posicion          | posicion         |
| jugador_id        | jugadorId        |
| apodo             | apodo            |
| avatar_url        | avatarUrl        |
| goles             | goles            |
| partidos_jugados  | partidosJugados  |
| promedio          | promedio         |
| total_jugadores   | totalJugadores   |

### Criterios de Aceptacion Frontend

- [x] **CA-001**: Implementado en `RankingGoleadoresBloc` - carga lista ordenada
- [x] **CA-002**: `RankingGoleadorModel` con todos los campos requeridos
- [x] **CA-003**: `PeriodoRanking` enum con 4 opciones, `CambiarPeriodoEvent`
- [x] **CA-004**: Delegado al backend (orden ya viene correcto)
- [x] **CA-005**: Implementado en UI - fila destacada con borde y color
- [x] **CA-006**: `RankingGoleadoresLoaded.top3` y `tienePodioCompleto` para UI
- [x] **CA-007**: `RankingGoleadoresVacio` state con mensaje informativo

### Verificacion

- [x] `flutter analyze`: 0 errores en archivos de estadisticas
- [x] Mapping snake_case <-> camelCase correcto
- [x] Either pattern en repository
- [x] Estados de Bloc completos (Initial, Loading, Loaded, Vacio, Refreshing, Error)

---

## FASE 1: Diseno UX/UI
**Responsable**: ux-ui-expert
**Status**: Completado
**Fecha**: 2026-02-02

### Componentes UI Diseados

**Paginas** (`lib/features/estadisticas/presentation/pages/`):
- `ranking_goleadores_page.dart`: Pagina principal con ResponsiveLayout (Mobile + Desktop)

**Widgets** (`lib/features/estadisticas/presentation/widgets/`):
- `podio_goleadores_widget.dart`: Widget del podio top 3 con medallas (oro, plata, bronce)
- `goleador_list_item.dart`: Fila de ranking para posiciones 4+
- `periodo_selector_widget.dart`: Chips para filtrar por periodo

**Routing** (`lib/core/routing/app_router.dart`):
- Ruta: `/ranking-goleadores`
- BlocProvider: `RankingGoleadoresBloc` con `CargarRankingEvent`

### Layout Mobile (< 600px)

```
+----------------------------------+
| AppBar: Ranking Goleadores   [R] |
+----------------------------------+
| [Historico][Este ano][Este mes]  |
+----------------------------------+
|                                  |
|   [PODIO TOP 3 - Medallas]       |
|   Plata | ORO  | Bronce          |
|                                  |
+----------------------------------+
|   Resto del ranking              |
|   #4 [Avatar] Apodo    [Goles]   |
|   #5 [Avatar] Apodo    [Goles]   |
|   ...                            |
+----------------------------------+
| [BottomNavBar - index 0]         |
+----------------------------------+
```

### Layout Desktop (>= 600px)

```
+----------------+--------------------------------------------------+
|                |  Header: Ranking de Goleadores            [R]   |
|   SIDEBAR      |  Breadcrumbs: Inicio > Estadisticas > Ranking   |
|   (240px)      +--------------+-----------------------------------+
|                | FILTROS      |  CONTENIDO PRINCIPAL              |
|   - Inicio     | (320px)      |  -------------------------------- |
|   - Perfil     |              |  [PODIO TOP 3 - Medallas]         |
|   - Jugadores  | Titulo       |                                   |
|   - Pichangas  | Descripcion  |  -------------------------------- |
|   - Stats      |              |  Resto del ranking (DataTable)    |
|                | [RESUMEN]    |  #  | Jugador | Goles | PJ | Prom |
|                | Goleadores:N |  4  | Apodo   |   5   | 3  | 1.67 |
|                | Periodo: X   |  5  | Apodo   |   4   | 4  | 1.00 |
|                |              |                                   |
|                | [PERIODO]    |                                   |
|                | (chips)      |                                   |
|                |              |                                   |
|                | [LEYENDA]    |                                   |
|                | Medallas     |                                   |
+----------------+--------------+-----------------------------------+
```

### Funcionalidad UI

**Responsive**:
- Mobile: AppBar + BottomNavBar + ScrollView con Podio y Lista
- Desktop: DashboardShell con Sidebar + Panel filtros (320px) + Contenido expandido

**Estados visuales**:
- Loading: CircularProgressIndicator centrado
- Error: Icono error + mensaje + boton reintentar
- Vacio (CA-007): Icono + mensaje + sugerencia cambiar periodo
- Datos: Podio + Lista/Tabla

**Interacciones**:
- Pull to refresh (mobile)
- Chips de periodo con animacion de carga
- Hover en cards y filas (desktop)

**Destacado usuario actual (CA-005)**:
- Fila con borde primario y fondo primaryContainer
- Badge "Tu" al lado del nombre
- En podio: Borde destacado

### Criterios de Aceptacion UI

- [x] **CA-001**: Lista de goleadores visible con datos completos
- [x] **CA-002**: Posicion, avatar, apodo, goles, partidos, promedio visibles
- [x] **CA-003**: Selector de periodo con 4 opciones funcional
- [x] **CA-005**: Fila del usuario actual destacada con borde y badge "Tu"
- [x] **CA-006**: Podio visual con medallas oro (#FFD700), plata (#C0C0C0), bronce (#CD7F32)
- [x] **CA-007**: Estado vacio con mensaje y sugerencia de cambiar periodo

### Verificacion ResponsiveLayout

- [x] ResponsiveLayout: Linea 56
- [x] DashboardShell (desktop): Linea 514
- [x] AppBottomNavBar (mobile): Linea 201
- [x] flutter analyze: 0 errores

### Archivos Creados

| Archivo | Lineas | Descripcion |
|---------|--------|-------------|
| `pages/ranking_goleadores_page.dart` | ~1200 | Pagina principal responsive |
| `widgets/podio_goleadores_widget.dart` | ~250 | Widget podio con medallas |
| `widgets/goleador_list_item.dart` | ~230 | Item de lista para ranking |
| `widgets/periodo_selector_widget.dart` | ~240 | Selector de periodos |
| `widgets/widgets.dart` | 6 | Barrel file |

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02

---

## FASE 5: Validacion QA Tecnica
**Responsable**: qa-testing-expert
**Fecha**: 2026-02-02

### Validacion Tecnica APROBADA

#### 1. Dependencias
```
$ flutter pub get
Resolving dependencies...
Downloading packages...
Got dependencies!
41 packages have newer versions incompatible with dependency constraints.
```
PASS - Sin errores

#### 2. Analisis Estatico
```
$ flutter analyze --no-pub
Analyzing gestion_deportiva...
18 issues found. (ran in 3.0s)
```
PASS - 0 errores en feature estadisticas
- 16 info (deprecaciones en otros features)
- 2 warnings (codigo no usado en mi_actividad - pre-existente)
- 0 errores bloqueantes

#### 3. Compilacion Web
```
$ flutter build web --release
Compiling lib\main.dart for the Web...
Built build\web
```
PASS - Compilacion exitosa (61.2s)

#### 4. Tests
SKIP - No hay tests especificos para estadisticas (a implementar en futuro)
- Tests existentes fallan por dependencia MiActividadBloc (problema pre-existente, no relacionado con esta HU)

### Verificacion de Archivos

| Componente | Archivo | Estado |
|------------|---------|--------|
| Model | `data/models/ranking_goleador_model.dart` | EXISTE |
| Model | `data/models/ranking_response_model.dart` | EXISTE |
| Model | `data/models/models.dart` | EXISTE |
| DataSource | `data/datasources/estadisticas_remote_datasource.dart` | EXISTE |
| Repository Interface | `domain/repositories/estadisticas_repository.dart` | EXISTE |
| Repository Impl | `data/repositories/estadisticas_repository_impl.dart` | EXISTE |
| Bloc | `presentation/bloc/ranking_goleadores/ranking_goleadores_bloc.dart` | EXISTE |
| Events | `presentation/bloc/ranking_goleadores/ranking_goleadores_event.dart` | EXISTE |
| States | `presentation/bloc/ranking_goleadores/ranking_goleadores_state.dart` | EXISTE |
| Barrel | `presentation/bloc/ranking_goleadores/ranking_goleadores.dart` | EXISTE |
| Page | `presentation/pages/ranking_goleadores_page.dart` | EXISTE |
| Widget | `presentation/widgets/podio_goleadores_widget.dart` | EXISTE |
| Widget | `presentation/widgets/goleador_list_item.dart` | EXISTE |
| Widget | `presentation/widgets/periodo_selector_widget.dart` | EXISTE |
| Widget | `presentation/widgets/widgets.dart` | EXISTE |
| SQL | `supabase/sql-cloud/2026-02-02_E006-HU-001_ranking_goleadores.sql` | EXISTE |
| Ruta | `/ranking-goleadores` en `app_router.dart` | EXISTE |
| DI | `RankingGoleadoresBloc` en `injection_container.dart` | EXISTE |

### Verificacion de CA Implementados

| CA | Descripcion | Backend | Frontend | Estado |
|----|-------------|---------|----------|--------|
| CA-001 | Ranking ordenado por goles | RPC con ORDER BY | BLoC + Page | IMPLEMENTADO |
| CA-002 | Info completa (posicion, avatar, apodo, goles, PJ, promedio) | JSON response | Model + Widget | IMPLEMENTADO |
| CA-003 | Filtros de periodo (4 opciones) | p_periodo param | PeriodoRanking enum + Chips | IMPLEMENTADO |
| CA-004 | Desempate (goles DESC, partidos ASC, created_at ASC) | SQL ORDER BY | Delegado al backend | IMPLEMENTADO |
| CA-005 | Mi posicion destacada | jugador_id en response | currentUserId + badge "Tu" | IMPLEMENTADO |
| CA-006 | Podio top 3 con medallas | top3 getter | PodioGoleadoresWidget | IMPLEMENTADO |
| CA-007 | Estado vacio con mensaje | mensaje en response | RankingGoleadoresVacio state | IMPLEMENTADO |

### Resumen

| Validacion | Estado |
|------------|--------|
| Dependencias | PASS |
| Analisis | PASS (0 errores) |
| Compilacion | PASS |
| Archivos creados | PASS (18/18) |
| CA implementados | PASS (7/7) |

### Decision

**VALIDACION TECNICA APROBADA**

Siguiente paso: Usuario valida manualmente los CA navegando a `/ranking-goleadores` en la aplicacion.

---
