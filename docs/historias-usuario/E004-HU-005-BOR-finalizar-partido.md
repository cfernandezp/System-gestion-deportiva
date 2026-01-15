# E004-HU-005 - Finalizar Partido

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** terminar el partido y registrar el resultado
**Para** cerrar el partido y calcular puntos

## Descripcion
Permite finalizar un partido, registrando el resultado final y calculando puntos.

## Criterios de Aceptacion (CA)

### CA-001: Finalizar partido
- **Dado** que el tiempo termino o quiero finalizar
- **Cuando** presiono "Finalizar partido"
- **Entonces** el partido se cierra con el marcador actual

### CA-002: Resultado registrado
- **Dado** que finalizo el partido
- **Cuando** se confirma
- **Entonces** se registra: equipos, marcador final, goles por jugador

### CA-003: Puntos por equipo
- **Dado** que el partido termino
- **Cuando** hay un ganador
- **Entonces** se asignan puntos: Victoria 3pts, Empate 1pt, Derrota 0pts

### CA-004: Determinar siguiente partido
- **Dado** que hay 3 equipos (formato 2 horas)
- **Cuando** termina el partido
- **Entonces** el sistema sugiere que equipo entra segun reglas de rotacion

### CA-005: Resumen del partido
- **Dado** que el partido finalizo
- **Cuando** veo el resultado
- **Entonces** veo resumen: marcador, goleadores, duracion real

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
