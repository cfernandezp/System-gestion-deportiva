# E006-HU-002 - Ranking de Puntos

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** usuario
**Quiero** ver el ranking por puntos acumulados
**Para** saber quienes son los jugadores mas exitosos del grupo

## Descripcion
Muestra ranking de jugadores ordenados por puntos acumulados segun resultados de sus equipos.

## Sistema de Puntos
- 1er puesto en fecha (2 equipos): 3 pts por jugador
- 2do puesto en fecha (2 equipos): 1 pt por jugador
- 1er puesto en fecha (3 equipos): 3 pts por jugador
- 2do puesto en fecha (3 equipos): 2 pts por jugador
- 3er puesto en fecha (3 equipos): 1 pt por jugador

## Criterios de Aceptacion (CA)

### CA-001: Ranking por puntos
- **Dado** que accedo a "Ranking de puntos"
- **Cuando** veo la lista
- **Entonces** veo jugadores ordenados por puntos acumulados

### CA-002: Informacion por jugador
- **Dado** que veo el ranking
- **Cuando** observo cada entrada
- **Entonces** veo: posicion, foto/avatar, apodo, puntos totales

### CA-003: Filtro por periodo
- **Dado** que veo el ranking
- **Cuando** quiero ver periodos especificos
- **Entonces** puedo filtrar por: Historico, Este ano, Este mes

### CA-004: Detalle de puntos
- **Dado** que selecciono un jugador
- **Cuando** veo el detalle
- **Entonces** veo desglose: fechas jugadas, puesto por fecha, puntos por fecha

### CA-005: Mi posicion destacada
- **Dado** que estoy en el ranking
- **Cuando** veo la lista
- **Entonces** mi posicion aparece destacada

### CA-006: Asistencia como criterio secundario
- **Dado** que hay empate en puntos
- **Cuando** se ordena
- **Entonces** desempata por cantidad de fechas asistidas (mas asistencia = mejor)

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
