# E005-HU-003: Ver Deudores

## INFORMACION
- **Codigo:** E005-HU-003
- **Epica:** E005 - Pagos
- **Titulo:** Ver Deudores
- **Story Points:** 5 pts
- **Estado:** Refinada
- **Prioridad:** Alta
- **Fecha:** 2026-02-21

## HISTORIA
**Como** administrador o co-administrador del grupo,
**Quiero** ver una lista consolidada de todos los jugadores con deudas pendientes,
**Para** hacer seguimiento y cobrar los montos adeudados acumulados de multiples fechas.

## CONTEXTO
A diferencia de HU-002 (que muestra pagos de UNA fecha), esta HU muestra una vista consolidada de TODOS los jugadores que deben dinero en el grupo, sumando deudas de todas las fechas.

### Criterios de Aceptacion

#### CA-001: Acceso a lista de deudores
- DADO que soy admin o co-admin del grupo
- CUANDO accedo a "Deudores" (desde home o menu)
- ENTONCES veo la lista de jugadores con pagos pendientes del grupo activo

#### CA-002: Informacion por deudor
- DADO que veo la lista de deudores
- CUANDO observo cada entrada
- ENTONCES veo: nombre del jugador, cantidad de fechas que debe, monto total adeudado

#### CA-003: Desglose por fecha
- DADO que selecciono un deudor
- CUANDO veo su detalle
- ENTONCES veo cada fecha que debe con: fecha, lugar, duracion, monto individual

#### CA-004: Ordenar lista
- DADO que veo la lista de deudores
- CUANDO quiero priorizar
- ENTONCES la lista esta ordenada por monto total de mayor a menor (los que mas deben primero)

#### CA-005: Resumen total del grupo
- DADO que veo la lista de deudores
- CUANDO observo el header
- ENTONCES veo: total deudores, monto total adeudado del grupo, total de fechas con deudas

#### CA-006: Sin deudores
- DADO que todos los jugadores estan al dia
- CUANDO accedo a deudores
- ENTONCES veo un estado vacio con mensaje "Todos estan al dia" o similar

#### CA-007: Accion rapida saldar desde lista
- DADO que veo un deudor
- CUANDO quiero registrar que pago
- ENTONCES puedo acceder directamente a saldar su deuda (navega a HU-005)

## REGLAS DE NEGOCIO (RN)

### RN-001: Solo admin y co-admin ven deudores
**Contexto**: Al acceder a la lista de deudores.
**Restriccion**: Solo Admin y Co-Admin del grupo activo pueden ver la lista consolidada de deudores.
**Validacion**: Verificar rol en grupo activo.

### RN-002: Deudas por grupo activo
**Contexto**: Al calcular deudas.
**Restriccion**: Solo se muestran deudas de fechas del grupo activo actual, no de otros grupos.
**Validacion**: Filtrar por grupo_id del grupo activo.

### RN-003: Solo pagos pendientes
**Contexto**: Al sumar deudas.
**Restriccion**: Solo se cuentan pagos con estado "pendiente". Los pagados y anulados no se incluyen.
**Regla calculo**: Monto total = SUM(monto WHERE estado='pendiente' AND fecha.grupo_id = grupo_activo).

### RN-004: Invitados tambien pueden tener deudas
**Contexto**: Al listar deudores.
**Restriccion**: Los invitados que participaron en fechas tambien aparecen en la lista de deudores si tienen pagos pendientes.
**Caso especial**: Se identifican con badge "Invitado" para diferenciarse de jugadores regulares.

### RN-005: Disponible en todos los planes
**Contexto**: Acceso a la funcionalidad.
**Restriccion**: Disponible para todos los planes incluido Gratis.

## NOTAS
- Esta es una de las funcionalidades mas solicitadas por admins: saber de un vistazo quien debe y cuanto.
- La lista es del grupo activo. Si el admin tiene multiples grupos, debe cambiar de grupo para ver deudores de otro grupo.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-21
