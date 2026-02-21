# E002-HU-004: Nombrar y Quitar Co-Administradores

## INFORMACION
- **Codigo:** E002-HU-004
- **Epica:** E002 - Grupos Deportivos
- **Titulo:** Nombrar y Quitar Co-Administradores
- **Story Points:** 3 pts
- **Estado:** Completada
- **Prioridad:** Media
- **Fecha:** 2026-02-20

## HISTORIA
**Como** admin del grupo
**Quiero** nombrar o quitar co-administradores entre los miembros del grupo
**Para** delegar la gestion del grupo a personas de confianza

### Criterios de Aceptacion

#### CA-001: Promover jugador a co-admin
- [x] **DADO** que soy el admin creador del grupo y estoy viendo la lista de miembros
- [x] **CUANDO** selecciono a un jugador y elijo la opcion de promover a co-admin
- [x] **ENTONCES** el sistema me pide confirmacion y, al confirmar, el jugador pasa a tener rol de co-admin con permisos de gestion del grupo (excepto eliminar el grupo)

#### CA-002: Degradar co-admin a jugador
- [x] **DADO** que soy el admin creador del grupo y hay co-admins en el grupo
- [x] **CUANDO** selecciono a un co-admin y elijo la opcion de quitar co-administracion
- [x] **ENTONCES** el sistema me pide confirmacion y, al confirmar, el co-admin vuelve a tener rol de jugador regular

#### CA-003: Solo el admin creador puede gestionar co-admins
- [x] **DADO** que soy co-admin del grupo
- [x] **CUANDO** veo la lista de miembros
- [x] **ENTONCES** NO tengo la opcion de promover ni degradar a ningun miembro, ya que esta accion es exclusiva del admin creador

#### CA-004: Limite de co-administradores
- [x] **DADO** que el grupo ya tiene el numero maximo de co-admins permitidos segun su plan (1 en Gratis, 3 en Plan 5, 6 en Plan 10, 9 en Plan 15/20)
- [x] **CUANDO** intento promover a otro jugador como co-admin
- [x] **ENTONCES** el sistema me informa que se ha alcanzado el limite de co-administradores para este grupo

#### CA-005: Permisos del co-admin
- [x] **DADO** que un miembro ha sido promovido a co-admin
- [x] **CUANDO** accede al grupo
- [x] **ENTONCES** tiene los mismos permisos que el admin (editar grupo, gestionar miembros, crear fechas) EXCEPTO eliminar el grupo y gestionar co-admins

## Reglas de Negocio (RN)

### RN-001: Exclusividad del admin creador para gestionar co-admins
**Contexto**: Cuando se intenta promover o degradar a un miembro en la gestion de co-administradores.
**Restriccion**: Los co-admins NO pueden nombrar ni quitar co-admins bajo ninguna circunstancia. Esta accion es exclusiva del administrador creador del grupo.
**Validacion**: Solo el usuario con rol de administrador creador del grupo puede acceder a las opciones de promover jugador a co-admin o degradar co-admin a jugador.
**Caso especial**: Ninguno.

### RN-002: Limite maximo de co-administradores por grupo
**Contexto**: Cuando el admin intenta promover a un nuevo jugador como co-admin.
**Restriccion**: No se permite exceder el numero maximo de co-admins permitidos para el grupo.
**Validacion**: El limite de co-administradores por grupo depende del plan: 1 (Gratis), 3 (Plan 5), 6 (Plan 10), 9 (Plan 15/20). Si el grupo ya tiene el maximo de co-admins, la promocion no se permite y se informa al admin.
**Caso especial**: Ninguno.

### RN-003: Solo jugadores activos del grupo pueden ser promovidos
**Contexto**: Al seleccionar un miembro para promoverlo a co-admin.
**Restriccion**: No se puede promover a miembros con estado pendiente ni a quienes ya son co-admin o admin.
**Validacion**: Solo los miembros con rol de jugador y estado activo dentro del grupo son elegibles para ser promovidos a co-admin.
**Caso especial**: Ninguno.

### RN-004: Alcance de permisos del co-admin
**Contexto**: Cuando un co-admin utiliza las funcionalidades del grupo.
**Restriccion**: El co-admin NO puede: eliminar el grupo, nombrar o quitar co-admins.
**Validacion**: El co-admin tiene los mismos permisos que el admin en todas las demas funciones: editar informacion del grupo, gestionar miembros (invitar, eliminar jugadores), crear y gestionar fechas/partidos.
**Caso especial**: Un co-admin puede eliminar jugadores regulares pero NO puede eliminar a otros co-admins ni al admin (ver E002-HU-006).

### RN-005: Degradacion de co-admin conserva membresia
**Contexto**: Cuando el admin quita el rol de co-admin a un miembro.
**Restriccion**: No se debe eliminar al miembro del grupo al degradarlo.
**Validacion**: Al degradar a un co-admin, este vuelve al rol de jugador regular manteniendo su membresia en el grupo y todo su historial de participacion.
**Caso especial**: Ninguno.

### RN-006: Confirmacion obligatoria para promover y degradar
**Contexto**: Antes de ejecutar cualquier cambio de rol (promocion o degradacion).
**Restriccion**: No se debe ejecutar el cambio de rol sin confirmacion explicita del admin.
**Validacion**: El sistema debe solicitar confirmacion mostrando claramente el nombre del miembro y la accion a realizar (promover a co-admin o degradar a jugador) antes de ejecutar el cambio.
**Caso especial**: Ninguno.

## NOTAS ADICIONALES
- Solo el admin creador del grupo puede nombrar y quitar co-admins
- Los co-admins tienen los mismos permisos que el admin excepto: eliminar el grupo y gestionar otros co-admins
- El limite maximo de co-admins depende del plan: 1 (Gratis), 3 (Plan 5), 6 (Plan 10), 9 (Plan 15/20)
- Al degradar un co-admin, no pierde su membresia; solo cambia su rol a jugador
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## FASE 2: Backend (Supabase)

### Script SQL
- `supabase/sql-cloud/2026-02-21_E002-HU-004_nombrar_quitar_coadmin.sql`

### Funciones RPC

#### `promover_a_coadmin(p_grupo_id UUID, p_miembro_id UUID)`
- Valida que el solicitante es admin creador del grupo (RN-001)
- Valida que el miembro es jugador activo (RN-003)
- Valida limite de co-admins segun plan del grupo (RN-002/CA-004)
- Actualiza `miembros_grupo.rol = 'coadmin'`
- Retorna datos del miembro promovido con conteo actual/max

#### `degradar_coadmin(p_grupo_id UUID, p_miembro_id UUID)`
- Valida que el solicitante es admin creador del grupo (RN-001)
- Valida que el miembro tiene rol `coadmin`
- Actualiza `miembros_grupo.rol = 'jugador'` (RN-005: conserva membresia)
- Retorna datos del miembro degradado

### Codigos de Error
| Codigo | Descripcion |
|--------|-------------|
| NOT_ADMIN_CREATOR | Solo el admin creador puede gestionar co-admins |
| COADMIN_LIMIT_REACHED | Limite de co-admins alcanzado segun plan |
| INVALID_ROLE | El miembro no tiene el rol esperado |
| MEMBER_NOT_FOUND | Miembro no encontrado en el grupo |
| MEMBER_INACTIVE | Miembro inactivo, no se puede promover |

---

## FASE 4: Frontend (Flutter)

### Archivos Modificados
- `lib/features/grupos/data/datasources/grupos_remote_datasource.dart` - Nuevos metodos `promoverACoadmin`, `degradarCoadmin`
- `lib/features/grupos/domain/repositories/grupos_repository.dart` - Nuevos contratos
- `lib/features/grupos/data/repositories/grupos_repository_impl.dart` - Implementacion Either
- `lib/features/grupos/presentation/bloc/miembros_grupo/miembros_grupo_event.dart` - `PromoverACoadminEvent`, `DegradarCoadminEvent`
- `lib/features/grupos/presentation/bloc/miembros_grupo/miembros_grupo_state.dart` - `PromoverCoadminSuccess`, `DegradarCoadminSuccess`
- `lib/features/grupos/presentation/bloc/miembros_grupo/miembros_grupo_bloc.dart` - Handlers para promover/degradar

### Flujo
1. Admin abre lista de miembros del grupo
2. PopupMenu en cada card muestra "Promover a Co-Admin" (jugadores) o "Quitar Co-Admin" (co-admins)
3. Se muestra dialogo de confirmacion (RN-006)
4. Al confirmar, se emite evento al Bloc
5. Bloc llama al repository -> datasource -> RPC
6. En exito, se muestra SnackBar y se recarga la lista

---

## FASE 6: UI (Flutter)

### Archivos Modificados
- `lib/features/grupos/presentation/pages/miembros_grupo_page.dart`

### Cambios UI
- PopupMenuButton en `_MiembroCard` ahora incluye opciones "Promover a Co-Admin" y "Quitar Co-Admin"
- CA-003: Las opciones solo aparecen cuando `miRol == 'admin'` (admin creador)
- RN-006: AlertDialog de confirmacion antes de cada accion, mostrando nombre del miembro y accion
- SnackBar verde de exito al completar la accion
- Iconos: `admin_panel_settings_outlined` (promover), `person_remove_outlined` (degradar)
- Colores: `secondaryColor` (promover), `accentColor` (degradar)
- La logica `_puedePromover()` verifica: miRol==admin, no es si mismo, miembro es jugador activo
- La logica `_puedeDegrada()` verifica: miRol==admin, no es si mismo, miembro es coadmin

---

## FASE 5: QA

### Validacion Tecnica
- `flutter analyze`: 0 errores (18 infos/warnings preexistentes en otros archivos)
- Arquitectura Clean Architecture respetada: DataSource -> Repository -> Bloc -> UI
- Patron Either para manejo de errores
- Convencion snake_case en backend, camelCase en frontend

### Cobertura de CA/RN
| CA/RN | Backend | Frontend | UI | Estado |
|-------|---------|----------|-----|--------|
| CA-001 | promover_a_coadmin | PromoverACoadminEvent | PopupMenu + AlertDialog | OK |
| CA-002 | degradar_coadmin | DegradarCoadminEvent | PopupMenu + AlertDialog | OK |
| CA-003 | RPC valida admin_creador | - | _puedePromover/_puedeDegrada check miRol | OK |
| CA-004 | Valida max_coadmins_por_grupo vs plan | Error message | SnackBar error via MiembrosGrupoError | OK |
| CA-005 | esAdminOCoadmin ya existente | - | Permisos pre-existentes en el sistema | OK |
| RN-001 | IF v_usuario_id != v_admin_creador_id | - | miRol != 'admin' oculta opciones | OK |
| RN-002 | COUNT coadmins vs max_coadmins_por_grupo | ServerFailure COADMIN_LIMIT_REACHED | Error mostrado en SnackBar | OK |
| RN-003 | IF v_miembro.rol != 'jugador' | _puedePromover: miembro.rol != 'jugador' | Solo jugadores activos ven opcion | OK |
| RN-004 | Permisos pre-existentes en sistema | esAdminOCoadmin en grupo_actual_cubit | Menu limitado para coadmin | OK |
| RN-005 | UPDATE rol='jugador' (no DELETE) | - | Mensaje "conservara membresia" | OK |
| RN-006 | - | - | AlertDialog confirmacion obligatoria | OK |

### Resultado: APROBADO
