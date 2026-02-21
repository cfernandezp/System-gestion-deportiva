# E001-HU-006: Cierre de Sesion

## INFORMACION
- **Codigo:** E001-HU-006
- **Epica:** E001 - Autenticacion y Gestion de Acceso
- **Titulo:** Cierre de Sesion
- **Story Points:** 2 pts
- **Estado:** ✅ Completada
- **Prioridad:** Media
- **Fecha:** 2026-02-20

## HISTORIA
**Como** usuario autenticado,
**Quiero** cerrar mi sesion de forma segura,
**Para** proteger mi cuenta cuando dejo de usar la aplicacion.

### Criterios de Aceptacion

#### CA-001: Cierre de sesion exitoso
- [ ] **DADO** que estoy autenticado en la aplicacion
- [ ] **CUANDO** selecciono la opcion de cerrar sesion
- [ ] **ENTONCES** el sistema me muestra una confirmacion preguntando si realmente quiero cerrar sesion

#### CA-002: Confirmacion y redireccion
- [ ] **DADO** que el sistema me pidio confirmar el cierre de sesion
- [ ] **CUANDO** confirmo que quiero cerrar sesion
- [ ] **ENTONCES** la sesion se cierra completamente, se limpia toda la informacion de sesion almacenada localmente y soy redirigido a la pantalla de inicio de sesion

#### CA-003: Cancelar cierre de sesion
- [ ] **DADO** que el sistema me pidio confirmar el cierre de sesion
- [ ] **CUANDO** cancelo la accion
- [ ] **ENTONCES** permanezco en la pantalla donde estaba sin que nada cambie

#### CA-004: Sesion invalidada tras cierre
- [ ] **DADO** que cerre mi sesion exitosamente
- [ ] **CUANDO** intento acceder a cualquier funcionalidad de la aplicacion
- [ ] **ENTONCES** el sistema me redirige a la pantalla de login sin mostrar informacion de la sesion anterior

## Reglas de Negocio (RN)

### RN-001: Requiere confirmacion antes de cerrar sesion
**Contexto**: Cuando el usuario selecciona la opcion de cerrar sesion desde cualquier pantalla de la aplicacion.
**Restriccion**: No se debe cerrar la sesion inmediatamente al pulsar el boton. Se debe evitar cierres accidentales.
**Validacion**: El sistema debe mostrar un dialogo de confirmacion preguntando si el usuario realmente desea cerrar sesion, con opciones claras de "Confirmar" y "Cancelar". Solo si confirma se procede con el cierre.
**Caso especial**: Si el usuario cancela la confirmacion, permanece exactamente en la misma pantalla sin cambios en su sesion.

### RN-002: Limpiar datos de sesion local
**Contexto**: Al confirmar el cierre de sesion.
**Restriccion**: No debe quedar informacion sensible de la sesion accesible en el dispositivo despues del cierre.
**Validacion**: Se debe eliminar toda la informacion de sesion almacenada localmente: credenciales en cache, datos del usuario, grupo seleccionado, preferencias de sesion y cualquier dato temporal.
**Caso especial**: Preferencias no sensibles (como configuracion de idioma o tema visual) pueden mantenerse a discrecion del diseno.

### RN-003: Invalidar sesion de autenticacion
**Contexto**: Al confirmar el cierre de sesion, ademas de limpiar datos locales.
**Restriccion**: La sesion de autenticacion no debe seguir siendo valida despues del cierre. No se debe poder acceder a funcionalidades protegidas reutilizando credenciales de la sesion cerrada.
**Validacion**: La sesion activa debe quedar completamente invalidada, de modo que cualquier intento de acceder a funcionalidades requiera un nuevo inicio de sesion.
**Caso especial**: Si el usuario tiene sesiones en multiples dispositivos, el cierre de sesion en un dispositivo no afecta las sesiones activas en otros dispositivos.

### RN-004: Redirigir a pantalla de login
**Contexto**: Inmediatamente despues de completar el cierre de sesion.
**Restriccion**: No se debe dejar al usuario en una pantalla protegida o en un estado indefinido despues del cierre.
**Validacion**: El sistema debe redirigir automaticamente al usuario a la pantalla de inicio de sesion. Desde ahi no debe poder navegar hacia atras a pantallas protegidas sin autenticarse nuevamente.
**Caso especial**: Si el usuario intenta acceder a cualquier funcionalidad mediante navegacion hacia atras o URL directa, debe ser redirigido al login.

## NOTAS
- El boton o enlace de cierre de sesion debe estar facilmente accesible, por ejemplo desde un menu de perfil o configuracion.
- Al cerrar sesion se debe limpiar toda la informacion sensible almacenada localmente en el dispositivo.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## IMPLEMENTACION TECNICA

> Funcionalidad implementada previamente (antigua E001-HU-004). Re-documentada con nueva numeracion.

### Backend (Supabase SQL)
- **RPC cerrar_sesion():** Registra evento de logout en sesiones_log para auditoria.
- Ya desplegado en Supabase Cloud.

### Frontend (Flutter)
- **DataSource:** `auth_remote_datasource.dart` -> `cerrarSesion()` llama RPC + `supabase.auth.signOut()`
- **Repository:** `auth_repository.dart` -> `cerrarSesion()` con Either<Failure, CerrarSesionResponseModel>
- **SessionBloc:** `session_bloc.dart` -> `LogoutEvent` invalida sesion, fuerza signOut local si falla RPC
- **Modelo:** `cerrar_sesion_response_model.dart`

### UI (Mobile)
- **LogoutButton:** `core/widgets/logout_button.dart` - Widget reutilizable con 3 variantes (expanded, iconOnly, menuItem)
  - CA-001: Dialogo de confirmacion con AlertDialog ("Cerrar sesion" / "Cancelar")
  - CA-002: BlocListener redirige a `/login` al detectar `SessionUnauthenticated`
  - CA-003: Dialog retorna `false` al cancelar -> sin cambios
- **Home Page:** LogoutButton accesible desde AppBar/menu

### Router
- **Guard global:** `app_router.dart` redirect -> si `!isAuthenticated` y ruta protegida -> `/login`
- **Limpieza grupo:** `GrupoActualCubit.limpiarGrupo()` al detectar logout
- CA-004: Cualquier intento de acceso post-logout redirige a login

### QA
- Sin codigo nuevo - funcionalidad pre-existente verificada
