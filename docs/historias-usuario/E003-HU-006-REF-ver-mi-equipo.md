# E003-HU-006 - Ver Mi Equipo

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟢 Refinado (REF)
- **Prioridad**: Alta

## Historia de Usuario
**Como** jugador inscrito
**Quiero** saber a que equipo pertenezco
**Para** llegar a la cancha con el chaleco del color correcto

## Descripcion
Muestra al jugador su equipo asignado y el color de chaleco que debe usar, junto con sus companeros de equipo.

## Criterios de Aceptacion (CA)

### CA-001: Ver mi equipo asignado
- **Dado** que estoy inscrito y los equipos fueron asignados
- **Cuando** veo la fecha
- **Entonces** veo prominentemente mi equipo con su color
- **Y** ejemplo: "Equipo Naranja" con fondo naranja

### CA-002: Color visual destacado
- **Dado** que veo mi equipo
- **Cuando** observo la pantalla
- **Entonces** el color se muestra claramente (fondo, borde o icono)
- **Y** el contraste es suficiente para identificar rapidamente

### CA-003: Lista de companeros
- **Dado** que veo mi equipo
- **Cuando** expando los detalles
- **Entonces** veo la lista de companeros del mismo equipo
- **Y** cada uno muestra: foto/avatar, apodo

### CA-004: Ver todos los equipos
- **Dado** que los equipos estan asignados
- **Cuando** quiero ver la distribucion completa
- **Entonces** puedo ver los 2 o 3 equipos con sus jugadores
- **Y** mi equipo aparece primero o destacado

### CA-005: Equipos no asignados aun
- **Dado** que estoy inscrito
- **Cuando** los equipos aun no se asignaron
- **Entonces** veo mensaje "Esperando asignacion de equipos"
- **Y** veo icono de reloj o pendiente

### CA-006: No inscrito
- **Dado** que no estoy inscrito a la fecha
- **Cuando** veo la fecha
- **Entonces** no veo seccion de "Mi equipo"
- **Y** solo veo opcion de inscribirme (si esta abierta) o los equipos generales

### CA-007: Cambio de equipo notificado
- **Dado** que tengo equipo asignado
- **Cuando** el admin me cambia de equipo
- **Entonces** recibo notificacion del cambio
- **Y** la vista se actualiza con el nuevo equipo

---

## Reglas de Negocio (RN)

### RN-001: Visibilidad de Equipo Propio
**Contexto**: Cada jugador inscrito puede ver su equipo asignado.
**Restriccion**: Solo ve su asignacion si esta inscrito y equipos fueron confirmados.
**Validacion**: EXISTS inscripcion (usuario, fecha) AND EXISTS asignacion_equipo (usuario, fecha).
**Regla calculo**: N/A.
**Caso especial**: Si no hay asignacion, mostrar estado pendiente.

### RN-002: Visibilidad de Todos los Equipos
**Contexto**: Cualquier jugador inscrito puede ver la distribucion completa.
**Restriccion**: No se ocultan equipos rivales.
**Validacion**: Si usuario tiene inscripcion activa a la fecha.
**Regla calculo**: N/A.
**Caso especial**: Jugadores no inscritos pueden ver equipos pero no destacado "el suyo".

### RN-003: Informacion de Companeros
**Contexto**: Se muestra informacion basica de companeros de equipo.
**Restriccion**: Solo informacion publica: foto, apodo.
**Validacion**: Query con campos limitados.
**Regla calculo**: N/A.
**Caso especial**: Si un jugador no tiene foto, mostrar avatar con inicial.

### RN-004: Actualizacion en Tiempo Real
**Contexto**: Si el admin modifica equipos, el cambio debe reflejarse.
**Restriccion**: Latencia maxima aceptable: 5 segundos.
**Validacion**: Subscripcion Supabase Realtime a asignaciones_equipo.
**Regla calculo**: N/A.
**Caso especial**: Mostrar indicador de "actualizado" al recibir cambios.

### RN-005: Codigo de Color Consistente
**Contexto**: El color del equipo debe ser uniforme en toda la app.
**Restriccion**: Usar palette de colores definida en design system.
**Validacion**: Colores hex predefinidos por color_equipo.
**Regla calculo**:
- naranja: #FF9800
- verde: #4CAF50
- azul: #2196F3
- rojo: #F44336
- amarillo: #FFEB3B
- blanco: #FFFFFF (con borde gris)
**Caso especial**: En modo oscuro ajustar luminosidad para contraste.

---

## Notas Tecnicas
- Query: asignaciones_equipo JOIN usuarios WHERE fecha_id AND usuario_id = current
- Componente: EquipoCard con color dinamico
- Supabase Realtime para actualizaciones
- Animacion al recibir asignacion inicial

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16
