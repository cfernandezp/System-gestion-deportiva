# E001-HU-003: Seleccion de Grupo Post-Login

## INFORMACION
- **Codigo:** E001-HU-003
- **Epica:** E001 - Autenticacion y Gestion de Acceso
- **Titulo:** Seleccion de Grupo Post-Login
- **Story Points:** 3 pts
- **Estado:** 🟢 Refinada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** usuario que pertenece a multiples grupos deportivos,
**Quiero** ver y seleccionar a cual grupo acceder despues de iniciar sesion,
**Para** entrar al grupo que necesito en ese momento.

### Criterios de Aceptacion

#### CA-001: Mostrar lista de grupos del usuario
- [ ] **DADO** que soy un usuario autenticado que pertenece a mas de un grupo
- [ ] **CUANDO** llego a la pantalla de seleccion de grupo
- [ ] **ENTONCES** veo una lista con todos mis grupos mostrando el logo del grupo, el nombre del grupo y mi rol en cada uno (Admin, Co-Admin o Jugador)

#### CA-002: Seleccionar un grupo
- [ ] **DADO** que estoy viendo la lista de mis grupos
- [ ] **CUANDO** selecciono uno de los grupos
- [ ] **ENTONCES** el sistema me lleva a la pantalla principal de ese grupo con las funcionalidades correspondientes a mi rol

#### CA-003: Skip automatico con un solo grupo
- [ ] **DADO** que soy un usuario autenticado que pertenece a un unico grupo
- [ ] **CUANDO** el sistema evalua mis grupos tras el login
- [ ] **ENTONCES** se salta esta pantalla y me lleva directamente a la pantalla principal de ese grupo

#### CA-004: Recordar ultimo grupo seleccionado
- [ ] **DADO** que seleccione un grupo en una sesion anterior
- [ ] **CUANDO** vuelvo a la pantalla de seleccion de grupo en una nueva sesion
- [ ] **ENTONCES** el sistema muestra el ultimo grupo seleccionado destacado o primero en la lista para facilitar el acceso rapido

#### CA-005: Cambiar de grupo durante una sesion activa
- [ ] **DADO** que estoy dentro de un grupo y quiero cambiar a otro
- [ ] **CUANDO** accedo a la opcion de cambiar grupo
- [ ] **ENTONCES** el sistema me muestra la pantalla de seleccion de grupo para elegir otro

## Reglas de Negocio (RN)

### RN-001: Skip automatico con un solo grupo
**Contexto**: Despues de que un usuario se autentica exitosamente y el sistema evalua a cuantos grupos pertenece.
**Restriccion**: No se debe mostrar la pantalla de seleccion de grupo si el usuario pertenece a un unico grupo.
**Validacion**: Si el usuario tiene exactamente 1 grupo, el sistema debe saltar automaticamente la pantalla de seleccion y llevarlo directamente a la pantalla principal de ese grupo.
**Caso especial**: Si el usuario pierde acceso a todos sus grupos menos uno durante una sesion, el siguiente login debera aplicar el skip automatico.

### RN-002: Mostrar rol del usuario en cada grupo
**Contexto**: Al presentar la lista de grupos disponibles para el usuario en la pantalla de seleccion.
**Restriccion**: No se debe mostrar un grupo sin indicar el rol que el usuario tiene en el.
**Validacion**: Cada grupo en la lista debe mostrar: el nombre del grupo, el logo del grupo (si existe) y el rol del usuario en ese grupo (Admin, Co-Admin o Jugador).
**Caso especial**: Un mismo usuario puede tener roles diferentes en distintos grupos (por ejemplo, Admin en un grupo y Jugador en otro).

### RN-003: Recordar ultimo grupo seleccionado
**Contexto**: Cuando un usuario con multiples grupos vuelve a la pantalla de seleccion de grupo en sesiones posteriores.
**Restriccion**: No se debe tratar todos los grupos por igual si hay un historial de seleccion previa.
**Validacion**: El sistema debe recordar cual fue el ultimo grupo seleccionado por el usuario y destacarlo visualmente (mostrandolo primero en la lista o con indicador visual) para facilitar el acceso rapido.
**Caso especial**: Si el ultimo grupo seleccionado fue eliminado o el usuario fue removido de el, se muestra la lista normal sin grupo destacado.

### RN-004: Acceso sin re-autenticacion al cambiar grupo
**Contexto**: Cuando un usuario autenticado quiere cambiar de grupo durante una sesion activa.
**Restriccion**: No se debe solicitar nuevamente las credenciales (celular y contrasena) para cambiar de grupo.
**Validacion**: El cambio de grupo se realiza dentro de la misma sesion autenticada. El usuario simplemente selecciona otro grupo de la lista y accede directamente con las funcionalidades de su rol en ese grupo.
**Caso especial**: Si la sesion expira mientras el usuario esta en la pantalla de seleccion de grupo, se debe redirigir al login.

## NOTAS
- Esta pantalla solo se muestra cuando el usuario pertenece a mas de un grupo. Con un solo grupo, el acceso es directo.
- Los roles son especificos por grupo: un mismo usuario puede ser Admin en un grupo y Jugador en otro.
- La opcion de cambiar de grupo debe estar accesible durante toda la sesion, no solo al inicio.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.
