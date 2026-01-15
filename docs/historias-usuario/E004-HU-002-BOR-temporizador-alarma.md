# E004-HU-002 - Temporizador con Alarma

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** usuario
**Quiero** que suene una alarma fuerte al terminar el tiempo
**Para** saber cuando termina el partido sin estar mirando constantemente

## Descripcion
El temporizador muestra cuenta regresiva y emite alarma sonora al finalizar.

## Criterios de Aceptacion (CA)

### CA-001: Visualizacion del tiempo
- **Dado** que hay un partido en curso
- **Cuando** veo la pantalla
- **Entonces** veo el tiempo restante en formato MM:SS

### CA-002: Cuenta regresiva
- **Dado** que el partido inicio
- **Cuando** el tiempo avanza
- **Entonces** el contador disminuye segundo a segundo

### CA-003: Alarma al finalizar
- **Dado** que el tiempo llega a 00:00
- **Cuando** termina el partido
- **Entonces** suena una alarma fuerte y clara

### CA-004: Alarma audible
- **Dado** que suena la alarma
- **Cuando** hay ruido ambiente (cancha)
- **Entonces** la alarma es lo suficientemente fuerte para escucharse

### CA-005: Indicador visual de fin
- **Dado** que termina el tiempo
- **Cuando** suena la alarma
- **Entonces** tambien hay indicador visual (pantalla roja/parpadeo)

### CA-006: Tiempo extra visible
- **Dado** que el tiempo llego a 00:00
- **Cuando** el partido no se finaliza inmediatamente
- **Entonces** el contador muestra tiempo extra en negativo (-00:30)

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
