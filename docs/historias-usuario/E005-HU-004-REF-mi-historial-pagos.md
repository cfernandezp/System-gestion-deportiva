# E005-HU-004: Mi Historial de Pagos

## INFORMACION
- **Codigo:** E005-HU-004
- **Epica:** E005 - Pagos
- **Titulo:** Mi Historial de Pagos
- **Story Points:** 3 pts
- **Estado:** Refinada
- **Prioridad:** Media
- **Fecha:** 2026-02-21

## HISTORIA
**Como** jugador del grupo,
**Quiero** ver mi historial personal de pagos,
**Para** saber si tengo deudas pendientes y llevar mi propio control.

## CONTEXTO
Esta es la vista del JUGADOR (no del admin). Cada jugador puede ver sus propios pagos sin depender de que el admin le informe. El admin ve TODOS los pagos (HU-001/002/003), el jugador solo los suyos.

### Criterios de Aceptacion

#### CA-001: Acceso desde mi perfil o menu
- DADO que estoy autenticado como jugador
- CUANDO accedo a "Mis Pagos" (desde perfil, menu o acceso rapido)
- ENTONCES veo mi historial de pagos del grupo activo

#### CA-002: Lista de fechas con estado de pago
- DADO que veo mi historial
- CUANDO observo la lista
- ENTONCES veo cada fecha a la que asisti con: fecha, lugar, monto, estado (pagado/pendiente)

#### CA-003: Deudas destacadas visualmente
- DADO que tengo pagos pendientes
- CUANDO veo mi historial
- ENTONCES las deudas se muestran destacadas con color rojo/naranja y al inicio de la lista

#### CA-004: Resumen personal
- DADO que veo mi historial
- CUANDO observo el header
- ENTONCES veo: total de fechas asistidas, monto total pagado, monto total pendiente (si tengo deudas)

#### CA-005: Estado "Al dia"
- DADO que no tengo deudas pendientes
- CUANDO veo mi historial
- ENTONCES veo un indicador positivo ("Al dia", check verde) en el header

#### CA-006: Orden cronologico
- DADO que veo mi historial
- CUANDO observo la lista
- ENTONCES las fechas estan ordenadas de la mas reciente a la mas antigua, con deudas pendientes primero

## REGLAS DE NEGOCIO (RN)

### RN-001: Solo mis propios pagos
**Contexto**: Al cargar el historial.
**Restriccion**: El jugador solo ve sus propios pagos, nunca los de otros jugadores.
**Validacion**: Filtrar por usuario_id = usuario actual.

### RN-002: Pagos del grupo activo
**Contexto**: Al listar pagos.
**Restriccion**: Solo se muestran pagos de fechas del grupo activo actual.
**Validacion**: Filtrar por grupo_id del grupo activo.

### RN-003: Pagos anulados no se muestran
**Contexto**: Al listar pagos.
**Restriccion**: Si el jugador cancelo una inscripcion y el pago fue anulado, ese pago no aparece.
**Validacion**: Filtrar WHERE estado IN ('pendiente', 'pagado').

### RN-004: Todos los roles ven su historial
**Contexto**: Acceso a la funcionalidad.
**Restriccion**: Admin, Co-Admin, Jugador e Invitado pueden ver su propio historial de pagos.
**Caso especial**: El admin tambien puede ver su propio historial como jugador si participo en fechas.

### RN-005: Disponible en todos los planes
**Contexto**: Acceso a la funcionalidad.
**Restriccion**: Disponible para todos los planes incluido Gratis.

## NOTAS
- Esta pantalla reduce la carga al admin: el jugador puede consultar por si mismo si tiene deudas.
- El acceso ideal seria desde el acceso rapido "Mi Actividad" o desde "Mi Perfil".
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-21
