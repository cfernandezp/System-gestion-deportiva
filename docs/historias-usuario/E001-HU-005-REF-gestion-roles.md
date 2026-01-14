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
- **Entonces** puedo elegir entre: Admin, Entrenador, Jugador, Arbitro

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
| Admin | Administrador del sistema | Acceso total |
| Entrenador | Director tecnico | Gestiona equipos y jugadores asignados |
| Jugador | Miembro de equipo | Ve su informacion y estadisticas |
| Arbitro | Oficial de partidos | Gestiona partidos asignados |

## Reglas de Negocio (RN)

### RN-001: Roles Validos del Sistema
**Contexto**: Cuando se asigna o modifica el rol de un usuario.
**Restriccion**: No se pueden crear, eliminar o usar roles fuera del catalogo oficial.
**Validacion**: Solo existen cuatro roles validos: Admin, Entrenador, Jugador, Arbitro.
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
**Ultima actualizacion**: 2026-01-13
