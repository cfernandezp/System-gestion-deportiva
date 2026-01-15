# E003 - Gestion de Fechas/Jornadas

## Descripcion
Gestiona las jornadas de pichanga: creacion de fechas, inscripcion de jugadores y asignacion de equipos por colores.

## Objetivo
Permitir a los administradores organizar las pichangas semanales y a los jugadores inscribirse y conocer su equipo asignado.

## Contexto de Negocio
- Se alquila cancha 1 dia a la semana (1 o 2 horas)
- Jugadores se anotan confirmando asistencia
- Admin cierra inscripciones y distribuye en equipos (2, 3 o 4)
- Cada jugador debe saber su equipo/color de chaleco antes de llegar

## Formatos de Juego

| Formato | Duracion | Equipos | Costo |
|---------|----------|---------|-------|
| 1 Hora | 60 min | 2 equipos | S/ 8 |
| 2 Horas | 120 min | 3 equipos | S/ 10 |

## Colores de Equipo
- Naranja
- Verde
- Azul
- Rojo (casos extraordinarios)

## Alcance
- Crear fecha/jornada
- Inscripcion de jugadores
- Cierre de inscripciones
- Asignacion de equipos por colores
- Ver fecha actual y proximas

## Historias de Usuario

| ID | Titulo | Estado | Descripcion |
|----|--------|--------|-------------|
| E003-HU-001 | Crear Fecha | 🟡 PEN | Como admin, quiero crear una nueva jornada de pichanga |
| E003-HU-002 | Inscribirse a Fecha | 🟡 PEN | Como jugador, quiero anotarme para la proxima pichanga |
| E003-HU-003 | Ver Inscritos | 🟡 PEN | Como usuario, quiero ver quienes se anotaron |
| E003-HU-004 | Cerrar Inscripciones | 🟡 PEN | Como admin, quiero cerrar las inscripciones |
| E003-HU-005 | Asignar Equipos | 🟡 PEN | Como admin, quiero distribuir jugadores en equipos |
| E003-HU-006 | Ver Mi Equipo | 🟡 PEN | Como jugador, quiero saber a que equipo/color pertenezco |
| E003-HU-007 | Cancelar Inscripcion | 🟡 PEN | Como jugador, quiero cancelar mi asistencia |

## Dependencias
- E001: Login de Usuario
- E002: Gestion de Jugadores

---
**Version**: 1.0
**Estado**: 🟡 En Definicion
