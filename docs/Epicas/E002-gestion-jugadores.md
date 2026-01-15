# E002 - Gestion de Jugadores

## Descripcion
Gestiona la informacion de los jugadores del grupo de pichangas, incluyendo perfiles y datos personales.

## Objetivo
Permitir que los administradores gestionen la lista de jugadores y que cada jugador pueda ver y actualizar su perfil.

## Contexto de Negocio
- Jugadores fijos registrados y aprobados por Admin
- Cada jugador tiene perfil con datos basicos y apodo para partidos
- No existen "invitados" en el sistema

## Alcance
- Ver y editar perfil propio
- Ver lista de jugadores del grupo
- Ver perfil publico de otros jugadores

## Historias de Usuario

| ID | Titulo | Estado | Descripcion |
|----|--------|--------|-------------|
| E002-HU-001 | Ver Perfil Propio | 🟢 REF | Como jugador, quiero ver mi perfil |
| E002-HU-002 | Editar Perfil Propio | 🟢 REF | Como jugador, quiero actualizar mis datos |
| E002-HU-003 | Lista de Jugadores | 🟢 REF | Como jugador, quiero ver los miembros del grupo |
| E002-HU-004 | Ver Perfil Otro Jugador | 🟢 REF | Como jugador, quiero ver perfil de otro miembro |

## Datos del Jugador
- Nombre completo
- Apodo/Alias (para mostrar en partidos)
- Email
- Telefono (opcional)
- Posicion preferida (opcional)
- Foto (opcional)
- Fecha de ingreso al grupo

## Dependencias
- E001: Login de Usuario

---
**Version**: 1.0
**Estado**: 🟢 Refinada
