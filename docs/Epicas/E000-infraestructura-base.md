# EPICA E000: Sprint 0 - Infraestructura Base

## INFORMACION
- **Codigo:** E000
- **Nombre:** Sprint 0 - Infraestructura Base
- **Descripcion:** Infraestructura fundacional que debe existir ANTES de cualquier epica de negocio. Incluye sistema de temas (dark/light), infraestructura de planes y limites (freemium), y pantalla placeholder de upgrade. Toda pantalla construida despues de este sprint nace con soporte de temas y validacion de limites/features por plan.
- **Story Points:** 23 pts
- **Estado:** 🟢 Refinada
- **Plataforma:** App Movil (Android/iOS) - Flutter + Supabase

## HISTORIAS

### E000-HU-001: Sistema de Temas (Dark/Light)
- **Archivo:** docs/historias-usuario/E000-HU-001-REF-sistema-temas.md
- **Estado:** 🟢 Refinada | **Story Points:** 5 | **Prioridad:** Alta

### E000-HU-002: Infraestructura de Planes y Limites
- **Archivo:** docs/historias-usuario/E000-HU-002-REF-infra-planes-limites.md
- **Estado:** 🟢 Refinada | **Story Points:** 8 | **Prioridad:** Alta

### E000-HU-003: Pantalla de Upgrade (Placeholder)
- **Archivo:** docs/historias-usuario/E000-HU-003-REF-pantalla-upgrade.md
- **Estado:** 🟢 Refinada | **Story Points:** 2 | **Prioridad:** Media

### E000-HU-004: Soporte Responsive Tablet
- **Archivo:** docs/historias-usuario/E000-HU-004-REF-soporte-responsive-tablet.md
- **Estado:** 🟢 Refinada | **Story Points:** 8 | **Prioridad:** Alta

## CRITERIOS EPICA
- [ ] La app soporta modo oscuro y modo claro con selector de tema
- [ ] La preferencia de tema se persiste entre sesiones
- [ ] La arquitectura de temas permite agregar mas temas en el futuro
- [ ] Existen 5 planes definidos (Gratis, Plan 5, Plan 10, Plan 15, Plan 20) con limites y features asociados
- [ ] Todo grupo/admin nuevo se asigna al plan gratuito automaticamente
- [ ] Cualquier HU puede consultar "puede este grupo hacer X?" y obtener respuesta
- [ ] Features bloqueadas muestran pantalla de upgrade con mensaje amigable
- [ ] Los limites numericos (jugadores, grupos, co-admins) se leen desde la configuracion del plan
- [ ] La app detecta automaticamente celular (<600dp) y tablet (>=600dp) y muestra layout optimizado
- [ ] En celular se fuerza portrait; en tablet se permite portrait y landscape
- [ ] Tablet usa navigation rail lateral en lugar de bottom navigation bar
- [ ] Las pantallas de partidos en vivo (temporizador, score, goles) tienen layout tablet optimizado para uso en cancha

## ORDEN DE IMPLEMENTACION
```
E000 (Sprint 0) → E001 (Auth) → E002 (Grupos) → E003 (Config UI) → E004+ (Fechas, Partidos...)
```
Este sprint es PREREQUISITO de todas las demas epicas.

## PROGRESO
**Total HU:** 4 | **Refinadas:** 4 (100%) | **En Desarrollo:** 0 | **Pendientes:** 0
