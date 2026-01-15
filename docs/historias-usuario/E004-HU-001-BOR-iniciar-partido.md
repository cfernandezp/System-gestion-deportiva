# E004-HU-001 - Iniciar Partido

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** iniciar un partido con temporizador
**Para** controlar el tiempo de juego

## Descripcion
Permite al admin iniciar un partido seleccionando los equipos que juegan y activando el temporizador.

## Criterios de Aceptacion (CA)

### CA-001: Seleccionar equipos
- **Dado** que los equipos estan asignados
- **Cuando** inicio un partido
- **Entonces** selecciono cuales 2 equipos se enfrentan (ej: Naranja vs Verde)

### CA-002: Duracion segun formato
- **Dado** que inicio un partido
- **Cuando** la fecha es de 1 hora (2 equipos)
- **Entonces** el partido dura 20 minutos
- **Cuando** la fecha es de 2 horas (3 equipos)
- **Entonces** el partido dura 10 minutos

### CA-003: Iniciar temporizador
- **Dado** que seleccione los equipos
- **Cuando** presiono "Iniciar partido"
- **Entonces** el temporizador comienza la cuenta regresiva

### CA-004: Partido en curso
- **Dado** que el partido inicio
- **Cuando** cualquier usuario ve la fecha
- **Entonces** ve indicador de "Partido en curso" con equipos y tiempo restante

### CA-005: Pausar partido
- **Dado** que el partido esta en curso
- **Cuando** necesito pausar (lesion, interrupcion)
- **Entonces** puedo pausar el temporizador y reanudarlo

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
