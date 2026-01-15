# E003-HU-003 - Ver Inscritos

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** usuario
**Quiero** ver quienes se anotaron a la pichanga
**Para** saber cuantos y quienes asistiran

## Descripcion
Muestra la lista de jugadores inscritos a una fecha.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a lista de inscritos
- **Dado** que veo una fecha
- **Cuando** selecciono "Ver inscritos"
- **Entonces** veo la lista de jugadores anotados

### CA-002: Informacion de cada inscrito
- **Dado** que veo la lista de inscritos
- **Cuando** observo cada entrada
- **Entonces** veo: foto/avatar, apodo del jugador

### CA-003: Contador de inscritos
- **Dado** que veo la lista
- **Cuando** hay jugadores inscritos
- **Entonces** veo el total de inscritos

### CA-004: Lista vacia
- **Dado** que no hay inscritos
- **Cuando** veo la lista
- **Entonces** veo mensaje "Aun no hay inscritos"

### CA-005: Mi inscripcion destacada
- **Dado** que estoy inscrito
- **Cuando** veo la lista
- **Entonces** mi nombre aparece destacado o con indicador

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
