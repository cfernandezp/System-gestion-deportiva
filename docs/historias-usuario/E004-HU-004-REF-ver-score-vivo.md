# E004-HU-004 - Ver Score en Vivo

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Alta
- **Dependencia**: E004-HU-003 (Registrar Gol)

## Historia de Usuario
**Como** usuario
**Quiero** ver el marcador actual del partido
**Para** saber como va el juego en tiempo real

## Descripcion
Muestra el score actualizado del partido en curso. Todos los usuarios inscritos a la fecha pueden ver el marcador sin necesidad de refrescar la pantalla.

## Criterios de Aceptacion (CA)

### CA-001: Marcador visible
- **Dado** que hay un partido en curso
- **Cuando** veo la pantalla
- **Entonces** veo el marcador: Equipo1 [goles] - [goles] Equipo2

### CA-002: Colores de equipo
- **Dado** que veo el marcador
- **Cuando** observo los equipos
- **Entonces** cada equipo se muestra con su color (Naranja, Verde, Azul)

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

### CA-006: Indicador de equipo ganando
- **Dado** que un equipo va ganando
- **Cuando** veo el marcador
- **Entonces** el equipo con ventaja se destaca visualmente

### CA-007: Empate visible
- **Dado** que el partido va empatado
- **Cuando** veo el marcador
- **Entonces** se indica claramente que van empatados

## 📐 Reglas de Negocio (RN)

### RN-001: Acceso universal al score
**Contexto**: Al visualizar el marcador
**Restriccion**: Cualquier usuario inscrito puede ver el score
**Validacion**: No requiere permisos especiales
**Caso especial**: Usuarios no inscritos pueden ver pero no los detalles

### RN-002: Actualizacion instantanea
**Contexto**: Cuando se registra un gol
**Restriccion**: El marcador debe reflejar el cambio inmediatamente
**Validacion**: Maximo 2 segundos de delay
**Caso especial**: Si hay problemas de conexion, mostrar indicador de "sincronizando"

### RN-003: Score oficial desde servidor
**Contexto**: Al mostrar el marcador
**Restriccion**: El score mostrado es el registrado en el sistema
**Validacion**: No hay scores "locales", siempre es el del servidor
**Caso especial**: Si no hay conexion, mostrar ultimo score conocido con advertencia

### RN-004: Formato de marcador estandar
**Contexto**: Al presentar el score
**Restriccion**: Formato consistente: EQUIPO_LOCAL [goles] - [goles] EQUIPO_VISITANTE
**Validacion**: Colores visibles, numeros grandes y legibles
**Caso especial**: El equipo que selecciono primero el admin es "local"

### RN-005: Detalle de goles cronologico
**Contexto**: Al ver lista de goles
**Restriccion**: Goles ordenados por minuto de anotacion
**Validacion**: Mostrar: minuto, nombre jugador, equipo, tipo (normal/autogol)
**Caso especial**: Goles sin asignar muestran "Gol de [EQUIPO]"

### RN-006: Indicadores visuales de estado
**Contexto**: Al mostrar el marcador
**Restriccion**: El estado del partido debe ser evidente
**Validacion**:
  - Partido en curso: indicador verde pulsante
  - Partido pausado: indicador amarillo
  - Tiempo extra: indicador rojo
  - Partido finalizado: sin indicador de "en vivo"

### RN-007: Goles recientes destacados
**Contexto**: Cuando se anota un gol
**Restriccion**: Notificar visualmente el gol reciente
**Validacion**: Animacion o highlight durante 5 segundos
**Caso especial**: Sonido opcional si el usuario lo tiene activado

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29
