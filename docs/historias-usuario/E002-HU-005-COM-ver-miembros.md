# E002-HU-005: Ver Miembros del Grupo

## INFORMACION
- **Codigo:** E002-HU-005
- **Epica:** E002 - Grupos Deportivos
- **Titulo:** Ver Miembros del Grupo
- **Story Points:** 3 pts
- **Estado:** Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** miembro del grupo
**Quiero** ver la lista de todos los miembros del grupo
**Para** conocer quienes forman parte del equipo y sus roles

### Criterios de Aceptacion

#### CA-001: Visualizacion de lista de miembros para cualquier miembro
- [ ] **DADO** que soy un miembro del grupo (admin, co-admin o jugador)
- [ ] **CUANDO** accedo a la seccion de miembros del grupo
- [ ] **ENTONCES** veo una lista con todos los miembros mostrando: nombre, numero de celular parcialmente oculto (ej: ****1234), rol en el grupo y estado (activo o pendiente de activacion)

#### CA-002: Vista ampliada para admin y co-admin
- [ ] **DADO** que soy admin o co-admin del grupo
- [ ] **CUANDO** veo la lista de miembros
- [ ] **ENTONCES** puedo ver informacion adicional que los jugadores regulares no ven, incluyendo el numero de celular completo y el estado detallado de cada miembro

#### CA-003: Filtrar por rol
- [ ] **DADO** que estoy viendo la lista de miembros del grupo
- [ ] **CUANDO** aplico un filtro por rol (Admin, Co-Admin o Jugador)
- [ ] **ENTONCES** la lista muestra unicamente los miembros que tienen el rol seleccionado

#### CA-004: Buscar por nombre
- [ ] **DADO** que estoy viendo la lista de miembros del grupo
- [ ] **CUANDO** escribo un nombre en el campo de busqueda
- [ ] **ENTONCES** la lista se filtra en tiempo real mostrando solo los miembros cuyo nombre coincide parcialmente con lo ingresado

#### CA-005: Grupo sin miembros adicionales
- [ ] **DADO** que soy el unico miembro del grupo (admin creador)
- [ ] **CUANDO** accedo a la lista de miembros
- [ ] **ENTONCES** me veo a mi mismo en la lista y se muestra un mensaje indicando que aun no hay otros miembros en el grupo

## Reglas de Negocio (RN)

### RN-001: Acceso universal a la lista de miembros
**Contexto**: Cuando cualquier miembro del grupo accede a la seccion de miembros.
**Restriccion**: No se debe restringir la visualizacion de la lista de miembros a ningun rol dentro del grupo.
**Validacion**: Todos los miembros del grupo (admin, co-admin y jugador) pueden ver la lista completa de miembros. La diferencia entre roles radica en el nivel de detalle de la informacion visible, no en el acceso.
**Caso especial**: Ninguno.

### RN-002: Privacidad del numero de celular segun rol
**Contexto**: Al mostrar la informacion de contacto de los miembros en la lista.
**Restriccion**: Los jugadores regulares NO deben ver el numero de celular completo de otros miembros.
**Validacion**: Jugadores ven el celular parcialmente oculto (formato: ***-***-789, mostrando solo los ultimos 3 digitos). Admin y co-admin ven el numero de celular completo de todos los miembros para poder contactarlos.
**Caso especial**: Cada miembro siempre puede ver su propio numero completo, independientemente de su rol.

### RN-003: Informacion visible por miembro
**Contexto**: Al renderizar cada elemento de la lista de miembros.
**Restriccion**: No se debe mostrar informacion sensible que no corresponda al rol del usuario que visualiza.
**Validacion**: Para cada miembro se muestra: nombre completo, numero de celular (segun regla de privacidad RN-002), rol en el grupo (Admin, Co-Admin o Jugador) y estado (activo o pendiente).
**Caso especial**: Ninguno.

### RN-004: Filtrado por rol
**Contexto**: Cuando el usuario aplica un filtro por rol en la lista de miembros.
**Restriccion**: No se debe permitir filtros que muestren informacion de miembros fuera del grupo.
**Validacion**: Se puede filtrar la lista por cualquiera de los tres roles: Admin, Co-Admin o Jugador. El filtro muestra unicamente los miembros que tienen el rol seleccionado. Se debe poder quitar el filtro para ver todos los miembros nuevamente.
**Caso especial**: Si no hay miembros con el rol filtrado, se muestra un mensaje indicando que no hay miembros con ese rol.

### RN-005: Busqueda por nombre
**Contexto**: Cuando el usuario escribe en el campo de busqueda de miembros.
**Restriccion**: La busqueda solo aplica sobre el nombre; no debe buscar por celular ni por rol.
**Validacion**: La busqueda debe ser por coincidencia parcial (contiene), insensible a mayusculas/minusculas, y filtrar la lista en tiempo real mientras el usuario escribe.
**Caso especial**: Si no hay coincidencias, se muestra un mensaje indicando que no se encontraron miembros con ese nombre.

## NOTAS ADICIONALES
- La privacidad del numero de celular es importante: los jugadores regulares solo ven los ultimos 4 digitos
- Admin y co-admin necesitan ver el celular completo para poder contactar a los jugadores
- Los estados posibles de un miembro son: activo (cuenta activada y en uso) y pendiente de activacion (invitado pero aun no activo su cuenta)
- La busqueda por nombre debe ser agil e inmediata para facilitar encontrar miembros en grupos grandes
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

## IMPLEMENTACION TECNICA

### Backend
- **Sin cambios SQL**: La RPC `obtener_miembros_grupo` (E001-HU-004) ya retorna todos los datos necesarios (nombre, celular, rol, estado_usuario)
- La privacidad del celular (RN-002), filtros (CA-003/RN-004) y busqueda (CA-004/RN-005) se manejan 100% en frontend

### Frontend (Flutter)

#### Modelo actualizado
- **miembro_grupo_model.dart**: Agregado getter `celularEnmascarado` con formato `***-***-789` (RN-002)

#### BLoC mejorado
- **miembros_grupo_event.dart**: Agregados `FiltrarPorRolEvent(rol?)` y `BuscarMiembroEvent(query)`
- **miembros_grupo_state.dart**: `MiembrosGrupoLoaded` ahora incluye `filtroRol`, `busqueda`, getters `miembrosFiltrados`, `esUnicoMiembro`, `tieneFiltrosActivos` y `copyWith`
- **miembros_grupo_bloc.dart**: Maneja filtro y busqueda client-side sobre la lista cargada

#### Pagina mejorada
- **miembros_grupo_page.dart**: Convertida a StatefulWidget con:
  - Barra de busqueda por nombre con limpieza (CA-004/RN-005)
  - FilterChip horizontales: Todos, Admin, Co-Admin, Jugador, Invitado (CA-003/RN-004)
  - Privacidad celular: jugadores ven `***-***-789`, admin/coadmin ven completo (RN-002)
  - Excepcion: cada miembro ve su propio celular completo (RN-002 caso especial)
  - Card mejorada con celular visible, rol badge, estado (CA-001/CA-002/RN-003)
  - Mensaje "unico miembro" cuando solo hay 1 (CA-005)
  - Mensajes vacios diferenciados: sin resultados de busqueda vs sin miembros con rol (RN-004/RN-005)
  - Identificacion del usuario actual via `Supabase.auth.currentUser?.phone`

### QA
- `flutter analyze lib/features/grupos/`: 0 errores
- Sin cambios en router, DI o datasource (reutiliza infraestructura existente)
