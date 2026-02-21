# E002-HU-003: Editar Grupo

## INFORMACION
- **Codigo:** E002-HU-003
- **Epica:** E002 - Grupos Deportivos
- **Titulo:** Editar Grupo
- **Story Points:** 3 pts
- **Estado:** ✅ Completada
- **Prioridad:** Media
- **Fecha:** 2026-02-20

## HISTORIA
**Como** admin o co-admin del grupo
**Quiero** editar la informacion del grupo (nombre, logo, lema, reglas)
**Para** mantener los datos del grupo actualizados y relevantes

### Criterios de Aceptacion

#### CA-001: Acceso a edicion por rol autorizado
- [ ] **DADO** que soy admin o co-admin de un grupo
- [ ] **CUANDO** accedo a la configuracion del grupo
- [ ] **ENTONCES** veo la opcion de editar la informacion del grupo con los datos actuales precargados en el formulario

#### CA-002: Edicion de campos del grupo
- [ ] **DADO** que estoy en el formulario de edicion del grupo
- [ ] **CUANDO** modifico el nombre, logo, lema o reglas
- [ ] **ENTONCES** puedo actualizar cualquiera de estos campos manteniendo las mismas validaciones que en la creacion (nombre obligatorio, logo maximo 2MB en JPG/PNG, lema y reglas opcionales)

#### CA-003: Confirmacion de cambios
- [ ] **DADO** que he realizado cambios en la informacion del grupo
- [ ] **CUANDO** presiono guardar
- [ ] **ENTONCES** el sistema me pide confirmacion antes de aplicar los cambios, mostrando un resumen de lo que se va a modificar

#### CA-004: Restriccion para jugadores
- [ ] **DADO** que soy un jugador regular del grupo (no admin ni co-admin)
- [ ] **CUANDO** accedo a la informacion del grupo
- [ ] **ENTONCES** puedo ver los datos del grupo pero NO tengo opcion de editarlos

#### CA-005: Validacion de nombre en edicion
- [ ] **DADO** que estoy editando el nombre del grupo
- [ ] **CUANDO** ingreso un nombre que el admin ya usa en otro grupo que administra
- [ ] **ENTONCES** el sistema me indica que ese nombre ya esta en uso y no permite guardar el cambio

## Reglas de Negocio (RN)

### RN-001: Permisos de edicion del grupo
**Contexto**: Cuando un miembro del grupo intenta acceder a la edicion de la informacion del grupo.
**Restriccion**: Los jugadores regulares no tienen acceso a la funcionalidad de edicion; solo pueden visualizar la informacion.
**Validacion**: Solo el admin y los co-admins del grupo pueden editar la informacion (nombre, logo, lema, reglas). Ambos roles tienen los mismos permisos de edicion.
**Caso especial**: Ninguno.

### RN-002: Jugadores solo visualizan
**Contexto**: Cuando un jugador regular accede a la informacion del grupo.
**Restriccion**: No se debe mostrar la opcion de editar ni permitir modificaciones desde la vista del jugador.
**Validacion**: El jugador puede ver toda la informacion publica del grupo (nombre, logo, lema, reglas) en modo solo lectura.
**Caso especial**: Ninguno.

### RN-003: Validaciones consistentes con la creacion
**Contexto**: Al guardar cambios en la informacion del grupo.
**Restriccion**: No se deben aplicar reglas de validacion diferentes a las de la creacion del grupo.
**Validacion**: Las mismas reglas que aplican al crear un grupo aplican al editarlo: nombre obligatorio, logo maximo 2MB en formato JPG/PNG, lema opcional (maximo 100 caracteres), reglas opcionales (texto libre). La unicidad del nombre se valida entre los grupos del mismo administrador creador.
**Caso especial**: Si el nombre no cambio, la validacion de unicidad no debe rechazarlo por coincidir consigo mismo.

### RN-004: Confirmacion antes de guardar cambios
**Contexto**: Cuando el usuario presiona guardar despues de editar la informacion del grupo.
**Restriccion**: No se deben aplicar cambios sin confirmacion explicita del usuario.
**Validacion**: El sistema debe mostrar un resumen de los campos modificados y solicitar confirmacion antes de aplicar los cambios.
**Caso especial**: Si no se modifico ningun campo, el boton de guardar no debe estar habilitado o se informa que no hay cambios.

## NOTAS ADICIONALES
- No se requiere historial de cambios en esta version
- Tanto admin como co-admin tienen los mismos permisos de edicion sobre la informacion del grupo
- La validacion de nombre unico aplica solo entre los grupos del mismo administrador creador
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## IMPLEMENTACION TECNICA

### Backend (Supabase SQL)
- **RPC editar_grupo(p_grupo_id, p_nombre, p_lema, p_reglas, p_logo_url):** SECURITY DEFINER, authenticated
  - Valida autenticacion, permisos admin/coadmin via miembros_grupo
  - Nombre obligatorio, max 100, unicidad case-insensitive por admin_creador (excluyendo grupo actual)
  - Lema max 100 chars, reglas texto libre
  - Logo: si NULL conserva actual, lema/reglas: si '' se limpian a NULL
- **Script:** `supabase/sql-cloud/2026-02-21_E002-HU-003_editar_grupo.sql`

### Frontend (Flutter)
- **Model:** `editar_grupo_response_model.dart` -> grupoId, nombre, logoUrl, lema, reglas, mensaje
- **DataSource:** `grupos_remote_datasource.dart` -> `obtenerDetalleGrupo()` (query directa), `editarGrupo()` (RPC)
- **Repository:** `grupos_repository.dart` / `grupos_repository_impl.dart` -> Either<Failure, ...>
- **EditarGrupoBloc:** `editar_grupo/` -> CargarDetalleGrupoEvent, EditarGrupoSubmitEvent
  - Sube logo nuevo via Storage si cambia, luego llama RPC
- **EditarGrupoPage:** `editar_grupo_page.dart`
  - Formulario precargado con datos del grupo (CA-001)
  - Logo: NetworkImage existente o FileImage nuevo (CA-002)
  - Deteccion de cambios: boton deshabilitado si no hay cambios (RN-004)
  - AlertDialog confirmacion con resumen de campos modificados (CA-003)
  - Validacion frontend nombre obligatorio, lema max 100 (RN-003)

### Router
- **Ruta:** `/grupos/:id/editar` (protegida, requiere auth)
- **BlocProvider** crea EditarGrupoBloc y despacha CargarDetalleGrupoEvent

### DI
- `EditarGrupoBloc` registrado como factory en injection_container.dart

### QA
- flutter analyze: 0 errores nuevos (18 pre-existentes info/warning)
