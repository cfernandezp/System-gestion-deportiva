# E001-HU-004 - Cierre de Sesion

## Informacion General
- **Epica**: E001 - Login de Usuario
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Alta

## Historia de Usuario
**Como** usuario autenticado
**Quiero** cerrar mi sesion
**Para** proteger mi cuenta cuando termine de usar el sistema

## Descripcion
Permite a usuarios autenticados cerrar su sesion de forma segura, invalidando su acceso actual.

## Criterios de Aceptacion (CA)

### CA-001: Opcion de cerrar sesion visible
- **Dado** que estoy autenticado en el sistema
- **Cuando** quiero cerrar sesion
- **Entonces** debo ver una opcion clara para "Cerrar sesion" o "Logout"

### CA-002: Cierre de sesion exitoso
- **Dado** que selecciono cerrar sesion
- **Cuando** confirmo la accion
- **Entonces** mi sesion se cierra y veo la pantalla de login

### CA-003: Acceso denegado post-logout
- **Dado** que cerre mi sesion
- **Cuando** intento acceder a una pagina protegida
- **Entonces** soy redirigido a la pantalla de login

### CA-004: Sesion no persistente
- **Dado** que cerre mi sesion
- **Cuando** cierro y vuelvo a abrir el navegador
- **Entonces** debo iniciar sesion nuevamente para acceder

## Reglas de Negocio (RN)

### RN-001: Disponibilidad de la opcion de cierre
**Contexto**: Usuario navegando en cualquier seccion del sistema mientras esta autenticado.
**Restriccion**: La opcion de cerrar sesion NO debe ocultarse ni deshabilitarse mientras el usuario tenga una sesion activa.
**Validacion**: El usuario debe poder localizar y acceder a la opcion de cierre de sesion desde cualquier pantalla del sistema.
**Caso especial**: Ninguno. Siempre disponible para usuarios autenticados.

### RN-002: Invalidacion inmediata de la sesion
**Contexto**: Usuario confirma el cierre de sesion.
**Restriccion**: NO se permite mantener acceso parcial o temporal despues del cierre. La sesion debe quedar invalida en su totalidad.
**Validacion**: Una vez cerrada la sesion, el usuario pierde inmediatamente todos los privilegios de acceso asociados a esa sesion.
**Caso especial**: Si el usuario tiene multiples sesiones activas (diferentes dispositivos), solo se cierra la sesion actual, no las demas.

### RN-003: Redireccion obligatoria post-cierre
**Contexto**: Sesion cerrada exitosamente.
**Restriccion**: NO se permite que el usuario permanezca en una pagina protegida despues del cierre.
**Validacion**: El usuario debe ser dirigido automaticamente a la pantalla de inicio de sesion.
**Caso especial**: Ninguno.

### RN-004: No persistencia de credenciales post-cierre
**Contexto**: Usuario cerro sesion y cierra el navegador o aplicacion.
**Restriccion**: NO se permite que la sesion se restaure automaticamente al reabrir el sistema.
**Validacion**: El usuario debe autenticarse nuevamente para acceder al sistema despues de un cierre de sesion.
**Caso especial**: Si el usuario marco "Recordarme" en el login, esta preferencia se elimina al cerrar sesion explicitamente.

### RN-005: Proteccion de recursos post-cierre
**Contexto**: Usuario intenta acceder a recursos protegidos despues de cerrar sesion.
**Restriccion**: NO se permite acceso a ninguna funcionalidad que requiera autenticacion.
**Validacion**: Cualquier intento de acceso a paginas protegidas debe redirigir al usuario a la pantalla de login.
**Caso especial**: Paginas publicas (si existen) permanecen accesibles sin autenticacion.

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

## Mockups/Wireframes
- Pendiente

---
**Creado**: 2025-01-13
**Ultima actualizacion**: 2025-01-13
