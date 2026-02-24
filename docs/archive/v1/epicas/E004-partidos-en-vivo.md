# E004 - Partidos en Vivo

## Descripcion
Gestiona el desarrollo de los partidos en tiempo real: temporizador, registro de goles, score y rotacion de equipos.

## Objetivo
Facilitar el control del tiempo de partidos y el registro de goles en tiempo real durante la pichanga.

## Contexto de Negocio
- Partidos con duracion definida (10 o 20 minutos)
- Alarma sonora al terminar cada partido
- Registro de goles por jugador en tiempo real
- Score actualizado (ej: Naranja 2 - Verde 1)
- Sistema de rotacion para 3 equipos

## Relacion con Fechas (E003)
- Una **Fecha** (E003) puede tener multiples **Partidos** (E004)
- Los partidos solo existen cuando la fecha esta en estado `en_juego`
- Jerarquia: Fecha → Partidos → Goles

## Formatos de Partido

| Formato | Equipos | Partidos | Duracion/Partido |
|---------|---------|----------|------------------|
| 1 Hora | 2 | 3 partidos | 20 min |
| 2 Horas | 3 | Rotacion | 10 min |

## Sistema de Rotacion (3 equipos)
1. Dos equipos inician (seleccion manual)
2. Ganador continua, perdedor descansa
3. Despues de 2 partidos seguidos, equipo descansa obligatoriamente
4. Empate: admin decide quien continua

## Alcance
- Iniciar partido con temporizador
- Alarma al finalizar tiempo
- Registrar goles (jugador + equipo)
- Ver score en tiempo real
- Gestionar rotacion de equipos
- Finalizar jornada

## Historias de Usuario

| ID | Titulo | Estado | Descripcion |
|----|--------|--------|-------------|
| E004-HU-001 | Iniciar Partido | 🟢 REF | Como admin, quiero iniciar un partido con temporizador |
| E004-HU-002 | Temporizador con Alarma | 🟢 REF | Como usuario, quiero que suene alarma al terminar el tiempo |
| E004-HU-003 | Registrar Gol | 🟢 REF | Como admin, quiero anotar quien hizo gol |
| E004-HU-004 | Ver Score en Vivo | 🟢 REF | Como usuario, quiero ver el marcador actual |
| E004-HU-005 | Finalizar Partido | 🟢 REF | Como admin, quiero terminar el partido y registrar resultado |
| E004-HU-006 | Rotacion de Equipos | 🟢 REF | Como admin, quiero gestionar que equipo entra/sale |
| E004-HU-007 | Resumen de Jornada | 🟢 REF | Como usuario, quiero ver resumen de todos los partidos |

## Dependencias
- E001: Login de Usuario
- E002: Gestion de Jugadores
- E003: Gestion de Fechas (estado `en_juego`)

---
**Version**: 1.1
**Estado**: 🟢 Refinada
**Refinado**: 2026-01-29
