# E004-HU-003 - Registrar Gol

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Alta
- **Dependencia**: E004-HU-001 (Iniciar Partido)

## Historia de Usuario
**Como** administrador
**Quiero** anotar quien hizo un gol
**Para** llevar el marcador y estadisticas de goleadores

## Descripcion
Permite registrar goles en tiempo real, indicando el jugador que anoto. Cada gol suma al marcador del equipo y a las estadisticas individuales del goleador.

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

### CA-007: Gol sin asignar jugador
- **Dado** que hubo un gol pero no se identifico al autor
- **Cuando** registro el gol
- **Entonces** puedo registrarlo como "Gol sin asignar" (suma al equipo pero no a jugador)

## 📐 Reglas de Negocio (RN)

### RN-001: Solo admin registra goles
**Contexto**: Al registrar un gol
**Restriccion**: Solo administradores aprobados pueden registrar goles
**Validacion**: Usuario debe tener rol "admin" y estado "aprobado"

### RN-002: Partido en curso obligatorio
**Contexto**: Al intentar registrar un gol
**Restriccion**: Solo se pueden registrar goles en partidos activos
**Validacion**: El partido debe estar en estado "en_curso"
**Caso especial**: En tiempo extra (negativo) se permiten goles

### RN-003: Goleador del equipo correcto
**Contexto**: Al seleccionar el jugador que anoto
**Restriccion**: El jugador debe pertenecer al equipo que marco
**Validacion**: Solo mostrar jugadores asignados al equipo seleccionado
**Caso especial**: Para gol en contra, el jugador es del equipo que recibe el gol

### RN-004: Minuto automatico
**Contexto**: Al registrar un gol
**Restriccion**: El minuto se calcula automaticamente
**Regla calculo**: Minuto = (duracion_partido - tiempo_restante) redondeado arriba
**Caso especial**: En tiempo extra, minuto = duracion + abs(tiempo_extra)

### RN-005: Ventana de deshacer
**Contexto**: Despues de registrar un gol
**Restriccion**: Solo se puede deshacer dentro de una ventana de tiempo
**Regla calculo**: 30 segundos desde el registro
**Caso especial**: Despues de 30 seg, requiere confirmacion adicional del admin

### RN-006: Gol en contra invierte equipo
**Contexto**: Al marcar autogol
**Restriccion**: El gol suma al equipo contrario
**Validacion**: Se registra: jugador del equipo A, gol para equipo B
**Caso especial**: Afecta negativamente las estadisticas individuales del jugador

### RN-007: Goles validos durante pausa
**Contexto**: Si el partido esta pausado
**Restriccion**: No se pueden registrar goles durante pausa
**Validacion**: El partido debe estar activo (no pausado)

### RN-008: Limite de goles por partido
**Contexto**: Al registrar goles
**Restriccion**: Advertencia si el marcador parece inusual
**Validacion**: Si un equipo llega a 10+ goles, mostrar confirmacion
**Caso especial**: No es un limite duro, solo advertencia

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29
