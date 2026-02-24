# E005-HU-001: Registrar Pago

## INFORMACION
- **Codigo:** E005-HU-001
- **Epica:** E005 - Pagos
- **Titulo:** Registrar Pago
- **Story Points:** 3 pts
- **Estado:** Refinada
- **Prioridad:** Alta
- **Fecha:** 2026-02-21

## HISTORIA
**Como** administrador o co-administrador del grupo,
**Quiero** marcar que un jugador pago su cuota de la fecha,
**Para** llevar control de quien cumplio con su aporte y cuanto se recaudo.

## CONTEXTO
La tabla `pagos` ya existe en Supabase. Se crea un registro automatico con estado `pendiente` cuando un jugador se inscribe a una fecha (E007-HU-002). Esta HU agrega la UI para que el admin cambie el estado de `pendiente` a `pagado`.

### Criterios de Aceptacion

#### CA-001: Acceso a registro de pagos desde fecha
- DADO que soy admin o co-admin del grupo
- CUANDO estoy en el detalle de una fecha (cualquier estado excepto cancelada)
- ENTONCES veo una seccion o boton "Pagos" que me permite gestionar los pagos de esa fecha

#### CA-002: Lista de inscritos con estado de pago
- DADO que accedo a pagos de una fecha
- CUANDO veo la lista
- ENTONCES veo cada inscrito con: nombre, estado de pago (pendiente/pagado), monto, y la fecha en que pago (si aplica)

#### CA-003: Marcar como pagado
- DADO que veo un jugador con estado "pendiente"
- CUANDO presiono el boton/toggle de pago
- ENTONCES se confirma la accion y el estado cambia a "pagado" con la fecha actual

#### CA-004: Desmarcar pago (correccion)
- DADO que marque un pago por error
- CUANDO presiono desmarcar
- ENTONCES el sistema me pide confirmacion y el estado vuelve a "pendiente"

#### CA-005: Indicador visual claro
- DADO que veo la lista de pagos
- CUANDO hay mix de pagados y pendientes
- ENTONCES los pagados se muestran con check verde y los pendientes con indicador rojo/naranja

#### CA-006: Resumen de recaudacion
- DADO que veo los pagos de la fecha
- CUANDO observo el header/resumen
- ENTONCES veo: total inscritos, cuantos pagaron, cuantos faltan, monto recaudado vs monto esperado (ej: "S/48 de S/80 recaudados")

#### CA-007: Notas opcionales en pago
- DADO que registro un pago
- CUANDO quiero agregar un detalle (ej: "pago con Yape", "pago parcial")
- ENTONCES puedo agregar una nota opcional al registro de pago

## REGLAS DE NEGOCIO (RN)

### RN-001: Solo admin o co-admin pueden registrar pagos
**Contexto**: Al intentar marcar un pago.
**Restriccion**: Solo roles Admin y Co-Admin del grupo pueden registrar o desmarcar pagos.
**Validacion**: Verificar rol del usuario en el grupo activo.

### RN-002: Monto automatico segun duracion
**Contexto**: Al mostrar el monto del pago.
**Restriccion**: El monto viene de la tabla `pagos` (ya calculado al inscribirse): S/8 (1 hora) o S/10 (2 horas).
**Validacion**: No se edita manualmente el monto desde esta pantalla.
**Caso especial**: Si la fecha fue editada y cambio de duracion, el monto ya fue ajustado automaticamente (E007-HU-008).

### RN-003: Registro de quien registro el pago
**Contexto**: Al marcar un pago como pagado.
**Restriccion**: Se debe registrar quien marco el pago (registrado_por) y cuando (fecha_pago).
**Validacion**: Campos registrado_por = usuario actual, fecha_pago = NOW().

### RN-004: Pagos anulados no se muestran
**Contexto**: Al listar pagos de una fecha.
**Restriccion**: Los pagos con estado "anulado" (cancelaciones de inscripcion) no deben aparecer en la lista de pagos activos.
**Validacion**: Filtrar WHERE estado IN ('pendiente', 'pagado').

### RN-005: Disponible en todos los planes
**Contexto**: Al acceder a la funcionalidad de pagos.
**Restriccion**: La gestion de pagos esta disponible para TODOS los planes (incluido Gratis).
**Validacion**: No hay restriccion de plan para esta funcionalidad.

## NOTAS
- La tabla `pagos` ya existe con campos: id, inscripcion_id, usuario_id, fecha_id, monto, estado, fecha_pago, registrado_por, notas, created_at, updated_at.
- Los estados posibles de pago son: pendiente, pagado, anulado.
- El pago se crea automatico al inscribirse (E007-HU-002), se anula si cancela inscripcion (E007-HU-007).
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-21
