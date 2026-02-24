# EPICA E007: Gestion de Pichangas/Fechas

## INFORMACION
- **Codigo:** E007
- **Nombre:** Gestion de Pichangas/Fechas
- **Descripcion:** Ciclo de vida completo de una pichanga (fecha deportiva): desde la creacion con fecha, hora, duracion y lugar, pasando por inscripcion de jugadores, asignacion de equipos, inicio de la jornada, hasta la finalizacion. Incluye gestion de inscripciones, cancelaciones, edicion y listados por rol.
- **Story Points:** 48 pts
- **Estado:** ✅ Completada
- **Plataforma:** App Movil (Android/iOS) - Flutter + Supabase
- **Origen:** Migrada desde archive/v1 (implementada 2026-01)

## CICLO DE VIDA DE UNA FECHA
```
abierta → cerrada → en_juego → finalizada
                  ↘ cancelada
```

## FORMATOS DE PICHANGA

| Duracion | Equipos | Costo/Jugador | Partidos |
|----------|---------|---------------|----------|
| 1 hora | 2 | S/ 8 | 3 x 20 min |
| 2 horas | 3 | S/ 10 | Rotacion x 10 min |

## HISTORIAS

### E007-HU-001: Crear Fecha
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-001-COM-crear-fecha.md
- **Estado:** ✅ Completada | **Story Points:** 5 | **Prioridad:** Alta
- **Funcionalidad:** Admin crea pichanga con fecha, hora, duracion (1h/2h), lugar. Costo y equipos se calculan automaticamente.

### E007-HU-002: Inscribirse a Fecha
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-002-COM-inscribirse-fecha.md
- **Estado:** ✅ Completada | **Story Points:** 5 | **Prioridad:** Alta
- **Funcionalidad:** Jugador se anota a una fecha abierta. Se crea pago pendiente automatico.

### E007-HU-003: Ver Inscritos
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-003-COM-ver-inscritos.md
- **Estado:** ✅ Completada | **Story Points:** 3 | **Prioridad:** Alta
- **Funcionalidad:** Lista de inscritos con realtime, badge "(Tu)", ordenada por fecha de inscripcion.

### E007-HU-004: Cerrar/Reabrir Inscripciones
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-004-COM-cerrar-inscripciones.md
- **Estado:** ✅ Completada | **Story Points:** 3 | **Prioridad:** Alta
- **Funcionalidad:** Admin cierra signups (abierta→cerrada), puede reabrir. Warning si <6 jugadores.

### E007-HU-005: Asignar Equipos
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-005-COM-asignar-equipos.md
- **Estado:** ✅ Completada | **Story Points:** 8 | **Prioridad:** Alta
- **Funcionalidad:** Admin distribuye jugadores en equipos (naranja/verde/azul). Drag-drop en desktop, selector en mobile.

### E007-HU-006: Ver Mi Equipo
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-006-COM-ver-mi-equipo.md
- **Estado:** ✅ Completada | **Story Points:** 3 | **Prioridad:** Alta
- **Funcionalidad:** Jugador ve su equipo asignado con color y companeros. Realtime.

### E007-HU-007: Cancelar Inscripcion
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-007-COM-cancelar-inscripcion.md
- **Estado:** ✅ Completada | **Story Points:** 3 | **Prioridad:** Media
- **Funcionalidad:** Jugador cancela si fecha abierta (deuda anulada). Admin puede cancelar en cualquier estado.

### E007-HU-008: Editar Fecha
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-008-COM-editar-fecha.md
- **Estado:** ✅ Completada | **Story Points:** 5 | **Prioridad:** Media
- **Funcionalidad:** Admin edita fecha abierta. Si cambia duracion, se recalcula costo y se ajustan deudas.

### E007-HU-009: Listado de Fechas por Rol
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-009-REF-listado-fechas-por-rol.md
- **Estado:** ✅ Completada | **Story Points:** 5 | **Prioridad:** Alta
- **Funcionalidad:** Vistas diferenciadas admin vs jugador: proximas, inscritas, en curso, historial.

### E007-HU-010: Finalizar Fecha
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-010-COM-finalizar-fecha.md
- **Estado:** ✅ Completada | **Story Points:** 3 | **Prioridad:** Alta
- **Funcionalidad:** Admin cierra jornada. Registro opcional de incidentes y comentarios.

### E007-HU-011: Inscribir Jugador (Admin)
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-011-COM-inscribir-jugador-admin.md
- **Estado:** ✅ Completada | **Story Points:** 3 | **Prioridad:** Media
- **Funcionalidad:** Admin anota jugadores manualmente con buscador. Se trackea inscrito_por.

### E007-HU-012: Iniciar Fecha
- **Archivo:** docs/archive/v1/historias-usuario/E003-HU-012-COM-iniciar-fecha.md
- **Estado:** ✅ Completada | **Story Points:** 2 | **Prioridad:** Alta
- **Funcionalidad:** Admin inicia jornada (cerrada→en_juego). Habilita creacion de partidos en vivo.

## CRITERIOS EPICA
- [x] Un admin puede crear una fecha con fecha, hora, duracion y lugar
- [x] El costo por jugador se calcula automaticamente segun duracion
- [x] Los jugadores pueden inscribirse a fechas abiertas
- [x] Se crea un pago pendiente automatico al inscribirse
- [x] El admin puede cerrar y reabrir inscripciones
- [x] El admin puede asignar jugadores a equipos con colores
- [x] Cada jugador puede ver su equipo asignado en tiempo real
- [x] Los jugadores pueden cancelar inscripcion si la fecha esta abierta
- [x] El admin puede cancelar inscripciones en cualquier estado
- [x] El admin puede editar fechas abiertas (recalcula costo si cambia duracion)
- [x] Las vistas de fechas son diferentes segun el rol (admin vs jugador)
- [x] El admin puede iniciar la jornada (habilita partidos en vivo)
- [x] El admin puede finalizar la jornada con comentarios e incidentes
- [x] El admin puede inscribir jugadores manualmente

## IMPLEMENTACION

### Backend (Supabase)
| RPC | HU |
|-----|-----|
| crear_fecha | HU-001 |
| inscribirse_fecha | HU-002 |
| cancelar_inscripcion | HU-002, HU-007 |
| obtener_fecha_detalle | HU-002 |
| obtener_inscritos_fecha | HU-003 |
| cerrar_inscripciones | HU-004 |
| reabrir_inscripciones | HU-004 |
| asignar_equipo | HU-005 |
| confirmar_equipos | HU-005 |
| obtener_asignaciones | HU-005 |
| obtener_mi_equipo | HU-006 |
| obtener_equipos_fecha | HU-006 |
| verificar_puede_cancelar | HU-007 |
| cancelar_inscripcion_admin | HU-007 |
| editar_fecha | HU-008 |
| listar_fechas_por_rol | HU-009 |
| finalizar_fecha | HU-010 |
| listar_jugadores_disponibles_inscripcion | HU-011 |
| inscribir_jugador_admin | HU-011 |
| iniciar_fecha | HU-012 |

### Frontend (Flutter)
- Feature: `lib/features/fechas/`
- BLoCs: CrearFecha, Inscripcion, Inscritos, CerrarInscripciones, Asignaciones, MiEquipo, CancelarInscripcion, EditarFecha, FechasPorRol, FinalizarFecha, InscribirJugadorAdmin, IniciarFecha
- Pages: crear_fecha_page, fechas_disponibles_page, fecha_detalle_page, asignar_equipos_page
- Realtime: inscripciones y asignaciones_equipos

### Tablas principales
- `fechas` (fecha_hora_inicio, duracion_horas, lugar, num_equipos, costo_por_jugador, estado)
- `inscripciones` (fecha_id, usuario_id, estado, inscrito_por, cancelado_at)
- `asignaciones_equipos` (fecha_id, usuario_id, equipo)
- `pagos` (inscripcion_id, monto, estado)

## DEPENDENCIAS
- E001: Autenticacion
- E002: Grupos Deportivos
- Prerequisito de E004 (Partidos en Vivo) y E005 (Pagos)

## PROGRESO
**Total HU:** 12 | **Completadas:** 12 (100%) | **En Desarrollo:** 0 | **Pendientes:** 0
