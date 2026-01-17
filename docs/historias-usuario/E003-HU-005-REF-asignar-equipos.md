# E003-HU-005 - Asignar Equipos

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟢 Refinado (REF)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** distribuir a los jugadores inscritos en equipos
**Para** que cada uno sepa su equipo y color de chaleco

## Descripcion
Permite al admin asignar jugadores a equipos identificados por colores. La cantidad de equipos depende de la duracion de la fecha (2 o 3 equipos).

## Criterios de Aceptacion (CA)

### CA-001: Acceso a asignacion
- **Dado** que las inscripciones estan cerradas
- **Cuando** accedo a "Asignar equipos"
- **Entonces** veo la lista de inscritos a la izquierda
- **Y** los equipos disponibles a la derecha (con colores)

### CA-002: Equipos segun formato
- **Dado** que la fecha es de 1 hora
- **Cuando** asigno equipos
- **Entonces** hay 2 equipos disponibles
- **Dado** que la fecha es de 2 horas
- **Cuando** asigno equipos
- **Entonces** hay 3 equipos disponibles

### CA-003: Colores de equipos
- **Dado** que veo los equipos
- **Cuando** observo las opciones
- **Entonces** los equipos tienen colores distintivos
- **Y** los colores base son: Naranja, Verde, Azul (si aplica)

### CA-004: Asignacion manual drag-drop
- **Dado** que veo un jugador sin asignar
- **Cuando** lo arrastro a un equipo
- **Entonces** queda asignado a ese equipo
- **Y** se muestra con el color del equipo

### CA-005: Asignacion con selector
- **Dado** que veo un jugador
- **Cuando** hago tap/click en el
- **Entonces** veo selector de equipo (Naranja/Verde/Azul)
- **Y** al seleccionar queda asignado

### CA-006: Advertencia de desbalance
- **Dado** que asigno jugadores
- **Cuando** un equipo tiene 2+ jugadores mas que otro
- **Entonces** veo advertencia visual "Equipos desbalanceados"
- **Y** puedo continuar si lo deseo

### CA-007: Confirmar asignacion
- **Dado** que termine de asignar todos los jugadores
- **Cuando** presiono "Confirmar equipos"
- **Entonces** los equipos quedan guardados
- **Y** todos los jugadores pueden ver su equipo

### CA-008: Modificar antes de iniciar
- **Dado** que ya confirme equipos
- **Cuando** la fecha aun no inicia (estado != 'en_juego')
- **Entonces** puedo reasignar jugadores
- **Y** los cambios se notifican a los afectados

---

## Reglas de Negocio (RN)

### RN-001: Permiso Exclusivo Admin
**Contexto**: Solo administradores pueden asignar equipos.
**Restriccion**: Jugadores no tienen acceso a esta funcionalidad.
**Validacion**: rol = 'admin' AND estado = 'aprobado'.
**Regla calculo**: N/A.
**Caso especial**: N/A.

### RN-002: Estado Valido para Asignar
**Contexto**: Solo se asignan equipos cuando inscripciones estan cerradas.
**Restriccion**: No se puede asignar si fecha.estado != 'cerrada'.
**Validacion**: fecha.estado = 'cerrada'.
**Regla calculo**: N/A.
**Caso especial**: Si se reabre inscripciones, las asignaciones se eliminan.

### RN-003: Cantidad de Equipos por Duracion
**Contexto**: El numero de equipos es fijo segun duracion.
**Restriccion**: No se puede cambiar la cantidad de equipos.
**Validacion**: Sistema determina automaticamente.
**Regla calculo**:
- 1 hora = 2 equipos
- 2 horas = 3 equipos
**Caso especial**: N/A.

### RN-004: Colores de Equipos Predefinidos
**Contexto**: Los colores identifican visualmente a cada equipo.
**Restriccion**: Los colores son fijos del catalogo.
**Validacion**: Enum color_equipo.
**Regla calculo**: Catalogo: naranja, verde, azul, rojo, amarillo, blanco.
**Caso especial**: Para 2 equipos usar naranja y verde. Para 3 equipos agregar azul.

### RN-005: Asignacion Completa Requerida
**Contexto**: Todos los jugadores inscritos deben tener equipo asignado.
**Restriccion**: No se puede confirmar con jugadores sin equipo.
**Validacion**: COUNT(sin_equipo) = 0 para permitir confirmar.
**Regla calculo**: N/A.
**Caso especial**: Si hay jugadores de mas (no divisible), se permite desbalance menor.

### RN-006: Balance de Equipos (Advertencia)
**Contexto**: Los equipos deben estar equilibrados en numero.
**Restriccion**: Diferencia maxima recomendada: 1 jugador entre equipos.
**Validacion**: |equipo_A.count - equipo_B.count| <= 1 para cada par.
**Regla calculo**: Advertencia si diferencia > 1.
**Caso especial**: Admin puede ignorar advertencia y confirmar equipos desbalanceados.

### RN-007: Notificacion de Asignacion
**Contexto**: Jugadores deben saber su equipo asignado.
**Restriccion**: N/A.
**Validacion**: Trigger de notificacion al confirmar equipos.
**Regla calculo**: N/A.
**Caso especial**: Notificacion incluye color de equipo y companeros.

### RN-008: Modificacion Pre-Partido
**Contexto**: Se pueden cambiar asignaciones antes de empezar.
**Restriccion**: Solo mientras fecha.estado = 'cerrada'.
**Validacion**: fecha.estado != 'en_juego' AND fecha.estado != 'finalizada'.
**Regla calculo**: N/A.
**Caso especial**: Si se cambia asignacion, notificar al jugador afectado.

---

## Notas Tecnicas
- Tabla: `asignaciones_equipo` con campos: id, fecha_id, usuario_id, equipo (enum color)
- Enum color_equipo: 'naranja', 'verde', 'azul', 'rojo', 'amarillo', 'blanco'
- UI: Drag and drop para web, selector para mobile
- Subscripcion realtime para que jugadores vean asignacion

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16
