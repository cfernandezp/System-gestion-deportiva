# E002-HU-004 - Ver Perfil de Otro Jugador

## Informacion General
- **Epica**: E002 - Gestion de Jugadores
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Baja

## Historia de Usuario
**Como** jugador registrado
**Quiero** ver el perfil de otro miembro del grupo
**Para** conocer informacion basica de mis companeros

## Descripcion
Permite ver informacion publica de otros jugadores del grupo.

## Criterios de Aceptacion (CA)

### CA-001: Acceso desde lista
- **Dado** que estoy en la lista de jugadores
- **Cuando** selecciono un jugador
- **Entonces** veo su perfil publico

### CA-002: Datos publicos visibles
- **Dado** que veo el perfil de otro jugador
- **Cuando** observo su informacion
- **Entonces** veo: foto, apodo, posicion preferida y fecha de ingreso

### CA-003: Datos privados ocultos
- **Dado** que veo el perfil de otro jugador
- **Cuando** observo su informacion
- **Entonces** NO veo: email ni telefono (datos privados)

### CA-004: Estadisticas basicas
- **Dado** que veo el perfil de otro jugador
- **Cuando** hay estadisticas disponibles
- **Entonces** veo: goles totales, partidos jugados, puntos acumulados

## Reglas de Negocio (RN)

### RN-001: Clasificacion de Datos Publicos
**Contexto**: Cuando un jugador visualiza el perfil de otro miembro del grupo.
**Restriccion**: No mostrar informacion clasificada como privada en el perfil de terceros.
**Validacion**: Los siguientes datos son publicos y visibles para cualquier miembro del grupo:
- Foto de perfil
- Apodo/Alias
- Posicion preferida de juego
- Fecha de ingreso al grupo
**Caso especial**: Si un dato publico no esta registrado (ej: foto, posicion), mostrar un valor por defecto o indicador de "no disponible".

### RN-002: Proteccion de Datos Privados
**Contexto**: Cuando un jugador visualiza el perfil de otro miembro del grupo.
**Restriccion**: Nunca exponer datos de contacto personal de otros jugadores.
**Validacion**: Los siguientes datos son privados y NO deben mostrarse a terceros:
- Email
- Telefono
**Caso especial**: El jugador SI puede ver sus propios datos privados en su perfil personal (HU-001).

### RN-003: Visibilidad de Estadisticas
**Contexto**: Cuando se visualiza el perfil de cualquier jugador del grupo.
**Restriccion**: No mostrar estadisticas si el jugador no tiene participacion registrada.
**Validacion**: Las estadisticas publicas incluyen:
- Goles totales anotados
- Cantidad de partidos jugados
- Puntos acumulados
**Caso especial**: Si el jugador no tiene partidos jugados, mostrar los valores en cero (0) en lugar de ocultar la seccion.

### RN-004: Requisito de Membresia
**Contexto**: Cuando se intenta acceder al perfil de otro jugador.
**Restriccion**: No permitir visualizar perfiles de jugadores que no pertenecen al mismo grupo.
**Validacion**: Solo los miembros registrados y activos del grupo pueden ver perfiles de otros miembros del mismo grupo.
**Caso especial**: Si el jugador consultado fue dado de baja del grupo, no debe ser accesible su perfil.

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-15
