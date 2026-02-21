# E001-HU-004: Invitar Jugador al Grupo

## INFORMACION
- **Codigo:** E001-HU-004
- **Epica:** E001 - Autenticacion y Gestion de Acceso
- **Titulo:** Invitar Jugador al Grupo
- **Story Points:** 5 pts
- **Estado:** ✅ Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** administrador de un grupo deportivo,
**Quiero** invitar jugadores registrando su numero de celular,
**Para** que puedan unirse a mi grupo y participar en las actividades deportivas.

### Criterios de Aceptacion

#### CA-001: Invitar jugador nuevo en el sistema
- [ ] **DADO** que soy administrador o co-administrador de un grupo
- [ ] **CUANDO** registro el numero de celular de un jugador que no existe en el sistema
- [ ] **ENTONCES** el sistema crea un usuario con estado "pendiente de activacion" y lo asocia a mi grupo con rol Jugador

#### CA-002: Invitar jugador que ya tiene cuenta en el sistema
- [ ] **DADO** que soy administrador o co-administrador de un grupo
- [ ] **CUANDO** registro el numero de celular de un jugador que ya tiene una cuenta activa en el sistema (pertenece a otro grupo)
- [ ] **ENTONCES** el sistema asocia a ese jugador a mi grupo con rol Jugador, sin duplicar su cuenta

#### CA-003: Jugador ya pertenece al grupo
- [ ] **DADO** que intento invitar a un jugador a mi grupo
- [ ] **CUANDO** el numero de celular ingresado ya esta asociado a mi grupo
- [ ] **ENTONCES** el sistema me informa que ese jugador ya pertenece al grupo

#### CA-004: Limite de jugadores por grupo
- [ ] **DADO** que mi grupo ya alcanzo el limite maximo de jugadores segun su plan (25 en Gratis, 50 en Plan 5/10, 70 en Plan 15/20)
- [ ] **CUANDO** intento invitar a un nuevo jugador
- [ ] **ENTONCES** el sistema me informa que se alcanzo el limite y no permite la invitacion

#### CA-005: Ver lista de jugadores invitados con estado
- [ ] **DADO** que soy administrador o co-administrador del grupo
- [ ] **CUANDO** accedo a la lista de jugadores del grupo
- [ ] **ENTONCES** veo cada jugador con su nombre (si ya activo su cuenta) o solo su celular (si esta pendiente), junto con su estado (activo o pendiente de activacion)

#### CA-006: Validacion de formato de celular al invitar
- [ ] **DADO** que estoy ingresando el celular de un jugador para invitarlo
- [ ] **CUANDO** el numero no tiene el formato valido esperado
- [ ] **ENTONCES** el sistema muestra un mensaje de error indicando el formato correcto

#### CA-007: Notificacion manual al jugador invitado
- [ ] **DADO** que invite exitosamente a un jugador al grupo
- [ ] **CUANDO** la invitacion se completa
- [ ] **ENTONCES** el sistema me confirma la invitacion y me recuerda que debo notificar al jugador por mis propios medios (WhatsApp, llamada, en persona) para que descargue la app y active su cuenta

## Reglas de Negocio (RN)

### RN-001: Solo admin o co-admin pueden invitar
**Contexto**: Al intentar invitar un nuevo jugador a un grupo deportivo.
**Restriccion**: Los usuarios con rol Jugador no pueden invitar a otras personas al grupo. Solo los roles Admin y Co-Admin tienen permiso para esta accion.
**Validacion**: El sistema debe verificar que el usuario que realiza la invitacion tenga rol Admin o Co-Admin en el grupo activo antes de permitir la operacion.
**Caso especial**: Un usuario que es Jugador en un grupo pero Admin en otro, solo puede invitar desde el grupo donde es Admin o Co-Admin.

### RN-002: Limite de jugadores por grupo
**Contexto**: Al intentar agregar un nuevo jugador a un grupo que podria estar cerca de su capacidad maxima.
**Restriccion**: No se puede exceder el limite maximo de miembros permitidos en un grupo.
**Validacion**: El limite de jugadores depende del plan del admin (25 en Gratis, 50 en Plan 5/10, 70 en Plan 15/20). El sistema debe contar todos los miembros del grupo (activos y pendientes de activacion) y rechazar la invitacion si se alcanza el limite.
**Regla calculo**: Total miembros del grupo (activos + pendientes) debe ser menor al limite configurado segun el plan.
**Caso especial**: El limite es configurable por grupo. Los administradores y co-administradores tambien cuentan dentro del limite total del grupo.

### RN-003: Celular existente en sistema se asocia al grupo sin duplicar
**Contexto**: Al invitar a un jugador cuyo numero de celular ya esta registrado en el sistema (pertenece a otro grupo).
**Restriccion**: No se debe crear una cuenta de usuario duplicada. Cada celular corresponde a una unica cuenta.
**Validacion**: Si el celular ya existe en el sistema con estado activo, el sistema asocia ese usuario al nuevo grupo con rol Jugador, manteniendo su cuenta y datos existentes intactos.
**Caso especial**: El jugador obtiene automaticamente acceso multi-grupo y vera el nuevo grupo en su pantalla de seleccion de grupo en su proximo login.

### RN-004: Celular nuevo crea usuario en estado pendiente de activacion
**Contexto**: Al invitar a un jugador cuyo numero de celular no existe en el sistema.
**Restriccion**: El usuario creado no puede hacer login hasta que complete el proceso de activacion (ver E001-HU-005).
**Validacion**: El sistema crea un registro de usuario con el celular proporcionado y estado "pendiente de activacion", y lo asocia al grupo con rol Jugador. El usuario no tiene nombre ni contrasena hasta que active su cuenta.
**Caso especial**: Si el mismo celular es invitado a multiples grupos antes de activar, al momento de activar tendra acceso a todos los grupos a los que fue invitado.

### RN-005: No se puede invitar al mismo celular dos veces al mismo grupo
**Contexto**: Al intentar invitar un numero de celular que ya esta asociado al grupo (ya sea activo o pendiente de activacion).
**Restriccion**: No se permite la invitacion duplicada al mismo grupo.
**Validacion**: El sistema debe verificar que el celular no exista ya como miembro del grupo antes de procesar la invitacion. Si ya existe, debe informar que el jugador ya pertenece al grupo.
**Caso especial**: Si un jugador fue removido del grupo, si se le puede volver a invitar (ya no es miembro activo del grupo).

### RN-006: Notificacion manual sin automatizacion
**Contexto**: Despues de completar exitosamente una invitacion de jugador.
**Restriccion**: El sistema NO envia SMS, push notifications, WhatsApp ni ningun tipo de notificacion automatica al jugador invitado.
**Validacion**: El sistema confirma la invitacion al admin y le muestra un recordatorio de que debe notificar al jugador por sus propios medios (WhatsApp, llamada, en persona) para que descargue la app y active su cuenta.
**Caso especial**: Esta decision es por diseno (modelo $0 costo) y coherente con el patron de comunicacion admin-jugador ya establecido en el flujo de invitacion.

## NOTAS
- El sistema NO envia SMS ni notificaciones automaticas al jugador invitado. El administrador es responsable de avisarle por WhatsApp, llamada telefonica o en persona.
- El limite de jugadores por grupo depende del plan: 25 (Gratis), 50 (Plan 5/10), 70 (Plan 15/20).
- Tanto administradores como co-administradores pueden invitar jugadores.
- Cuando un jugador que ya existe en el sistema es invitado a un nuevo grupo, automaticamente tiene acceso multi-grupo.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## IMPLEMENTACION TECNICA

### 🗄️ FASE 2: Backend (Supabase)

**Script SQL:** `supabase/sql-cloud/2026-02-20_E001-HU-004_invitar_jugador.sql`

**RPCs creados:**
- `invitar_jugador_grupo(p_grupo_id, p_celular)` - Invita jugador al grupo
  - Valida rol admin/coadmin (RN-001)
  - Valida formato celular Peru 9 digitos (CA-006)
  - Valida limite jugadores por plan (CA-004, RN-002)
  - Si celular existe y no es miembro: asocia al grupo (CA-002, RN-003)
  - Si celular existe y ya es miembro: error (CA-003, RN-005)
  - Si celular no existe: crea usuario pendiente (CA-001, RN-004)
  - Retorna recordatorio de notificacion manual (CA-007, RN-006)
- `obtener_miembros_grupo(p_grupo_id)` - Lista miembros con estado (CA-005)

**RLS:** Policy update en miembros_grupo para reactivar miembros removidos

### 💻 FASE 4: Frontend (Flutter)

**Modelos:**
- `invitar_jugador_response_model.dart` - Response de invitacion
- `miembro_grupo_model.dart` - Modelo de miembro con estado

**DataSource:** Metodos `invitarJugadorGrupo()` y `obtenerMiembrosGrupo()` en `GruposRemoteDataSource`

**Repository:** Metodos correspondientes en `GruposRepository` / `GruposRepositoryImpl`

**Blocs:**
- `InvitarJugadorBloc` - Gestiona flujo de invitacion
- `MiembrosGrupoBloc` - Gestiona lista de miembros

### 🎨 FASE 1: UI

**Paginas:**
- `miembros_grupo_page.dart` - ListView con Cards, FAB invitar (CA-005)
- `invitar_jugador_page.dart` - Formulario celular + validacion + confirmacion (CA-001, CA-006, CA-007)

**Rutas:**
- `/grupos/:id/miembros` - Ver miembros
- `/grupos/:id/invitar` - Invitar jugador

**DI:** `InvitarJugadorBloc` y `MiembrosGrupoBloc` registrados en `injection_container.dart`

### 🧪 FASE 5: QA

- flutter analyze: 0 errores, 0 warnings nuevos
- Todos los CA (001-007) y RN (001-006) cubiertos end-to-end
