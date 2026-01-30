# E004-HU-002 - Temporizador con Alarma

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Alta
- **Dependencia**: E004-HU-001 (Iniciar Partido)

## Historia de Usuario
**Como** usuario
**Quiero** que suene una alarma fuerte al terminar el tiempo
**Para** saber cuando termina el partido sin estar mirando constantemente

## Descripcion
El temporizador muestra cuenta regresiva y emite alarma sonora al finalizar. Es visible para todos los participantes de la fecha.

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

### CA-007: Sincronizacion entre dispositivos
- **Dado** que varios usuarios ven el partido
- **Cuando** miran el temporizador
- **Entonces** todos ven el mismo tiempo (sincronizado)

## 📐 Reglas de Negocio (RN)

### RN-001: Tiempo desde servidor
**Contexto**: Al mostrar el temporizador
**Restriccion**: El tiempo debe calcularse desde una fuente unica
**Validacion**: Hora de inicio del partido + duracion - hora actual = tiempo restante
**Caso especial**: Si hay desconexion, al reconectar se sincroniza

### RN-002: Alarma obligatoria al terminar
**Contexto**: Cuando el tiempo llega a cero
**Restriccion**: La alarma debe sonar automaticamente
**Validacion**: No requiere intervencion del admin para activarse
**Caso especial**: Si el dispositivo esta en silencio, mostrar alerta visual prominente

### RN-003: Tiempo extra sin limite
**Contexto**: Cuando el partido pasa de 00:00
**Restriccion**: El contador sigue corriendo en negativo
**Validacion**: Se registra el tiempo extra jugado (-MM:SS)
**Caso especial**: El admin puede finalizar en cualquier momento del tiempo extra

### RN-004: Visibilidad universal
**Contexto**: Al mostrar el temporizador
**Restriccion**: Todos los usuarios inscritos pueden ver el tiempo
**Validacion**: No se requiere permisos especiales para ver el temporizador
**Caso especial**: Usuarios no inscritos ven tiempo pero no pueden interactuar

### RN-005: Alerta previa al fin
**Contexto**: Cuando quedan 2 minutos
**Restriccion**: Notificar que el partido esta por terminar
**Validacion**: Alerta visual (color amarillo) a los 2:00 minutos restantes
**Regla calculo**: Si duracion < 5 min, alerta al 40% del tiempo restante

### RN-006: Formato tiempo legible
**Contexto**: Al mostrar el tiempo
**Restriccion**: Formato siempre MM:SS
**Validacion**:
  - Positivo: "05:30" (5 min 30 seg)
  - Cero: "00:00"
  - Negativo: "-01:15" (1 min 15 seg de tiempo extra)

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29
