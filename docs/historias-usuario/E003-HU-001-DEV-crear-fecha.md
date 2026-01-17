# E003-HU-001 - Crear Fecha

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🔵 En Desarrollo (DEV)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** crear una nueva jornada de pichanga
**Para** que los jugadores puedan inscribirse

## Descripcion
Permite al admin crear una fecha de pichanga definiendo dia, hora, duracion y lugar. El formato de juego y costo se determinan automaticamente segun la duracion seleccionada.

## Criterios de Aceptacion (CA)

### CA-001: Acceso exclusivo admin
- **Dado** que soy administrador aprobado
- **Cuando** accedo al menu de gestion
- **Entonces** veo la opcion "Crear Fecha" disponible
- **Y** si no soy admin, no veo esta opcion

### CA-002: Formulario de creacion
- **Dado** que selecciono "Crear Fecha"
- **Cuando** se abre el formulario
- **Entonces** veo los campos: fecha, hora inicio, duracion, lugar
- **Y** duracion tiene opciones: 1 hora, 2 horas

### CA-003: Formato automatico segun duracion
- **Dado** que selecciono la duracion
- **Cuando** elijo 1 hora
- **Entonces** el sistema muestra: "2 equipos - S/8.00 por jugador"
- **Cuando** elijo 2 horas
- **Entonces** el sistema muestra: "3 equipos con rotacion - S/10.00 por jugador"

### CA-004: Validacion de fecha futura
- **Dado** que ingreso una fecha y hora
- **Cuando** la fecha/hora es anterior al momento actual
- **Entonces** veo error "La fecha debe ser futura"
- **Y** no puedo crear la fecha

### CA-005: Lugar de la cancha
- **Dado** que ingreso el lugar
- **Cuando** completo el campo
- **Entonces** acepta texto libre (nombre de cancha, direccion)
- **Y** el campo es obligatorio

### CA-006: Confirmacion de creacion
- **Dado** que complete todos los datos correctamente
- **Cuando** presiono "Crear Fecha"
- **Entonces** la fecha se crea con estado "abierta"
- **Y** veo mensaje de confirmacion con resumen

### CA-007: Notificacion a jugadores
- **Dado** que se crea la fecha exitosamente
- **Cuando** se confirma la creacion
- **Entonces** todos los jugadores aprobados reciben notificacion
- **Y** la notificacion incluye: fecha, hora, lugar, costo

---

## Reglas de Negocio (RN)

### RN-001: Permisos de Creacion
**Contexto**: Solo administradores pueden crear fechas de pichanga.
**Restriccion**: Usuarios con rol "jugador" no tienen acceso a esta funcionalidad.
**Validacion**: Verificar rol = 'admin' y estado = 'aprobado' antes de permitir acceso.
**Regla calculo**: N/A.
**Caso especial**: Si el unico admin pierde acceso, se debe restaurar manualmente en BD.

### RN-002: Formato segun Duracion
**Contexto**: El formato de juego depende de la duracion alquilada.
**Restriccion**: No se puede elegir formato independiente de la duracion.
**Validacion**: Sistema asigna automaticamente el formato.
**Regla calculo**:
- 1 hora = 2 equipos (partido continuo)
- 2 horas = 3 equipos (rotacion: ganador se queda, perdedor descansa)
**Caso especial**: No se permiten duraciones diferentes a 1 o 2 horas.

### RN-003: Costo por Duracion
**Contexto**: El costo por jugador esta predefinido segun duracion.
**Restriccion**: El admin no puede modificar el costo manualmente.
**Validacion**: Sistema asigna costo automaticamente.
**Regla calculo**:
- 1 hora = S/8.00 por jugador
- 2 horas = S/10.00 por jugador
**Caso especial**: Si hay promociones o cambios de precio, se debe actualizar en configuracion del sistema.

### RN-004: Fecha Futura Obligatoria
**Contexto**: Solo se pueden crear fechas para eventos futuros.
**Restriccion**: La fecha y hora deben ser posteriores al momento de creacion.
**Validacion**: fecha_hora_inicio > NOW().
**Regla calculo**: N/A.
**Caso especial**: Se recomienda minimo 24 horas de anticipacion, pero no es obligatorio.

### RN-005: Unicidad de Fecha
**Contexto**: Evitar fechas duplicadas o superpuestas.
**Restriccion**: No pueden existir dos fechas en el mismo dia y hora.
**Validacion**: Verificar que no exista otra fecha activa (no cancelada) en la misma fecha y hora.
**Regla calculo**: N/A.
**Caso especial**: Si hay cancha con horario diferente el mismo dia, se permite (ej: 8am y 10am).

### RN-006: Estado Inicial
**Contexto**: Toda fecha nueva inicia con estado que permite inscripciones.
**Restriccion**: El estado inicial siempre es "abierta".
**Validacion**: Sistema asigna estado = 'abierta' automaticamente.
**Regla calculo**: N/A.
**Caso especial**: Estados posibles del ciclo de vida: abierta -> cerrada -> en_juego -> finalizada. Alternativo: abierta -> cancelada.

### RN-007: Numero de Equipos
**Contexto**: La cantidad de equipos determina como se organizan los partidos.
**Restriccion**: Esta vinculado directamente a la duracion.
**Validacion**: Sistema calcula automaticamente.
**Regla calculo**:
- 2 equipos: Juegan todo el tiempo uno contra otro
- 3 equipos: Rotacion cada partido (ganador continua, perdedor sale, entra tercero)
**Caso especial**: Con 3 equipos, si un equipo gana 2 partidos consecutivos, descansa obligatoriamente.

---

## Notas Tecnicas
- Tabla: `fechas` con campos: id, fecha_hora_inicio, duracion_horas, lugar, num_equipos, costo_por_jugador, estado, created_by, created_at
- Enum estado_fecha: 'abierta', 'cerrada', 'en_juego', 'finalizada', 'cancelada'
- Trigger para notificaciones push al crear fecha
- Zona horaria: America/Lima (UTC-5)

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-16

### Objetos de Base de Datos Creados

#### Enum `estado_fecha`
Estados del ciclo de vida de una fecha de pichanga:
- `abierta` - Inscripciones abiertas
- `cerrada` - Inscripciones cerradas, esperando inicio
- `en_juego` - Jornada en progreso
- `finalizada` - Jornada completada
- `cancelada` - Jornada cancelada

#### Tabla `fechas`
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id` | UUID (PK) | Identificador unico |
| `fecha_hora_inicio` | TIMESTAMPTZ | Fecha y hora de inicio (UTC) |
| `duracion_horas` | INTEGER | 1 o 2 horas |
| `lugar` | TEXT | Nombre de cancha o direccion |
| `num_equipos` | INTEGER | 2 o 3 (calculado automatico) |
| `costo_por_jugador` | DECIMAL(10,2) | S/8.00 o S/10.00 (calculado automatico) |
| `estado` | estado_fecha | Estado actual de la fecha |
| `created_by` | UUID (FK) | Admin que creo la fecha |
| `created_at` | TIMESTAMPTZ | Fecha de creacion |
| `updated_at` | TIMESTAMPTZ | Ultima actualizacion |

**Indices**:
- `idx_fechas_fecha_hora_inicio` - Busqueda por fecha
- `idx_fechas_estado` - Filtro por estado
- `idx_fechas_created_by` - Fechas por admin
- `idx_fechas_unico_activo` - Unicidad de fechas no canceladas

### Funcion RPC Implementada

**`crear_fecha(p_fecha_hora_inicio TIMESTAMPTZ, p_duracion_horas INTEGER, p_lugar TEXT) -> JSON`**

- **Descripcion**: Crea una nueva fecha de pichanga con calculos automaticos
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007
- **Parametros**:
  - `p_fecha_hora_inicio`: TIMESTAMPTZ - Fecha y hora de inicio (UTC)
  - `p_duracion_horas`: INTEGER - Duracion en horas (1 o 2)
  - `p_lugar`: TEXT - Nombre de cancha o direccion (min 3 caracteres)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "fecha_id": "uuid",
      "fecha_hora_inicio": "2026-01-20T20:00:00Z",
      "fecha_hora_local": "2026-01-20T15:00:00-05:00",
      "fecha_formato": "20/01/2026 15:00",
      "duracion_horas": 2,
      "lugar": "Cancha Los Olivos",
      "num_equipos": 3,
      "costo_por_jugador": 10.00,
      "costo_formato": "S/ 10.00",
      "estado": "abierta",
      "formato_juego": "3 equipos con rotacion",
      "created_by": "uuid",
      "created_by_nombre": "Admin Name"
    },
    "message": "Fecha de pichanga creada exitosamente. Se ha notificado a los jugadores."
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `usuario_no_encontrado` -> Usuario no existe en sistema
  - `sin_permisos` -> Usuario no es admin aprobado
  - `fecha_requerida` -> Fecha/hora no proporcionada
  - `duracion_requerida` -> Duracion no proporcionada
  - `duracion_invalida` -> Duracion no es 1 o 2
  - `lugar_invalido` -> Lugar vacio o muy corto
  - `fecha_pasada` -> Fecha/hora no es futura
  - `fecha_duplicada` -> Ya existe fecha en ese horario

### Politicas RLS

| Operacion | Politica | Condicion |
|-----------|----------|-----------|
| SELECT | Usuarios autenticados pueden ver fechas | authenticated = true |
| INSERT | Admins pueden insertar fechas | rol = 'admin' AND estado = 'aprobado' |
| UPDATE | Admins pueden actualizar fechas | rol = 'admin' AND estado = 'aprobado' |
| DELETE | Admins pueden eliminar fechas | rol = 'admin' AND estado = 'aprobado' |

### Script SQL
- `supabase/sql-cloud/2026-01-16_E003-HU-001_crear_fecha.sql`

### Criterios de Aceptacion Backend

| CA | Estado | Implementacion |
|----|--------|----------------|
| CA-001 | Completado | Validacion rol='admin' AND estado='aprobado' en crear_fecha() |
| CA-002 | Completado | Parametros p_fecha_hora_inicio, p_duracion_horas, p_lugar |
| CA-003 | Completado | Calculo automatico num_equipos y costo_por_jugador segun duracion |
| CA-004 | Completado | Validacion p_fecha_hora_inicio > NOW() |
| CA-005 | Completado | Campo lugar TEXT NOT NULL con CHECK min 3 chars |
| CA-006 | Completado | Estado inicial 'abierta' y response con resumen completo |
| CA-007 | Completado | Notificacion a usuarios aprobados al crear fecha |

### Reglas de Negocio Backend

| RN | Estado | Implementacion |
|----|--------|----------------|
| RN-001 | Completado | Validacion admin aprobado antes de insertar |
| RN-002 | Completado | 1h=2 equipos, 2h=3 equipos (calculo automatico) |
| RN-003 | Completado | 1h=S/8.00, 2h=S/10.00 (calculo automatico) |
| RN-004 | Completado | Validacion fecha_hora_inicio > NOW() |
| RN-005 | Completado | Indice unico + validacion duplicados (excluye canceladas) |
| RN-006 | Completado | DEFAULT 'abierta' en tabla y funcion |
| RN-007 | Completado | num_equipos calculado segun duracion |

---

## FASE 4: Implementacion Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-01-16

### Estructura Clean Architecture

```
lib/features/fechas/
├── data/
│   ├── models/
│   │   ├── fecha_model.dart
│   │   ├── crear_fecha_request_model.dart
│   │   ├── crear_fecha_response_model.dart
│   │   └── models.dart (barrel)
│   ├── datasources/
│   │   └── fechas_remote_datasource.dart
│   └── repositories/
│       └── fechas_repository_impl.dart
├── domain/
│   └── repositories/
│       └── fechas_repository.dart
└── presentation/
    └── bloc/
        └── crear_fecha/
            ├── crear_fecha_bloc.dart
            ├── crear_fecha_event.dart
            ├── crear_fecha_state.dart
            └── crear_fecha.dart (barrel)
```

### Models Implementados

#### `EstadoFecha` (Enum)
Mapeo BD -> Dart:
- `abierta` -> `EstadoFecha.abierta`
- `cerrada` -> `EstadoFecha.cerrada`
- `en_juego` -> `EstadoFecha.enJuego`
- `finalizada` -> `EstadoFecha.finalizada`
- `cancelada` -> `EstadoFecha.cancelada`

#### `FechaModel`
Mapeo snake_case -> camelCase:
| Backend | Dart |
|---------|------|
| `fecha_id` | `fechaId` |
| `fecha_hora_inicio` | `fechaHoraInicio` |
| `fecha_hora_local` | `fechaHoraLocal` |
| `fecha_formato` | `fechaFormato` |
| `duracion_horas` | `duracionHoras` |
| `lugar` | `lugar` |
| `num_equipos` | `numEquipos` |
| `costo_por_jugador` | `costoPorJugador` |
| `costo_formato` | `costoFormato` |
| `estado` | `estado` (EstadoFecha) |
| `formato_juego` | `formatoJuego` |
| `created_by` | `createdBy` |
| `created_by_nombre` | `createdByNombre` |

#### `CrearFechaRequestModel`
Parametros para RPC `crear_fecha`:
- `fechaHoraInicio` -> `p_fecha_hora_inicio` (UTC)
- `duracionHoras` -> `p_duracion_horas`
- `lugar` -> `p_lugar`

Incluye validacion frontend: fecha futura, duracion 1|2, lugar min 3 chars

### Integracion Backend

| Capa | Llamada |
|------|---------|
| UI | `BlocProvider<CrearFechaBloc>` |
| Bloc | `CrearFechaSubmitEvent(fechaHoraInicio, duracionHoras, lugar)` |
| Repository | `crearFecha(CrearFechaRequestModel)` |
| DataSource | `supabase.rpc('crear_fecha', params)` |
| Backend | `crear_fecha(p_fecha_hora_inicio, p_duracion_horas, p_lugar)` |

### Estados del Bloc

| Estado | Descripcion |
|--------|-------------|
| `CrearFechaInitial` | Formulario listo |
| `CrearFechaLoading` | Enviando al servidor |
| `CrearFechaSuccess` | Fecha creada (contiene FechaModel) |
| `CrearFechaError` | Error con message, code, hint |

### Inyeccion de Dependencias (DI)

Registrado en `core/di/injection_container.dart`:
- `CrearFechaBloc` (Factory)
- `FechasRepository` -> `FechasRepositoryImpl` (Singleton)
- `FechasRemoteDataSource` -> `FechasRemoteDataSourceImpl` (Singleton)

### Criterios de Aceptacion Frontend

| CA | Estado | Implementacion |
|----|--------|----------------|
| CA-001 | Pendiente UI | Validacion permisos en UI (verificar rol admin) |
| CA-002 | Completado | Campos en CrearFechaSubmitEvent |
| CA-003 | Completado | CrearFechaRequestModel.formatoJuego, costoPorJugador |
| CA-004 | Completado | Validacion frontend + backend (hint: fecha_pasada) |
| CA-005 | Completado | Validacion lugar min 3 chars |
| CA-006 | Completado | CrearFechaSuccess con FechaModel completo |
| CA-007 | Backend | Notificacion manejada por backend |

### Reglas de Negocio Frontend

| RN | Estado | Implementacion |
|----|--------|----------------|
| RN-001 | Backend | Validacion admin en RPC |
| RN-002 | Completado | numEquipos calculado en request model |
| RN-003 | Completado | costoPorJugador calculado en request model |
| RN-004 | Completado | Validacion fechaHoraInicio > now |
| RN-005 | Backend | Unicidad validada en RPC |
| RN-006 | Backend | Estado inicial en RPC |
| RN-007 | Completado | numEquipos segun duracion |

### Verificacion
- [x] `flutter analyze`: 0 issues
- [x] Mapping snake_case <-> camelCase correcto
- [x] Either pattern en repository
- [x] Zona horaria: fechas en UTC para BD, toLocal() para mostrar

---

## FASE 1: Diseno UX/UI
**Responsable**: ux-ui-expert
**Status**: Completado
**Fecha**: 2026-01-16

### Componentes UI Disenados

**Paginas**:
- `crear_fecha_page.dart`: Formulario de creacion con ResponsiveLayout

**Layout Mobile (< 600px)**:
- Scaffold con AppBar contextual (boton cerrar + boton Crear)
- Formulario vertical full-width
- NO BottomNavigationBar (es pagina de formulario/modal)
- Selectores nativos de fecha/hora
- SegmentedButton para duracion

**Layout Desktop (>= 600px)**:
- DashboardShell con Sidebar y breadcrumbs
- Card centrada con maxWidth: 800px
- Grid de 2 columnas para fecha/hora
- Botones de accion en header del dashboard

### Widgets Implementados

| Widget | Descripcion |
|--------|-------------|
| `_MobileView` | Vista mobile con Scaffold y formulario vertical |
| `_DesktopView` | Vista desktop con DashboardShell y card centrada |
| `_ResumenItem` | Widget auxiliar para mostrar resumen en dialog de exito |

### Interacciones UI

| Componente | Interaccion |
|------------|-------------|
| Selector fecha | DatePicker nativo con locale es_PE |
| Selector hora | TimePicker 24h |
| Duracion | SegmentedButton (1h / 2h) |
| Lugar | TextField con validacion |
| Info formato | Card informativa actualizada en tiempo real |
| Boton Crear | Deshabilitado si formulario invalido, loading durante envio |
| Dialog exito | Muestra resumen completo de la fecha creada |

### Estados Visuales

| Estado | UI |
|--------|-----|
| Initial | Formulario listo, valores por defecto |
| Loading | Boton con CircularProgressIndicator |
| Success | Dialog con icono check verde y resumen |
| Error | SnackBar rojo con mensaje de error |
| Fecha pasada | Borde rojo en selector + mensaje error |

### Routing

- **Ruta**: `/fechas/crear`
- **Nombre**: `crearFecha`
- **Protegida**: Si (requiere autenticacion)
- **Permisos**: Admin (validado en backend)

### Criterios de Aceptacion UI

| CA | Estado | Implementacion UI |
|----|--------|-------------------|
| CA-001 | Completado | Ruta `/fechas/crear`, validacion de permisos en backend |
| CA-002 | Completado | Campos: DatePicker, TimePicker, SegmentedButton, TextField |
| CA-003 | Completado | Card `_buildFormatoInfo` actualiza dinamicamente segun duracion |
| CA-004 | Completado | Validacion visual de fecha futura + mensaje error |
| CA-005 | Completado | TextField lugar con validacion min 3 chars |
| CA-006 | Completado | Dialog `_mostrarExito` con resumen completo |
| CA-007 | Backend | Notificacion manejada por backend |

### Validacion ResponsiveLayout

- [x] ResponsiveLayout: Linea 194
- [x] DashboardShell (desktop): Linea 697
- [x] Scaffold (mobile): Linea 334
- [x] flutter analyze: 0 errores

### Verificacion

- [x] Mobile layout verificado (formulario vertical)
- [x] Desktop layout verificado (card centrada con sidebar)
- [x] Sin overflow warnings
- [x] Design System aplicado (DesignTokens)
- [x] Textos en espanol (Peru)
- [x] Formato de moneda: S/ X.XX

---
