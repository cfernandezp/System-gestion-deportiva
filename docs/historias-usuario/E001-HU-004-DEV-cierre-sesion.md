# E001-HU-004 - Cierre de Sesion

## Informacion General
- **Epica**: E001 - Login de Usuario
- **Estado**: 🔵 En Desarrollo (DEV)
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
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Arquitectura de Logout

**Importante**: Supabase Auth maneja el logout principalmente desde el cliente:
- `supabase.auth.signOut()` invalida el JWT token
- Supabase elimina automaticamente el refresh token

La funcion RPC `cerrar_sesion()` complementa este flujo para:
1. Registrar el evento de cierre de sesion (auditoria)
2. Permitir logica adicional futura
3. Confirmar al cliente que el backend proceso el logout

### Tabla Creada

**`sesiones_log`**
- **Descripcion**: Registro de eventos de inicio y cierre de sesion
- **Columnas**:
  - `id`: UUID (PK)
  - `usuario_id`: UUID (FK -> usuarios)
  - `auth_user_id`: UUID
  - `evento`: VARCHAR ('login' | 'logout')
  - `ip_address`: INET (opcional)
  - `user_agent`: TEXT (opcional)
  - `fecha_evento`: TIMESTAMPTZ
  - `created_at`: TIMESTAMPTZ

### Funciones RPC Implementadas

**`cerrar_sesion() -> JSON`**
- **Descripcion**: Registra el cierre de sesion y confirma la invalidacion
- **Reglas de Negocio**: RN-002
- **Parametros**: Ninguno (usa auth.uid() automaticamente)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "usuario_id": "uuid",
      "email": "user@example.com",
      "fecha_cierre": "2026-01-14T10:30:00-05:00",
      "sesion_invalidada": true
    },
    "message": "Sesion cerrada exitosamente"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> No hay sesion activa
  - `usuario_no_encontrado` -> Usuario no existe en tabla usuarios

**`registrar_inicio_sesion() -> JSON`**
- **Descripcion**: Registra un inicio de sesion exitoso (complemento de HU-002)
- **Uso**: Llamar desde cliente despues de login exitoso
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "usuario_id": "uuid",
      "fecha_login": "2026-01-14T10:30:00-05:00"
    },
    "message": "Inicio de sesion registrado"
  }
  ```

**`obtener_historial_sesiones(p_limite INT) -> JSON`**
- **Descripcion**: Obtiene historial de sesiones del usuario actual
- **Parametros**:
  - `p_limite`: INT (default 10) - Cantidad maxima de registros
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "sesiones": [
        {"evento": "login", "fecha_utc": "...", "fecha_local": "..."},
        {"evento": "logout", "fecha_utc": "...", "fecha_local": "..."}
      ],
      "total": 15
    },
    "message": "Historial obtenido"
  }
  ```

### Script SQL
- `supabase/sql-cloud/2026-01-14_HU-004_cierre_sesion.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Opcion visible -> Frontend (no aplica backend)
- [x] **CA-002**: Cierre exitoso -> Implementado en `cerrar_sesion()`
- [x] **CA-003**: Acceso denegado post-logout -> Supabase Auth + Frontend
- [x] **CA-004**: Sesion no persistente -> Supabase Auth maneja tokens

### Reglas de Negocio Backend
- [x] **RN-001**: Disponibilidad de opcion -> Frontend
- [x] **RN-002**: Invalidacion inmediata -> `cerrar_sesion()` + `supabase.auth.signOut()`
- [x] **RN-003**: Redireccion obligatoria -> Frontend
- [x] **RN-004**: No persistencia de credenciales -> Supabase Auth
- [x] **RN-005**: Proteccion de recursos -> RLS + Frontend

### Flujo Recomendado para Frontend

```dart
// En Flutter/Dart
Future<void> logout() async {
  // 1. Llamar funcion RPC para registrar logout
  final response = await supabase.rpc('cerrar_sesion');

  // 2. Cerrar sesion en Supabase Auth (invalida token)
  await supabase.auth.signOut();

  // 3. Redirigir a login
  Navigator.pushReplacementNamed(context, '/login');
}
```

---
**Creado**: 2025-01-13
**Ultima actualizacion**: 2026-01-14
