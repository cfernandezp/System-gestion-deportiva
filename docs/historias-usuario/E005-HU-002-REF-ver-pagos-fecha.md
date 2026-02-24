# E005-HU-002: Ver Pagos de Fecha

## INFORMACION
- **Codigo:** E005-HU-002
- **Epica:** E005 - Pagos
- **Titulo:** Ver Pagos de Fecha
- **Story Points:** 3 pts
- **Estado:** Refinada
- **Prioridad:** Alta
- **Fecha:** 2026-02-21

## HISTORIA
**Como** administrador o co-administrador del grupo,
**Quiero** ver el estado de pagos de cualquier fecha (actual o pasada),
**Para** tener control del estado financiero de cada jornada y hacer seguimiento.

## CONTEXTO
Complementa a E005-HU-001 (Registrar Pago). Mientras HU-001 se enfoca en la accion de marcar pagos, esta HU es la vista de consulta con filtros y resumen financiero.

### Criterios de Aceptacion

#### CA-001: Seccion de pagos en detalle de fecha
- DADO que soy admin o co-admin
- CUANDO entro al detalle de cualquier fecha (incluyendo finalizadas)
- ENTONCES veo una seccion con el resumen y detalle de pagos de esa fecha

#### CA-002: Lista con estado de cada inscrito
- DADO que veo los pagos de una fecha
- CUANDO observo la lista
- ENTONCES veo cada inscrito con: nombre, estado (pagado/pendiente), monto, fecha de pago (si pagado), quien registro el pago, nota (si tiene)

#### CA-003: Filtrar por estado de pago
- DADO que veo la lista de pagos
- CUANDO quiero ver solo los que faltan
- ENTONCES puedo filtrar por "Todos", "Pagados" o "Pendientes"

#### CA-004: Resumen financiero de la fecha
- DADO que veo los pagos de una fecha
- CUANDO observo el header
- ENTONCES veo: total inscritos, pagados, pendientes, monto recaudado, monto esperado, porcentaje de recaudacion

#### CA-005: Indicador en lista de fechas
- DADO que veo la lista de fechas (E007-HU-009)
- CUANDO una fecha tiene pagos pendientes
- ENTONCES veo un indicador (badge o icono) que me dice cuantos faltan por pagar

#### CA-006: Fechas finalizadas son solo lectura
- DADO que veo los pagos de una fecha finalizada
- CUANDO la fecha ya cerro
- ENTONCES puedo ver los pagos pero los botones de marcar/desmarcar estan deshabilitados (para saldar deudas antiguas se usa HU-005)

## REGLAS DE NEGOCIO (RN)

### RN-001: Visibilidad segun rol
**Contexto**: Al acceder a pagos de una fecha.
**Restriccion**: Admin y Co-Admin ven todos los pagos de todos los inscritos. Jugador solo ve su propio estado de pago (ver HU-004).
**Validacion**: Filtrar segun rol del usuario en el grupo.

### RN-002: Pagos anulados excluidos del resumen
**Contexto**: Al calcular totales.
**Restriccion**: Los pagos anulados (cancelaciones) no cuentan en el resumen financiero.
**Regla calculo**: Total esperado = COUNT(estado IN pendiente,pagado) * monto. Recaudado = SUM(monto WHERE estado=pagado).

### RN-003: Orden de la lista
**Contexto**: Al mostrar la lista de pagos.
**Restriccion**: Pendientes primero (para que el admin vea rapidamente quien falta), luego pagados.
**Validacion**: Ordenar por estado (pendiente primero), luego por nombre alfabetico.

### RN-004: Disponible en todos los planes
**Contexto**: Acceso a la funcionalidad.
**Restriccion**: Disponible para todos los planes incluido Gratis.

## NOTAS
- Esta HU es complementaria a HU-001 (Registrar Pago). Comparten la misma pantalla pero HU-002 se enfoca en la consulta y HU-001 en la accion.
- El indicador en la lista de fechas (CA-005) requiere modificar el RPC `listar_fechas_por_rol` de E007-HU-009 para incluir conteo de pagos pendientes.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-21
