# E004-HU-005 - Finalizar Partido

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Alta
- **Dependencia**: E004-HU-001 (Iniciar Partido), E004-HU-003 (Registrar Gol)

## Historia de Usuario
**Como** administrador
**Quiero** terminar el partido y registrar el resultado
**Para** cerrar el partido y preparar el siguiente

## Descripcion
Permite finalizar un partido, registrando el resultado final. Al finalizar, se determina el ganador/empate y se prepara la rotacion para el siguiente partido si aplica.

## Criterios de Aceptacion (CA)

### CA-001: Finalizar partido
- **Dado** que el tiempo termino o quiero finalizar antes
- **Cuando** presiono "Finalizar partido"
- **Entonces** el partido se cierra con el marcador actual

### CA-002: Resultado registrado
- **Dado** que finalizo el partido
- **Cuando** se confirma
- **Entonces** se registra: equipos, marcador final, goles por jugador

### CA-003: Determinar resultado
- **Dado** que el partido termino
- **Cuando** se calcula el resultado
- **Entonces** se determina: Victoria equipo A, Victoria equipo B, o Empate

### CA-004: Sugerir siguiente partido
- **Dado** que hay 3 equipos (formato 2 horas)
- **Cuando** termina el partido
- **Entonces** el sistema sugiere que equipo entra segun reglas de rotacion

### CA-005: Resumen del partido
- **Dado** que el partido finalizo
- **Cuando** veo el resultado
- **Entonces** veo resumen: marcador, goleadores, duracion real

### CA-006: Confirmacion antes de finalizar
- **Dado** que el tiempo no ha terminado
- **Cuando** intento finalizar anticipadamente
- **Entonces** se solicita confirmacion

### CA-007: Notificacion de fin
- **Dado** que el partido finalizo
- **Cuando** los usuarios ven la fecha
- **Entonces** ven que el partido termino con el resultado final

## 📐 Reglas de Negocio (RN)

### RN-001: Solo admin finaliza partido
**Contexto**: Al finalizar un partido
**Restriccion**: Solo administradores aprobados pueden finalizar partidos
**Validacion**: Usuario debe tener rol "admin" y estado "aprobado"

### RN-002: Partido debe estar activo
**Contexto**: Al intentar finalizar
**Restriccion**: Solo se pueden finalizar partidos en curso
**Validacion**: Estado del partido debe ser "en_curso" o "pausado"
**Caso especial**: Partidos ya finalizados no pueden finalizarse de nuevo

### RN-003: Resultado inmutable
**Contexto**: Despues de finalizar
**Restriccion**: El resultado del partido no puede modificarse
**Validacion**: Una vez finalizado, el marcador queda registrado permanentemente
**Caso especial**: Solo un superadmin podria corregir errores graves

### RN-004: Determinacion de ganador
**Contexto**: Al calcular el resultado
**Restriccion**: Logica clara para determinar el resultado
**Regla calculo**:
  - Goles equipo A > Goles equipo B = Victoria A
  - Goles equipo A < Goles equipo B = Victoria B
  - Goles equipo A = Goles equipo B = Empate

### RN-005: Duracion real registrada
**Contexto**: Al finalizar el partido
**Restriccion**: Registrar cuanto duro realmente el partido
**Regla calculo**: Duracion = hora_fin - hora_inicio - tiempo_pausado
**Caso especial**: Tiempo extra se suma a la duracion

### RN-006: Finalizacion automatica opcional
**Contexto**: Cuando el temporizador llega a cero
**Restriccion**: El partido NO se finaliza automaticamente
**Validacion**: Requiere accion explicita del admin
**Caso especial**: Alarma suena pero el juego puede continuar en tiempo extra

### RN-007: Estadisticas individuales actualizadas
**Contexto**: Al finalizar el partido
**Restriccion**: Los goles se consolidan en estadisticas de jugadores
**Validacion**: Cada jugador suma sus goles a su historial personal
**Caso especial**: Autogoles no suman al goleador pero si al equipo contrario

### RN-008: Partido sin goles valido
**Contexto**: Si el partido termina 0-0
**Restriccion**: Es un resultado valido
**Validacion**: Se registra como empate 0-0

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29
