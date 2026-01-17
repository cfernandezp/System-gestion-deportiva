# E003-HU-001 - Crear Fecha

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🔵 En Desarrollo (DEV)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** crear una nueva jornada de pichanga
**Para** que los jugadores puedan inscribirse

## Descripcion
Permite al admin crear una fecha de pichanga definiendo dia, hora, duracion y lugar. El formato de juego y costo se determinan automaticamente segun la duracion seleccionada.

## Criterios de Aceptacion (CA)

### CA-001: Acceso exclusivo admin
- **Dado** que soy administrador aprobado
- **Cuando** accedo al menu de gestion
- **Entonces** veo la opcion "Crear Fecha" disponible
- **Y** si no soy admin, no veo esta opcion

### CA-002: Formulario de creacion
- **Dado** que selecciono "Crear Fecha"
- **Cuando** se abre el formulario
- **Entonces** veo los campos: fecha, hora inicio, duracion, lugar
- **Y** duracion tiene opciones: 1 hora, 2 horas

### CA-003: Formato automatico segun duracion
- **Dado** que selecciono la duracion
- **Cuando** elijo 1 hora
- **Entonces** el sistema muestra: "2 equipos - S/8.00 por jugador"
- **Cuando** elijo 2 horas
- **Entonces** el sistema muestra: "3 equipos con rotacion - S/10.00 por jugador"

### CA-004: Validacion de fecha futura
- **Dado** que ingreso una fecha y hora
- **Cuando** la fecha/hora es anterior al momento actual
- **Entonces** veo error "La fecha debe ser futura"
- **Y** no puedo crear la fecha

### CA-005: Lugar de la cancha
- **Dado** que ingreso el lugar
- **Cuando** completo el campo
- **Entonces** acepta texto libre (nombre de cancha, direccion)
- **Y** el campo es obligatorio

### CA-006: Confirmacion de creacion
- **Dado** que complete todos los datos correctamente
- **Cuando** presiono "Crear Fecha"
- **Entonces** la fecha se crea con estado "abierta"
- **Y** veo mensaje de confirmacion con resumen

### CA-007: Notificacion a jugadores
- **Dado** que se crea la fecha exitosamente
- **Cuando** se confirma la creacion
- **Entonces** todos los jugadores aprobados reciben notificacion
- **Y** la notificacion incluye: fecha, hora, lugar, costo

---

## Reglas de Negocio (RN)

### RN-001: Permisos de Creacion
**Contexto**: Solo administradores pueden crear fechas de pichanga.
**Restriccion**: Usuarios con rol "jugador" no tienen acceso a esta funcionalidad.
**Validacion**: Verificar rol = 'admin' y estado = 'aprobado' antes de permitir acceso.
**Regla calculo**: N/A.
**Caso especial**: Si el unico admin pierde acceso, se debe restaurar manualmente en BD.

### RN-002: Formato segun Duracion
**Contexto**: El formato de juego depende de la duracion alquilada.
**Restriccion**: No se puede elegir formato independiente de la duracion.
**Validacion**: Sistema asigna automaticamente el formato.
**Regla calculo**:
- 1 hora = 2 equipos (partido continuo)
- 2 horas = 3 equipos (rotacion: ganador se queda, perdedor descansa)
**Caso especial**: No se permiten duraciones diferentes a 1 o 2 horas.

### RN-003: Costo por Duracion
**Contexto**: El costo por jugador esta predefinido segun duracion.
**Restriccion**: El admin no puede modificar el costo manualmente.
**Validacion**: Sistema asigna costo automaticamente.
**Regla calculo**:
- 1 hora = S/8.00 por jugador
- 2 horas = S/10.00 por jugador
**Caso especial**: Si hay promociones o cambios de precio, se debe actualizar en configuracion del sistema.

### RN-004: Fecha Futura Obligatoria
**Contexto**: Solo se pueden crear fechas para eventos futuros.
**Restriccion**: La fecha y hora deben ser posteriores al momento de creacion.
**Validacion**: fecha_hora_inicio > NOW().
**Regla calculo**: N/A.
**Caso especial**: Se recomienda minimo 24 horas de anticipacion, pero no es obligatorio.

### RN-005: Unicidad de Fecha
**Contexto**: Evitar fechas duplicadas o superpuestas.
**Restriccion**: No pueden existir dos fechas en el mismo dia y hora.
**Validacion**: Verificar que no exista otra fecha activa (no cancelada) en la misma fecha y hora.
**Regla calculo**: N/A.
**Caso especial**: Si hay cancha con horario diferente el mismo dia, se permite (ej: 8am y 10am).

### RN-006: Estado Inicial
**Contexto**: Toda fecha nueva inicia con estado que permite inscripciones.
**Restriccion**: El estado inicial siempre es "abierta".
**Validacion**: Sistema asigna estado = 'abierta' automaticamente.
**Regla calculo**: N/A.
**Caso especial**: Estados posibles del ciclo de vida: abierta -> cerrada -> en_juego -> finalizada. Alternativo: abierta -> cancelada.

### RN-007: Numero de Equipos
**Contexto**: La cantidad de equipos determina como se organizan los partidos.
**Restriccion**: Esta vinculado directamente a la duracion.
**Validacion**: Sistema calcula automaticamente.
**Regla calculo**:
- 2 equipos: Juegan todo el tiempo uno contra otro
- 3 equipos: Rotacion cada partido (ganador continua, perdedor sale, entra tercero)
**Caso especial**: Con 3 equipos, si un equipo gana 2 partidos consecutivos, descansa obligatoriamente.

---

## Notas Tecnicas
- Tabla: `fechas` con campos: id, fecha_hora_inicio, duracion_horas, lugar, num_equipos, costo_por_jugador, estado, created_by, created_at
- Enum estado_fecha: 'abierta', 'cerrada', 'en_juego', 'finalizada', 'cancelada'
- Trigger para notificaciones push al crear fecha
- Zona horaria: America/Lima (UTC-5)

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-16

### Objetos de Base de Datos Creados

#### Enum `estado_fecha`
Estados del ciclo de vida de una fecha de pichanga:
- `abierta` - Inscripciones abiertas
- `cerrada` - Inscripciones cerradas, esperando inicio
- `en_juego` - Jornada en progreso
- `finalizada` - Jornada completada
- `cancelada` - Jornada cancelada

#### Tabla `fechas`
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id` | UUID (PK) | Identificador unico |
| `fecha_hora_inicio` | TIMESTAMPTZ | Fecha y hora de inicio (UTC) |
| `duracion_horas` | INTEGER | 1 o 2 horas |
| `lugar` | TEXT | Nombre de cancha o direccion |
| `num_equipos` | INTEGER | 2 o 3 (calculado automatico) |
| `costo_por_jugador` | DECIMAL(10,2) | S/8.00 o S/10.00 (calculado automatico) |
| `estado` | estado_fecha | Estado actual de la fecha |
| `created_by` | UUID (FK) | Admin que creo la fecha |
| `created_at` | TIMESTAMPTZ | Fecha de creacion |
| `updated_at` | TIMESTAMPTZ | Ultima actualizacion |

**Indices**:
- `idx_fechas_fecha_hora_inicio` - Busqueda por fecha
- `idx_fechas_estado` - Filtro por estado
- `idx_fechas_created_by` - Fechas por admin
- `idx_fechas_unico_activo` - Unicidad de fechas no canceladas

### Funcion RPC Implementada

**`crear_fecha(p_fecha_hora_inicio TIMESTAMPTZ, p_duracion_horas INTEGER, p_lugar TEXT) -> JSON`**

- **Descripcion**: Crea una nueva fecha de pichanga con calculos automaticos
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007
- **Parametros**:
  - `p_fecha_hora_inicio`: TIMESTAMPTZ - Fecha y hora de inicio (UTC)
  - `p_duracion_horas`: INTEGER - Duracion en horas (1 o 2)
  - `p_lugar`: TEXT - Nombre de cancha o direccion (min 3 caracteres)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "fecha_id": "uuid",
      "fecha_hora_inicio": "2026-01-20T20:00:00Z",
      "fecha_hora_local": "2026-01-20T15:00:00-05:00",
      "fecha_formato": "20/01/2026 15:00",
      "duracion_horas": 2,
      "lugar": "Cancha Los Olivos",
      "num_equipos": 3,
      "costo_por_jugador": 10.00,
      "costo_formato": "S/ 10.00",
      "estado": "abierta",
      "formato_juego": "3 equipos con rotacion",
      "created_by": "uuid",
      "created_by_nombre": "Admin Name"
    },
    "message": "Fecha de pichanga creada exitosamente. Se ha notificado a los jugadores."
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `usuario_no_encontrado` -> Usuario no existe en sistema
  - `sin_permisos` -> Usuario no es admin aprobado
  - `fecha_requerida` -> Fecha/hora no proporcionada
  - `duracion_requerida` -> Duracion no proporcionada
  - `duracion_invalida` -> Duracion no es 1 o 2
  - `lugar_invalido` -> Lugar vacio o muy corto
  - `fecha_pasada` -> Fecha/hora no es futura
  - `fecha_duplicada` -> Ya existe fecha en ese horario

### Politicas RLS

| Operacion | Politica | Condicion |
|-----------|----------|-----------|
| SELECT | Usuarios autenticados pueden ver fechas | authenticated = true |
| INSERT | Admins pueden insertar fechas | rol = 'admin' AND estado = 'aprobado' |
| UPDATE | Admins pueden actualizar fechas | rol = 'admin' AND estado = 'aprobado' |
| DELETE | Admins pueden eliminar fechas | rol = 'admin' AND estado = 'aprobado' |

### Script SQL
- `supabase/sql-cloud/2026-01-16_E003-HU-001_crear_fecha.sql`

### Criterios de Aceptacion Backend

| CA | Estado | Implementacion |
|----|--------|----------------|
| CA-001 | Completado | Validacion rol='admin' AND estado='aprobado' en crear_fecha() |
| CA-002 | Completado | Parametros p_fecha_hora_inicio, p_duracion_horas, p_lugar |
| CA-003 | Completado | Calculo automatico num_equipos y costo_por_jugador segun duracion |
| CA-004 | Completado | Validacion p_fecha_hora_inicio > NOW() |
| CA-005 | Completado | Campo lugar TEXT NOT NULL con CHECK min 3 chars |
| CA-006 | Completado | Estado inicial 'abierta' y response con resumen completo |
| CA-007 | Completado | Notificacion a usuarios aprobados al crear fecha |

### Reglas de Negocio Backend

| RN | Estado | Implementacion |
|----|--------|----------------|
| RN-001 | Completado | Validacion admin aprobado antes de insertar |
| RN-002 | Completado | 1h=2 equipos, 2h=3 equipos (calculo automatico) |
| RN-003 | Completado | 1h=S/8.00, 2h=S/10.00 (calculo automatico) |
| RN-004 | Completado | Validacion fecha_hora_inicio > NOW() |
| RN-005 | Completado | Indice unico + validacion duplicados (excluye canceladas) |
| RN-006 | Completado | DEFAULT 'abierta' en tabla y funcion |
| RN-007 | Completado | num_equipos calculado segun duracion |

---
