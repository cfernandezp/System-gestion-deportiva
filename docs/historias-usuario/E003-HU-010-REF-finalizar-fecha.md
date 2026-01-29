# E003-HU-010 - Finalizar Fecha

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: DEV (En Desarrollo)
- **Prioridad**: Alta
- **Story Points**: 5 pts

## Historia de Usuario
**Como** administrador
**Quiero** marcar una fecha de pichanga como finalizada
**Para** que quede registrada en el historial de participaciones de los jugadores y se cierre oficialmente el ciclo de la jornada

## Descripcion
Actualmente el sistema tiene un ciclo de vida incompleto para las fechas de pichanga. Una vez que se juega la pichanga (estado 'en_juego'), no existe forma de cerrar oficialmente el ciclo. Esto causa que:
- El historial de jugadores permanece vacio (no hay fechas finalizadas)
- No existe registro oficial de las pichangas jugadas
- No se pueden registrar observaciones o incidentes del partido
- La pestana "Historial" de E003-HU-009 no muestra ninguna fecha

Esta HU implementa la funcionalidad para finalizar una fecha, completando el ciclo de vida:
`abierta -> cerrada -> en_juego -> finalizada`

## Criterios de Aceptacion (CA)

### CA-001: Boton finalizar fecha
- **Dado** que soy admin y hay una fecha con estado "en_juego"
- **Cuando** veo el detalle de la fecha
- **Entonces** veo opcion "Finalizar Pichanga"
- **Y** el boton es claramente visible con icono distintivo

### CA-002: Finalizar desde estado cerrada (alternativo)
- **Dado** que soy admin y hay una fecha con estado "cerrada"
- **Cuando** la pichanga ya se jugo pero nunca se marco como "en_juego"
- **Entonces** tambien puedo ver opcion "Finalizar Pichanga"
- **Y** el sistema permite finalizar directamente desde 'cerrada'

### CA-003: Dialog de confirmacion con opciones
- **Dado** que presiono "Finalizar Pichanga"
- **Cuando** aparece el dialog de finalizacion
- **Entonces** veo:
  - Resumen de la fecha (fecha, hora, lugar, inscritos)
  - Campo opcional para comentarios/observaciones
  - Checkbox opcional "Hubo algun incidente"
  - Campo condicional para describir el incidente (si checkbox activo)
- **Y** veo botones "Cancelar" y "Confirmar Finalizacion"

### CA-004: Registro de comentarios opcional
- **Dado** que finalizo una pichanga
- **Cuando** escribo comentarios u observaciones
- **Entonces** el texto se guarda asociado a la fecha
- **Y** puede quedar vacio si no hay nada que reportar

### CA-005: Registro de incidentes opcional
- **Dado** que marco "Hubo algun incidente"
- **Cuando** aparece el campo de descripcion
- **Entonces** debo escribir una descripcion del incidente
- **Y** el campo es obligatorio si el checkbox esta activo

### CA-006: Estado actualizado a finalizada
- **Dado** que confirmo la finalizacion
- **Cuando** se procesa
- **Entonces** el estado cambia a "finalizada"
- **Y** se registra quien finalizo y cuando
- **Y** veo mensaje de exito "Pichanga finalizada correctamente"

### CA-007: Aparece en historial de jugadores
- **Dado** que la fecha esta finalizada
- **Cuando** un jugador que estuvo inscrito consulta su historial
- **Entonces** la fecha aparece en su pestana "Historial"
- **Y** puede ver la fecha, lugar y su equipo asignado

### CA-008: Aparece en historial del admin
- **Dado** que la fecha esta finalizada
- **Cuando** el admin consulta el listado de fechas
- **Entonces** la fecha aparece en la pestana "Historial"
- **Y** puede ver todos los detalles incluyendo comentarios e incidentes

### CA-009: Estado terminal no reversible
- **Dado** que una fecha esta finalizada
- **Cuando** intento cambiar su estado
- **Entonces** no hay opcion para reabrir o modificar el estado
- **Y** el estado "finalizada" es permanente

### CA-010: Indicador visual de estado
- **Dado** que veo una fecha finalizada en el listado
- **Cuando** observo su indicador de estado
- **Entonces** muestra color gris (#9E9E9E)
- **Y** icono check_circle
- **Y** texto "Finalizada"

---

## Reglas de Negocio (RN)

### RN-001: Permiso Exclusivo Admin
**Contexto**: Solo administradores pueden finalizar fechas de pichanga.
**Restriccion**: Jugadores no tienen acceso a esta funcionalidad.
**Validacion**: Verificar rol = 'admin' y estado = 'aprobado' antes de permitir accion.
**Regla calculo**: N/A.
**Caso especial**: N/A.

### RN-002: Estados Validos para Finalizar
**Contexto**: Solo se pueden finalizar fechas que ya se jugaron o estaban listas para jugarse.
**Restriccion**: No se puede finalizar una fecha con estado 'abierta', 'finalizada' o 'cancelada'.
**Validacion**: fecha.estado IN ('en_juego', 'cerrada').
**Regla calculo**: N/A.
**Caso especial**: Se permite finalizar desde 'cerrada' para casos donde el admin olvido marcar como 'en_juego'.

### RN-003: Estado Terminal
**Contexto**: Una vez finalizada, la fecha no puede cambiar de estado.
**Restriccion**: No existe transicion desde 'finalizada' a ningun otro estado.
**Validacion**: Rechazar cualquier intento de modificar estado de fecha finalizada.
**Regla calculo**: N/A.
**Caso especial**: Si hubo un error, se debe crear una nueva fecha. La finalizada queda como registro historico.

### RN-004: Auditoria de Finalizacion
**Contexto**: Se debe registrar quien y cuando finalizo la fecha.
**Restriccion**: Estos campos son obligatorios y se llenan automaticamente.
**Validacion**: Guardar id del admin que finaliza y timestamp de finalizacion.
**Regla calculo**: N/A.
**Caso especial**: N/A.

### RN-005: Comentarios e Incidentes Opcionales
**Contexto**: El admin puede registrar observaciones o incidentes del partido.
**Restriccion**: Los comentarios son opcionales. Si se marca incidente, la descripcion es obligatoria.
**Validacion**: Si hubo_incidente = true, entonces descripcion_incidente no puede estar vacio.
**Regla calculo**: N/A.
**Caso especial**: Un incidente puede ser: lesion de jugador, pelea, dano a infraestructura, etc.

### RN-006: Efecto en Historial de Jugadores
**Contexto**: Al finalizar, la fecha aparece en el historial de todos los jugadores inscritos.
**Restriccion**: Solo jugadores con inscripcion activa (no cancelada) ven la fecha en su historial.
**Validacion**: Filtrar por inscripciones con estado_inscripcion = 'inscrito'.
**Regla calculo**: N/A.
**Caso especial**: Jugadores que cancelaron su inscripcion NO ven la fecha en su historial.

### RN-007: Preservacion de Datos
**Contexto**: Al finalizar, todos los datos de la fecha se preservan intactos.
**Restriccion**: No se modifican inscripciones, equipos asignados ni deudas.
**Validacion**: Solo se actualiza el estado y campos de finalizacion.
**Regla calculo**: N/A.
**Caso especial**: Las deudas pendientes de jugadores siguen activas.

---

## UI/UX Sugerido

### Para Admin (Mobile)
```
+----------------------------------+
| <- Pichanga 25/01/2026           |
|                     [Finalizar]  |  <- IconButton
+----------------------------------+
|                                  |
| Estado: En Juego                 |
| Lugar: Cancha Los Amigos         |
| Inscritos: 12 jugadores          |
|                                  |
| [Ver Equipos]                    |
|                                  |
+----------------------------------+

-- Dialog Finalizar (BottomSheet) --
+----------------------------------+
|    ====                          |  <- Handle
|                                  |
| [check_circle] Finalizar Pichanga|
|                                  |
| Esta accion no se puede deshacer.|
| La fecha quedara registrada en   |
| el historial de participaciones. |
|                                  |
| +------------------------------+ |
| | Fecha: 25/01/2026 19:00      | |
| | Lugar: Cancha Los Amigos     | |
| | Inscritos: 12 jugadores      | |
| | Equipos asignados: Si        | |
| +------------------------------+ |
|                                  |
| Comentarios (opcional):          |
| +------------------------------+ |
| | Buen partido, todos puntuales| |
| +------------------------------+ |
|                                  |
| [ ] Hubo algun incidente         |
|                                  |
| [Cancelar]    [Confirmar]        |
+----------------------------------+

-- Con incidente marcado --
+----------------------------------+
| [x] Hubo algun incidente         |
|                                  |
| Describe el incidente:           |
| +------------------------------+ |
| | Jugador X se lesiono el      | |
| | tobillo en el minuto 45      | |
| +------------------------------+ |
|                                  |
| [Cancelar]    [Confirmar]        |
+----------------------------------+
```

### Para Admin (Desktop)
```
+--------------------------------------------------+
| Gestion de Fechas                    [Finalizar] |  <- FilledButton
+--------------------------------------------------+
|                                                  |
| Card con detalles de la fecha                    |
|                                                  |
+--------------------------------------------------+

-- Dialog Finalizar (Centrado) --
+------------------------------------------------+
|                                                |
|      [check_circle]                            |
|                                                |
|      Finalizar Pichanga                        |
|      Esta accion es permanente                 |
|                                                |
| +--------------------------------------------+ |
| | Fecha: Sabado 25/01/2026 a las 19:00      | |
| | Lugar: Cancha Los Amigos                  | |
| | Participantes: 12 jugadores               | |
| | Equipos: 2 equipos asignados              | |
| +--------------------------------------------+ |
|                                                |
| Comentarios u observaciones:                   |
| +--------------------------------------------+ |
| |                                            | |
| |                                            | |
| +--------------------------------------------+ |
|                                                |
| [x] Reportar incidente                         |
|                                                |
| Descripcion del incidente:                     |
| +--------------------------------------------+ |
| |                                            | |
| +--------------------------------------------+ |
|                                                |
|               [Cancelar] [Confirmar Finalizacion]
+------------------------------------------------+
```

### Indicadores Visuales de Estado (ya definidos en HU-009)
| Estado | Color | Icono | Texto |
|--------|-------|-------|-------|
| finalizada | #9E9E9E (gris) | check_circle | Finalizada |

---

## Notas Tecnicas

### Backend (supabase-expert)

**Nuevos campos en tabla fechas** (sugerido):
- `finalizado_por`: UUID - ID del admin que finalizo
- `finalizado_at`: TIMESTAMPTZ - Timestamp de finalizacion
- `comentarios_finalizacion`: TEXT - Observaciones opcionales
- `hubo_incidente`: BOOLEAN DEFAULT FALSE - Flag de incidente
- `descripcion_incidente`: TEXT - Descripcion si hubo incidente

**Nueva funcion RPC sugerida**: `finalizar_fecha()`

```
Parametros:
- p_fecha_id: UUID (obligatorio)
- p_comentarios: TEXT (opcional)
- p_hubo_incidente: BOOLEAN (opcional, default false)
- p_descripcion_incidente: TEXT (obligatorio si p_hubo_incidente = true)
```

**Validaciones**:
1. Usuario es admin aprobado (RN-001)
2. Fecha existe y estado IN ('en_juego', 'cerrada') (RN-002)
3. Si p_hubo_incidente = true, p_descripcion_incidente no puede ser NULL/vacio (RN-005)

**Response Success sugerido**:
```json
{
  "success": true,
  "data": {
    "fecha_id": "uuid",
    "fecha_formato": "DD/MM/YYYY HH24:MI",
    "lugar": "string",
    "estado_anterior": "en_juego",
    "estado_nuevo": "finalizada",
    "total_participantes": 12,
    "comentarios": "string o null",
    "hubo_incidente": false,
    "descripcion_incidente": "string o null",
    "finalizado_por": "uuid",
    "finalizado_por_nombre": "string",
    "finalizado_at": "timestamp",
    "finalizado_at_formato": "DD/MM/YYYY HH24:MI"
  },
  "message": "Pichanga finalizada exitosamente. Ahora aparece en el historial de los 12 participantes."
}
```

**Response Error - Hints sugeridos**:
- `no_autenticado` - Usuario no ha iniciado sesion
- `fecha_id_requerido` - Falta parametro fecha_id
- `usuario_no_encontrado` - Usuario no existe en tabla usuarios
- `sin_permisos` - Usuario no es admin aprobado
- `fecha_no_encontrada` - Fecha no existe
- `estado_invalido` - Fecha no esta en estado 'en_juego' o 'cerrada'
- `descripcion_incidente_requerida` - Se marco incidente pero falta descripcion

### Frontend (flutter-expert)

**Nuevo Model sugerido**: `FinalizarFechaResponseModel`
- Mapeo snake_case -> camelCase
- Campos segun response del backend

**Nuevo Bloc sugerido**: `FinalizarFechaBloc`

**Eventos**:
- `FinalizarFechaSubmitEvent(fechaId, comentarios, huboIncidente, descripcionIncidente)`
- `FinalizarFechaResetEvent`

**Estados**:
- `FinalizarFechaInitial`
- `FinalizarFechaLoading`
- `FinalizarFechaSuccess(data)`
- `FinalizarFechaError(mensaje, hint)`

**UI**:
- Dialog/BottomSheet segun ResponsiveLayout
- TextField para comentarios (multiline)
- Checkbox para incidente
- TextField condicional para descripcion incidente
- Validacion local: si checkbox activo, campo incidente no puede estar vacio

---

## Dependencias

### Prerequisitos
- [x] E003-HU-001: Crear fecha (tabla fechas existe)
- [x] E003-HU-002: Inscribirse a fecha (inscripciones existen)
- [x] E003-HU-004: Cerrar inscripciones (estado 'cerrada' existe)
- [x] E003-HU-005: Asignar equipos (equipos asignados existe)
- [x] E003-HU-009: Listado fechas por rol (pestana Historial existe pero vacia)

### Impacta
- E003-HU-009: La pestana "Historial" comenzara a mostrar fechas
- Historial de jugadores: Podran ver sus participaciones pasadas
- Posible futuro: Estadisticas de jugadores (partidos jugados, etc.)

---

## Casos de Prueba Sugeridos

### Flujo Principal
1. Admin finaliza fecha en estado 'en_juego' - Exito
2. Admin finaliza fecha en estado 'cerrada' - Exito
3. Admin finaliza con comentarios - Comentarios guardados
4. Admin finaliza con incidente - Incidente registrado correctamente
5. Jugador inscrito ve fecha en historial - Aparece correctamente

### Validaciones
1. Jugador intenta finalizar - Error sin_permisos
2. Admin intenta finalizar fecha 'abierta' - Error estado_invalido
3. Admin intenta finalizar fecha ya 'finalizada' - Error estado_invalido
4. Admin intenta finalizar fecha 'cancelada' - Error estado_invalido
5. Admin marca incidente sin descripcion - Error descripcion_incidente_requerida

### Edge Cases
1. Fecha sin inscritos se finaliza - Funciona pero historial vacio
2. Jugador que cancelo inscripcion NO ve fecha en historial
3. Fecha finalizada no puede ser reabierta ni editada
4. Admin ve comentarios e incidentes en detalle de fecha finalizada

---

**Creado**: 2026-01-29
**Autor**: Business Analyst

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-29

### Nuevos Campos en Tabla fechas

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `finalizado_por` | UUID (FK usuarios) | ID del admin que finalizo la fecha |
| `finalizado_at` | TIMESTAMPTZ | Timestamp de finalizacion (UTC) |
| `comentarios_finalizacion` | TEXT | Observaciones opcionales del admin |
| `hubo_incidente` | BOOLEAN DEFAULT FALSE | Flag que indica si hubo incidente |
| `descripcion_incidente` | TEXT | Descripcion del incidente (obligatoria si hubo_incidente=true) |

### Funcion RPC Implementada

**`finalizar_fecha(p_fecha_id UUID, p_comentarios TEXT, p_hubo_incidente BOOLEAN, p_descripcion_incidente TEXT) -> JSON`**

- **Descripcion**: Finaliza una fecha de pichanga, marcandola como completada y registrando observaciones/incidentes opcionales
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007
- **Parametros**:
  - `p_fecha_id`: UUID (obligatorio) - ID de la fecha a finalizar
  - `p_comentarios`: TEXT (opcional, default null) - Observaciones del admin
  - `p_hubo_incidente`: BOOLEAN (opcional, default false) - Flag de incidente
  - `p_descripcion_incidente`: TEXT (requerido si p_hubo_incidente=true) - Descripcion del incidente

**Response Success**:
```json
{
  "success": true,
  "data": {
    "fecha_id": "uuid",
    "fecha_formato": "DD/MM/YYYY HH24:MI",
    "lugar": "string",
    "estado_anterior": "en_juego",
    "estado_nuevo": "finalizada",
    "total_participantes": 12,
    "comentarios": "string o null",
    "hubo_incidente": false,
    "descripcion_incidente": "string o null",
    "finalizado_por": "uuid",
    "finalizado_por_nombre": "string",
    "finalizado_at": "timestamp",
    "finalizado_at_formato": "DD/MM/YYYY HH24:MI"
  },
  "message": "Pichanga finalizada exitosamente. Ahora aparece en el historial de los 12 participantes."
}
```

**Response Error - Hints**:
| Hint | Descripcion |
|------|-------------|
| `no_autenticado` | Usuario no ha iniciado sesion |
| `fecha_id_requerido` | Falta parametro fecha_id |
| `usuario_no_encontrado` | Usuario no existe en tabla usuarios |
| `sin_permisos` | Usuario no es admin aprobado |
| `fecha_no_encontrada` | Fecha no existe |
| `estado_invalido` | Fecha no esta en estado 'en_juego' o 'cerrada' |
| `descripcion_incidente_requerida` | Se marco incidente pero falta descripcion |

### Script SQL
- `supabase/sql-cloud/2026-01-29_E003-HU-010_finalizar_fecha.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001/CA-002**: Funcion permite finalizar desde estados 'en_juego' y 'cerrada'
- [x] **CA-003**: Response incluye resumen completo de la fecha
- [x] **CA-004**: Campo p_comentarios es opcional y se almacena en comentarios_finalizacion
- [x] **CA-005**: Validacion: si p_hubo_incidente=true, p_descripcion_incidente es obligatoria
- [x] **CA-006**: Estado cambia a 'finalizada' con auditoria (quien/cuando)
- [x] **CA-007/CA-008**: La funcion listar_fechas_por_rol (HU-009) ya filtra por estado='finalizada' en seccion 'historial'
- [x] **CA-009**: Validacion impide finalizar fecha ya finalizada (estado terminal)
- [x] **CA-010**: Indicador visual manejado por HU-009

### Reglas de Negocio Implementadas
- [x] **RN-001**: Validacion de admin aprobado con hint `sin_permisos`
- [x] **RN-002**: Solo permite estados 'en_juego' o 'cerrada' con hint `estado_invalido`
- [x] **RN-003**: Rechaza fecha ya finalizada con mensaje especifico
- [x] **RN-004**: Registra finalizado_por y finalizado_at automaticamente
- [x] **RN-005**: Valida descripcion obligatoria si hubo_incidente=true
- [x] **RN-006**: Cuenta solo inscripciones con estado='inscrito' como participantes
- [x] **RN-007**: Solo actualiza estado y campos de finalizacion, preserva demas datos

### Notificaciones
- Se notifica a todos los participantes (inscripciones activas) cuando la fecha es finalizada
- Tipo: 'general'
- Titulo: 'Pichanga finalizada'
- Mensaje incluye fecha, lugar e invitacion a ver historial

---
