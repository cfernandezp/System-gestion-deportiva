# E003-HU-003 - Ver Inscritos

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Media

## Historia de Usuario
**Como** usuario (admin o jugador)
**Quiero** ver quienes se anotaron a la pichanga
**Para** saber cuantos y quienes asistiran

## Descripcion
Muestra la lista de jugadores inscritos a una fecha, permitiendo a todos ver quien asistira.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a lista de inscritos
- **Dado** que veo una fecha
- **Cuando** selecciono "Ver inscritos" o el contador de jugadores
- **Entonces** veo la lista completa de jugadores anotados

### CA-002: Informacion de cada inscrito
- **Dado** que veo la lista de inscritos
- **Cuando** observo cada entrada
- **Entonces** veo: foto/avatar, apodo, posicion preferida (si tiene)
- **Y** la lista esta ordenada por orden de inscripcion

### CA-003: Contador total
- **Dado** que veo la lista
- **Cuando** hay jugadores inscritos
- **Entonces** veo header con "X jugadores anotados"
- **Y** el numero coincide con la cantidad de la lista

### CA-004: Lista vacia
- **Dado** que no hay inscritos
- **Cuando** veo la lista
- **Entonces** veo mensaje "Aun no hay jugadores anotados"
- **Y** veo icono ilustrativo de lista vacia

### CA-005: Mi inscripcion destacada
- **Dado** que estoy inscrito
- **Cuando** veo la lista
- **Entonces** mi nombre aparece con indicador "(Tu)" al lado
- **Y** opcionalmente fondo diferenciado

### CA-006: Actualizacion en tiempo real
- **Dado** que estoy viendo la lista
- **Cuando** otro jugador se inscribe o cancela
- **Entonces** la lista se actualiza automaticamente
- **Y** veo el cambio sin recargar la pagina

---

## Reglas de Negocio (RN)

### RN-001: Visibilidad de Inscritos
**Contexto**: Todos los usuarios aprobados pueden ver la lista de inscritos.
**Restriccion**: Usuarios no autenticados o no aprobados no ven la lista.
**Validacion**: usuario.estado = 'aprobado'.
**Regla calculo**: N/A.
**Caso especial**: La lista es publica dentro del grupo, no hay restricciones entre jugadores.

### RN-002: Informacion Visible de Inscritos
**Contexto**: Solo se muestra informacion publica de cada inscrito.
**Restriccion**: No se muestra: email, telefono, fecha de nacimiento.
**Validacion**: Query solo selecciona campos permitidos.
**Regla calculo**: Campos visibles: foto_url, apodo, nombre_completo, posicion_preferida.
**Caso especial**: Si no tiene apodo, mostrar nombre_completo.

### RN-003: Orden de Visualizacion
**Contexto**: La lista tiene un orden predeterminado.
**Restriccion**: N/A.
**Validacion**: ORDER BY inscripciones.created_at ASC.
**Regla calculo**: Primero quien se inscribio primero (orden de llegada).
**Caso especial**: Admin puede ver opcion de ordenar por nombre si lo prefiere.

### RN-004: Solo Inscripciones Activas
**Contexto**: Solo se muestran jugadores actualmente inscritos.
**Restriccion**: Inscripciones canceladas no aparecen en la lista.
**Validacion**: inscripcion.estado = 'inscrito'.
**Regla calculo**: N/A.
**Caso especial**: Historial de cancelaciones solo visible para admin (si se implementa).

### RN-005: Actualizacion en Tiempo Real
**Contexto**: La lista debe reflejar el estado actual.
**Restriccion**: Latencia maxima aceptable: 5 segundos.
**Validacion**: Implementar subscripcion a cambios (Supabase Realtime).
**Regla calculo**: N/A.
**Caso especial**: Si falla conexion realtime, permitir pull-to-refresh manual.

---

## Notas Tecnicas
- Query: JOIN inscripciones + usuarios WHERE inscripcion.estado = 'inscrito'
- Supabase Realtime para actualizaciones en vivo
- Componente reutilizable para lista de jugadores (usado en otros contextos)

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16

---
## FASE 2: Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-28

### Funcion RPC Implementada

**`obtener_inscritos_fecha(p_fecha_id UUID) -> JSON`**
- **Descripcion**: Obtiene la lista de jugadores inscritos a una fecha de pichanga
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004
- **Parametros**:
  - `p_fecha_id`: UUID - ID de la fecha de pichanga a consultar
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "fecha_id": "uuid",
      "fecha_info": {
        "fecha_formato": "DD/MM/YYYY",
        "hora_formato": "HH:MI",
        "lugar": "string",
        "estado": "abierta|cerrada|..."
      },
      "total": 5,
      "inscritos": [
        {
          "usuario_id": "uuid",
          "foto_url": "string|null",
          "apodo": "string",
          "nombre_completo": "string",
          "posicion_preferida": "string|null",
          "es_usuario_actual": true|false,
          "inscrito_at": "timestamp",
          "inscrito_formato": "DD/MM/YYYY HH:MI"
        }
      ]
    },
    "message": "5 jugadores anotados"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `fecha_id_requerido` -> No se envio el parametro p_fecha_id
  - `usuario_no_encontrado` -> Usuario autenticado no existe en tabla usuarios
  - `usuario_no_aprobado` -> Usuario no tiene estado 'aprobado'
  - `fecha_no_encontrada` -> La fecha especificada no existe

### Supabase Realtime (RN-005, CA-006)

La tabla `inscripciones` se agrega a la publicacion `supabase_realtime` para permitir actualizaciones en tiempo real.

**Suscripcion en Frontend (Flutter/Dart)**:
```dart
final channel = supabase.channel('inscripciones_fecha_$fechaId');

channel.onPostgresChanges(
  event: PostgresChangeEvent.all,
  schema: 'public',
  table: 'inscripciones',
  filter: PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'fecha_id',
    value: fechaId,
  ),
  callback: (payload) {
    // Recargar lista de inscritos cuando hay cambios
    _cargarInscritos();
  },
).subscribe();
```

**Eventos que disparan actualizacion**:
- INSERT: Nuevo jugador se inscribe
- UPDATE: Cambio de estado (inscrito -> cancelado)
- DELETE: Inscripcion eliminada

### Script SQL
- `supabase/sql-cloud/2026-01-27_E003-HU-003_ver_inscritos.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Lista de inscritos retornada en `data.inscritos`
- [x] **CA-002**: Cada inscrito incluye foto_url, apodo, posicion_preferida, ordenados por created_at ASC
- [x] **CA-003**: Total de inscritos en `data.total`
- [x] **CA-004**: Lista vacia retorna `[]` con message "Aun no hay jugadores anotados"
- [x] **CA-005**: Flag `es_usuario_actual` para identificar la inscripcion del usuario actual
- [x] **CA-006**: Realtime habilitado para tabla inscripciones

### Reglas de Negocio Backend
- [x] **RN-001**: Validacion de usuario autenticado y aprobado
- [x] **RN-002**: Solo campos publicos (usuario_id, foto_url, apodo, nombre_completo, posicion_preferida)
- [x] **RN-003**: ORDER BY inscripciones.created_at ASC
- [x] **RN-004**: WHERE estado = 'inscrito'
- [x] **RN-005**: Supabase Realtime habilitado para tabla inscripciones

---

## FASE 4: Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-01-28

### Estructura Clean Architecture

```
lib/features/fechas/
├── data/
│   ├── models/
│   │   ├── inscrito_fecha_model.dart    # Modelo de inscrito HU-003
│   │   └── inscritos_response_model.dart # Respuesta RPC con total e inscritos
│   ├── datasources/
│   │   └── fechas_remote_datasource.dart # Metodo obtenerInscritosFecha()
│   └── repositories/
│       └── fechas_repository_impl.dart   # Implementacion con Either pattern
├── domain/
│   └── repositories/
│       └── fechas_repository.dart        # Interface con obtenerInscritosFecha()
└── presentation/
    └── bloc/
        └── inscritos/
            ├── inscritos.dart            # Barrel file
            ├── inscritos_bloc.dart       # BLoC con Supabase Realtime
            ├── inscritos_event.dart      # Eventos (Cargar, Realtime, Refresh)
            └── inscritos_state.dart      # Estados (Initial, Loading, Loaded, Error)
```

### Integracion Backend

```
UI -> InscritosBloc -> FechasRepository -> FechasRemoteDataSource -> RPC obtener_inscritos_fecha
```

### Models Implementados

**InscritoFechaModel** (`inscrito_fecha_model.dart`):
- Campos: usuarioId, fotoUrl, apodo, nombreCompleto, posicionPreferida, esUsuarioActual, inscritoAt, inscritoFormato
- Mapeo snake_case (BD) -> camelCase (Dart)
- Propiedad `nombreDisplay` para CA-005 (agrega "(Tu)" si es usuario actual)

**InscritosFechaResponseModel** (`inscritos_response_model.dart`):
- Estructura completa de respuesta RPC
- Incluye FechaInfoModel y InscritosFechaDataModel
- Propiedades de acceso directo: total, inscritos, estaVacia

### Bloc Implementado

**InscritosBloc** (`inscritos_bloc.dart`):
- Eventos:
  - `CargarInscritosEvent(fechaId)` - CA-001: Cargar lista
  - `InscritoAgregadoEvent(fechaId)` - CA-006: Realtime INSERT
  - `InscritoRemovidoEvent(fechaId)` - CA-006: Realtime DELETE/UPDATE
  - `RefrescarInscritosEvent` - RN-005: Pull-to-refresh manual
  - `IniciarRealtimeEvent(fechaId)` - RN-005: Suscripcion Realtime
  - `DetenerRealtimeEvent` - Limpiar suscripcion
  - `ResetInscritosEvent` - Reiniciar estado
- Estados:
  - `InscritosInitial` - Estado inicial
  - `InscritosLoading` - Cargando datos
  - `InscritosLoaded` - Lista cargada con total, inscritos, mensaje
  - `InscritosError` - Error con message, code, hint

### Supabase Realtime (RN-005, CA-006)

Implementado en `InscritosBloc._onIniciarRealtime()`:
- Canal: `inscripciones_fecha_{fechaId}`
- Filtro por `fecha_id` especifico
- Eventos manejados: INSERT, UPDATE, DELETE
- Recarga automatica de lista cuando hay cambios
- Limpieza de canal en `close()` y `_onReset()`

### Inyeccion de Dependencias

Registrado en `injection_container.dart`:
```dart
sl.registerFactory(() => InscritosBloc(repository: sl(), supabase: sl()));
```

### Criterios de Aceptacion Frontend

- [x] **CA-001**: Implementado en `CargarInscritosEvent` -> `InscritosLoaded`
- [x] **CA-002**: `InscritoFechaModel` con foto, apodo, posicion. Lista ordenada por backend
- [x] **CA-003**: `InscritosLoaded.total` y `InscritosLoaded.message`
- [x] **CA-004**: `InscritosLoaded.estaVacia` para mostrar mensaje vacio
- [x] **CA-005**: `InscritoFechaModel.esUsuarioActual` y `nombreDisplay` con "(Tu)"
- [x] **CA-006**: Realtime con `IniciarRealtimeEvent` y eventos de cambio

### Reglas de Negocio Frontend

- [x] **RN-001**: Validacion en backend, error `usuario_no_aprobado` manejado en `InscritosError`
- [x] **RN-002**: Modelo solo expone campos publicos del backend
- [x] **RN-003**: Orden manejado por backend (ORDER BY created_at ASC)
- [x] **RN-004**: Filtrado en backend (WHERE estado = 'inscrito')
- [x] **RN-005**: Supabase Realtime implementado + `RefrescarInscritosEvent` para fallback

### Verificacion

- [x] `flutter analyze`: 0 errores
- [x] Mapping snake_case (BD) -> camelCase (Dart) correcto
- [x] Either pattern en repository
- [x] Realtime con limpieza de recursos

---

## FASE 1: UX/UI
**Responsable**: ux-ui-expert
**Status**: Completado
**Fecha**: 2026-01-28

### Componentes UI Diseñados

**Widget Principal**:
- `inscritos_list_widget.dart`: Widget reutilizable con BLoC propio

**Integracion**:
- Integrado en `fecha_detalle_page.dart` (Mobile y Desktop)

### Estructura del Widget InscritosListWidget

```dart
InscritosListWidget(
  fechaId: String,           // ID de la fecha
  compacto: bool,            // Modo compacto para cards
  habilitarRealtime: bool,   // Activar actualizacion en tiempo real
  expandidoInicial: bool,    // Estado inicial expandido/colapsado
  expandible: bool,          // Si permite expandir/colapsar
  capacidadMaxima: int?,     // Para mostrar indicador de progreso
)
```

### Layout Mobile (< 600px)

```
+----------------------------------+
|     AppBar: Detalle Pichanga     |
+----------------------------------+
| [Card Info Fecha]                |
|                                  |
+----------------------------------+
| [Icon] Jugadores anotados    [5] |
| -------------------------------- |
| [Avatar] Apodo (Tu)    Hace 2h   |
|          Posicion                |
| -------------------------------- |
| [Avatar] Nombre        Hace 1d   |
|          Posicion                |
| -------------------------------- |
| [Avatar] Nombre        15/01     |
+----------------------------------+
| [Boton Anotarme / Ya anotado]    |
+----------------------------------+
```

### Layout Desktop (>= 600px)

```
+------------+----------------------------------------+
| Sidebar    | Detalle de Pichanga    [Editar] [<-]  |
|            |----------------------------------------|
|            | +----------------+ +------------------+|
|            | | Card Info      | | Jugadores       ||
|            | | - Fecha/Hora   | | anotados    [5] ||
|            | | - Lugar        | |-----------------|
|            | | - Formato      | | [Av] Apodo (Tu) ||
|            | | - Costo        | |     Posicion    ||
|            | +----------------+ |-----------------|
|            | +----------------+ | [Av] Nombre     ||
|            | | Card Accion    | |     Posicion    ||
|            | | [Anotarme]     | +------------------+|
|            | +----------------+                     |
+------------+----------------------------------------+
```

### Estados UI Implementados

**Loading State**:
- Skeleton/shimmer con 3 filas placeholder
- Indicador de carga en header

**Loaded State**:
- Header con contador "X jugadores anotados"
- Lista de inscritos con avatar, nombre, posicion
- Fecha de inscripcion relativa (Hace Xh, Hace Xd)

**Empty State (CA-004)**:
- Icono `people_outline` con opacidad reducida
- Mensaje: "Aun no hay jugadores anotados"
- Submensaje: "Se el primero en anotarte"

**Error State**:
- Icono `error_outline` en color error
- Mensaje de error del servidor
- Boton "Reintentar" (RN-005 fallback)

### Criterios de Aceptacion UI

- [x] **CA-001**: Widget accesible desde pagina de detalle de fecha
- [x] **CA-002**: Cada inscrito muestra avatar circular, apodo, posicion preferida
- [x] **CA-003**: Header con contador "X jugadores anotados"
- [x] **CA-004**: Estado vacio con icono y mensaje ilustrativo
- [x] **CA-005**: Usuario actual destacado con "(Tu)" y fondo diferenciado
- [x] **CA-006**: Animacion de borde durante actualizacion realtime

### Reglas de Negocio UI

- [x] **RN-003**: Lista ordenada por fecha de inscripcion (manejado por backend)
- [x] **RN-005**: Pull-to-refresh implementado como fallback de realtime

### Funcionalidad UI

**Responsivo**:
- Mobile: Lista vertical con tiles compactos, expandible/colapsable
- Desktop: Lista expandida siempre visible, grid de 2 columnas

**Estados visuales**:
- Loading: Skeleton shimmer
- Loaded: Lista completa
- Empty: Mensaje ilustrativo
- Error: Mensaje + boton reintentar

**Realtime feedback (CA-006)**:
- Animacion de borde brillante al recibir actualizacion
- Transicion suave con AnimationController

**Design System**:
- DesignTokens para colores, spacing, radios
- Theme-aware (soporta light/dark mode)
- Textos en espanol

### Archivos Modificados/Creados

| Archivo | Accion | Descripcion |
|---------|--------|-------------|
| `presentation/widgets/inscritos_list_widget.dart` | Creado | Widget reutilizable HU-003 |
| `presentation/widgets/widgets.dart` | Modificado | Export del nuevo widget |
| `presentation/pages/fecha_detalle_page.dart` | Modificado | Integracion del widget |

### Verificacion

- [x] ResponsiveLayout: Usa vistas existentes de fecha_detalle_page
- [x] InscritosListWidget usa InscritosBloc propio
- [x] Mobile: Widget expandible con pull-to-refresh
- [x] Desktop: Widget expandido siempre visible
- [x] flutter analyze: 0 errores
- [x] Design System aplicado (DesignTokens)

---

## FASE 5: Validacion QA Tecnica
**Responsable**: qa-testing-expert
**Fecha**: 2026-01-28

### VALIDACION TECNICA APROBADA

#### 1. Dependencias
```bash
$ flutter pub get
Resolving dependencies...
Got dependencies!
```
Resultado: PASS - Sin errores

#### 2. Analisis Estatico
```bash
$ flutter analyze --no-pub
Analyzing gestion_deportiva...
No issues found! (ran in 1.5s)
```
Resultado: PASS - 0 issues

#### 3. Tests
```bash
$ flutter test
```
Resultado: OBSERVACION

Los tests existentes (`widget_test.dart`) presentan errores de overflow en componentes generales del sistema (`dashboard_shell.dart:346`, `home_page.dart:422`), pero estos NO estan relacionados con la HU-003 - Ver Inscritos.

No existen tests especificos para la funcionalidad de Ver Inscritos.

#### 4. Compilacion Web
```bash
$ flutter build web
Compiling lib\main.dart for the Web... 38,1s
Built build\web
```
Resultado: PASS - Compilacion exitosa

### Validacion de Archivos

| Archivo | Ubicacion | Estado |
|---------|-----------|--------|
| Script SQL | `supabase/sql-cloud/2026-01-27_E003-HU-003_ver_inscritos.sql` | EXISTE |
| InscritoFechaModel | `lib/features/fechas/data/models/inscrito_fecha_model.dart` | EXISTE |
| InscritosFechaResponseModel | `lib/features/fechas/data/models/inscritos_response_model.dart` | EXISTE |
| InscritosBloc | `lib/features/fechas/presentation/bloc/inscritos/inscritos_bloc.dart` | EXISTE |
| inscritos_event.dart | `lib/features/fechas/presentation/bloc/inscritos/inscritos_event.dart` | EXISTE |
| inscritos_state.dart | `lib/features/fechas/presentation/bloc/inscritos/inscritos_state.dart` | EXISTE |
| InscritosListWidget | `lib/features/fechas/presentation/widgets/inscritos_list_widget.dart` | EXISTE |
| Integracion DI | `lib/core/di/injection_container.dart` (linea 142) | EXISTE |
| Integracion UI | `fecha_detalle_page.dart` usa InscritosListWidget | EXISTE |

### Cobertura de Criterios de Aceptacion

| CA | Descripcion | Backend | Frontend | UI |
|----|-------------|---------|----------|-----|
| CA-001 | Acceso a lista de inscritos | RPC obtener_inscritos_fecha | CargarInscritosEvent | InscritosListWidget |
| CA-002 | Info: foto, apodo, posicion | JSON con campos publicos | InscritoFechaModel | _InscritoTile con avatar |
| CA-003 | Header con contador | data.total en respuesta | InscritosLoaded.total | _buildHeader() |
| CA-004 | Estado vacio | Lista vacia + mensaje | estaVacia property | _buildEmptyState() |
| CA-005 | Usuario actual "(Tu)" | es_usuario_actual flag | nombreDisplay property | Fondo diferenciado |
| CA-006 | Realtime | supabase_realtime publication | IniciarRealtimeEvent | Animacion de borde |

### Cobertura de Reglas de Negocio

| RN | Descripcion | Implementacion |
|----|-------------|----------------|
| RN-001 | Solo usuarios aprobados | Validacion en RPC + error hint |
| RN-002 | Solo campos publicos | Query SQL selecciona campos especificos |
| RN-003 | Orden por inscripcion | ORDER BY created_at ASC |
| RN-004 | Solo estado 'inscrito' | WHERE estado = 'inscrito' |
| RN-005 | Realtime + fallback | Supabase channel + RefreshIndicator |

### RESUMEN

| Validacion | Estado |
|------------|--------|
| Dependencias | PASS |
| Analisis Estatico | PASS |
| Tests | OBSERVACION (errores en otros componentes) |
| Compilacion Web | PASS |
| Archivos HU-003 | PASS (todos existen) |
| Cobertura CA | PASS (6/6 implementados) |
| Cobertura RN | PASS (5/5 implementados) |

### DECISION

**VALIDACION TECNICA APROBADA**

La HU-003 - Ver Inscritos esta correctamente implementada a nivel tecnico:
- El codigo compila sin errores
- El analisis estatico no reporta issues
- Todos los archivos requeridos existen
- Todos los CA y RN estan cubiertos en las 3 capas (Backend, Frontend, UI)
- La integracion de dependencias esta configurada
- El widget esta integrado en la pagina de detalle de fecha

**Siguiente paso**: Usuario debe validar manualmente los CA en la aplicacion desplegada.

**Nota**: Los errores de overflow en tests son de componentes generales (`dashboard_shell.dart`, `home_page.dart`) y no afectan la funcionalidad de Ver Inscritos. Se recomienda crear una tarea separada para corregir esos problemas de layout.

---
