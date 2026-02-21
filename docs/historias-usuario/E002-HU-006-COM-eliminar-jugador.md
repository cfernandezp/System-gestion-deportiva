# E002-HU-006: Eliminar Jugador del Grupo

## INFORMACION
- **Codigo:** E002-HU-006
- **Epica:** E002 - Grupos Deportivos
- **Titulo:** Eliminar Jugador del Grupo
- **Story Points:** 3 pts
- **Estado:** Completada
- **Prioridad:** Media
- **Fecha:** 2026-02-20

## HISTORIA
**Como** admin o co-admin del grupo
**Quiero** eliminar a un jugador del grupo
**Para** gestionar la membresia y mantener el grupo organizado

### Criterios de Aceptacion

#### CA-001: Eliminar jugador del grupo
- [ ] **DADO** que soy admin o co-admin del grupo y estoy viendo la lista de miembros
- [ ] **CUANDO** selecciono a un jugador y elijo la opcion de eliminar del grupo
- [ ] **ENTONCES** el sistema me pide confirmacion mostrando el nombre del jugador, y al confirmar, el jugador pierde acceso a este grupo

#### CA-002: Proteccion del admin creador
- [ ] **DADO** que estoy viendo la lista de miembros como admin o co-admin
- [ ] **CUANDO** veo al admin creador del grupo en la lista
- [ ] **ENTONCES** NO aparece la opcion de eliminarlo, ya que el creador del grupo no puede ser removido

#### CA-003: Restriccion entre co-admins
- [ ] **DADO** que soy co-admin del grupo
- [ ] **CUANDO** veo a otro co-admin o al admin en la lista de miembros
- [ ] **ENTONCES** NO tengo la opcion de eliminarlos; un co-admin solo puede eliminar jugadores regulares

#### CA-004: Cuenta del jugador eliminado sigue activa
- [ ] **DADO** que un jugador ha sido eliminado de este grupo
- [ ] **CUANDO** el jugador intenta acceder al grupo
- [ ] **ENTONCES** ya no tiene acceso a este grupo, pero su cuenta de usuario sigue activa y puede seguir accediendo a otros grupos de los que sea miembro

#### CA-005: Confirmacion de eliminacion
- [ ] **DADO** que he seleccionado eliminar a un jugador del grupo
- [ ] **CUANDO** el sistema me muestra la confirmacion
- [ ] **ENTONCES** debo confirmar explicitamente la accion, y el sistema indica claramente que esta accion eliminara al jugador de este grupo pero no afectara su cuenta ni su participacion en otros grupos

## Reglas de Negocio (RN)

### RN-001: Permisos de eliminacion segun rol
**Contexto**: Cuando un miembro del grupo intenta eliminar a otro miembro.
**Restriccion**: Los jugadores regulares no tienen permiso para eliminar a nadie del grupo.
**Validacion**: Solo el admin y los co-admins del grupo pueden eliminar miembros. El admin puede eliminar tanto jugadores como co-admins. El co-admin solo puede eliminar jugadores regulares.
**Caso especial**: Ninguno.

### RN-002: Proteccion absoluta del admin creador
**Contexto**: En cualquier operacion de eliminacion de miembros del grupo.
**Restriccion**: El admin creador del grupo NO puede ser eliminado bajo ninguna circunstancia, ni por si mismo ni por nadie.
**Validacion**: La opcion de eliminar no debe estar visible ni disponible para el admin creador del grupo. Esta proteccion es absoluta e invariable.
**Caso especial**: Ninguno.

### RN-003: Restriccion de co-admin sobre otros co-admins y admin
**Contexto**: Cuando un co-admin visualiza la lista de miembros con opciones de gestion.
**Restriccion**: Un co-admin NO puede eliminar a otro co-admin ni al admin del grupo.
**Validacion**: Las opciones de eliminacion para un co-admin solo deben aparecer junto a miembros con rol de jugador regular. Para co-admins y admin, la opcion de eliminar no debe ser visible.
**Caso especial**: Ninguno.

### RN-004: El admin puede eliminar co-admins
**Contexto**: Cuando el admin creador gestiona los miembros del grupo.
**Restriccion**: Ninguna restriccion adicional para el admin respecto a co-admins.
**Validacion**: El admin puede eliminar a cualquier miembro del grupo excepto a si mismo, incluyendo co-admins. Al eliminar a un co-admin, este pierde tanto su rol como su membresia en el grupo.
**Caso especial**: Ninguno.

### RN-005: Eliminacion es del grupo, no de la cuenta
**Contexto**: Cuando un miembro es eliminado de un grupo.
**Restriccion**: No se debe afectar la cuenta del usuario ni su participacion en otros grupos.
**Validacion**: La eliminacion remueve al miembro unicamente del grupo en cuestion. Su cuenta de usuario permanece activa y sigue teniendo acceso a todos los demas grupos donde sea miembro.
**Caso especial**: Un jugador eliminado puede ser re-invitado al mismo grupo en el futuro si el admin lo decide.

### RN-006: Confirmacion obligatoria con datos visibles
**Contexto**: Antes de ejecutar la eliminacion de un miembro del grupo.
**Restriccion**: No se debe ejecutar la eliminacion sin confirmacion explicita.
**Validacion**: El sistema debe mostrar el nombre del jugador a eliminar y solicitar confirmacion explicita. Se debe informar claramente que la accion elimina al jugador de este grupo pero no afecta su cuenta ni su participacion en otros grupos.
**Caso especial**: Ninguno.

### RN-007: Notificacion manual al jugador eliminado
**Contexto**: Despues de que un jugador ha sido eliminado del grupo.
**Restriccion**: No se envia notificacion automatica al jugador eliminado en esta version.
**Validacion**: La comunicacion de la eliminacion al jugador es responsabilidad del admin o co-admin que realizo la accion, de forma manual y fuera del sistema.
**Caso especial**: En versiones futuras se podra implementar notificacion automatica.

## NOTAS ADICIONALES
- La eliminacion es del grupo, no de la cuenta del usuario en el sistema
- Un jugador eliminado podria ser re-invitado al grupo en el futuro si el admin lo decide
- La notificacion al jugador eliminado no es automatica en esta version; se espera que el admin informe manualmente
- El admin puede eliminar tanto jugadores como co-admins; el co-admin solo puede eliminar jugadores regulares
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

## IMPLEMENTACION TECNICA

### Backend (Supabase SQL)

#### RPC creada
- **`eliminar_jugador_grupo(p_grupo_id UUID, p_miembro_id UUID)`** → JSON
- SECURITY DEFINER, GRANT a authenticated
- Archivo: `supabase/sql-cloud/2026-02-21_E002-HU-006_eliminar_jugador_grupo.sql`

#### Validaciones implementadas
| Paso | Validacion | Hint |
|------|-----------|------|
| 1 | auth.uid() presente | `no_autenticado` |
| 2 | usuario_id del caller existe | `usuario_no_encontrado` |
| 3 | Grupo existe y activo | `grupo_no_encontrado` |
| 4 | Caller es admin o coadmin activo (RN-001) | `sin_permisos` |
| 5 | Target existe y activo en el grupo | `miembro_no_encontrado` |
| 6 | No auto-eliminacion | `auto_eliminacion` |
| 7 | Target no es admin creador (RN-002) | `admin_creador_protegido` |
| 8 | Coadmin solo elimina jugadores/invitados (RN-003) | `coadmin_sin_permiso` |

#### Accion
- Soft delete: `UPDATE miembros_grupo SET activo = FALSE, updated_at = NOW()` (RN-005)
- No toca tabla `usuarios` ni otros grupos

### Frontend (Flutter)

#### Datasource
- **grupos_remote_datasource.dart**: Agregado `eliminarJugadorGrupo(grupoId, miembroId)` con llamada RPC

#### Repository
- **grupos_repository.dart**: Agregado `eliminarJugadorGrupo` con Either pattern
- **grupos_repository_impl.dart**: Implementacion con ServerException → ServerFailure

#### BLoC (reutiliza MiembrosGrupoBloc)
- **miembros_grupo_event.dart**: Agregado `EliminarJugadorEvent(grupoId, miembroId, nombreJugador)`
- **miembros_grupo_state.dart**: Agregado `EliminarJugadorSuccess(nombreJugador)`
- **miembros_grupo_bloc.dart**: Handler que llama repository y emite success/error

#### Pagina
- **miembros_grupo_page.dart**: Mejorada con:
  - Parametro `miRol` para permisos diferenciados admin vs coadmin
  - Metodo `_puedeEliminar(miembro)` que implementa RN-001 a RN-004 en UI
  - Dialogo de confirmacion con nombre del jugador y mensaje informativo (CA-005/RN-006)
  - BlocConsumer con listener para EliminarJugadorSuccess → SnackBar + recarga
  - IconButton delete rojo en trailing de cards elegibles

#### Router
- **app_router.dart**: Extrae `miRol` desde GrupoActualCubit y lo pasa a MiembrosGrupoPage

### QA
- `flutter analyze`: 0 errores en grupos/ y app_router.dart
- Sin cambios en injection_container.dart (reutiliza BLoC existente)
