# EPICA E005: Pagos

## INFORMACION
- **Codigo:** E005
- **Nombre:** Pagos
- **Descripcion:** Gestiona el registro de pagos de cada jugador por fecha y el historial de deudas. La tabla `pagos` ya existe y se crea automaticamente al inscribirse a una fecha (E007). Esta epica cubre la UI de gestion: registrar pagos, ver estado por fecha, deudores consolidados, historial del jugador y saldar deudas.
- **Story Points:** 18 pts
- **Estado:** 🟢 Refinada (backend parcial existe, UI pendiente)
- **Plataforma:** App Movil (Android/iOS) - Flutter + Supabase

## CONTEXTO DE NEGOCIO
- Cada asistente debe pagar segun duracion de la pichanga
- S/ 8 por 1 hora | S/ 10 por 2 horas
- Admin registra quien pago
- Historial de deudores para seguimiento
- Jugadores pueden ver su propio estado de pagos

## LO QUE YA EXISTE (implementado en E007)
- Tabla `pagos` con campos: id, inscripcion_id, usuario_id, fecha_id, monto, estado (pendiente/pagado/anulado), fecha_pago, registrado_por, notas
- Pago se **crea automatico** al inscribirse a una fecha (monto segun duracion)
- Pago se **ajusta automatico** si cambia duracion de la fecha
- Pago se **anula automatico** si jugador cancela inscripcion en fecha abierta

## TARIFAS

| Duracion | Monto |
|----------|-------|
| 1 Hora | S/ 8 |
| 2 Horas | S/ 10 |

## HISTORIAS

### E005-HU-001: Registrar Pago
- **Archivo:** docs/historias-usuario/E005-HU-001-REF-registrar-pago.md
- **Estado:** 🟢 Refinada | **Story Points:** 3 | **Prioridad:** Alta

### E005-HU-002: Ver Pagos de Fecha
- **Archivo:** docs/historias-usuario/E005-HU-002-REF-ver-pagos-fecha.md
- **Estado:** 🟢 Refinada | **Story Points:** 3 | **Prioridad:** Alta

### E005-HU-003: Ver Deudores
- **Archivo:** docs/historias-usuario/E005-HU-003-REF-ver-deudores.md
- **Estado:** 🟢 Refinada | **Story Points:** 5 | **Prioridad:** Alta

### E005-HU-004: Mi Historial de Pagos
- **Archivo:** docs/historias-usuario/E005-HU-004-REF-mi-historial-pagos.md
- **Estado:** 🟢 Refinada | **Story Points:** 3 | **Prioridad:** Media

### E005-HU-005: Saldar Deuda
- **Archivo:** docs/historias-usuario/E005-HU-005-REF-saldar-deuda.md
- **Estado:** 🟢 Refinada | **Story Points:** 4 | **Prioridad:** Media

## CRITERIOS EPICA
- [ ] El admin puede marcar pagos de jugadores en una fecha activa
- [ ] El admin puede ver lista de pagos/pendientes por fecha con resumen financiero
- [ ] El admin puede ver deudores consolidados del grupo (todas las fechas)
- [ ] Los jugadores pueden ver su propio historial de pagos
- [ ] El admin puede saldar deudas de fechas anteriores
- [x] El pago se crea automatico al inscribirse (via E007)
- [x] El monto se ajusta automatico si cambia duracion (via E007)
- [x] El pago se anula si se cancela inscripcion (via E007)

## DEPENDENCIAS
- E001: Autenticacion
- E002: Grupos Deportivos
- E007: Gestion de Pichangas/Fechas (tabla pagos creada ahi)

## PROGRESO
**Total HU:** 5 | **Refinadas:** 5 (100%) | **Completadas:** 0 | **Backend parcial:** Si (tabla existe)
