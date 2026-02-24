# E002-HU-002: Ver Mis Grupos

## INFORMACION
- **Codigo:** E002-HU-002
- **Epica:** E002 - Grupos Deportivos
- **Titulo:** Ver Mis Grupos
- **Story Points:** 3 pts
- **Estado:** Refinada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** usuario
**Quiero** ver todos los grupos a los que pertenezco
**Para** acceder rapidamente a cualquiera de ellos y conocer mi participacion en cada uno

### Criterios de Aceptacion

#### CA-001: Visualizacion de lista de grupos
- [ ] **DADO** que soy un usuario autenticado que pertenece a uno o mas grupos
- [ ] **CUANDO** accedo a la seccion de mis grupos
- [ ] **ENTONCES** veo una lista con todos los grupos mostrando para cada uno: logo del grupo, nombre, mi rol en ese grupo (Admin, Co-Admin o Jugador) y la cantidad de miembros

#### CA-002: Indicador visual de rol
- [ ] **DADO** que estoy viendo la lista de mis grupos
- [ ] **CUANDO** observo cada grupo en la lista
- [ ] **ENTONCES** mi rol se muestra con un indicador visual diferenciado que permite distinguir facilmente si soy Admin, Co-Admin o Jugador en ese grupo

#### CA-003: Orden de la lista
- [ ] **DADO** que tengo multiples grupos
- [ ] **CUANDO** se muestra la lista de mis grupos
- [ ] **ENTONCES** los grupos aparecen ordenados por ultimo acceso, mostrando primero el grupo al que accedi mas recientemente

#### CA-004: Acceso al grupo
- [ ] **DADO** que estoy viendo la lista de mis grupos
- [ ] **CUANDO** toco sobre un grupo de la lista
- [ ] **ENTONCES** ingreso directamente a ese grupo y todo el contexto de la aplicacion (fechas, partidos, miembros) cambia al grupo seleccionado

#### CA-005: Usuario sin grupos
- [ ] **DADO** que soy un usuario autenticado que no pertenece a ningun grupo
- [ ] **CUANDO** accedo a la seccion de mis grupos
- [ ] **ENTONCES** veo un mensaje amigable indicando que aun no pertenezco a ningun grupo, con una opcion visible para crear uno si tengo permisos de administrador

## Reglas de Negocio (RN)

### RN-001: Acceso a la lista de grupos propios
**Contexto**: Cuando un usuario autenticado accede a la seccion "Mis Grupos".
**Restriccion**: No se deben mostrar grupos a los que el usuario no pertenece.
**Validacion**: Todo usuario autenticado puede ver exclusivamente los grupos donde es miembro activo, independientemente de su rol (Admin, Co-Admin o Jugador).
**Caso especial**: Ninguno.

### RN-002: Informacion visible por grupo
**Contexto**: Al renderizar cada elemento de la lista de grupos.
**Restriccion**: No se debe mostrar informacion interna del grupo (partidos, pagos, etc.) en la vista de lista.
**Validacion**: Cada grupo en la lista debe mostrar: logo del grupo (o indicador por defecto si no tiene), nombre del grupo, rol del usuario en ese grupo y cantidad total de miembros (activos y pendientes).
**Caso especial**: Si el grupo no tiene logo, se muestra un indicador visual por defecto.

### RN-003: Ordenamiento por ultimo acceso
**Contexto**: Cuando se muestra la lista de grupos del usuario.
**Restriccion**: No se debe ordenar alfabeticamente ni por fecha de creacion.
**Validacion**: Los grupos se ordenan por la fecha/hora del ultimo acceso del usuario a cada grupo, mostrando primero el mas reciente. Al ingresar a un grupo, se actualiza automaticamente su registro de ultimo acceso.
**Caso especial**: Si un grupo nunca ha sido accedido (recien invitado), se posiciona al final de la lista.

### RN-004: Estado vacio para usuarios sin grupos - con capacidad de crear
**Contexto**: Cuando un usuario autenticado no pertenece a ningun grupo y tiene la posibilidad de crear grupos.
**Restriccion**: No se debe mostrar una pantalla en blanco sin orientacion.
**Validacion**: Se muestra un mensaje amigable indicando que no pertenece a ningun grupo junto con una opcion visible y directa para crear un grupo nuevo.
**Caso especial**: Ninguno.

### RN-005: Estado vacio para usuarios sin grupos - solo jugador
**Contexto**: Cuando un usuario autenticado no pertenece a ningun grupo y no ha creado grupos propios.
**Restriccion**: No se debe mostrar la opcion de crear grupo como unica alternativa sin contexto.
**Validacion**: Se muestra un mensaje amigable como "Aun no perteneces a ningun grupo" y se ofrece la opcion de crear un grupo (ya que cualquier usuario puede crear grupos y volverse admin de estos).
**Caso especial**: Ninguno.

## NOTAS ADICIONALES
- Un usuario puede tener diferentes roles en diferentes grupos
- La cantidad de miembros mostrada incluye a todos los miembros del grupo (activos y pendientes de activacion)
- El acceso a un grupo actualiza automaticamente el registro de "ultimo acceso" para el ordenamiento
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.
