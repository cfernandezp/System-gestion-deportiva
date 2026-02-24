# E005-HU-005: Saldar Deuda

## INFORMACION
- **Codigo:** E005-HU-005
- **Epica:** E005 - Pagos
- **Titulo:** Saldar Deuda
- **Story Points:** 4 pts
- **Estado:** Refinada
- **Prioridad:** Media
- **Fecha:** 2026-02-21

## HISTORIA
**Como** administrador o co-administrador del grupo,
**Quiero** registrar el pago de deudas de fechas anteriores (ya finalizadas),
**Para** actualizar el estado cuando un jugador salda su deuda fuera de la fecha.

## CONTEXTO
E005-HU-001 permite marcar pagos durante la fecha (mientras esta abierta/cerrada/en juego). Esta HU cubre el caso de pagos posteriores: un jugador que no pago en la fecha pero paga despues (dias o semanas despues). Es comun que jugadores paguen acumulado al final del mes.

### Criterios de Aceptacion

#### CA-001: Acceso desde lista de deudores
- DADO que estoy en la lista de deudores (HU-003)
- CUANDO selecciono un jugador con deudas
- ENTONCES veo sus deudas pendientes y puedo marcarlas como pagadas

#### CA-002: Seleccionar deudas especificas
- DADO que un jugador debe varias fechas
- CUANDO quiero registrar un pago parcial
- ENTONCES puedo seleccionar solo las fechas que pago (checkbox por fecha)

#### CA-003: Saldar todo de una vez
- DADO que un jugador paga todo lo que debe
- CUANDO quiero registrar el pago total
- ENTONCES puedo seleccionar "Saldar todo" que marca todas sus deudas como pagadas

#### CA-004: Confirmacion antes de saldar
- DADO que seleccione las deudas a saldar
- CUANDO confirmo la accion
- ENTONCES veo un resumen: jugador, fechas a saldar, monto total, y boton de confirmar

#### CA-005: Nota de pago
- DADO que saldo una deuda
- CUANDO quiero registrar el metodo de pago
- ENTONCES puedo agregar una nota opcional (ej: "Pago por Yape 15/02", "Pago en efectivo")

#### CA-006: Actualizacion inmediata
- DADO que salde deudas
- CUANDO vuelvo a la lista de deudores
- ENTONCES el jugador ya no aparece (o su monto se actualizo si fue pago parcial)

#### CA-007: Registro de auditoria
- DADO que saldo una deuda
- CUANDO se guarda
- ENTONCES se registra: quien registro el pago (registrado_por), fecha del registro (fecha_pago), nota

## REGLAS DE NEGOCIO (RN)

### RN-001: Solo admin o co-admin pueden saldar deudas
**Contexto**: Al intentar saldar una deuda.
**Restriccion**: Solo Admin y Co-Admin del grupo pueden registrar pagos de deudas.
**Validacion**: Verificar rol en grupo activo.

### RN-002: Solo deudas pendientes se pueden saldar
**Contexto**: Al seleccionar deudas.
**Restriccion**: Solo pagos con estado "pendiente" pueden cambiar a "pagado".
**Validacion**: No se pueden modificar pagos ya pagados o anulados.

### RN-003: Monto no editable
**Contexto**: Al saldar una deuda.
**Restriccion**: El monto de la deuda no se puede cambiar al saldar. Es el monto original de la fecha.
**Validacion**: Solo se cambia el estado (pendiente→pagado), no el monto.
**Caso especial**: Si el jugador paga menos del monto total, el admin registra la nota pero el pago queda como "pagado" por el monto completo. No existe pago parcial por fecha individual.

### RN-004: Historial del jugador se actualiza
**Contexto**: Al saldar una deuda.
**Restriccion**: El historial de pagos del jugador (HU-004) debe reflejar inmediatamente el cambio.
**Validacion**: La fecha pasa de "pendiente" a "pagado" en el historial del jugador.

### RN-005: Disponible en todos los planes
**Contexto**: Acceso a la funcionalidad.
**Restriccion**: Disponible para todos los planes incluido Gratis.

## NOTAS
- Caso tipico: "Oye admin, te pago las 3 pichangas que debo" → admin abre deudores, selecciona al jugador, marca las 3 fechas como pagadas.
- No existe concepto de pago parcial por fecha. Si una fecha cuesta S/10, se paga S/10 o no se paga.
- El campo `registrado_por` ya existe en la tabla `pagos`.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-21
