# E006 - Estadisticas y Rankings

## Descripcion
Muestra estadisticas de jugadores, equipos y rankings historicos.

## Objetivo
Permitir a los usuarios ver goleadores, puntos acumulados y estadisticas historicas.

## Contexto de Negocio

### Sistema de Puntuacion por Equipo (en la fecha)
- Victoria: 3 pts
- Empate: 1 pt
- Derrota: 0 pts

### Puntos por Jugador (segun puesto de su equipo)

| Formato | 1er Puesto | 2do Puesto | 3er Puesto |
|---------|------------|------------|------------|
| 2 equipos | 3 pts | 1 pt | - |
| 3 equipos | 3 pts | 2 pts | 1 pt |

### Metricas Clave
- Goles por jugador (fecha, mes, ano, historico)
- Puntos acumulados por jugador
- Asistencias a fechas
- Equipo ganador por fecha

## Alcance
- Ranking de goleadores
- Ranking de puntos
- Estadisticas por jugador
- Resultados por fecha
- Historico mensual/anual

## Historias de Usuario

| ID | Titulo | Estado | Descripcion |
|----|--------|--------|-------------|
| E006-HU-001 | Ranking Goleadores | 🟡 PEN | Como usuario, quiero ver el ranking de goleadores |
| E006-HU-002 | Ranking Puntos | 🟡 PEN | Como usuario, quiero ver el ranking por puntos |
| E006-HU-003 | Mis Estadisticas | 🟡 PEN | Como jugador, quiero ver mis estadisticas personales |
| E006-HU-004 | Resultados por Fecha | 🟡 PEN | Como usuario, quiero ver resultados de una fecha especifica |
| E006-HU-005 | Estadisticas Mensuales | 🟡 PEN | Como usuario, quiero ver estadisticas del mes |
| E006-HU-006 | Goleador de la Fecha | 🟡 PEN | Como usuario, quiero ver quien fue el goleador de la fecha |

## Dependencias
- E001: Login de Usuario
- E002: Gestion de Jugadores
- E003: Gestion de Fechas
- E004: Partidos en Vivo

---
**Version**: 1.0
**Estado**: 🟡 En Definicion
