# E004-HU-004 - Ver Score en Vivo

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** usuario
**Quiero** ver el marcador actual del partido
**Para** saber como va el juego en tiempo real

## Descripcion
Muestra el score actualizado del partido en curso.

## Criterios de Aceptacion (CA)

### CA-001: Marcador visible
- **Dado** que hay un partido en curso
- **Cuando** veo la pantalla
- **Entonces** veo el marcador: Equipo1 [goles] - [goles] Equipo2

### CA-002: Colores de equipo
- **Dado** que veo el marcador
- **Cuando** observo los equipos
- **Entonces** cada equipo se muestra con su color (Naranja, Verde, etc)

### CA-003: Actualizacion en tiempo real
- **Dado** que se registra un gol
- **Cuando** veo el marcador
- **Entonces** se actualiza inmediatamente sin recargar

### CA-004: Lista de goles
- **Dado** que quiero ver detalle
- **Cuando** accedo al detalle del partido
- **Entonces** veo lista de goles con: jugador, minuto, equipo

### CA-005: Tiempo restante
- **Dado** que veo el marcador
- **Cuando** el partido esta en curso
- **Entonces** tambien veo el tiempo restante junto al score

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
