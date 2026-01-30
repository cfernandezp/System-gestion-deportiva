# E004-HU-001 - Iniciar Partido

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🔵 En Desarrollo (DEV)
- **Prioridad**: Alta
- **Dependencia**: E003 (Gestion de Fechas) - La fecha debe estar en estado `en_juego`

## Historia de Usuario
**Como** administrador
**Quiero** iniciar un partido con temporizador
**Para** controlar el tiempo de juego

## Descripcion
Permite al admin iniciar un partido seleccionando los equipos que juegan y activando el temporizador. Un partido es un encuentro entre 2 equipos dentro de una fecha de pichanga.

## Relacion Fecha-Partido
- Una **Fecha** (E003) puede tener multiples **Partidos** (E004)
- Los partidos solo existen cuando la fecha esta en estado `en_juego`
- Ejemplo: Fecha de 2 horas con 3 equipos = multiples partidos de 10 min con rotacion

## Criterios de Aceptacion (CA)

### CA-001: Seleccionar equipos
- **Dado** que los equipos estan asignados en la fecha
- **Cuando** inicio un partido
- **Entonces** selecciono cuales 2 equipos se enfrentan (ej: Naranja vs Verde)

### CA-002: Duracion segun formato
- **Dado** que inicio un partido
- **Cuando** la fecha es de 1 hora (2 equipos)
- **Entonces** el partido dura 20 minutos
- **Cuando** la fecha es de 2 horas (3 equipos)
- **Entonces** el partido dura 10 minutos

### CA-003: Iniciar temporizador
- **Dado** que seleccione los equipos
- **Cuando** presiono "Iniciar partido"
- **Entonces** el temporizador comienza la cuenta regresiva

### CA-004: Partido en curso
- **Dado** que el partido inicio
- **Cuando** cualquier usuario ve la fecha
- **Entonces** ve indicador de "Partido en curso" con equipos y tiempo restante

### CA-005: Pausar partido
- **Dado** que el partido esta en curso
- **Cuando** necesito pausar (lesion, interrupcion)
- **Entonces** puedo pausar el temporizador y reanudarlo

### CA-006: Un partido a la vez
- **Dado** que hay un partido en curso en la fecha
- **Cuando** intento iniciar otro partido
- **Entonces** el sistema no lo permite hasta finalizar el actual

## 📐 Reglas de Negocio (RN)

### RN-001: Permiso para iniciar partido
**Contexto**: Al intentar iniciar un partido
**Restriccion**: Solo administradores aprobados pueden iniciar partidos
**Validacion**: El usuario debe tener rol "admin" y estado "aprobado"

### RN-002: Estado de fecha requerido
**Contexto**: Al crear un partido
**Restriccion**: No se pueden iniciar partidos en fechas que no estan en juego
**Validacion**: La fecha debe estar en estado `en_juego`
**Caso especial**: Si la fecha esta en "cerrada", primero debe cambiarse a "en_juego"

### RN-003: Equipos asignados obligatorios
**Contexto**: Al seleccionar equipos para el partido
**Restriccion**: Solo se pueden seleccionar equipos con jugadores asignados
**Validacion**: Ambos equipos deben tener al menos 1 jugador asignado
**Caso especial**: Si un equipo no tiene jugadores, no aparece como opcion

### RN-004: Duracion por formato de fecha
**Contexto**: Al determinar la duracion del partido
**Restriccion**: La duracion depende de la configuracion de la fecha
**Regla calculo**:
  - Fecha 1 hora (2 equipos): 20 minutos por partido
  - Fecha 2 horas (3 equipos): 10 minutos por partido
**Caso especial**: Admin puede ajustar duracion manualmente si es necesario

### RN-005: Un partido activo por fecha
**Contexto**: Al iniciar un nuevo partido
**Restriccion**: No puede haber mas de un partido en curso simultaneamente en la misma fecha
**Validacion**: Verificar que no exista otro partido con estado "en_curso" para esa fecha
**Caso especial**: Se debe finalizar el partido actual antes de iniciar otro

### RN-006: Equipos diferentes obligatorio
**Contexto**: Al seleccionar los 2 equipos
**Restriccion**: Un equipo no puede jugar contra si mismo
**Validacion**: Equipo local != Equipo visitante

### RN-007: Pausa con motivo
**Contexto**: Al pausar un partido
**Restriccion**: La pausa debe registrar el momento y es temporal
**Validacion**: El tiempo pausado se registra para estadisticas
**Caso especial**: Si se pausa mas de 10 minutos, alertar al admin

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-29

### Estructura de Datos

**ENUM `estado_partido`**
- `pendiente` - Partido creado pero no iniciado
- `en_curso` - Partido en progreso con temporizador activo
- `pausado` - Partido pausado temporalmente
- `finalizado` - Partido terminado normalmente
- `cancelado` - Partido cancelado

**TABLA `partidos`**
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | UUID PK | Identificador unico |
| fecha_id | UUID FK | Referencia a fechas (CASCADE) |
| equipo_local | color_equipo | Color del equipo local |
| equipo_visitante | color_equipo | Color del equipo visitante |
| duracion_minutos | INTEGER | 10 o 20 segun formato |
| estado | estado_partido | Estado actual del partido |
| hora_inicio | TIMESTAMPTZ | Cuando inicio el partido |
| hora_fin_estimada | TIMESTAMPTZ | hora_inicio + duracion (se ajusta con pausas) |
| tiempo_pausado_segundos | INTEGER | Total segundos acumulados en pausas |
| pausado_at | TIMESTAMPTZ | Momento de ultima pausa (NULL si no pausado) |
| created_by | UUID FK | Admin que inicio el partido |
| created_at | TIMESTAMPTZ | Timestamp de creacion |
| updated_at | TIMESTAMPTZ | Timestamp de actualizacion |

**Constraints**:
- CHECK: `equipo_local != equipo_visitante` (RN-006)
- CHECK: `duracion_minutos IN (10, 20)`

### Funciones RPC Implementadas

**`iniciar_partido(p_fecha_id UUID, p_equipo_local TEXT, p_equipo_visitante TEXT) -> JSON`**
- **Descripcion**: Inicia un nuevo partido seleccionando 2 equipos
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006
- **Parametros**:
  - `p_fecha_id`: UUID - ID de la fecha de pichanga
  - `p_equipo_local`: TEXT - Color del equipo local (naranja, verde, azul)
  - `p_equipo_visitante`: TEXT - Color del equipo visitante
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "partido_id": "uuid",
      "fecha_id": "uuid",
      "equipo_local": {"color": "naranja", "jugadores_count": 5, "jugadores": [...]},
      "equipo_visitante": {"color": "verde", "jugadores_count": 5, "jugadores": [...]},
      "duracion_minutos": 20,
      "estado": "en_curso",
      "hora_inicio_formato": "15:30:00",
      "hora_fin_estimada_formato": "15:50:00",
      "tiempo_restante_segundos": 1200
    },
    "message": "Partido iniciado: NARANJA vs VERDE - 20 minutos"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` - Usuario no ha iniciado sesion
  - `sin_permisos` - Usuario no es admin aprobado
  - `fecha_no_encontrada` - La fecha no existe
  - `fecha_no_en_juego` - La fecha no esta en estado en_juego
  - `partido_activo_existe` - Ya hay un partido en_curso o pausado
  - `equipo_local_sin_jugadores` - El equipo local no tiene jugadores asignados
  - `equipo_visitante_sin_jugadores` - El equipo visitante no tiene jugadores
  - `equipos_iguales` - Se selecciono el mismo equipo como local y visitante

**`pausar_partido(p_partido_id UUID) -> JSON`**
- **Descripcion**: Pausa un partido en curso
- **Reglas de Negocio**: RN-001, RN-007
- **Parametros**:
  - `p_partido_id`: UUID - ID del partido a pausar
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "partido_id": "uuid",
      "estado": "pausado",
      "pausado_at_formato": "15:35:00",
      "tiempo_restante_segundos": 900,
      "pausado_por_nombre": "Admin"
    },
    "message": "Partido pausado: NARANJA vs VERDE. Tiempo restante: 15 minutos"
  }
  ```
- **Response Error - Hints**:
  - `partido_no_encontrado` - El partido no existe
  - `partido_no_en_curso` - El partido no esta en estado en_curso

**`reanudar_partido(p_partido_id UUID) -> JSON`**
- **Descripcion**: Reanuda un partido pausado
- **Reglas de Negocio**: RN-001, RN-007
- **Parametros**:
  - `p_partido_id`: UUID - ID del partido a reanudar
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "partido_id": "uuid",
      "estado": "en_curso",
      "hora_fin_estimada_formato": "15:55:00",
      "tiempo_restante_segundos": 900,
      "tiempo_pausa_actual_segundos": 120,
      "tiempo_pausado_total_segundos": 120
    },
    "message": "Partido reanudado: NARANJA vs VERDE. Tiempo restante: 15 minutos. Estuvo pausado 2 minutos."
  }
  ```
- **Response Error - Hints**:
  - `partido_no_encontrado` - El partido no existe
  - `partido_no_pausado` - El partido no esta en estado pausado

**`obtener_partido_activo(p_fecha_id UUID) -> JSON`**
- **Descripcion**: Obtiene el partido activo (en_curso o pausado) de una fecha con tiempo restante calculado dinamicamente
- **Criterios**: CA-004
- **Parametros**:
  - `p_fecha_id`: UUID - ID de la fecha
- **Response Success (con partido activo)**:
  ```json
  {
    "success": true,
    "data": {
      "partido_activo": true,
      "partido": {
        "id": "uuid",
        "equipo_local": {"color": "naranja", "jugadores": [...]},
        "equipo_visitante": {"color": "verde", "jugadores": [...]},
        "estado": "en_curso",
        "tiempo_restante_segundos": 600,
        "tiempo_restante_formato": "10:00",
        "tiempo_transcurrido_formato": "10:00",
        "tiempo_terminado": false
      },
      "puede_pausar": true,
      "puede_reanudar": false
    },
    "message": "Partido en curso: NARANJA vs VERDE"
  }
  ```
- **Response Success (sin partido activo)**:
  ```json
  {
    "success": true,
    "data": {
      "partido_activo": false,
      "partido": null,
      "fecha": {...},
      "puede_iniciar_partido": true
    },
    "message": "No hay partido activo en esta fecha"
  }
  ```

### Seguridad

**RLS Policies para tabla `partidos`**:
- SELECT: Todos los usuarios autenticados pueden ver partidos
- INSERT: Solo admin aprobado
- UPDATE: Solo admin aprobado
- DELETE: Solo admin aprobado

**Realtime**: Habilitado para actualizaciones en tiempo real

### Script SQL
- `supabase/sql-cloud/2026-01-29_E004-HU-001_iniciar_partido.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Seleccionar equipos - Implementado en `iniciar_partido()`
- [x] **CA-002**: Duracion segun formato - Calculado automaticamente (10 o 20 min)
- [x] **CA-003**: Iniciar temporizador - Registra hora_inicio y hora_fin_estimada
- [x] **CA-004**: Partido en curso - Implementado en `obtener_partido_activo()`
- [x] **CA-005**: Pausar partido - Implementado en `pausar_partido()` y `reanudar_partido()`
- [x] **CA-006**: Un partido a la vez - Validado en `iniciar_partido()`

### Reglas de Negocio Backend
- [x] **RN-001**: Solo admin aprobado - Validado en todas las funciones
- [x] **RN-002**: Estado fecha en_juego - Validado en `iniciar_partido()`
- [x] **RN-003**: Equipos con jugadores - Validado contando asignaciones
- [x] **RN-004**: Duracion automatica - 20 min (2 equipos) / 10 min (3 equipos)
- [x] **RN-005**: Un partido activo - Validado buscando estado IN ('en_curso', 'pausado')
- [x] **RN-006**: Equipos diferentes - CHECK constraint + validacion en funcion
- [x] **RN-007**: Registro de pausas - tiempo_pausado_segundos y pausado_at
