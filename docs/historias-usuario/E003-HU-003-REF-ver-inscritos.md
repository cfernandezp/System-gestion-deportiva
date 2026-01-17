# E003-HU-003 - Ver Inscritos

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟢 Refinado (REF)
- **Prioridad**: Media

## Historia de Usuario
**Como** usuario (admin o jugador)
**Quiero** ver quienes se anotaron a la pichanga
**Para** saber cuantos y quienes asistiran

## Descripcion
Muestra la lista de jugadores inscritos a una fecha, permitiendo a todos ver quien asistira.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a lista de inscritos
- **Dado** que veo una fecha
- **Cuando** selecciono "Ver inscritos" o el contador de jugadores
- **Entonces** veo la lista completa de jugadores anotados

### CA-002: Informacion de cada inscrito
- **Dado** que veo la lista de inscritos
- **Cuando** observo cada entrada
- **Entonces** veo: foto/avatar, apodo, posicion preferida (si tiene)
- **Y** la lista esta ordenada por orden de inscripcion

### CA-003: Contador total
- **Dado** que veo la lista
- **Cuando** hay jugadores inscritos
- **Entonces** veo header con "X jugadores anotados"
- **Y** el numero coincide con la cantidad de la lista

### CA-004: Lista vacia
- **Dado** que no hay inscritos
- **Cuando** veo la lista
- **Entonces** veo mensaje "Aun no hay jugadores anotados"
- **Y** veo icono ilustrativo de lista vacia

### CA-005: Mi inscripcion destacada
- **Dado** que estoy inscrito
- **Cuando** veo la lista
- **Entonces** mi nombre aparece con indicador "(Tu)" al lado
- **Y** opcionalmente fondo diferenciado

### CA-006: Actualizacion en tiempo real
- **Dado** que estoy viendo la lista
- **Cuando** otro jugador se inscribe o cancela
- **Entonces** la lista se actualiza automaticamente
- **Y** veo el cambio sin recargar la pagina

---

## Reglas de Negocio (RN)

### RN-001: Visibilidad de Inscritos
**Contexto**: Todos los usuarios aprobados pueden ver la lista de inscritos.
**Restriccion**: Usuarios no autenticados o no aprobados no ven la lista.
**Validacion**: usuario.estado = 'aprobado'.
**Regla calculo**: N/A.
**Caso especial**: La lista es publica dentro del grupo, no hay restricciones entre jugadores.

### RN-002: Informacion Visible de Inscritos
**Contexto**: Solo se muestra informacion publica de cada inscrito.
**Restriccion**: No se muestra: email, telefono, fecha de nacimiento.
**Validacion**: Query solo selecciona campos permitidos.
**Regla calculo**: Campos visibles: foto_url, apodo, nombre_completo, posicion_preferida.
**Caso especial**: Si no tiene apodo, mostrar nombre_completo.

### RN-003: Orden de Visualizacion
**Contexto**: La lista tiene un orden predeterminado.
**Restriccion**: N/A.
**Validacion**: ORDER BY inscripciones.created_at ASC.
**Regla calculo**: Primero quien se inscribio primero (orden de llegada).
**Caso especial**: Admin puede ver opcion de ordenar por nombre si lo prefiere.

### RN-004: Solo Inscripciones Activas
**Contexto**: Solo se muestran jugadores actualmente inscritos.
**Restriccion**: Inscripciones canceladas no aparecen en la lista.
**Validacion**: inscripcion.estado = 'inscrito'.
**Regla calculo**: N/A.
**Caso especial**: Historial de cancelaciones solo visible para admin (si se implementa).

### RN-005: Actualizacion en Tiempo Real
**Contexto**: La lista debe reflejar el estado actual.
**Restriccion**: Latencia maxima aceptable: 5 segundos.
**Validacion**: Implementar subscripcion a cambios (Supabase Realtime).
**Regla calculo**: N/A.
**Caso especial**: Si falla conexion realtime, permitir pull-to-refresh manual.

---

## Notas Tecnicas
- Query: JOIN inscripciones + usuarios WHERE inscripcion.estado = 'inscrito'
- Supabase Realtime para actualizaciones en vivo
- Componente reutilizable para lista de jugadores (usado en otros contextos)

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16
