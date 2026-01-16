# E002-HU-003 - Lista de Jugadores

## Informacion General
- **Epica**: E002 - Gestion de Jugadores
- **Estado**: 🟢 Completada (COM)
- **Prioridad**: Media

## Historia de Usuario
**Como** jugador registrado
**Quiero** ver la lista de miembros del grupo
**Para** conocer quienes forman parte del grupo de pichangas

## Descripcion
Muestra la lista de todos los jugadores aprobados del grupo.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a lista
- **Dado** que estoy autenticado
- **Cuando** accedo a "Jugadores" o "Miembros"
- **Entonces** veo la lista de jugadores del grupo

### CA-002: Informacion mostrada
- **Dado** que veo la lista de jugadores
- **Cuando** observo cada entrada
- **Entonces** veo: foto (o avatar), apodo y posicion preferida

### CA-003: Buscar jugador
- **Dado** que hay muchos jugadores
- **Cuando** busco por nombre o apodo
- **Entonces** la lista se filtra mostrando coincidencias

### CA-004: Ordenamiento
- **Dado** que veo la lista
- **Cuando** quiero ordenar
- **Entonces** puedo ordenar por nombre o por fecha de ingreso

### CA-005: Solo jugadores aprobados
- **Dado** que veo la lista
- **Cuando** hay usuarios pendientes de aprobacion
- **Entonces** NO aparecen en esta lista (solo aprobados)

## 📐 Reglas de Negocio (RN)

### RN-001: Visibilidad exclusiva de jugadores aprobados
**Contexto**: Al mostrar la lista de miembros del grupo
**Restriccion**: No mostrar usuarios con estado pendiente de aprobacion, rechazados o inactivos
**Validacion**: Solo aparecen jugadores cuyo estado sea "aprobado" en el grupo
**Caso especial**: Si no hay jugadores aprobados, mostrar mensaje indicando lista vacia

### RN-002: Informacion publica del jugador en lista
**Contexto**: Al renderizar cada entrada de la lista de jugadores
**Restriccion**: No mostrar informacion sensible (email, telefono, datos privados)
**Validacion**: Cada entrada muestra unicamente: foto o avatar por defecto, apodo del jugador, posicion preferida (o "Sin definir" si no la tiene)
**Caso especial**: Si el jugador no tiene foto, mostrar avatar generico; si no tiene posicion, mostrar "Sin definir"

### RN-003: Busqueda por identificacion del jugador
**Contexto**: Cuando el usuario utiliza el campo de busqueda
**Restriccion**: La busqueda solo aplica sobre nombre completo y apodo, no sobre otros campos
**Validacion**: El filtro debe ser insensible a mayusculas/minusculas y encontrar coincidencias parciales
**Caso especial**: Si la busqueda no retorna resultados, mostrar mensaje "No se encontraron jugadores"

### RN-004: Ordenamiento de la lista
**Contexto**: Cuando el usuario selecciona criterio de ordenamiento
**Restriccion**: Solo se permite ordenar por nombre (alfabetico) o por fecha de ingreso al grupo
**Validacion**: El ordenamiento por defecto es por nombre alfabetico ascendente (A-Z)
**Caso especial**: El usuario puede alternar entre ascendente y descendente para cada criterio

### RN-005: Acceso restringido a usuarios autenticados
**Contexto**: Al intentar acceder a la lista de jugadores
**Restriccion**: Usuarios no autenticados no pueden ver la lista de miembros
**Validacion**: Solo jugadores autenticados y pertenecientes al grupo pueden acceder a esta funcionalidad
**Caso especial**: Si la sesion expira, redirigir al login

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

---

## FASE 2: Backend (Supabase)

### Implementado por: @supabase-expert
### Fecha: 2026-01-16

### Funcion RPC: `listar_jugadores`

**Archivo**: `supabase/sql-cloud/2026-01-16_E002-HU-003_listar_jugadores.sql`

**Parametros**:
- `p_busqueda` (TEXT): Texto para filtrar por nombre/apodo (RN-003)
- `p_orden_campo` (TEXT): 'nombre' | 'fecha_ingreso' (RN-004)
- `p_orden_direccion` (TEXT): 'asc' | 'desc' (RN-004)

**Respuesta exitosa**:
```json
{
  "success": true,
  "data": {
    "jugadores": [
      {
        "jugador_id": "uuid",
        "nombre_completo": "Juan Perez",
        "apodo": "Juancho",
        "posicion_preferida": "delantero",
        "foto_url": null,
        "fecha_ingreso": "2026-01-15T10:00:00",
        "fecha_ingreso_formato": "15 de Enero de 2026"
      }
    ],
    "total": 1,
    "filtros": {
      "busqueda": null,
      "orden_campo": "nombre",
      "orden_direccion": "asc"
    }
  },
  "message": "Se encontro 1 jugador"
}
```

**Cumplimiento de CA/RN**:
- CA-001: Acceso via RPC autenticada
- CA-002: Retorna foto, apodo, posicion
- CA-003: Busqueda por p_busqueda
- CA-004: Ordenamiento por p_orden_campo/p_orden_direccion
- CA-005: Filtro `estado = 'aprobado'`
- RN-001: Solo aprobados
- RN-002: Solo info publica (no email/telefono)
- RN-003: Busqueda case-insensitive con LIKE
- RN-004: Orden por nombre (default) o fecha
- RN-005: Requiere auth.uid()

---

## FASE 4: Frontend (Flutter)

### Implementado por: @flutter-expert
### Fecha: 2026-01-16

### Estructura Clean Architecture

```
lib/features/jugadores/
├── data/
│   ├── models/
│   │   ├── jugador_model.dart      # JugadorModel, FiltrosJugadores, enums
│   │   └── models.dart             # Barrel
│   ├── datasources/
│   │   └── jugadores_remote_datasource.dart  # RPC listar_jugadores
│   └── repositories/
│       └── jugadores_repository_impl.dart
├── domain/
│   └── repositories/
│       └── jugadores_repository.dart  # Interface
└── presentation/
    ├── bloc/jugadores/
    │   ├── jugadores_bloc.dart
    │   ├── jugadores_event.dart
    │   ├── jugadores_state.dart
    │   └── jugadores.dart          # Barrel
    ├── pages/
    │   ├── jugadores_page.dart     # Mobile + Desktop views
    │   └── pages.dart              # Barrel
    └── widgets/
        ├── jugador_avatar.dart
        ├── jugador_card.dart
        ├── jugadores_empty_state.dart
        ├── jugadores_search_bar.dart
        ├── jugadores_sort_button.dart
        └── widgets.dart            # Barrel
```

### BLoC Events
- `CargarJugadoresEvent`: Carga inicial (CA-001)
- `RefrescarJugadoresEvent`: Pull to refresh
- `BuscarJugadoresEvent`: Busqueda (CA-003)
- `LimpiarBusquedaEvent`: Limpiar filtro
- `CambiarOrdenEvent`: Cambiar ordenamiento (CA-004)
- `AlternarDireccionOrdenEvent`: Alternar asc/desc

### BLoC States
- `JugadoresInitial`: Estado inicial
- `JugadoresLoading`: Cargando
- `JugadoresLoaded`: Lista cargada con jugadores, filtros, total
- `JugadoresRefreshing`: Refrescando (mantiene datos)
- `JugadoresBuscando`: Buscando (mantiene datos)
- `JugadoresVacio`: Sin resultados (RN-001, RN-003)
- `JugadoresError`: Error con mensaje

### Dependencias registradas
- `injection_container.dart`: JugadoresBloc, JugadoresRepository, JugadoresRemoteDataSource

---

## FASE 1: UX/UI

### Implementado por: @ux-ui-expert
### Fecha: 2026-01-16

### Vista Mobile (App Style)
- AppBar con titulo "Jugadores"
- Barra de busqueda (CA-003)
- Contador de jugadores + boton de ordenamiento (CA-004)
- Lista con `RefreshIndicator` (pull to refresh)
- `JugadorCard` con avatar, apodo, nombre, posicion (CA-002)
- `AppBottomNavBar` con item "Jugadores" (CA-001)

### Vista Desktop (Dashboard Style)
- `DashboardShell` con sidebar y breadcrumbs
- Barra de busqueda expandida
- Grid responsive (1-3 columnas segun ancho)
- `JugadorCard` igual que mobile

### Widgets Creados
- `JugadorAvatar`: Avatar con foto o iniciales (RN-002)
- `JugadorCard`: Card con info publica (CA-002, RN-002)
- `JugadoresSearchBar`: Busqueda con debounce (CA-003, RN-003)
- `JugadoresSortButton`: Selector de ordenamiento (CA-004, RN-004)
- `JugadoresEmptyState`: Estado vacio (RN-001, RN-003)

### Navegacion Actualizada
- `app_bottom_nav_bar.dart`: Agregado item "Jugadores" (index 2)
- `dashboard_shell.dart`: Agregado item "Jugadores" en sidebar
- `app_router.dart`: Ruta `/jugadores` con BlocProvider

### Responsive
- Mobile: Lista vertical, cards de ancho completo
- Desktop: Grid 1-3 columnas, cards 400px minimo

---

## FASE 5: QA

### Validado por: @qa-testing-expert
### Fecha: 2026-01-16

### Validacion Tecnica
- [x] `flutter pub get`: OK
- [x] `flutter analyze`: 0 errores, 0 warnings
- [x] Estructura Clean Architecture correcta
- [x] Dependencias registradas en injection_container
- [x] Rutas configuradas en app_router
- [x] Navegacion actualizada (BottomNav + Sidebar)

### Validacion de CA/RN

| Criterio | Estado | Notas |
|----------|--------|-------|
| CA-001 | OK | Acceso via "/jugadores", item en navegacion |
| CA-002 | OK | JugadorCard muestra foto/avatar, apodo, posicion |
| CA-003 | OK | JugadoresSearchBar con debounce, busqueda en backend |
| CA-004 | OK | JugadoresSortButton con nombre/fecha, asc/desc |
| CA-005 | OK | RPC filtra estado='aprobado' |
| RN-001 | OK | Solo aprobados via SQL |
| RN-002 | OK | No se expone email/telefono |
| RN-003 | OK | Busqueda case-insensitive con LIKE |
| RN-004 | OK | Orden default: nombre asc |
| RN-005 | OK | Guard de autenticacion en router + RPC |

### Resultado: APROBADO

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-15
**Implementado**: 2026-01-16
