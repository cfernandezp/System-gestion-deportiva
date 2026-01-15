# E004-HU-006 - Rotacion de Equipos

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** gestionar que equipo entra y cual sale
**Para** seguir el sistema de rotacion de 3 equipos

## Descripcion
Gestiona la rotacion de equipos en formato de 3 equipos (2 horas).

## Contexto de Rotacion
- 2 equipos juegan, 1 descansa
- Ganador continua, perdedor descansa
- Despues de 2 partidos seguidos, equipo descansa obligatoriamente
- En empate, admin decide quien continua

## Criterios de Aceptacion (CA)

### CA-001: Sugerencia automatica
- **Dado** que termino un partido
- **Cuando** hay 3 equipos
- **Entonces** el sistema sugiere que equipo entra segun las reglas

### CA-002: Regla ganador continua
- **Dado** que un equipo gano
- **Cuando** no ha jugado 2 partidos seguidos
- **Entonces** el sistema sugiere que continue

### CA-003: Regla descanso obligatorio
- **Dado** que un equipo jugo 2 partidos seguidos
- **Cuando** termina el segundo partido
- **Entonces** el sistema indica que debe descansar (gane o pierda)

### CA-004: Empate - decision manual
- **Dado** que el partido termino en empate
- **Cuando** el sistema no puede decidir automaticamente
- **Entonces** el admin elige cual equipo continua

### CA-005: Ver estado de rotacion
- **Dado** que estoy gestionando la jornada
- **Cuando** veo el panel
- **Entonces** veo: partidos jugados por equipo, quien descansa, quien sigue

### CA-006: Override manual
- **Dado** que el sistema sugiere una rotacion
- **Cuando** necesito cambiarla por alguna razon
- **Entonces** puedo seleccionar manualmente los equipos del siguiente partido

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
