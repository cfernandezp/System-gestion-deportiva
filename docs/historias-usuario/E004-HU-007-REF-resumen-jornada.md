# E004-HU-007 - Resumen de Jornada

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Media
- **Dependencia**: E004-HU-005 (Finalizar Partido)

## Historia de Usuario
**Como** usuario
**Quiero** ver el resumen de todos los partidos de la jornada
**Para** conocer los resultados finales y estadisticas

## Descripcion
Muestra resumen completo de la jornada (fecha de pichanga) con todos los partidos jugados, goleadores y posiciones de equipos. Disponible durante y despues de la jornada.

## Criterios de Aceptacion (CA)

### CA-001: Lista de partidos
- **Dado** que la jornada termino o esta en curso
- **Cuando** accedo al resumen
- **Entonces** veo lista de todos los partidos con sus resultados

### CA-002: Posiciones de equipos
- **Dado** que veo el resumen
- **Cuando** hay resultados
- **Entonces** veo tabla de posiciones: 1ro, 2do, 3ro con puntos

### CA-003: Goleadores de la fecha
- **Dado** que veo el resumen
- **Cuando** hubo goles
- **Entonces** veo ranking de goleadores de la fecha

### CA-004: Estadisticas de equipos
- **Dado** que veo el resumen
- **Cuando** la jornada tiene partidos
- **Entonces** veo por equipo: partidos jugados, ganados, empatados, perdidos, goles a favor, goles en contra

### CA-005: Goleador de la fecha destacado
- **Dado** que veo el resumen
- **Cuando** hay un maximo goleador
- **Entonces** se destaca al goleador de la fecha

### CA-006: Compartir resumen
- **Dado** que veo el resumen final
- **Cuando** quiero compartirlo
- **Entonces** puedo generar imagen o texto para compartir en WhatsApp

### CA-007: Resumen parcial en vivo
- **Dado** que la jornada esta en curso
- **Cuando** accedo al resumen
- **Entonces** veo datos actualizados hasta el momento (no solo al final)

## 📐 Reglas de Negocio (RN)

### RN-001: Acceso para todos los inscritos
**Contexto**: Al ver el resumen
**Restriccion**: Cualquier usuario inscrito a la fecha puede ver el resumen
**Validacion**: No requiere permisos especiales
**Caso especial**: Despues de finalizada la fecha, queda como historial

### RN-002: Calculo de posiciones por puntos
**Contexto**: Al generar tabla de posiciones
**Restriccion**: Sistema de puntos estandar
**Regla calculo**:
  - Victoria: 3 puntos
  - Empate: 1 punto
  - Derrota: 0 puntos
**Desempate**: 1) Diferencia de goles, 2) Goles a favor, 3) Enfrentamiento directo

### RN-003: Goleador de la fecha
**Contexto**: Al determinar el maximo goleador
**Restriccion**: Se cuenta solo goles validos (no autogoles)
**Regla calculo**: Jugador con mas goles en todos los partidos de la fecha
**Caso especial**: Si hay empate, todos son co-goleadores

### RN-004: Estadisticas en tiempo real
**Contexto**: Durante la jornada
**Restriccion**: El resumen se actualiza con cada partido finalizado
**Validacion**: Datos reflejan estado actual, no solo al final
**Caso especial**: Partido en curso no suma a estadisticas hasta finalizar

### RN-005: Formato compartible
**Contexto**: Al compartir resumen
**Restriccion**: Generar formato legible para redes sociales
**Validacion**: Incluir: fecha, lugar, posiciones, goleador, marcadores
**Caso especial**: Opcion de imagen (screenshot) o texto plano

### RN-006: Historial permanente
**Contexto**: Despues de finalizar la fecha
**Restriccion**: El resumen queda guardado permanentemente
**Validacion**: Usuarios pueden consultar jornadas pasadas
**Caso especial**: Vinculado con E006 (Estadisticas historicas)

### RN-007: Resumen vacio si no hay partidos
**Contexto**: Si la fecha no tuvo partidos
**Restriccion**: Mostrar mensaje informativo
**Validacion**: "No se jugaron partidos en esta fecha"
**Caso especial**: Puede pasar si la fecha se finalizo sin iniciar partidos

### RN-008: Datos de cada partido
**Contexto**: Al mostrar lista de partidos
**Restriccion**: Informacion completa por partido
**Validacion**: Mostrar:
  - Equipos enfrentados con colores
  - Marcador final
  - Goleadores del partido
  - Duracion del partido

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29
