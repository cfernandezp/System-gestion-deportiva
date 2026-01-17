# E003-HU-007 - Cancelar Inscripcion

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟢 Refinado (REF)
- **Prioridad**: Media

## Historia de Usuario
**Como** jugador inscrito
**Quiero** cancelar mi asistencia
**Para** avisar que ya no podre asistir a la pichanga

## Descripcion
Permite a un jugador retirar su inscripcion de una fecha, con diferentes reglas segun el estado de la fecha.

## Criterios de Aceptacion (CA)

### CA-001: Opcion de cancelar visible
- **Dado** que estoy inscrito a una fecha
- **Cuando** veo la fecha
- **Entonces** veo opcion "Cancelar inscripcion" o icono de X

### CA-002: Confirmacion de cancelacion
- **Dado** que presiono cancelar
- **Cuando** aparece dialogo de confirmacion
- **Entonces** veo mensaje "Estas seguro de cancelar tu inscripcion?"
- **Y** veo botones "Si, cancelar" y "No, mantenerme"

### CA-003: Cancelacion exitosa (fecha abierta)
- **Dado** que las inscripciones estan abiertas
- **Cuando** confirmo la cancelacion
- **Entonces** mi inscripcion se elimina
- **Y** veo mensaje "Inscripcion cancelada"
- **Y** mi deuda asociada se anula

### CA-004: Re-inscripcion permitida
- **Dado** que cancele mi inscripcion
- **Cuando** las inscripciones siguen abiertas
- **Entonces** puedo volver a inscribirme si cambio de opinion

### CA-005: Cancelar despues del cierre
- **Dado** que las inscripciones estan cerradas
- **Cuando** intento cancelar
- **Entonces** veo mensaje "Las inscripciones estan cerradas. Contacta al administrador"
- **Y** no puedo cancelar directamente

### CA-006: Cancelacion por admin
- **Dado** que soy admin
- **Cuando** un jugador no puede asistir y fecha esta cerrada
- **Entonces** puedo cancelar la inscripcion de ese jugador
- **Y** el jugador recibe notificacion de la cancelacion

### CA-007: Notificacion al admin
- **Dado** que cancelo mi inscripcion (fecha abierta)
- **Cuando** se procesa
- **Entonces** el admin recibe notificacion de mi baja
- **Y** ve mensaje "[Jugador] cancelo su inscripcion para [fecha]"

---

## Reglas de Negocio (RN)

### RN-001: Cancelacion Libre en Fecha Abierta
**Contexto**: Mientras inscripciones estan abiertas, jugador puede cancelar libremente.
**Restriccion**: Solo aplica si fecha.estado = 'abierta'.
**Validacion**: Verificar estado de fecha antes de procesar.
**Regla calculo**: N/A.
**Caso especial**: N/A.

### RN-002: Bloqueo de Cancelacion Post-Cierre
**Contexto**: Despues de cerrar inscripciones, no se permite cancelacion directa.
**Restriccion**: Si fecha.estado != 'abierta', jugador no puede cancelar solo.
**Validacion**: Deshabilitar boton/opcion si estado != 'abierta'.
**Regla calculo**: N/A.
**Caso especial**: Admin puede cancelar inscripcion de cualquier jugador en cualquier estado pre-partido.

### RN-003: Efecto en Deuda al Cancelar
**Contexto**: La cancelacion afecta la deuda generada al inscribirse.
**Restriccion**: Depende del momento de cancelacion.
**Validacion**: Actualizar tabla pagos segun reglas.
**Regla calculo**:
- Si fecha.estado = 'abierta': Deuda se anula (estado = 'anulado')
- Si fecha.estado = 'cerrada' o posterior: Deuda permanece (a criterio del admin)
**Caso especial**: Admin puede anular deuda manualmente si lo considera justo.

### RN-004: Efecto en Asignacion de Equipo
**Contexto**: Si ya hay equipos asignados, la cancelacion afecta el equipo.
**Restriccion**: Se debe eliminar la asignacion de equipo.
**Validacion**: DELETE asignacion_equipo WHERE usuario_id AND fecha_id.
**Regla calculo**: N/A.
**Caso especial**: Admin debe re-balancear equipos si queda desbalanceado.

### RN-005: Notificacion Bidireccional
**Contexto**: Tanto admin como jugador deben estar informados.
**Restriccion**: N/A.
**Validacion**: Crear notificaciones en ambos casos.
**Regla calculo**:
- Si jugador cancela: Notificar a admin
- Si admin cancela por jugador: Notificar al jugador
**Caso especial**: N/A.

### RN-006: Registro de Cancelacion
**Contexto**: Se debe mantener historial de cancelaciones.
**Restriccion**: No eliminar fisicamente, solo cambiar estado.
**Validacion**: UPDATE inscripcion SET estado = 'cancelado', cancelado_at = NOW().
**Regla calculo**: N/A.
**Caso especial**: Para estadisticas futuras de asistencia/cancelacion por jugador.

---

## Notas Tecnicas
- UPDATE inscripciones SET estado = 'cancelado', cancelado_at = NOW(), cancelado_por = auth.uid()
- Si admin cancela por jugador: cancelado_por = admin_id (diferente a usuario_id)
- Trigger para notificaciones
- Soft delete para mantener historial

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16
