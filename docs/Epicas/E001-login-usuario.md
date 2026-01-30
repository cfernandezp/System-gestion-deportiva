# E001 - Login de Usuario

## Descripcion
Gestiona la autenticacion y autorizacion de usuarios en el sistema de gestion deportiva, incluyendo registro, inicio de sesion, recuperacion de contrasena y asignacion de roles.

## Objetivo
Permitir que los usuarios accedan al sistema de forma segura segun su rol (Admin o Jugador) con autenticacion por email/password.

## Alcance
- Registro de nuevos usuarios
- Inicio de sesion (login)
- Cierre de sesion (logout)
- Recuperacion de contrasena
- Gestion de roles y permisos
- Aprobacion de solicitudes de registro

## Historias de Usuario

| ID | Titulo | Estado | Descripcion |
|----|--------|--------|-------------|
| E001-HU-001 | Registro de Usuario | ✅ COM | Como nuevo usuario, quiero registrarme en el sistema |
| E001-HU-002 | Inicio de Sesion | ✅ COM | Como usuario registrado, quiero iniciar sesion |
| E001-HU-003 | Recuperacion de Contrasena | ✅ COM | Como usuario, quiero recuperar mi contrasena si la olvido |
| E001-HU-004 | Cierre de Sesion | ✅ COM | Como usuario autenticado, quiero cerrar mi sesion |
| E001-HU-005 | Gestion de Roles | ✅ COM | Como administrador, quiero asignar roles a usuarios |
| E001-HU-006 | Gestionar Solicitudes de Registro | 🟢 REF | Como administrador, quiero aprobar o rechazar nuevos usuarios |

## Roles del Sistema
- **Admin**: Acceso total (crear fechas, asignar equipos, registrar goles, gestionar pagos, aprobar usuarios)
- **Jugador**: Inscribirse a fechas, ver su equipo, ver estadisticas, ver historial de pagos

## Dependencias
- Ninguna (es la epica base del sistema)

## Criterios de Exito
- Usuarios pueden registrarse y acceder al sistema
- Cada usuario tiene un rol asignado
- Las contrasenas se pueden recuperar de forma segura
- Solo usuarios autenticados acceden a funcionalidades protegidas

---
**Version**: 1.0
**Estado**: 🟡 En Definicion
