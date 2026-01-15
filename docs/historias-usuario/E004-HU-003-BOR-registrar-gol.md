# E004-HU-003 - Registrar Gol

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** anotar quien hizo un gol
**Para** llevar el marcador y estadisticas de goleadores

## Descripcion
Permite registrar goles en tiempo real, indicando el jugador que anoto.

## Criterios de Aceptacion (CA)

### CA-001: Boton de gol por equipo
- **Dado** que hay un partido en curso
- **Cuando** veo la pantalla de partido
- **Entonces** veo boton de "Gol" para cada equipo

### CA-002: Seleccionar goleador
- **Dado** que presiono "Gol" de un equipo
- **Cuando** se abre la seleccion
- **Entonces** veo lista de jugadores de ese equipo para seleccionar quien anoto

### CA-003: Registro rapido
- **Dado** que selecciono el goleador
- **Cuando** confirmo
- **Entonces** el gol se registra inmediatamente y el marcador se actualiza

### CA-004: Gol en contra
- **Dado** que hubo un autogol
- **Cuando** registro el gol
- **Entonces** puedo marcar como "Gol en contra" (suma al equipo contrario)

### CA-005: Deshacer gol
- **Dado** que registre un gol por error
- **Cuando** selecciono "Deshacer" (dentro de 30 seg)
- **Entonces** el gol se elimina y el marcador se corrige

### CA-006: Minuto del gol
- **Dado** que registro un gol
- **Cuando** se guarda
- **Entonces** se registra automaticamente el minuto del partido

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
