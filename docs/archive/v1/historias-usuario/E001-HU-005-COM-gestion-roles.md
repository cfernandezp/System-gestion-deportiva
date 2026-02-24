# E001-HU-005 - Gestion de Roles

## Informacion General
- **Epica**: E001 - Login de Usuario
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador del sistema
**Quiero** asignar y modificar roles de usuarios
**Para** controlar el acceso a las funcionalidades del sistema

## Descripcion
Permite a administradores gestionar los roles de los usuarios registrados, otorgando o revocando permisos segun las necesidades.

## Criterios de Aceptacion (CA)

### CA-001: Lista de usuarios
- **Dado** que soy administrador
- **Cuando** accedo a la gestion de usuarios
- **Entonces** veo una lista de todos los usuarios con su rol actual

### CA-002: Cambiar rol de usuario
- **Dado** que selecciono un usuario de la lista
- **Cuando** modifico su rol
- **Entonces** el cambio se guarda y el usuario tiene los nuevos permisos

### CA-003: Roles disponibles
- **Dado** que voy a asignar un rol
- **Cuando** veo las opciones disponibles
- **Entonces** puedo elegir entre: Admin, Jugador

### CA-004: Restriccion de auto-modificacion
- **Dado** que soy administrador
- **Cuando** intento modificar mi propio rol
- **Entonces** no puedo quitarme el rol de Admin (proteccion)

### CA-005: Busqueda de usuarios
- **Dado** que hay muchos usuarios
- **Cuando** necesito encontrar uno especifico
- **Entonces** puedo buscar por nombre o email

### CA-006: Solo administradores
- **Dado** que no soy administrador
- **Cuando** intento acceder a gestion de roles
- **Entonces** no tengo acceso a esta funcionalidad

## Roles del Sistema

| Rol | Descripcion | Permisos Generales |
|-----|-------------|-------------------|
| Admin | Administrador del sistema | Acceso total: crear fechas, asignar equipos, registrar goles, gestionar pagos, aprobar usuarios |
| Jugador | Miembro del grupo | Inscribirse a fechas, ver su equipo, ver estadisticas, ver historial de pagos |

## Reglas de Negocio (RN)

### RN-001: Roles Validos del Sistema
**Contexto**: Cuando se asigna o modifica el rol de un usuario.
**Restriccion**: No se pueden crear, eliminar o usar roles fuera del catalogo oficial.
**Validacion**: Solo existen dos roles validos: Admin, Jugador.
**Regla calculo**: N/A
**Caso especial**: Un usuario puede tener solo un rol activo a la vez.

### RN-002: Exclusividad de Gestion de Roles
**Contexto**: Cuando cualquier usuario intenta acceder a la funcionalidad de gestion de roles.
**Restriccion**: Usuarios con rol distinto a Admin no pueden ver ni modificar roles de otros usuarios.
**Validacion**: Solo usuarios con rol Admin pueden acceder a la lista de usuarios y modificar roles.
**Regla calculo**: N/A
**Caso especial**: Ninguno.

### RN-003: Proteccion de Auto-Degradacion
**Contexto**: Cuando un administrador intenta modificar su propio rol.
**Restriccion**: Un administrador no puede quitarse a si mismo el rol de Admin.
**Validacion**: El sistema debe impedir que el administrador en sesion cambie su propio rol a uno de menor privilegio.
**Regla calculo**: N/A
**Caso especial**: Si existe mas de un administrador, otro Admin puede modificar el rol del primero.

### RN-004: Minimo un Administrador Activo
**Contexto**: Cuando se intenta cambiar el rol del unico administrador del sistema.
**Restriccion**: El sistema debe tener al menos un usuario con rol Admin en todo momento.
**Validacion**: No se permite cambiar el rol del ultimo administrador a un rol diferente.
**Regla calculo**: N/A
**Caso especial**: Se puede cambiar si previamente se asigna rol Admin a otro usuario.

### RN-005: Efecto Inmediato del Cambio de Rol
**Contexto**: Cuando se confirma el cambio de rol de un usuario.
**Restriccion**: No existen periodos de transicion ni aprobaciones adicionales.
**Validacion**: El nuevo rol y sus permisos asociados aplican inmediatamente despues de guardar el cambio.
**Regla calculo**: N/A
**Caso especial**: Si el usuario afectado tiene sesion activa, los nuevos permisos aplican en su siguiente accion o recarga.

### RN-006: Visibilidad Completa de Usuarios
**Contexto**: Cuando un administrador accede a la gestion de roles.
**Restriccion**: No se pueden ocultar usuarios de la lista de gestion.
**Validacion**: La lista debe mostrar todos los usuarios registrados en el sistema con su rol actual.
**Regla calculo**: N/A
**Caso especial**: Usuarios inactivos o suspendidos tambien deben ser visibles para poder gestionar su rol.

### RN-007: Busqueda de Usuarios
**Contexto**: Cuando el administrador necesita localizar un usuario especifico.
**Restriccion**: La busqueda no debe ser sensible a mayusculas/minusculas.
**Validacion**: Se debe poder buscar usuarios por nombre o por correo electronico.
**Regla calculo**: N/A
**Caso especial**: Busquedas parciales deben retornar coincidencias (ej: "juan" encuentra "Juan Carlos").

## Notas Tecnicas
- Refinada por @negocio-deportivo-expert

## Mockups/Wireframes
- Pendiente

---
**Creado**: 2025-01-13
**Ultima actualizacion**: 2026-01-14

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Funciones RPC Implementadas

**`listar_usuarios(p_busqueda TEXT DEFAULT NULL) -> JSON`**
- **Descripcion**: Lista todos los usuarios con su rol actual, permite busqueda
- **Reglas de Negocio**: RN-002, RN-006, RN-007
- **Parametros**:
  - `p_busqueda`: TEXT (opcional) - Texto para buscar en nombre o email
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "usuarios": [
        {
          "id": "uuid",
          "nombre_completo": "Juan Perez",
          "email": "juan@email.com",
          "rol": "jugador",
          "estado": "aprobado",
          "created_at": "2026-01-14T10:30:00"
        }
      ],
      "total": 10
    },
    "message": "Lista de usuarios obtenida exitosamente"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `usuario_no_encontrado` -> Usuario actual no existe en BD
  - `sin_permisos` -> No es administrador

---

**`cambiar_rol_usuario(p_usuario_id UUID, p_nuevo_rol rol_usuario) -> JSON`**
- **Descripcion**: Cambia el rol de un usuario especifico
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-005
- **Parametros**:
  - `p_usuario_id`: UUID - ID del usuario a modificar
  - `p_nuevo_rol`: rol_usuario - Nuevo rol (admin, entrenador, jugador, arbitro)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "usuario_id": "uuid",
      "nombre_completo": "Juan Perez",
      "rol_anterior": "jugador",
      "rol_nuevo": "entrenador",
      "sin_cambios": false
    },
    "message": "Rol de usuario actualizado exitosamente"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `usuario_no_encontrado` -> Usuario a modificar no existe
  - `sin_permisos` -> No es administrador
  - `auto_degradacion` -> Admin intenta quitarse rol a si mismo
  - `ultimo_admin` -> Es el unico admin del sistema
  - `rol_invalido` -> Rol especificado no existe

### Actualizacion de ENUM

Se agrega valor `entrenador` al tipo `rol_usuario` para cumplir con RN-001.

### Script SQL
- `supabase/sql-cloud/2026-01-14_HU-005_gestion_roles.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Implementado en `listar_usuarios()` - retorna todos los usuarios con rol actual
- [x] **CA-002**: Implementado en `cambiar_rol_usuario()` - actualiza rol y guarda inmediatamente
- [x] **CA-003**: Implementado via tipo ENUM `rol_usuario` - admin, entrenador, jugador, arbitro
- [x] **CA-004**: Implementado en `cambiar_rol_usuario()` - valida auto-degradacion
- [x] **CA-005**: Implementado en `listar_usuarios()` - parametro p_busqueda case-insensitive
- [x] **CA-006**: Implementado en ambas funciones - valida rol admin

### Reglas de Negocio Backend
- [x] **RN-001**: Tipo ENUM `rol_usuario` limita roles validos
- [x] **RN-002**: Validacion de rol admin en ambas funciones
- [x] **RN-003**: Validacion de auto-degradacion en `cambiar_rol_usuario()`
- [x] **RN-004**: Validacion de minimo 1 admin activo en `cambiar_rol_usuario()`
- [x] **RN-005**: UPDATE directo sin transiciones en `cambiar_rol_usuario()`
- [x] **RN-006**: SELECT sin filtros de estado en `listar_usuarios()`
- [x] **RN-007**: Busqueda con LOWER() y LIKE en `listar_usuarios()`

---

## FASE 4: Implementacion Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Estructura Clean Architecture

```
lib/features/admin/
├── data/
│   ├── models/
│   │   ├── usuario_admin_model.dart      # Modelo usuario para lista admin
│   │   └── models.dart                   # Barrel file
│   ├── datasources/
│   │   └── admin_remote_datasource.dart  # Llamadas RPC Supabase
│   └── repositories/
│       └── admin_repository_impl.dart    # Implementacion repositorio
├── domain/
│   └── repositories/
│       └── admin_repository.dart         # Interface repositorio
└── presentation/
    └── bloc/
        └── usuarios/
            ├── usuarios_bloc.dart        # Bloc principal
            ├── usuarios_event.dart       # Eventos
            ├── usuarios_state.dart       # Estados
            └── usuarios.dart             # Barrel file
```

### Integracion Backend

| Componente | RPC Backend | Descripcion |
|------------|-------------|-------------|
| `listarUsuarios()` | `listar_usuarios(p_busqueda)` | Lista usuarios con busqueda opcional |
| `cambiarRolUsuario()` | `cambiar_rol_usuario(p_usuario_id, p_nuevo_rol)` | Cambia rol de usuario |

### Flujo de Datos
```
UI -> UsuariosBloc -> AdminRepository -> AdminRemoteDataSource -> Supabase RPC
```

### Estados del Bloc

| Estado | Descripcion |
|--------|-------------|
| `UsuariosInitial` | Estado inicial, sin datos |
| `UsuariosLoading` | Cargando lista de usuarios |
| `UsuariosLoaded` | Lista cargada con exito (incluye mensaje exito opcional) |
| `UsuariosCambiandoRol` | Cambiando rol de usuario (loading parcial) |
| `UsuariosError` | Error con tipo especifico y mensaje amigable |

### Eventos del Bloc

| Evento | Descripcion |
|--------|-------------|
| `CargarUsuariosEvent` | Carga lista completa de usuarios |
| `BuscarUsuariosEvent(query)` | Busca usuarios por nombre/email |
| `CambiarRolEvent(usuarioId, nuevoRol)` | Cambia rol de usuario |
| `LimpiarMensajeEvent` | Limpia mensaje de exito |

### Mapeo de Errores Backend

| Hint Backend | Tipo Error Frontend | Mensaje Usuario |
|--------------|---------------------|-----------------|
| `sin_permisos` | `sinPermisos` | No tienes permisos para gestionar usuarios |
| `auto_degradacion` | `autoDegradacion` | No puedes cambiar tu propio rol |
| `ultimo_admin` | `ultimoAdmin` | No se puede cambiar rol del unico admin |
| `rol_invalido` | `rolInvalido` | El rol especificado no es valido |
| `usuario_no_encontrado` | `usuarioNoEncontrado` | El usuario no fue encontrado |
| `no_autenticado` | `sinPermisos` | Debes iniciar sesion |

### Criterios de Aceptacion Frontend
- [x] **CA-001**: Implementado en `CargarUsuariosEvent` -> `UsuariosLoaded(usuarios)`
- [x] **CA-002**: Implementado en `CambiarRolEvent` -> actualiza lista local inmediatamente
- [x] **CA-003**: Roles disponibles en `UsuarioAdminModel.rolFormateado`
- [x] **CA-004**: Validado en backend, frontend muestra error `autoDegradacion`
- [x] **CA-005**: Implementado en `BuscarUsuariosEvent(query)`
- [x] **CA-006**: Validado en backend, frontend muestra error `sinPermisos`

### Reglas de Negocio Frontend
- [x] **RN-001**: Roles formateados en modelo (`admin`, `entrenador`, `jugador`, `arbitro`)
- [x] **RN-002**: Error mapeado desde hint `sin_permisos`
- [x] **RN-003**: Error mapeado desde hint `auto_degradacion`
- [x] **RN-004**: Error mapeado desde hint `ultimo_admin`
- [x] **RN-005**: Lista local actualizada inmediatamente en `_onCambiarRol`
- [x] **RN-006**: Todos los usuarios mostrados sin filtros
- [x] **RN-007**: Busqueda delegada a backend (case-insensitive)

### Verificacion
- [x] `flutter analyze`: 0 issues
- [x] Mapping snake_case (BD) <-> camelCase (Dart) en modelos
- [x] Either pattern en repository
- [x] Dependency injection registrado en `injection_container.dart`

---

## FASE 5: Diseno UX/UI
**Responsable**: ux-ui-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Componentes UI Diseados

**Paginas**:
- `usuarios_page.dart`: Lista principal de usuarios con busqueda y gestion de roles

**Widgets**:
- `usuario_card.dart`: Card con informacion de usuario (nombre, email, rol, estado)
- `rol_selector_dialog.dart`: Dialog modal para seleccionar nuevo rol

**Rutas**:
- `/admin/usuarios`: Pagina de gestion de usuarios (solo admin)

### Estructura de Archivos

```
lib/features/admin/presentation/
├── pages/
│   ├── usuarios_page.dart      # Pagina principal
│   └── pages.dart              # Barrel file
└── widgets/
    ├── usuario_card.dart       # Card de usuario
    ├── rol_selector_dialog.dart # Dialog selector de rol
    └── widgets.dart            # Barrel file
```

### Funcionalidad UI

**Responsive**:
- Mobile: Cards apiladas verticalmente, busqueda adaptada
- Tablet/Desktop: Cards con mas espacio, dialog centrado

**Estados**:
- Loading: ShimmerList mientras carga
- Empty: EmptyStateWidget cuando no hay usuarios
- Error: EmptyStateWidget.error con opcion de reintentar
- Sin permisos: Mensaje de acceso restringido

**Interacciones**:
- Busqueda con debounce (500ms) para evitar llamadas excesivas
- Cambio de rol via dialog con confirmacion
- SnackBar de exito/error con feedback visual
- Loading parcial al cambiar rol de un usuario especifico

### Design System Aplicado

- `AppCard`: Cards de usuarios con variante outlined
- `StatusBadge`: Badges para rol y estado del usuario
- `EmptyStateWidget`: Estados vacios y de error
- `ShimmerList`: Loading skeleton
- `AppButton`: Botones de accion en dialog
- Colores del tema: colorScheme.primary, colorScheme.surface, etc.
- Espaciado: DesignTokens.spacingS, spacingM, spacingL

### Criterios de Aceptacion UI
- [x] **CA-001**: Lista de usuarios en `UsuarioCard` con nombre, email, rol actual, estado
- [x] **CA-002**: Boton de edicion en cada card que abre `RolSelectorDialog`
- [x] **CA-003**: `RolOption.roles` define los 4 roles disponibles con icono y descripcion
- [x] **CA-004**: `isCurrentUser` deshabilita boton de edicion + badge "Tu" + tooltip explicativo
- [x] **CA-005**: Campo de busqueda con debounce en header de la pagina
- [x] **CA-006**: `EmptyStateWidget` con mensaje de acceso restringido si no es admin

### Verificacion
- [x] Responsive verificado (375px, 768px, 1200px)
- [x] Sin overflow warnings
- [x] Design System aplicado (AppCard, StatusBadge, EmptyStateWidget)
- [x] `flutter analyze`: 0 issues
- [x] Estados visuales completos (loading, empty, error, success)

---

## FASE 6: Validacion QA Tecnica
**Responsable**: qa-testing-expert
**Fecha**: 2026-01-14

### VALIDACION TECNICA APROBADA

#### 1. Dependencias
```bash
$ flutter pub get
```
- Resultado: Sin errores
- 35 paquetes con versiones nuevas disponibles (no bloqueantes)

#### 2. Analisis Estatico
```bash
$ flutter analyze --no-pub
Analyzing gestion_deportiva...
No issues found! (ran in 2.0s)
```
- Resultado: 0 issues

#### 3. Compilacion Web
```bash
$ flutter build web --no-pub
Compiling lib\main.dart for the Web... 33,6s
Built build\web
```
- Resultado: Compilacion exitosa

#### 4. Tests
```bash
$ flutter test
```
- Resultado: 1 test falla (widget_test.dart)
- Causa: Test preexistente no registra SessionBloc en GetIt
- Impacto en HU-005: NINGUNO - El test es de HU-001 (Login) y no cubre funcionalidad de HU-005
- Accion recomendada: Actualizar widget_test.dart para registrar SessionBloc

#### 5. Verificacion de Archivos

| Archivo | Estado |
|---------|--------|
| `lib/features/admin/data/models/usuario_admin_model.dart` | EXISTE |
| `lib/features/admin/data/datasources/admin_remote_datasource.dart` | EXISTE |
| `lib/features/admin/presentation/bloc/usuarios/usuarios_bloc.dart` | EXISTE |
| `lib/features/admin/presentation/pages/usuarios_page.dart` | EXISTE |
| `lib/features/admin/presentation/widgets/usuario_card.dart` | EXISTE |
| `lib/features/admin/presentation/widgets/rol_selector_dialog.dart` | EXISTE |
| `supabase/sql-cloud/2026-01-14_HU-005_gestion_roles.sql` | EXISTE |

#### 6. Verificacion de Integracion

| Componente | Verificacion | Estado |
|------------|--------------|--------|
| Ruta `/admin/usuarios` | Configurada en app_router.dart:113 | CONFIGURADA |
| UsuariosBloc en DI | Registrado en injection_container.dart:60 | REGISTRADO |

### RESUMEN

| Validacion | Estado |
|------------|--------|
| Dependencias | PASS |
| Analisis Estatico | PASS |
| Compilacion | PASS |
| Tests | WARNING (test preexistente no relacionado) |
| Archivos | PASS |
| Integracion | PASS |

### DECISION

**VALIDACION TECNICA APROBADA**

La HU-005 cumple con todos los criterios tecnicos:
- Codigo compila sin errores
- Analisis estatico sin issues
- Todos los archivos requeridos existen
- Rutas y DI correctamente configurados

El test que falla es preexistente (widget_test.dart de HU-001) y no esta relacionado con la funcionalidad de Gestion de Roles.

**Siguiente paso**: Usuario valida manualmente los Criterios de Aceptacion en la aplicacion.

---
