# E003-HU-002 - Inscribirse a Fecha

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟢 Refinado (REF)
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
