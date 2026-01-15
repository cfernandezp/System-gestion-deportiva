# E006-HU-001 - Ranking de Goleadores

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** usuario
**Quiero** ver el ranking de goleadores
**Para** saber quienes son los maximos anotadores del grupo

## Descripcion
Muestra ranking de jugadores ordenados por cantidad de goles.

## Criterios de Aceptacion (CA)

### CA-001: Ranking general
- **Dado** que accedo a "Goleadores"
- **Cuando** veo el ranking
- **Entonces** veo lista de jugadores ordenados por goles (mayor a menor)

### CA-002: Informacion por jugador
- **Dado** que veo el ranking
- **Cuando** observo cada entrada
- **Entonces** veo: posicion, foto/avatar, apodo, cantidad de goles

### CA-003: Filtro por periodo
- **Dado** que veo el ranking
- **Cuando** quiero ver periodos especificos
- **Entonces** puedo filtrar por: Historico, Este ano, Este mes, Ultima fecha

### CA-004: Empates
- **Dado** que varios jugadores tienen mismos goles
- **Cuando** veo el ranking
- **Entonces** comparten posicion o se ordena por otro criterio (ej: menos partidos jugados)

### CA-005: Mi posicion destacada
- **Dado** que estoy en el ranking
- **Cuando** veo la lista
- **Entonces** mi posicion aparece destacada

### CA-006: Top 3 destacado
- **Dado** que veo el ranking
- **Cuando** hay suficientes jugadores
- **Entonces** el top 3 se muestra de forma especial (podio, medallas)

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
