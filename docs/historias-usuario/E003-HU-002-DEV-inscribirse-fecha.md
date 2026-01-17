# E003-HU-002 - Inscribirse a Fecha

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🔵 En Desarrollo (DEV)
- **Prioridad**: Alta

## Historia de Usuario
**Como** jugador aprobado
**Quiero** anotarme para la proxima pichanga
**Para** confirmar mi asistencia y reservar mi lugar

## Descripcion
Permite a los jugadores inscribirse a una fecha abierta, confirmando su asistencia y compromiso de pago.

## Criterios de Aceptacion (CA)

### CA-001: Ver fecha disponible
- **Dado** que hay una fecha con estado "abierta"
- **Cuando** accedo a "Proxima Pichanga" o calendario
- **Entonces** veo los detalles: fecha, hora, lugar, duracion, costo, inscritos actuales

### CA-002: Boton de inscripcion visible
- **Dado** que veo una fecha abierta
- **Cuando** no estoy inscrito
- **Entonces** veo boton "Anotarme" habilitado
- **Y** veo el costo que debo pagar (S/8 o S/10)

### CA-003: Confirmar inscripcion
- **Dado** que presiono "Anotarme"
- **Cuando** confirmo la accion
- **Entonces** quedo inscrito con estado "inscrito"
- **Y** veo mensaje "Te anotaste para la pichanga del [fecha]"
- **Y** se actualiza el contador de inscritos

### CA-004: Ya inscrito - estado visual
- **Dado** que ya estoy inscrito
- **Cuando** veo la fecha
- **Entonces** veo indicador "Ya estas anotado" con icono de check
- **Y** el boton cambia a "Cancelar inscripcion"

### CA-005: Inscripciones cerradas
- **Dado** que la fecha tiene estado "cerrada" o posterior
- **Cuando** veo la fecha sin estar inscrito
- **Entonces** veo mensaje "Inscripciones cerradas"
- **Y** no hay boton para anotarme

### CA-006: Contador de inscritos
- **Dado** que veo la fecha
- **Cuando** hay jugadores inscritos
- **Entonces** veo "[N] jugadores anotados"
- **Y** el numero se actualiza en tiempo real

### CA-007: Inscripcion genera deuda
- **Dado** que me inscribo exitosamente
- **Cuando** se confirma la inscripcion
- **Entonces** se registra una deuda pendiente por el costo de la fecha
- **Y** podre ver esta deuda en mi historial de pagos

---

## Reglas de Negocio (RN)

### RN-001: Estado de Usuario para Inscripcion
**Contexto**: Solo jugadores aprobados pueden inscribirse.
**Restriccion**: Usuarios pendientes, rechazados o suspendidos no pueden inscribirse.
**Validacion**: estado = 'aprobado' en tabla usuarios.
**Regla calculo**: N/A.
**Caso especial**: Admin tambien puede inscribirse (es un jugador mas).

### RN-002: Estado de Fecha para Inscripcion
**Contexto**: Solo se puede inscribir a fechas abiertas.
**Restriccion**: No se permite inscripcion si estado != 'abierta'.
**Validacion**: Verificar fecha.estado = 'abierta' antes de procesar.
**Regla calculo**: N/A.
**Caso especial**: Estados que bloquean inscripcion: cerrada, en_juego, finalizada, cancelada.

### RN-003: Inscripcion Unica por Fecha
**Contexto**: Un jugador solo puede inscribirse una vez a la misma fecha.
**Restriccion**: No se permiten inscripciones duplicadas.
**Validacion**: Verificar que no exista registro en inscripciones para (usuario_id, fecha_id).
**Regla calculo**: N/A.
**Caso especial**: Si cancelo y quiero volver a inscribirme (fecha abierta), se permite crear nuevo registro.

### RN-004: Generacion de Deuda al Inscribirse
**Contexto**: Al inscribirse se compromete a pagar el costo de la fecha.
**Restriccion**: Toda inscripcion genera una deuda automaticamente.
**Validacion**: Sistema crea registro en tabla pagos/deudas con estado 'pendiente'.
**Regla calculo**: monto_deuda = fecha.costo_por_jugador (S/8 o S/10 segun duracion).
**Caso especial**: Si cancela antes del cierre, la deuda se anula. Si cancela despues, la deuda permanece.

### RN-005: Limite de Inscripciones (Opcional)
**Contexto**: Se puede limitar el numero maximo de jugadores.
**Restriccion**: Si la fecha tiene limite, no se aceptan mas inscripciones al alcanzarlo.
**Validacion**: COUNT(inscripciones) < fecha.limite_jugadores (si existe).
**Regla calculo**: Tipicamente 15-18 jugadores maximo.
**Caso especial**: Por defecto no hay limite. Admin puede cerrar manualmente cuando considere suficiente.

### RN-006: Notificacion de Inscripcion
**Contexto**: El admin debe saber quien se inscribe.
**Restriccion**: N/A.
**Validacion**: Sistema genera notificacion al admin con cada inscripcion.
**Regla calculo**: N/A.
**Caso especial**: Notificaciones agrupadas si hay muchas inscripciones en poco tiempo.

---

## Notas Tecnicas
- Tabla: `inscripciones` con campos: id, fecha_id, usuario_id, estado, created_at
- Enum estado_inscripcion: 'inscrito', 'cancelado'
- Tabla: `pagos` se actualiza con deuda pendiente al inscribirse
- Indices: (fecha_id, usuario_id) UNIQUE para evitar duplicados

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-17

### Tablas Creadas

#### Tabla: `inscripciones`
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id` | UUID (PK) | Identificador unico |
| `fecha_id` | UUID (FK -> fechas) | Fecha a la que se inscribe |
| `usuario_id` | UUID (FK -> usuarios) | Usuario que se inscribe |
| `estado` | estado_inscripcion | 'inscrito', 'cancelado' |
| `created_at` | TIMESTAMPTZ | Fecha de inscripcion |
| `updated_at` | TIMESTAMPTZ | Ultima actualizacion |

**Indices**:
- UNIQUE INDEX en (fecha_id, usuario_id) WHERE estado = 'inscrito'

#### Tabla: `pagos`
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id` | UUID (PK) | Identificador unico |
| `inscripcion_id` | UUID (FK -> inscripciones) | Inscripcion asociada |
| `usuario_id` | UUID (FK -> usuarios) | Usuario deudor |
| `fecha_id` | UUID (FK -> fechas) | Fecha asociada |
| `monto` | DECIMAL(10,2) | Monto en soles |
| `estado` | estado_pago | 'pendiente', 'pagado', 'anulado' |
| `fecha_pago` | TIMESTAMPTZ | Cuando se pago |
| `registrado_por` | UUID (FK -> usuarios) | Admin que registro |
| `notas` | TEXT | Notas adicionales |
| `created_at` | TIMESTAMPTZ | Fecha de creacion |
| `updated_at` | TIMESTAMPTZ | Ultima actualizacion |

### Tipos ENUM Creados

- `estado_inscripcion`: 'inscrito', 'cancelado'
- `estado_pago`: 'pendiente', 'pagado', 'anulado'

### Funciones RPC Implementadas

#### `inscribirse_fecha(p_fecha_id UUID) -> JSON`
- **Descripcion**: Inscribe al usuario actual a una fecha de pichanga
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-006
- **Parametros**:
  - `p_fecha_id`: UUID - ID de la fecha a inscribirse
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "inscripcion_id": "uuid",
      "fecha_id": "uuid",
      "fecha_formato": "DD/MM/YYYY HH24:MI",
      "lugar": "Cancha X",
      "costo_por_jugador": 10.00,
      "costo_formato": "S/ 10.00",
      "pago_id": "uuid",
      "estado_inscripcion": "inscrito",
      "estado_pago": "pendiente",
      "total_inscritos": 5
    },
    "message": "Te anotaste para la pichanga del DD/MM/YYYY..."
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `fecha_id_requerido` -> No se proporciono ID de fecha
  - `usuario_no_encontrado` -> Usuario no existe en tabla usuarios
  - `usuario_no_aprobado` -> Usuario no tiene estado 'aprobado'
  - `fecha_no_encontrada` -> Fecha no existe
  - `fecha_no_abierta` -> Fecha no tiene estado 'abierta'
  - `ya_inscrito` -> Usuario ya esta inscrito a esta fecha

#### `cancelar_inscripcion(p_fecha_id UUID) -> JSON`
- **Descripcion**: Cancela la inscripcion del usuario a una fecha
- **Reglas de Negocio**: RN-004 (gestiona deuda segun estado de fecha)
- **Parametros**:
  - `p_fecha_id`: UUID - ID de la fecha a cancelar inscripcion
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "inscripcion_id": "uuid",
      "fecha_id": "uuid",
      "fecha_formato": "DD/MM/YYYY HH24:MI",
      "estado_inscripcion": "cancelado",
      "deuda_anulada": true
    },
    "message": "Has cancelado tu inscripcion. La deuda ha sido anulada."
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `usuario_no_encontrado` -> Usuario no existe
  - `fecha_no_encontrada` -> Fecha no existe
  - `no_inscrito` -> Usuario no esta inscrito a esta fecha

#### `obtener_fecha_detalle(p_fecha_id UUID) -> JSON`
- **Descripcion**: Obtiene detalles de una fecha con lista de inscritos
- **Criterios de Aceptacion**: CA-001, CA-002, CA-004, CA-005, CA-006
- **Parametros**:
  - `p_fecha_id`: UUID - ID de la fecha a consultar
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "fecha": {
        "id": "uuid",
        "fecha_hora_inicio": "timestamp",
        "fecha_formato": "DD/MM/YYYY",
        "hora_formato": "HH24:MI",
        "duracion_horas": 2,
        "lugar": "Cancha X",
        "num_equipos": 3,
        "costo_por_jugador": 10.00,
        "costo_formato": "S/ 10.00",
        "estado": "abierta",
        "formato_juego": "3 equipos con rotacion",
        "creador": {"id": "uuid", "nombre": "Admin"}
      },
      "inscripciones": {
        "total": 5,
        "lista": [
          {"usuario_id": "uuid", "nombre_completo": "Juan", "inscrito_formato": "DD/MM/YYYY HH24:MI"}
        ]
      },
      "usuario_actual": {
        "esta_inscrito": false,
        "inscripcion_id": null,
        "puede_inscribirse": true,
        "puede_cancelar": false
      }
    },
    "message": "Detalle de fecha obtenido exitosamente"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `fecha_no_encontrada` -> Fecha no existe

#### `listar_fechas_disponibles() -> JSON`
- **Descripcion**: Lista fechas con estado 'abierta' ordenadas por fecha_hora_inicio
- **Criterios de Aceptacion**: CA-001, CA-006
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "fechas": [
        {
          "id": "uuid",
          "fecha_formato": "DD/MM/YYYY",
          "hora_formato": "HH24:MI",
          "duracion_horas": 2,
          "lugar": "Cancha X",
          "costo_formato": "S/ 10.00",
          "estado": "abierta",
          "total_inscritos": 5,
          "usuario_inscrito": false
        }
      ],
      "total": 3
    },
    "message": "Lista de fechas disponibles obtenida exitosamente"
  }
  ```

### Script SQL
- `supabase/sql-cloud/2026-01-17_E003-HU-002_inscribirse_fecha.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Ver fecha disponible -> Implementado en `obtener_fecha_detalle` y `listar_fechas_disponibles`
- [x] **CA-002**: Boton de inscripcion visible -> `usuario_actual.puede_inscribirse` en respuesta
- [x] **CA-003**: Confirmar inscripcion -> Implementado en `inscribirse_fecha`
- [x] **CA-004**: Ya inscrito - estado visual -> `usuario_actual.esta_inscrito` en respuesta
- [x] **CA-005**: Inscripciones cerradas -> Validacion `fecha_no_abierta` en `inscribirse_fecha`
- [x] **CA-006**: Contador de inscritos -> `total_inscritos` en todas las respuestas
- [x] **CA-007**: Inscripcion genera deuda -> Tabla `pagos` con estado 'pendiente'

### Reglas de Negocio Backend
- [x] **RN-001**: Usuario aprobado -> Validacion `estado = 'aprobado'`
- [x] **RN-002**: Fecha abierta -> Validacion `fecha.estado = 'abierta'`
- [x] **RN-003**: Inscripcion unica -> UNIQUE INDEX + validacion previa
- [x] **RN-004**: Genera deuda -> INSERT en tabla `pagos`, anulacion segun estado
- [x] **RN-005**: Limite inscripciones -> Preparado (sin limite por defecto)
- [x] **RN-006**: Notificacion admin -> INSERT en tabla `notificaciones`

### RLS (Row Level Security)
- **inscripciones**: Usuarios ven sus inscripciones, admins ven todas, usuarios aprobados ven lista de inscritos
- **pagos**: Usuarios ven sus pagos, admins ven y actualizan todos
