# E003-HU-009 - Listado de Fechas con Visibilidad por Rol

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: En Desarrollo (DEV)
- **Prioridad**: Alta
- **Story Points**: 5 pts

## Historia de Usuario
**Como** usuario del sistema (admin o jugador)
**Quiero** ver las fechas de pichanga relevantes segun mi rol y participacion
**Para** gestionar efectivamente las jornadas (admin) o consultar mis inscripciones pasadas y futuras (jugador)

## Descripcion
Actualmente la funcion `listar_fechas_disponibles()` solo muestra fechas con estado 'abierta' y fecha futura, lo cual limita severamente la experiencia de usuario:
- El admin no puede ver fechas cerradas (necesarias para asignar equipos)
- El jugador no ve fechas donde esta inscrito si ya cerraron inscripciones
- No existe historial de pichangas

Esta HU implementa un sistema de visibilidad diferenciada por rol que resuelve estas limitaciones.

## Criterios de Aceptacion (CA)

### CA-001: Visibilidad de fechas abiertas para todos
- **Dado** que soy un usuario autenticado (admin o jugador)
- **Cuando** consulto el listado de fechas
- **Entonces** veo todas las fechas con estado "abierta" y fecha futura
- **Y** puedo ver los detalles basicos: fecha, hora, lugar, costo, inscritos

### CA-002: Vision completa del admin
- **Dado** que soy un administrador aprobado
- **Cuando** consulto el listado de fechas
- **Entonces** veo TODAS las fechas del sistema sin restriccion
- **Y** puedo ver fechas en cualquier estado (abierta, cerrada, en_juego, finalizada, cancelada)
- **Y** puedo ver fechas pasadas y futuras

### CA-003: Filtros disponibles para admin
- **Dado** que soy un administrador
- **Cuando** veo el listado de fechas
- **Entonces** tengo filtros por estado (todos, abierta, cerrada, en_juego, finalizada, cancelada)
- **Y** tengo filtros por rango de fechas (esta semana, este mes, historico)
- **Y** puedo combinar filtros

### CA-004: Inscripciones activas del jugador
- **Dado** que soy un jugador aprobado
- **Cuando** consulto el listado de fechas
- **Entonces** veo las fechas donde estoy inscrito con estado "cerrada" o "en_juego"
- **Y** estas fechas aparecen claramente marcadas como "Inscrito"
- **Y** puedo ver en cual equipo fui asignado (si aplica)

### CA-005: Historial de participaciones del jugador
- **Dado** que soy un jugador aprobado
- **Cuando** consulto mi historial de pichangas
- **Entonces** veo las fechas con estado "finalizada" donde participe
- **Y** puedo ver la fecha, lugar, y resultado de mi participacion
- **Y** las fechas estan ordenadas de mas reciente a mas antigua

### CA-006: Exclusion de fechas irrelevantes para jugador
- **Dado** que soy un jugador aprobado
- **Cuando** consulto el listado de fechas
- **Entonces** NO veo fechas finalizadas donde NO participe
- **Y** NO veo fechas canceladas donde NO estuve inscrito
- **Y** solo veo informacion relevante a mi participacion

### CA-007: Pestanas o segmentos de navegacion
- **Dado** que soy un jugador
- **Cuando** accedo al listado de fechas
- **Entonces** veo pestanas o segmentos: "Proximas" | "Mis Inscripciones" | "Historial"
- **Y** cada seccion muestra las fechas correspondientes a su categoria

### CA-008: Pestanas o segmentos para admin
- **Dado** que soy un administrador
- **Cuando** accedo al listado de fechas
- **Entonces** veo pestanas o segmentos: "Proximas" | "En Curso" | "Historial" | "Todas"
- **Y** la pestana "Todas" permite filtros adicionales por estado

### CA-009: Indicadores visuales por estado
- **Dado** que veo el listado de fechas
- **Cuando** hay fechas en diferentes estados
- **Entonces** cada estado tiene un color/icono distintivo:
  - Abierta: Verde (icono personas)
  - Cerrada: Amarillo (icono candado)
  - En juego: Azul (icono balon)
  - Finalizada: Gris (icono check)
  - Cancelada: Rojo (icono X)

### CA-010: Mensaje vacio contextual
- **Dado** que consulto una seccion sin fechas
- **Cuando** no hay datos para mostrar
- **Entonces** veo un mensaje apropiado segun el contexto:
  - "Proximas": "No hay pichangas programadas"
  - "Mis Inscripciones": "No tienes inscripciones activas"
  - "Historial": "Aun no has participado en pichangas"

---

## Reglas de Negocio (RN)

### RN-001: Visibilidad de Fechas Abiertas
**Contexto**: Las fechas con inscripciones abiertas son visibles para todos los usuarios autenticados.
**Restriccion**: Solo fechas con estado = 'abierta' Y fecha_hora_inicio > NOW().
**Validacion**: Sistema filtra automaticamente.
**Regla calculo**: N/A.
**Caso especial**: Una fecha abierta pero con fecha pasada (error de datos) no se muestra.

### RN-002: Visibilidad de Inscripciones Activas del Jugador
**Contexto**: Un jugador debe poder ver las fechas donde confirmo asistencia aunque ya no esten abiertas.
**Restriccion**: Mostrar fechas con estado IN ('cerrada', 'en_juego') donde usuario tiene inscripcion activa.
**Validacion**: JOIN con tabla inscripciones donde estado_inscripcion = 'inscrito'.
**Regla calculo**: N/A.
**Caso especial**: Si el jugador cancelo su inscripcion, no ve la fecha en esta seccion.

### RN-003: Historial de Participaciones del Jugador
**Contexto**: Jugadores quieren ver su historial de pichangas jugadas.
**Restriccion**: Solo fechas con estado = 'finalizada' donde usuario tiene inscripcion con estado = 'inscrito'.
**Validacion**: Sistema verifica participacion efectiva (no cancelo).
**Regla calculo**: N/A.
**Caso especial**: Las pichangas finalizadas pero donde el jugador cancelo su inscripcion NO aparecen en su historial.

### RN-004: Vision Completa del Administrador
**Contexto**: El admin necesita ver todas las fechas para gestion integral.
**Restriccion**: Sin filtros automaticos por rol.
**Validacion**: rol = 'admin' AND estado = 'aprobado'.
**Regla calculo**: N/A.
**Caso especial**: Un admin puede ver fechas creadas por otros admins.

### RN-005: Filtros Exclusivos de Admin
**Contexto**: Solo admins tienen acceso a filtros avanzados.
**Restriccion**: Jugadores tienen vista segmentada, no filtros libres.
**Validacion**: Verificar rol antes de mostrar opciones de filtro.
**Regla calculo**: N/A.
**Caso especial**: Los filtros de admin pueden combinarse (ej: estado 'cerrada' + ultimo mes).

### RN-006: Exclusion de Fechas Irrelevantes para Jugador
**Contexto**: Evitar saturar al jugador con informacion que no le concierne.
**Restriccion**: Jugador NO ve: fechas finalizadas sin participacion, fechas canceladas sin inscripcion previa.
**Validacion**: Sistema aplica exclusion automatica.
**Regla calculo**: N/A.
**Caso especial**: Si una fecha fue cancelada DESPUES de que el jugador se inscribio, SI la ve (para saber que se cancelo).

### RN-007: Orden por Defecto
**Contexto**: Las fechas deben ordenarse de forma logica segun el contexto.
**Restriccion**: N/A.
**Validacion**: N/A.
**Regla calculo**:
- Proximas/Abiertas: fecha_hora_inicio ASC (mas cercana primero)
- Mis Inscripciones: fecha_hora_inicio ASC
- Historial: fecha_hora_inicio DESC (mas reciente primero)
- Todas (admin): fecha_hora_inicio DESC por defecto
**Caso especial**: N/A.

---

## UI/UX Sugerido

### Para Jugador (Mobile)
```
+----------------------------------+
|     Pichangas                    |
+----------------------------------+
| [Proximas] [Inscrito] [Historial]|  <- Tabs/SegmentedButton
+----------------------------------+
|                                  |
| Tab "Proximas":                  |
|   - Fechas abiertas              |
|   - Boton "Anotarme"             |
|                                  |
| Tab "Inscrito":                  |
|   - Fechas cerradas/en_juego     |
|   - Badge "Equipo: Azul"         |
|   - Ver mi equipo                |
|                                  |
| Tab "Historial":                 |
|   - Fechas finalizadas           |
|   - Participaste como jugador    |
|                                  |
+----------------------------------+
```

### Para Admin (Desktop)
```
+--------------------------------------------------+
| Gestion de Fechas                    [+ Nueva]   |
+--------------------------------------------------+
| [Proximas] [En Curso] [Historial] [Todas]        |
+--------------------------------------------------+
| Filtros (solo en "Todas"):                       |
| Estado: [Todos v]  Desde: [____]  Hasta: [____]  |
+--------------------------------------------------+
| Card Fecha 1                                     |
| Card Fecha 2                                     |
| ...                                              |
+--------------------------------------------------+
```

### Indicadores Visuales de Estado
| Estado | Color | Icono | Badge |
|--------|-------|-------|-------|
| abierta | Verde (#4CAF50) | group | "Inscripciones Abiertas" |
| cerrada | Amarillo (#FFC107) | lock | "Inscripciones Cerradas" |
| en_juego | Azul (#2196F3) | sports_soccer | "En Juego" |
| finalizada | Gris (#9E9E9E) | check_circle | "Finalizada" |
| cancelada | Rojo (#F44336) | cancel | "Cancelada" |

---

## Notas Tecnicas

### Backend (supabase-expert)

**Nueva funcion RPC sugerida**: `listar_fechas_por_rol()`

```sql
-- Parametros opcionales para admin
p_filtro_estado: estado_fecha DEFAULT NULL
p_fecha_desde: DATE DEFAULT NULL
p_fecha_hasta: DATE DEFAULT NULL
p_seccion: TEXT DEFAULT 'proximas' -- 'proximas', 'inscrito', 'historial', 'todas'
```

**Logica interna**:
1. Detectar rol del usuario autenticado
2. Si es jugador:
   - 'proximas': fechas abiertas futuras
   - 'inscrito': fechas cerradas/en_juego donde esta inscrito
   - 'historial': fechas finalizadas donde participo
3. Si es admin:
   - 'proximas': fechas abiertas futuras
   - 'en_curso': fechas cerradas/en_juego
   - 'historial': fechas finalizadas
   - 'todas': todas las fechas con filtros opcionales

**Response incluye**:
- Datos basicos de fecha
- total_inscritos
- usuario_inscrito (boolean)
- equipo_asignado (si aplica, para jugador)
- estado con color/icono sugerido

### Frontend (flutter-expert)

**Nuevo BLoC sugerido**: `ListarFechasPorRolBloc`

**Eventos**:
- `CargarFechasEvent(seccion: String, filtros: FiltrosAdmin?)`
- `CambiarSeccionEvent(seccion: String)`
- `AplicarFiltrosEvent(filtros: FiltrosAdmin)` // solo admin

**Estados**:
- `FechasLoading`
- `FechasLoaded(fechas: List<FechaItem>, seccion: String, esAdmin: bool)`
- `FechasEmpty(mensaje: String, seccion: String)`
- `FechasError(mensaje: String)`

**Consideraciones UI**:
- TabBar o SegmentedButton segun rol
- Pull-to-refresh en mobile
- Paginacion si hay muchas fechas (historial)

---

## Dependencias

### Prerequisitos
- [x] E003-HU-001: Crear fecha (tabla fechas existe)
- [x] E003-HU-002: Inscribirse a fecha (tabla inscripciones existe)
- [x] E003-HU-005: Asignar equipos (campo equipo_asignado existe)

### Impacta
- Reemplaza/mejora funcion actual `listar_fechas_disponibles()`
- Modifica pagina `fechas_disponibles_page.dart`

---

## Casos de Prueba Sugeridos

### Jugador
1. Jugador sin inscripciones ve solo fechas abiertas en "Proximas"
2. Jugador inscrito a fecha cerrada la ve en "Inscrito" con su equipo
3. Jugador con historial ve sus participaciones ordenadas
4. Jugador NO ve fechas finalizadas donde no participo

### Admin
1. Admin ve todas las fechas en pestana "Todas"
2. Admin puede filtrar por estado especifico
3. Admin ve fechas en cualquier estado sin restriccion
4. Filtros de admin funcionan combinados

### Edge Cases
1. Fecha abierta que pasa su hora (debe dejar de aparecer en "Proximas")
2. Jugador que cancelo inscripcion no ve fecha en "Inscrito"
3. Fecha cancelada visible para jugador que estaba inscrito

---

**Creado**: 2026-01-29
**Refinado**: 2026-01-29

---

## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-29

### Funciones RPC Implementadas

**`listar_fechas_por_rol(p_seccion TEXT, p_filtro_estado TEXT, p_fecha_desde DATE, p_fecha_hasta DATE) -> JSON`**

- **Descripcion**: Lista fechas de pichanga con visibilidad diferenciada por rol (jugador/admin) y seccion solicitada
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007
- **Parametros**:
  - `p_seccion`: TEXT (DEFAULT 'proximas') - Seccion a consultar: 'proximas', 'inscrito', 'historial', 'en_curso', 'todas'
  - `p_filtro_estado`: TEXT (DEFAULT NULL) - Solo admin: filtro por estado de fecha
  - `p_fecha_desde`: DATE (DEFAULT NULL) - Solo admin: filtro fecha inicio
  - `p_fecha_hasta`: DATE (DEFAULT NULL) - Solo admin: filtro fecha fin
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "fechas": [
        {
          "id": "uuid",
          "fecha_hora_inicio": "timestamp",
          "fecha_formato": "DD/MM/YYYY",
          "hora_formato": "HH:MI",
          "lugar": "string",
          "duracion_horas": 2,
          "num_equipos": 2,
          "costo_por_jugador": 15.00,
          "costo_formato": "S/ 15.00",
          "estado": "abierta",
          "total_inscritos": 10,
          "usuario_inscrito": true,
          "equipo_asignado": "azul",
          "numero_equipo": 1,
          "puede_inscribirse": true,
          "puede_cancelar": false,
          "indicador": {
            "color": "#4CAF50",
            "icono": "group",
            "texto": "Inscripciones Abiertas"
          }
        }
      ],
      "seccion": "proximas",
      "total": 5,
      "es_admin": false,
      "filtros_aplicados": null
    },
    "message": "5 fechas encontradas"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `usuario_no_encontrado` -> Usuario no existe en tabla usuarios
  - `usuario_no_aprobado` -> Usuario no tiene estado 'aprobado'
  - `seccion_no_permitida` -> Jugador intento acceder a seccion de admin
  - `seccion_invalida` -> Seccion no reconocida

### Logica por Rol y Seccion

| Rol | Seccion | Estados incluidos | Condicion adicional |
|-----|---------|-------------------|---------------------|
| Jugador | proximas | abierta | fecha_hora_inicio > NOW() |
| Jugador | inscrito | cerrada, en_juego | Usuario tiene inscripcion activa |
| Jugador | historial | finalizada | Usuario tiene inscripcion activa |
| Admin | proximas | abierta | fecha_hora_inicio > NOW() |
| Admin | en_curso | cerrada, en_juego | Ninguna |
| Admin | historial | finalizada | Ninguna |
| Admin | todas | Todos los estados | Filtros opcionales |

### Indicadores Visuales por Estado

| Estado | Color | Icono | Texto |
|--------|-------|-------|-------|
| abierta | #4CAF50 | group | Inscripciones Abiertas |
| cerrada | #FFC107 | lock | Inscripciones Cerradas |
| en_juego | #2196F3 | sports_soccer | En Juego |
| finalizada | #9E9E9E | check_circle | Finalizada |
| cancelada | #F44336 | cancel | Cancelada |

### Orden de Resultados

- **proximas, inscrito, en_curso**: fecha_hora_inicio ASC (mas cercana primero)
- **historial, todas**: fecha_hora_inicio DESC (mas reciente primero)

### Script SQL
- `supabase/sql-cloud/2026-01-29_E003-HU-009_listar_fechas_por_rol.sql`

### Criterios de Aceptacion Backend

- [x] **CA-001**: Implementado - Fechas abiertas con fecha futura visibles para todos
- [x] **CA-002**: Implementado - Admin ve todas las fechas en seccion 'todas'
- [x] **CA-003**: Implementado - Filtros por estado, fecha_desde, fecha_hasta para admin
- [x] **CA-004**: Implementado - Jugador ve fechas inscrito en seccion 'inscrito' con equipo asignado
- [x] **CA-005**: Implementado - Jugador ve historial de fechas finalizadas donde participo
- [x] **CA-006**: Implementado - Jugador NO ve fechas finalizadas sin participacion
- [x] **CA-007**: Implementado - Secciones para jugador: proximas, inscrito, historial
- [x] **CA-008**: Implementado - Secciones para admin: proximas, en_curso, historial, todas
- [x] **CA-009**: Implementado - Indicadores visuales por estado (color, icono, texto)
- [x] **CA-010**: Implementado - Mensaje contextual cuando total = 0

---
