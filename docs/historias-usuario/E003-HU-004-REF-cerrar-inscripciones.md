# E003-HU-004 - Cerrar Inscripciones

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟢 Refinado (REF)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** cerrar las inscripciones de una fecha
**Para** proceder a armar los equipos con los jugadores confirmados

## Descripcion
Permite al admin cerrar las inscripciones cuando ya no se aceptan mas jugadores, pasando al siguiente paso del flujo.

## Criterios de Aceptacion (CA)

### CA-001: Boton cerrar inscripciones
- **Dado** que soy admin y hay una fecha con estado "abierta"
- **Cuando** veo la fecha
- **Entonces** veo opcion "Cerrar inscripciones"

### CA-002: Confirmacion con resumen
- **Dado** que presiono cerrar inscripciones
- **Cuando** aparece el dialogo de confirmacion
- **Entonces** veo resumen: cantidad de inscritos, formato (2 o 3 equipos)
- **Y** veo botones "Confirmar" y "Cancelar"

### CA-003: Validacion de minimo
- **Dado** que quiero cerrar inscripciones
- **Cuando** hay menos de 6 jugadores inscritos
- **Entonces** veo advertencia "Solo hay [N] jugadores. Se recomiendan minimo 6"
- **Y** puedo continuar si lo deseo (no es bloqueante)

### CA-004: Estado actualizado
- **Dado** que confirmo el cierre
- **Cuando** se procesa
- **Entonces** el estado cambia a "cerrada"
- **Y** todos los usuarios ven "Inscripciones cerradas"

### CA-005: Bloqueo de nuevas inscripciones
- **Dado** que las inscripciones estan cerradas
- **Cuando** un jugador intenta inscribirse
- **Entonces** no puede y ve mensaje "Inscripciones cerradas"

### CA-006: Reabrir inscripciones
- **Dado** que las inscripciones estan cerradas
- **Cuando** necesito agregar mas jugadores
- **Entonces** veo opcion "Reabrir inscripciones" (solo admin)
- **Y** al reabrir, el estado vuelve a "abierta"

### CA-007: Notificacion de cierre
- **Dado** que se cierran las inscripciones
- **Cuando** se confirma
- **Entonces** los jugadores inscritos reciben notificacion
- **Y** el mensaje indica "Inscripciones cerradas. Pronto se asignaran equipos"

---

## Reglas de Negocio (RN)

### RN-001: Permiso Exclusivo Admin
**Contexto**: Solo administradores pueden cerrar inscripciones.
**Restriccion**: Jugadores no tienen esta opcion.
**Validacion**: rol = 'admin' AND estado = 'aprobado'.
**Regla calculo**: N/A.
**Caso especial**: N/A.

### RN-002: Estado Valido para Cierre
**Contexto**: Solo se pueden cerrar fechas abiertas.
**Restriccion**: No se puede cerrar una fecha que ya esta cerrada, en juego, finalizada o cancelada.
**Validacion**: fecha.estado = 'abierta'.
**Regla calculo**: N/A.
**Caso especial**: Si por error se intenta cerrar fecha no abierta, mostrar mensaje de error.

### RN-003: Minimo Recomendado de Jugadores
**Contexto**: Para jugar se necesita un minimo de jugadores.
**Restriccion**: Advertencia si hay menos de 6 jugadores (3 por equipo minimo).
**Validacion**: COUNT(inscripciones activas) >= 6.
**Regla calculo**: Minimo absoluto = 6 jugadores (3 por equipo). Recomendado = 10-12 para 2 equipos, 12-15 para 3 equipos.
**Caso especial**: Admin puede cerrar con menos jugadores bajo su responsabilidad.

### RN-004: Transicion de Estado
**Contexto**: Cerrar inscripciones cambia el estado de la fecha.
**Restriccion**: El nuevo estado es fijo: "cerrada".
**Validacion**: UPDATE fecha SET estado = 'cerrada'.
**Regla calculo**: N/A.
**Caso especial**: Se registra quien cerro y cuando para auditoria.

### RN-005: Reapertura de Inscripciones
**Contexto**: Se puede reabrir si aun no se ha avanzado al siguiente paso.
**Restriccion**: Solo se puede reabrir si estado = 'cerrada' (no en_juego ni finalizada).
**Validacion**: fecha.estado = 'cerrada'.
**Regla calculo**: Al reabrir: estado = 'abierta', se eliminan asignaciones de equipo si existen.
**Caso especial**: Las inscripciones existentes se mantienen. Las deudas permanecen activas.

### RN-006: Efecto en Inscripciones Existentes
**Contexto**: Cerrar no afecta a los ya inscritos.
**Restriccion**: No se eliminan ni modifican las inscripciones activas.
**Validacion**: Solo cambia fecha.estado, no inscripciones.
**Regla calculo**: N/A.
**Caso especial**: Jugadores inscritos mantienen su deuda pendiente.

---

## Notas Tecnicas
- UPDATE fechas SET estado = 'cerrada', cerrado_por = auth.uid(), cerrado_at = NOW()
- Trigger para enviar notificaciones a inscritos
- Validar estado previo antes de UPDATE
- Log de auditoria: quien cerro y cuando

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16
