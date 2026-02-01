# E003-HU-012 - Iniciar Fecha

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: DEV (En Desarrollo)
- **Prioridad**: Alta
- **Story Points**: 5 pts

## Historia de Usuario
**Como** administrador
**Quiero** iniciar una fecha de pichanga (cambiar a estado en_juego)
**Para** indicar que la jornada ha comenzado y habilitar los partidos

## Descripcion
Esta funcionalidad permite al administrador marcar el inicio oficial de una pichanga. Cuando una fecha cambia de estado 'cerrada' a 'en_juego', se indica que la jornada ha comenzado formalmente, se registra la hora real de inicio (que puede diferir de la hora pactada), y se habilita la funcionalidad de partidos (E004).

El flujo completo del ciclo de vida de una fecha es:
`abierta -> cerrada -> en_juego -> finalizada`

---

## Criterios de Aceptacion (CA)

### CA-001: Boton visible solo en estado cerrada
- **Dado** que soy admin y hay una fecha con estado "cerrada"
- **Cuando** veo el detalle de la fecha
- **Entonces** veo boton "Iniciar Pichanga"
- **Y** el boton NO aparece en otros estados (abierta, en_juego, finalizada)

### CA-002: Confirmacion con resumen
- **Dado** que presiono "Iniciar Pichanga"
- **Cuando** aparece el dialogo de confirmacion
- **Entonces** veo resumen de la fecha:
  - Fecha y hora pactada
  - Lugar
  - Numero de equipos asignados
  - Numero de jugadores inscritos por equipo
- **Y** veo botones "Cancelar" e "Iniciar"

### CA-003: Warning si no hay equipos asignados
- **Dado** que presiono "Iniciar Pichanga"
- **Cuando** no hay equipos asignados a la fecha
- **Entonces** veo advertencia "No hay equipos asignados. Se recomienda asignar equipos antes de iniciar."
- **Y** puedo continuar de todas formas (es warning, no bloqueo)

### CA-004: Estado cambia a en_juego
- **Dado** que confirmo el inicio
- **Cuando** se procesa la accion
- **Entonces** el estado cambia a "en_juego"
- **Y** se registra la hora real de inicio (timestamp actual)
- **Y** veo mensaje de exito "Pichanga iniciada correctamente"

### CA-005: Boton desaparece tras iniciar
- **Dado** que la fecha ya tiene estado "en_juego"
- **Cuando** veo el detalle de la fecha
- **Entonces** NO veo boton "Iniciar Pichanga"
- **Y** veo indicador visual "En Juego" (estado activo)

### CA-006: Notificacion a jugadores inscritos
- **Dado** que inicio una pichanga exitosamente
- **Cuando** se confirma el cambio de estado
- **Entonces** todos los jugadores inscritos reciben notificacion
- **Y** el mensaje indica "La pichanga del [fecha] ha comenzado!"
- **Y** incluye el lugar para referencia

### CA-007: Registro de hora real de inicio
- **Dado** que inicio una pichanga
- **Cuando** se procesa la accion
- **Entonces** se registra la hora real de inicio (puede diferir de hora pactada)
- **Y** este timestamp queda disponible para consultas futuras
- **Y** se registra quien inicio la pichanga

---

## Reglas de Negocio (RN)

### RN-001: Permiso Exclusivo Admin/Organizador
**Contexto**: Solo administradores u organizadores aprobados pueden iniciar una pichanga.
**Restriccion**: Jugadores regulares no tienen acceso a esta funcionalidad.
**Validacion**: Verificar rol = 'admin' y estado = 'aprobado', o ser creador de la fecha.
**Regla calculo**: N/A.
**Caso especial**: El organizador (creador de la fecha) puede iniciar aunque no sea admin global.

### RN-002: Solo Estado Cerrada Permite Inicio
**Contexto**: Una pichanga solo puede iniciarse si las inscripciones estan cerradas.
**Restriccion**: No se puede iniciar desde estado 'abierta', 'en_juego', 'finalizada' o 'cancelada'.
**Validacion**: fecha.estado = 'cerrada'.
**Regla calculo**: N/A.
**Caso especial**: Si se olvido cerrar inscripciones, debe hacerse primero con HU-004.

### RN-003: Validacion de Equipos Asignados
**Contexto**: Para un inicio optimo, deberia haber al menos 2 equipos con jugadores asignados.
**Restriccion**: Se muestra advertencia si no hay equipos, pero no se bloquea.
**Validacion**: Contar equipos con al menos 1 jugador asignado.
**Regla calculo**: equipos_con_jugadores >= 2 (recomendado, no obligatorio).
**Caso especial**: Admin puede iniciar sin equipos si la asignacion se hara en cancha.

### RN-004: Auditoria de Inicio
**Contexto**: Se debe registrar quien y cuando inicio la pichanga.
**Restriccion**: Campos de auditoria son obligatorios.
**Validacion**: Guardar id del admin que inicia y timestamp de inicio real.
**Regla calculo**: iniciado_por = auth.uid(), iniciado_at = NOW().
**Caso especial**: N/A.

### RN-005: Notificacion Obligatoria a Inscritos
**Contexto**: Todos los jugadores inscritos deben ser notificados del inicio.
**Restriccion**: La notificacion es automatica, no opcional.
**Validacion**: Crear notificacion para cada inscripcion con estado = 'inscrito'.
**Regla calculo**: N/A.
**Caso especial**: Jugadores que cancelaron inscripcion NO reciben notificacion.

### RN-006: Habilitacion de Partidos
**Contexto**: Al pasar a 'en_juego', se habilita la funcionalidad de E004 (Partidos en Vivo).
**Restriccion**: Los partidos solo pueden iniciarse si la fecha esta en estado 'en_juego'.
**Validacion**: E004 valida fecha.estado = 'en_juego' antes de crear partidos.
**Regla calculo**: N/A.
**Caso especial**: N/A.

### RN-007: Transicion Irreversible
**Contexto**: Una vez iniciada, la fecha no puede volver a estado 'cerrada'.
**Restriccion**: El unico estado siguiente permitido es 'finalizada'.
**Validacion**: No existe funcion para revertir a 'cerrada' desde 'en_juego'.
**Regla calculo**: Flujo unidireccional: cerrada -> en_juego -> finalizada.
**Caso especial**: En caso de error grave, se debe finalizar y crear nueva fecha.

---

## UI/UX Sugerido

### Ubicacion del Boton (Mobile)
```
+----------------------------------+
| <- Pichanga 25/01/2026           |
|                                  |
+----------------------------------+
| Estado: Cerrada                  |
| Lugar: Cancha Los Amigos         |
| Hora pactada: 19:00              |
|                                  |
| Equipos: 2 asignados             |
| Jugadores: 12 inscritos          |
|                                  |
|  +----------------------------+  |
|  |   [play_arrow] INICIAR    |  |  <- FilledButton prominente
|  |       PICHANGA            |  |
|  +----------------------------+  |
|                                  |
+----------------------------------+
```

### Modal de Confirmacion (Mobile - BottomSheet)
```
+----------------------------------+
|    ====                          |  <- Handle
|                                  |
| [sports_soccer] Iniciar Pichanga |
|                                  |
| Estas a punto de iniciar la      |
| jornada. Esta accion no se puede |
| deshacer.                        |
|                                  |
| +------------------------------+ |
| | Fecha: 25/01/2026            | |
| | Hora pactada: 19:00          | |
| | Lugar: Cancha Los Amigos     | |
| | Equipos: 2                   | |
| |   - Naranja: 6 jugadores     | |
| |   - Verde: 6 jugadores       | |
| +------------------------------+ |
|                                  |
| [Cancelar]     [Iniciar Ahora]   |
+----------------------------------+

-- Con Warning (sin equipos) --
+----------------------------------+
|    ====                          |
|                                  |
| [sports_soccer] Iniciar Pichanga |
|                                  |
| +------------------------------+ |
| | [warning] ATENCION           | |
| | No hay equipos asignados.    | |
| | Se recomienda asignarlos     | |
| | antes de iniciar.            | |
| +------------------------------+ |
|                                  |
| +------------------------------+ |
| | Fecha: 25/01/2026            | |
| | Hora pactada: 19:00          | |
| | Lugar: Cancha Los Amigos     | |
| | Inscritos: 12 jugadores      | |
| | Equipos: Sin asignar         | |
| +------------------------------+ |
|                                  |
| [Cancelar]  [Iniciar de Todas]   |
|              [Formas]            |
+----------------------------------+
```

### Modal de Confirmacion (Desktop)
```
+------------------------------------------------+
|                                                |
|        [sports_soccer]                         |
|                                                |
|        Iniciar Pichanga                        |
|        Esta accion es irreversible             |
|                                                |
| +--------------------------------------------+ |
| | Fecha: Sabado 25/01/2026 a las 19:00      | |
| | Lugar: Cancha Los Amigos                  | |
| | Equipos asignados: 2                      | |
| |                                            | |
| | Equipo Naranja: 6 jugadores               | |
| | Equipo Verde: 6 jugadores                 | |
| +--------------------------------------------+ |
|                                                |
|                [Cancelar] [Iniciar Pichanga]   |
+------------------------------------------------+
```

### Estados Visuales Post-Inicio
```
+----------------------------------+
| <- Pichanga 25/01/2026           |
|                                  |
+----------------------------------+
| Estado: [EN JUEGO]               |  <- Chip verde con icono play
| Iniciada: 19:05 (hace 15 min)    |  <- Hora real de inicio
| Lugar: Cancha Los Amigos         |
|                                  |
| [Ver Partidos]  [Finalizar]      |  <- Nuevas acciones disponibles
|                                  |
+----------------------------------+
```

### Indicadores Visuales de Estado
| Estado | Color | Icono | Texto |
|--------|-------|-------|-------|
| cerrada | #FF9800 (naranja) | lock | Cerrada |
| en_juego | #4CAF50 (verde) | play_circle | En Juego |

---

## Notas Tecnicas

### Backend (supabase-expert)

**Nuevos campos en tabla fechas** (sugerido):
- `iniciado_por`: UUID - ID del admin que inicio
- `iniciado_at`: TIMESTAMPTZ - Timestamp real de inicio

**Nueva funcion RPC sugerida**: `iniciar_fecha()`

```
Parametros:
- p_fecha_id: UUID (obligatorio)
```

**Validaciones**:
1. Usuario es admin aprobado o creador de la fecha (RN-001)
2. Fecha existe y estado = 'cerrada' (RN-002)
3. Contar equipos con jugadores para warning (RN-003, info en response)

**Response Success sugerido**:
```json
{
  "success": true,
  "data": {
    "fecha_id": "uuid",
    "fecha_formato": "DD/MM/YYYY HH24:MI",
    "lugar": "string",
    "estado_anterior": "cerrada",
    "estado_nuevo": "en_juego",
    "hora_pactada": "19:00",
    "hora_inicio_real": "19:05",
    "iniciado_por": "uuid",
    "iniciado_por_nombre": "string",
    "iniciado_at": "timestamp",
    "total_equipos": 2,
    "total_jugadores": 12,
    "equipos_detalle": [
      {"color": "Naranja", "jugadores": 6},
      {"color": "Verde", "jugadores": 6}
    ],
    "warning_sin_equipos": false
  },
  "message": "Pichanga iniciada exitosamente. Se notifico a 12 jugadores."
}
```

**Response Error - Hints sugeridos**:
- `no_autenticado` - Usuario no ha iniciado sesion
- `fecha_id_requerido` - Falta parametro fecha_id
- `usuario_no_encontrado` - Usuario no existe en tabla usuarios
- `sin_permisos` - Usuario no es admin aprobado ni creador
- `fecha_no_encontrada` - Fecha no existe
- `estado_invalido` - Fecha no esta en estado 'cerrada'

### Frontend (flutter-expert)

**Nuevo Model sugerido**: `IniciarFechaResponseModel`
- Mapeo snake_case -> camelCase
- Campos segun response del backend

**Nuevo Bloc sugerido**: `IniciarFechaBloc`

**Eventos**:
- `IniciarFechaSubmitEvent(fechaId)`
- `IniciarFechaResetEvent`

**Estados**:
- `IniciarFechaInitial`
- `IniciarFechaLoading`
- `IniciarFechaSuccess(data)`
- `IniciarFechaError(mensaje, hint)`

**UI**:
- Dialog/BottomSheet segun ResponsiveLayout
- Resumen de equipos y jugadores en card
- Warning condicional si no hay equipos
- Boton de confirmacion prominente

---

## Dependencias

### Prerequisitos
- [x] E003-HU-001: Crear fecha (tabla fechas existe)
- [x] E003-HU-002: Inscribirse a fecha (inscripciones existen)
- [x] E003-HU-004: Cerrar inscripciones (estado 'cerrada' existe)
- [x] E003-HU-005: Asignar equipos (equipos asignados existe)

### Impacta
- E003-HU-010: Finalizar Fecha (siguiente estado despues de en_juego)
- E004-HU-001: Iniciar Partido (requiere fecha en estado en_juego)
- E004: Toda la epica de Partidos en Vivo depende de este estado

---

## Casos de Prueba Sugeridos

### Flujo Principal
1. Admin inicia fecha en estado 'cerrada' con equipos - Exito
2. Admin inicia fecha en estado 'cerrada' sin equipos - Exito con warning
3. Jugadores inscritos reciben notificacion - Notificacion creada
4. Hora real de inicio se registra correctamente - Timestamp guardado

### Validaciones
1. Jugador intenta iniciar - Error sin_permisos
2. Admin intenta iniciar fecha 'abierta' - Error estado_invalido
3. Admin intenta iniciar fecha ya 'en_juego' - Error estado_invalido
4. Admin intenta iniciar fecha 'finalizada' - Error estado_invalido

### Edge Cases
1. Fecha sin inscritos se inicia - Funciona pero notificacion a 0 jugadores
2. Organizador (no admin) puede iniciar su propia fecha - Exito
3. Fecha iniciada no puede volver a 'cerrada' - Sin opcion en UI
4. Hora pactada vs hora real se muestran ambas en detalle

---

## IMPLEMENTACION TECNICA

### FASE 2: Backend (Supabase)

**Archivo SQL**: `supabase/sql-cloud/E003-HU-012-iniciar-fecha.sql`

**Implementado**:
- Columnas de auditoria en tabla fechas: `iniciado_por`, `iniciado_at`
- Funcion RPC `iniciar_fecha(p_fecha_id)`:
  - RN-001: Valida permisos (admin aprobado o creador)
  - RN-002: Valida estado = 'cerrada'
  - RN-003: Calcula warning si hay menos de 2 equipos (no bloquea)
  - RN-004: Registra `iniciado_por` e `iniciado_at`
  - RN-005: Crea notificaciones para todos los inscritos
  - Cambia estado a 'en_juego'

**Response Success**:
```json
{
  "success": true,
  "data": {
    "fecha_id": "uuid",
    "fecha_formato": "DD/MM/YYYY HH24:MI",
    "lugar": "string",
    "estado_anterior": "cerrada",
    "estado_nuevo": "en_juego",
    "hora_pactada": "HH24:MI",
    "hora_inicio_real": "HH24:MI",
    "iniciado_por": "uuid",
    "iniciado_por_nombre": "string",
    "iniciado_at": "timestamp",
    "total_equipos": 2,
    "total_jugadores": 12,
    "equipos_detalle": [{"color": "Naranja", "jugadores": 6}],
    "warning_sin_equipos": false,
    "notificaciones_enviadas": 12
  },
  "message": "Pichanga iniciada exitosamente. Se notifico a 12 jugadores."
}
```

**Pendiente**: Usuario debe ejecutar el script SQL en Supabase Cloud.

---

### FASE 4: Frontend (Flutter)

**Archivos creados**:

1. **Model**: `lib/features/fechas/data/models/iniciar_fecha_response_model.dart`
   - `IniciarFechaDataModel`: Datos de fecha iniciada
   - `EquipoDetalleModel`: Resumen de cada equipo
   - `IniciarFechaResponseModel`: Response completo

2. **DataSource**: Metodo `iniciarFecha()` agregado a `fechas_remote_datasource.dart`
   - Llama RPC `iniciar_fecha`
   - Maneja errores con ServerException

3. **Repository**: Metodo `iniciarFecha()` agregado a:
   - `fechas_repository.dart` (interface)
   - `fechas_repository_impl.dart` (implementacion)

4. **BLoC**: `lib/features/fechas/presentation/bloc/iniciar_fecha/`
   - `iniciar_fecha_event.dart`: IniciarFechaSubmitEvent, IniciarFechaResetEvent
   - `iniciar_fecha_state.dart`: Initial, Loading, Success, Error
   - `iniciar_fecha_bloc.dart`: Logica de negocio
   - `iniciar_fecha.dart`: Barrel file

---

### FASE 5: UI (Flutter)

**Archivos creados/modificados**:

1. **Dialog**: `lib/features/fechas/presentation/widgets/iniciar_fecha_dialog.dart`
   - CA-002: Muestra resumen de fecha (lugar, hora, inscritos)
   - CA-003: Warning si no hay equipos asignados
   - Responsive: BottomSheet (mobile) / Dialog (desktop)
   - Botones: "Cancelar" e "Iniciar Pichanga" / "Iniciar de Todas Formas"

2. **Pagina detalle**: `lib/features/fechas/presentation/pages/fecha_detalle_page.dart`
   - CA-001: Boton "Iniciar Pichanga" visible solo si estado = 'cerrada' (admin)
   - Icono play_circle verde en AppBar (mobile)
   - Boton prominente en panel de admin (desktop)
   - CA-005: Boton desaparece cuando estado = 'en_juego'

3. **Widgets barrel**: Actualizado `widgets.dart` para exportar IniciarFechaDialog

**Flujo UI**:
1. Admin ve fecha con estado 'cerrada'
2. Hace click en boton "Iniciar Pichanga"
3. Se muestra dialog con resumen de la fecha
4. Si no hay equipos, muestra warning (pero puede continuar)
5. Confirma y se llama al RPC
6. Exito: snackbar verde, recarga detalle
7. Error: snackbar rojo con mensaje

---

**Creado**: 2026-02-01
**Autor**: Business Analyst
**Implementado**: 2026-02-01
**Estado**: DEV (En Desarrollo)
