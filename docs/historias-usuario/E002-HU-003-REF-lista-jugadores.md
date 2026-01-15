# E002-HU-003 - Lista de Jugadores

## Informacion General
- **Epica**: E002 - Gestion de Jugadores
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Media

## Historia de Usuario
**Como** jugador registrado
**Quiero** ver la lista de miembros del grupo
**Para** conocer quienes forman parte del grupo de pichangas

## Descripcion
Muestra la lista de todos los jugadores aprobados del grupo.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a lista
- **Dado** que estoy autenticado
- **Cuando** accedo a "Jugadores" o "Miembros"
- **Entonces** veo la lista de jugadores del grupo

### CA-002: Informacion mostrada
- **Dado** que veo la lista de jugadores
- **Cuando** observo cada entrada
- **Entonces** veo: foto (o avatar), apodo y posicion preferida

### CA-003: Buscar jugador
- **Dado** que hay muchos jugadores
- **Cuando** busco por nombre o apodo
- **Entonces** la lista se filtra mostrando coincidencias

### CA-004: Ordenamiento
- **Dado** que veo la lista
- **Cuando** quiero ordenar
- **Entonces** puedo ordenar por nombre o por fecha de ingreso

### CA-005: Solo jugadores aprobados
- **Dado** que veo la lista
- **Cuando** hay usuarios pendientes de aprobacion
- **Entonces** NO aparecen en esta lista (solo aprobados)

## 📐 Reglas de Negocio (RN)

### RN-001: Visibilidad exclusiva de jugadores aprobados
**Contexto**: Al mostrar la lista de miembros del grupo
**Restriccion**: No mostrar usuarios con estado pendiente de aprobacion, rechazados o inactivos
**Validacion**: Solo aparecen jugadores cuyo estado sea "aprobado" en el grupo
**Caso especial**: Si no hay jugadores aprobados, mostrar mensaje indicando lista vacia

### RN-002: Informacion publica del jugador en lista
**Contexto**: Al renderizar cada entrada de la lista de jugadores
**Restriccion**: No mostrar informacion sensible (email, telefono, datos privados)
**Validacion**: Cada entrada muestra unicamente: foto o avatar por defecto, apodo del jugador, posicion preferida (o "Sin definir" si no la tiene)
**Caso especial**: Si el jugador no tiene foto, mostrar avatar generico; si no tiene posicion, mostrar "Sin definir"

### RN-003: Busqueda por identificacion del jugador
**Contexto**: Cuando el usuario utiliza el campo de busqueda
**Restriccion**: La busqueda solo aplica sobre nombre completo y apodo, no sobre otros campos
**Validacion**: El filtro debe ser insensible a mayusculas/minusculas y encontrar coincidencias parciales
**Caso especial**: Si la busqueda no retorna resultados, mostrar mensaje "No se encontraron jugadores"

### RN-004: Ordenamiento de la lista
**Contexto**: Cuando el usuario selecciona criterio de ordenamiento
**Restriccion**: Solo se permite ordenar por nombre (alfabetico) o por fecha de ingreso al grupo
**Validacion**: El ordenamiento por defecto es por nombre alfabetico ascendente (A-Z)
**Caso especial**: El usuario puede alternar entre ascendente y descendente para cada criterio

### RN-005: Acceso restringido a usuarios autenticados
**Contexto**: Al intentar acceder a la lista de jugadores
**Restriccion**: Usuarios no autenticados no pueden ver la lista de miembros
**Validacion**: Solo jugadores autenticados y pertenecientes al grupo pueden acceder a esta funcionalidad
**Caso especial**: Si la sesion expira, redirigir al login

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-15
