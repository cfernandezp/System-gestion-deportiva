# E001-HU-006 - Gestionar Solicitudes de Registro

## Informacion General
- **Epica**: E001 - Login de Usuario
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** ver y gestionar las solicitudes de registro pendientes
**Para** aprobar o rechazar nuevos jugadores que desean unirse al grupo

## Descripcion
Permite al admin visualizar todas las solicitudes de registro pendientes de aprobacion, con la capacidad de aprobar (asignando rol) o rechazar (con motivo opcional) cada solicitud. Los usuarios son notificados del resultado.

## Criterios de Aceptacion (CA)

### CA-001: Acceso exclusivo admin
- **Dado** que soy administrador aprobado
- **Cuando** accedo al menu de administracion
- **Entonces** veo la opcion "Solicitudes Pendientes" disponible
- **Y** si no soy admin, no veo esta opcion

### CA-002: Indicador de solicitudes pendientes
- **Dado** que hay solicitudes pendientes de aprobacion
- **Cuando** veo el menu de administracion
- **Entonces** veo un badge/contador con el numero de pendientes
- **Y** si no hay pendientes, no se muestra el badge

### CA-003: Lista de solicitudes pendientes
- **Dado** que accedo a "Solicitudes Pendientes"
- **Cuando** se carga la pantalla
- **Entonces** veo la lista de usuarios con estado "pendiente_aprobacion"
- **Y** cada solicitud muestra: nombre, email, fecha de registro, dias pendiente

### CA-004: Ordenamiento por antiguedad
- **Dado** que veo la lista de solicitudes
- **Cuando** hay multiples solicitudes
- **Entonces** se ordenan por fecha de registro (mas antiguas primero)
- **Y** se muestra cuantos dias lleva pendiente cada solicitud

### CA-005: Aprobar solicitud
- **Dado** que selecciono "Aprobar" en una solicitud
- **Cuando** confirmo la aprobacion
- **Entonces** puedo seleccionar el rol a asignar (por defecto "Jugador")
- **Y** el usuario pasa a estado "aprobado"
- **Y** el usuario recibe notificacion de aprobacion
- **Y** la solicitud desaparece de la lista

### CA-006: Rechazar solicitud
- **Dado** que selecciono "Rechazar" en una solicitud
- **Cuando** se abre el dialog de rechazo
- **Entonces** puedo ingresar un motivo (opcional)
- **Y** al confirmar, el usuario pasa a estado "rechazado"
- **Y** el usuario recibe notificacion con el motivo (si se proporciono)
- **Y** la solicitud desaparece de la lista

### CA-007: Estado vacio
- **Dado** que no hay solicitudes pendientes
- **Cuando** veo la pantalla
- **Entonces** veo un mensaje indicando que no hay solicitudes pendientes
- **Y** se muestra un icono ilustrativo

### CA-008: Confirmacion de acciones
- **Dado** que voy a aprobar o rechazar
- **Cuando** presiono el boton de accion
- **Entonces** veo un dialog de confirmacion antes de ejecutar
- **Y** puedo cancelar la accion

### CA-009: Feedback de exito
- **Dado** que apruebo o rechazo una solicitud
- **Cuando** la accion se completa exitosamente
- **Entonces** veo un mensaje de confirmacion (SnackBar)
- **Y** la lista se actualiza automaticamente

### CA-010: Notificacion push al admin
- **Dado** que soy admin con sesion activa
- **Cuando** un nuevo usuario se registra
- **Entonces** recibo notificacion de nueva solicitud pendiente
- **Y** el badge de pendientes se actualiza

---

## Reglas de Negocio (RN)

### RN-001: Acceso Exclusivo Administrador
**Contexto**: Solo administradores pueden gestionar solicitudes de registro.
**Restriccion**: Usuarios con rol "jugador" no tienen acceso a esta funcionalidad.
**Validacion**: Verificar rol = 'admin' y estado = 'aprobado' antes de permitir acceso.
**Regla calculo**: N/A.
**Caso especial**: Si no hay admins activos, las solicitudes quedan en cola hasta que se restaure un admin.

### RN-002: Solo Solicitudes Pendientes
**Contexto**: La pantalla muestra unicamente usuarios pendientes de aprobacion.
**Restriccion**: No mostrar usuarios ya aprobados o rechazados en esta vista.
**Validacion**: Filtrar por estado = 'pendiente_aprobacion'.
**Regla calculo**: N/A.
**Caso especial**: Usuarios rechazados pueden volver a registrarse con el mismo email.

### RN-003: Rol por Defecto al Aprobar
**Contexto**: Al aprobar un usuario, se debe asignar un rol.
**Restriccion**: No dejar usuarios aprobados sin rol.
**Validacion**: El rol por defecto es "Jugador", pero el admin puede seleccionar otro.
**Regla calculo**: Rol inicial = "Jugador" si no se especifica otro.
**Caso especial**: El admin puede asignar rol "Admin" si lo desea.

### RN-004: Notificacion Obligatoria al Usuario
**Contexto**: El usuario debe ser informado del resultado de su solicitud.
**Restriccion**: Siempre se envia notificacion al aprobar o rechazar.
**Validacion**: Insertar registro en tabla notificaciones con tipo correspondiente.
**Regla calculo**: N/A.
**Caso especial**: Si el email del usuario es invalido, la notificacion queda solo en el sistema.

### RN-005: Motivo de Rechazo Opcional
**Contexto**: El admin puede proporcionar un motivo al rechazar.
**Restriccion**: El motivo no es obligatorio.
**Validacion**: Si se proporciona, se guarda en campo motivo_rechazo y se incluye en notificacion.
**Regla calculo**: N/A.
**Caso especial**: Si no hay motivo, la notificacion indica "Tu solicitud ha sido rechazada".

### RN-006: Ordenamiento por Antiguedad
**Contexto**: Las solicitudes mas antiguas deben atenderse primero.
**Restriccion**: Ordenar siempre por fecha de creacion ascendente.
**Validacion**: ORDER BY created_at ASC.
**Regla calculo**: dias_pendiente = fecha_actual - created_at.
**Caso especial**: Solicitudes del mismo dia se ordenan por hora.

### RN-007: Accion Irreversible
**Contexto**: Una vez aprobado o rechazado, no se puede deshacer desde esta pantalla.
**Restriccion**: Confirmar antes de ejecutar la accion.
**Validacion**: Mostrar dialog de confirmacion.
**Regla calculo**: N/A.
**Caso especial**: Un usuario rechazado puede volver a registrarse. Un usuario aprobado puede ser modificado desde gestion de roles.

### RN-008: Actualizacion en Tiempo Real
**Contexto**: Si hay multiples admins, la lista debe reflejar cambios.
**Restriccion**: Al aprobar/rechazar, la lista se actualiza para evitar acciones duplicadas.
**Validacion**: Recargar lista despues de cada accion exitosa.
**Regla calculo**: N/A.
**Caso especial**: Si otro admin ya proceso la solicitud, mostrar mensaje informativo.

---

## Notas Tecnicas

### Backend (Ya implementado en E001-HU-001)
- `obtener_usuarios_pendientes()` - Lista usuarios pendientes
- `aprobar_usuario(p_usuario_id, p_rol)` - Aprueba con rol
- `rechazar_usuario(p_usuario_id, p_motivo)` - Rechaza con motivo opcional

### Frontend (Por implementar)
- Pagina: `solicitudes_pendientes_page.dart`
- Widgets: `solicitud_card.dart`, `aprobar_dialog.dart`, `rechazar_dialog.dart`
- Bloc: `solicitudes_bloc.dart` (o extender `UsuariosBloc`)
- Ruta: `/admin/solicitudes`

### Integracion con menu
- Agregar item "Solicitudes" en DashboardShell/Drawer para admins
- Badge con contador de pendientes

---
**Creado**: 2026-01-27
**Refinado**: 2026-01-27

