# EPICA E002: Grupos Deportivos

## INFORMACION
- **Codigo:** E002
- **Nombre:** Grupos Deportivos
- **Descripcion:** Gestion completa de grupos deportivos de futbol (pichangas), incluyendo creacion, edicion, administracion de miembros, roles por grupo (Admin, Co-Admin, Jugador) y navegacion multi-grupo. Soporta modelo freemium con limites configurables de grupos por administrador y jugadores por grupo.
- **Story Points:** 37 pts
- **Estado:** 🟢 Refinada

## HISTORIAS

### E002-HU-001: Crear Grupo Deportivo
- **Archivo:** docs/historias-usuario/E002-HU-001-REF-crear-grupo.md
- **Estado:** 🟢 Refinada | **Story Points:** 5 | **Prioridad:** Alta

### E002-HU-002: Ver Mis Grupos
- **Archivo:** docs/historias-usuario/E002-HU-002-REF-ver-mis-grupos.md
- **Estado:** 🟢 Refinada | **Story Points:** 3 | **Prioridad:** Alta

### E002-HU-003: Editar Grupo
- **Archivo:** docs/historias-usuario/E002-HU-003-REF-editar-grupo.md
- **Estado:** 🟢 Refinada | **Story Points:** 3 | **Prioridad:** Media

### E002-HU-004: Nombrar y Quitar Co-Administradores
- **Archivo:** docs/historias-usuario/E002-HU-004-REF-nombrar-co-admin.md
- **Estado:** 🟢 Refinada | **Story Points:** 3 | **Prioridad:** Media

### E002-HU-005: Ver Miembros del Grupo
- **Archivo:** docs/historias-usuario/E002-HU-005-REF-ver-miembros.md
- **Estado:** 🟢 Refinada | **Story Points:** 3 | **Prioridad:** Alta

### E002-HU-006: Eliminar Jugador del Grupo
- **Archivo:** docs/historias-usuario/E002-HU-006-REF-eliminar-jugador.md
- **Estado:** 🟢 Refinada | **Story Points:** 3 | **Prioridad:** Media

### E002-HU-007: Cambiar de Grupo Activo
- **Archivo:** docs/historias-usuario/E002-HU-007-REF-cambiar-grupo.md
- **Estado:** 🟢 Refinada | **Story Points:** 2 | **Prioridad:** Alta

### E002-HU-008: Registrar Invitado en el Grupo
- **Archivo:** docs/historias-usuario/E002-HU-008-REF-registrar-invitado.md
- **Estado:** 🟢 Refinada | **Story Points:** 5 | **Prioridad:** Alta

### E002-HU-009: Promover Invitado a Jugador
- **Archivo:** docs/historias-usuario/E002-HU-009-REF-promover-invitado.md
- **Estado:** 🟢 Refinada | **Story Points:** 5 | **Prioridad:** Alta

### E002-HU-010: Invitar Jugador Existente a Grupo
- **Archivo:** docs/historias-usuario/E002-HU-010-REF-invitar-jugador-existente.md
- **Estado:** 🟢 Refinada | **Story Points:** 5 | **Prioridad:** Media
- **Funcionalidad:** Buscar jugador con cuenta activa (por celular o nombre) e invitarlo a unirse al grupo. El jugador acepta/rechaza.

## CRITERIOS EPICA
- [ ] Un administrador puede crear un grupo deportivo con nombre, logo, lema y reglas
- [ ] Se respetan los limites de grupos por administrador segun el plan (freemium)
- [ ] Un usuario puede ver todos los grupos a los que pertenece con su rol en cada uno
- [ ] Un admin o co-admin puede editar la informacion del grupo
- [ ] El admin creador puede nombrar y quitar co-administradores
- [ ] Cualquier miembro puede ver la lista de miembros del grupo
- [ ] Un admin o co-admin puede eliminar jugadores del grupo
- [ ] Un usuario multi-grupo puede cambiar de grupo activo sin cerrar sesion
- [ ] Los roles son especificos por grupo: un usuario puede ser admin en un grupo y jugador en otro
- [ ] El limite de jugadores por grupo es configurable (default 35)
- [ ] Un admin o co-admin puede registrar invitados (max 1 por grupo, configurable) sin requerir celular
- [ ] Un invitado puede participar en fechas, anotar goles y pagar cancha
- [ ] Un invitado NO aparece en rankings publicos del grupo
- [ ] El admin puede promover un invitado a jugador asignandole un celular, conservando todo su historial
- [ ] Al promover, el historial del invitado se incluye retroactivamente en rankings

## PROGRESO
**Total HU:** 9 | **Refinadas:** 9 (100%) | **En Desarrollo:** 0 | **Pendientes:** 0
