# E003-HU-011 - Inscribir Jugador como Admin

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: Completada (COM)
- **Prioridad**: Media

## Historia de Usuario
**Como** administrador u organizador
**Quiero** inscribir a un jugador a una fecha (pichanga) desde la vista de detalle
**Para** gestionar las inscripciones cuando el jugador no puede hacerlo por si mismo

## Descripcion
Permite al administrador u organizador inscribir manualmente a cualquier jugador aprobado a una fecha de pichanga. Esta funcionalidad se accede desde el panel "Jugadores anotados" en la vista de detalle de la pichanga, donde el admin puede seleccionar un jugador de la lista de jugadores existentes en el sistema.

## Contexto Visual
- **Vista**: Detalle de Pichanga
- **Ubicacion**: Panel derecho "Jugadores anotados"
- **Accion**: Boton "Agregar jugador" o icono "+" visible solo para admin/organizador
- **Flujo**: Admin selecciona jugador de lista desplegable/buscable y confirma inscripcion

## Criterios de Aceptacion (CA)

### CA-001: Acceso exclusivo admin/organizador
- **Dado** que soy admin u organizador de la fecha
- **Cuando** veo el detalle de una pichanga con estado "abierta"
- **Entonces** veo boton "Agregar jugador" o icono "+" en el panel de inscritos
- **Y** si soy jugador regular, NO veo esta opcion

### CA-002: Selector de jugadores
- **Dado** que presiono "Agregar jugador"
- **Cuando** se abre el dialogo de seleccion
- **Entonces** veo lista de jugadores aprobados del sistema
- **Y** la lista es buscable por nombre o apodo
- **Y** NO aparecen jugadores ya inscritos a esta fecha

### CA-003: Validacion jugador no inscrito
- **Dado** que selecciono un jugador
- **Cuando** el jugador ya esta inscrito a esta fecha
- **Entonces** veo mensaje "Este jugador ya esta anotado"
- **Y** no puedo inscribirlo nuevamente

### CA-004: Confirmacion de inscripcion
- **Dado** que selecciono un jugador valido
- **Cuando** confirmo la accion
- **Entonces** el jugador queda inscrito con estado "inscrito"
- **Y** veo mensaje "Jugador [nombre] inscrito exitosamente"
- **Y** se actualiza la lista de inscritos en tiempo real

### CA-005: Generacion de deuda
- **Dado** que inscribo exitosamente a un jugador
- **Cuando** se confirma la inscripcion
- **Entonces** se registra deuda pendiente por el costo de la fecha
- **Y** el jugador podra ver esta deuda en su historial de pagos

### CA-006: Notificacion al jugador
- **Dado** que inscribo a un jugador
- **Cuando** se procesa la inscripcion
- **Entonces** el jugador recibe notificacion "Te han inscrito a la pichanga del [fecha]"
- **Y** la notificacion incluye: fecha, hora, lugar, costo

### CA-007: Respeto al limite de cupos
- **Dado** que la fecha tiene un limite de jugadores definido
- **Cuando** ya se alcanzo el limite
- **Entonces** no puedo inscribir mas jugadores
- **Y** veo mensaje "Se alcanzo el limite de cupos ([N] jugadores)"

### CA-008: Solo fechas abiertas
- **Dado** que la fecha tiene estado diferente a "abierta"
- **Cuando** veo el detalle de la fecha
- **Entonces** NO veo la opcion de agregar jugador
- **Y** solo puedo inscribir jugadores a fechas con inscripciones abiertas

---

## Reglas de Negocio (RN)

### RN-001: Permisos de Inscripcion por Admin
**Contexto**: Solo administradores u organizadores de la fecha pueden inscribir a otros jugadores.
**Restriccion**: Jugadores regulares no pueden inscribir a otros.
**Validacion**: Usuario que ejecuta la accion debe tener rol = 'admin' y estado = 'aprobado', o ser el creador de la fecha.
**Regla calculo**: N/A.
**Caso especial**: El organizador (creador de la fecha) puede inscribir jugadores aunque no sea admin global.

### RN-002: Jugador Destino Valido
**Contexto**: Solo se pueden inscribir jugadores aprobados y activos.
**Restriccion**: No se permiten inscribir usuarios pendientes, rechazados o suspendidos.
**Validacion**: El jugador seleccionado debe tener estado = 'aprobado'.
**Regla calculo**: N/A.
**Caso especial**: Admins no pueden inscribirse a si mismos usando esta funcion (deben usar auto-inscripcion normal).

### RN-003: Inscripcion Unica por Fecha
**Contexto**: Un jugador solo puede estar inscrito una vez a la misma fecha.
**Restriccion**: No se permiten inscripciones duplicadas.
**Validacion**: Verificar que no exista registro activo en inscripciones para (jugador_id, fecha_id).
**Regla calculo**: N/A.
**Caso especial**: Si el jugador cancelo previamente, se permite crear nueva inscripcion.

### RN-004: Estado de Fecha para Inscripcion
**Contexto**: Solo se puede inscribir jugadores a fechas abiertas.
**Restriccion**: No se permite inscripcion si estado != 'abierta'.
**Validacion**: Verificar fecha.estado = 'abierta' antes de procesar.
**Regla calculo**: N/A.
**Caso especial**: Estados que bloquean inscripcion: cerrada, en_juego, finalizada, cancelada.

### RN-005: Generacion de Deuda al Inscribir
**Contexto**: Al inscribir un jugador, este adquiere compromiso de pago.
**Restriccion**: Toda inscripcion genera una deuda automaticamente.
**Validacion**: Sistema crea registro de pago con estado 'pendiente'.
**Regla calculo**: monto_deuda = fecha.costo_por_jugador (S/8 o S/10 segun duracion).
**Caso especial**: Admin puede anular deuda posteriormente si lo considera necesario.

### RN-006: Limite de Inscripciones
**Contexto**: Se puede limitar el numero maximo de jugadores por fecha.
**Restriccion**: Si la fecha tiene limite, no se aceptan mas inscripciones al alcanzarlo.
**Validacion**: COUNT(inscripciones_activas) < fecha.limite_jugadores (si existe).
**Regla calculo**: Tipicamente 15-18 jugadores maximo.
**Caso especial**: Por defecto no hay limite. Admin puede cerrar inscripciones manualmente cuando considere suficiente.

### RN-007: Registro de Quien Inscribio
**Contexto**: Se debe registrar quien realizo la inscripcion administrativa.
**Restriccion**: N/A.
**Validacion**: Campo inscrito_por = admin_id cuando es inscripcion administrativa.
**Regla calculo**: N/A.
**Caso especial**: Diferencia con auto-inscripcion: inscrito_por = NULL o mismo usuario_id.

### RN-008: Notificacion Obligatoria al Jugador
**Contexto**: El jugador debe ser informado de su inscripcion.
**Restriccion**: N/A.
**Validacion**: Sistema crea notificacion automatica al jugador inscrito.
**Regla calculo**: N/A.
**Caso especial**: Notificacion incluye quien lo inscribio para transparencia.

---

## FASE 2: Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-31

### Modificaciones a Tabla Existente

#### Tabla: `inscripciones` - Nueva columna
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `inscrito_por` | UUID (FK -> usuarios) | RN-007: ID del admin que realizo inscripcion administrativa. NULL si es auto-inscripcion |

### Funciones RPC Implementadas

#### `listar_jugadores_disponibles_inscripcion(p_fecha_id UUID) -> JSON`
- **Descripcion**: Lista jugadores aprobados que NO estan inscritos a una fecha
- **Criterios**: CA-002 (selector de jugadores)
- **Validaciones**: RN-001 (solo admin/organizador puede ver)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "jugadores": [
        {
          "id": "uuid",
          "nombre_completo": "Juan Perez",
          "apodo": "Juanito",
          "nombre_display": "Juanito",
          "posicion_preferida": "Defensa",
          "foto_url": "url"
        }
      ],
      "total": 15
    },
    "message": "Lista de jugadores disponibles obtenida exitosamente"
  }
  ```

#### `inscribir_jugador_admin(p_fecha_id UUID, p_jugador_id UUID) -> JSON`
- **Descripcion**: Inscribe un jugador a una fecha como admin/organizador
- **Criterios**: CA-001 a CA-008
- **Reglas**: RN-001 a RN-008
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "inscripcion_id": "uuid",
      "fecha_id": "uuid",
      "jugador_id": "uuid",
      "jugador_nombre": "Juanito",
      "fecha_formato": "DD/MM/YYYY HH24:MI",
      "lugar": "Cancha X",
      "costo_por_jugador": 10.00,
      "costo_formato": "S/ 10.00",
      "pago_id": "uuid",
      "estado_inscripcion": "inscrito",
      "estado_pago": "pendiente",
      "total_inscritos": 12,
      "inscrito_por_id": "uuid",
      "inscrito_por_nombre": "Admin"
    },
    "message": "Jugador Juanito inscrito exitosamente"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `sin_permisos` -> No es admin ni organizador
  - `fecha_no_abierta` -> Fecha no acepta inscripciones
  - `jugador_no_aprobado` -> Jugador no tiene estado aprobado
  - `ya_inscrito` -> Jugador ya esta inscrito
  - `limite_cupos` -> Se alcanzo limite de jugadores
  - `no_auto_inscripcion` -> Admin no puede inscribirse a si mismo

### Script SQL
- `supabase/sql-cloud/2026-01-31_E003-HU-011_inscribir_jugador_admin.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Validacion permisos admin/organizador
- [x] **CA-002**: Lista jugadores aprobados no inscritos
- [x] **CA-003**: Validacion jugador no duplicado
- [x] **CA-004**: Inscripcion exitosa con mensaje
- [x] **CA-005**: Generacion automatica de deuda
- [x] **CA-006**: Notificacion al jugador inscrito
- [x] **CA-007**: Validacion limite de cupos
- [x] **CA-008**: Solo fechas abiertas

### Reglas de Negocio Backend
- [x] **RN-001**: Validacion admin o creador de fecha
- [x] **RN-002**: Solo jugadores aprobados (no admin a si mismo)
- [x] **RN-003**: Unique constraint por fecha/usuario
- [x] **RN-004**: Estado fecha = 'abierta'
- [x] **RN-005**: INSERT en tabla pagos
- [x] **RN-006**: Validacion limite_jugadores
- [x] **RN-007**: Campo inscrito_por en inscripciones
- [x] **RN-008**: INSERT en notificaciones

---

## FASE 3: Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-01-31

### Data Layer - Models
| Archivo | Descripcion |
|---------|-------------|
| `lib/features/fechas/data/models/inscribir_jugador_admin_response_model.dart` | Modelos: `JugadorDisponibleModel`, `ListarJugadoresDisponiblesResponseModel`, `InscripcionAdminDataModel`, `InscribirJugadorAdminResponseModel` |

### Data Layer - DataSource
| Archivo | Metodos RPC |
|---------|-------------|
| `lib/features/fechas/data/datasources/fechas_remote_datasource.dart` | `listarJugadoresDisponiblesInscripcion()`, `inscribirJugadorAdmin()` |

### Domain Layer
| Archivo | Metodos |
|---------|---------|
| `lib/features/fechas/domain/repositories/fechas_repository.dart` | Interface con 2 nuevos metodos |
| `lib/features/fechas/data/repositories/fechas_repository_impl.dart` | Implementacion con patron Either |

### Presentation Layer - BLoC
| BLoC | Archivos |
|------|----------|
| **InscribirJugadorAdminBloc** | `inscribir_jugador_admin_bloc.dart`, `inscribir_jugador_admin_event.dart`, `inscribir_jugador_admin_state.dart` |

### Dependency Injection
- `lib/core/di/injection_container.dart` - Registrado: `InscribirJugadorAdminBloc`

---

## FASE 4: UI
**Responsable**: ux-ui-expert
**Status**: Completado
**Fecha**: 2026-01-31

### Widgets Creados
| Widget | Descripcion |
|--------|-------------|
| `lib/features/fechas/presentation/widgets/agregar_jugador_admin_dialog.dart` | Dialog modal con selector de jugadores buscable |

### Widgets Modificados
| Widget | Modificacion |
|--------|--------------|
| `lib/features/fechas/presentation/widgets/inscritos_list_widget.dart` | Agregado boton "Agregar jugador" en header (solo admin, fecha abierta) |
| `lib/features/fechas/presentation/pages/fecha_detalle_page.dart` | Agregado parametro `fechaAbierta` al InscritosListWidget |

### Criterios de Aceptacion UI
- [x] **CA-001**: Boton "+" visible solo para admin si fecha abierta
- [x] **CA-002**: Dialog con lista buscable de jugadores
- [x] **CA-003**: Mensaje de error si jugador ya inscrito
- [x] **CA-004**: SnackBar de exito y recarga de lista
- [x] **CA-008**: Boton oculto si fecha no abierta

---

## FASE 5: QA
**Responsable**: qa-testing-expert
**Status**: Completado
**Fecha**: 2026-01-31

### Resultados
- **flutter analyze**: 0 errores (14 warnings de deprecacion en archivos no relacionados)
- **flutter pub get**: Dependencias instaladas correctamente
- **Imports**: Todos correctos
- **DI**: BLoC registrado correctamente
- **Exports**: Models y widgets exportados en barrel files

---

## Nota de Despliegue
**IMPORTANTE**: El script SQL debe ejecutarse manualmente en Supabase Cloud:
- Archivo: `supabase/sql-cloud/2026-01-31_E003-HU-011_inscribir_jugador_admin.sql`
- Dashboard: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql/new

---
**Creado**: 2026-01-31
**Refinado**: 2026-01-31
**Completado**: 2026-01-31
