# E004-HU-006 - Rotacion de Equipos

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Alta
- **Dependencia**: E004-HU-005 (Finalizar Partido)
- **Aplica a**: Solo formato 3 equipos (2 horas)

## Historia de Usuario
**Como** administrador
**Quiero** gestionar que equipo entra y cual sale
**Para** seguir el sistema de rotacion de 3 equipos

## Descripcion
Gestiona la rotacion de equipos en formato de 3 equipos (2 horas). El sistema sugiere automaticamente segun las reglas, pero el admin puede hacer override manual.

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
- **Cuando** ambos podrian continuar
- **Entonces** el admin elige cual equipo continua

### CA-005: Ver estado de rotacion
- **Dado** que estoy gestionando la jornada
- **Cuando** veo el panel
- **Entonces** veo: partidos jugados por equipo, quien descansa, quien sigue

### CA-006: Override manual
- **Dado** que el sistema sugiere una rotacion
- **Cuando** necesito cambiarla por alguna razon
- **Entonces** puedo seleccionar manualmente los equipos del siguiente partido

### CA-007: Historial de rotacion
- **Dado** que quiero ver la secuencia de partidos
- **Cuando** accedo al historial
- **Entonces** veo orden de partidos con equipos que jugaron y descansaron

## 📐 Reglas de Negocio (RN)

### RN-001: Rotacion solo para 3 equipos
**Contexto**: Al aplicar reglas de rotacion
**Restriccion**: Solo aplica cuando la fecha tiene 3 equipos
**Validacion**: Si fecha.num_equipos = 2, no hay rotacion (siempre los mismos)
**Caso especial**: Formato 2 equipos juegan los 3 partidos entre ellos

### RN-002: Ganador continua por defecto
**Contexto**: Al sugerir siguiente partido
**Restriccion**: El equipo ganador tiene prioridad para continuar
**Regla calculo**:
  - Si equipo A gana y no ha jugado 2 seguidos → A continua
  - Equipo B (perdedor) descansa
  - Equipo C (descansando) entra
**Caso especial**: Si A ya jugo 2 seguidos, descansa aunque gane

### RN-003: Maximo 2 partidos consecutivos
**Contexto**: Al verificar si un equipo puede continuar
**Restriccion**: Ningun equipo puede jugar mas de 2 partidos seguidos
**Validacion**: Contador de partidos consecutivos por equipo
**Regla calculo**: Si contador >= 2, forzar descanso
**Caso especial**: El contador se reinicia despues de descansar

### RN-004: Empate requiere decision
**Contexto**: Cuando el partido termina empatado
**Restriccion**: El sistema no puede decidir automaticamente
**Validacion**: Mostrar opciones al admin para elegir
**Opciones**:
  - Equipo A continua (B descansa)
  - Equipo B continua (A descansa)
  - Ambos descansan, entra C vs el que descansaba

### RN-005: Todos juegan equitativamente
**Contexto**: Durante la jornada completa
**Restriccion**: Buscar balance en partidos jugados por equipo
**Validacion**: Al final de la jornada, diferencia maxima de 1 partido entre equipos
**Caso especial**: Si quedan pocos partidos, ajustar para equilibrar

### RN-006: Override con motivo
**Contexto**: Al cambiar la sugerencia del sistema
**Restriccion**: El admin puede hacer override pero se registra
**Validacion**: Se guarda: sugerencia original, decision final, motivo opcional
**Caso especial**: Motivos comunes: lesion, ausencia, acuerdo entre jugadores

### RN-007: Estado visible de cada equipo
**Contexto**: Al mostrar panel de rotacion
**Restriccion**: Claridad sobre estado actual de cada equipo
**Validacion**: Mostrar para cada equipo:
  - Partidos jugados en la jornada
  - Partidos consecutivos actuales
  - Estado: Jugando / Descansando / Siguiente

### RN-008: Sin rotacion en primer partido
**Contexto**: Al iniciar el primer partido de la jornada
**Restriccion**: El admin elige libremente los 2 equipos iniciales
**Validacion**: No hay sugerencia, seleccion manual
**Caso especial**: Se registra quien empezo descansando

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29
