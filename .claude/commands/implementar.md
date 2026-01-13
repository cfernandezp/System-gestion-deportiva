# Comando: /implementar

## Descripción
Comando para coordinar la implementación de Historias de Usuario (HU) invocando al **web-architect-expert**.

## Uso
```bash
/implementar <ruta-archivo-HU>
```

## Ejemplo
```bash
/implementar docs/historias-usuario/E001-HU-001-REF-gestion-miembros.md
```

## Lo que hace

1. **Valida** que la HU esté en estado REF (Refinada)
2. **Cambia estado** a DEV (En Desarrollo)
3. **Coordina agentes** en orden secuencial:
   - @supabase-expert → Backend
   - @flutter-expert → Frontend
   - @ux-ui-expert → UI
   - @qa-testing-expert → Validación
4. **Gestiona correcciones** si QA encuentra errores
5. **Completa la HU** cambiando estado a COM

## Resultado Esperado
- HU completamente implementada
- Secciones técnicas documentadas en la HU
- App compilando y funcionando
- Usuario informado de pasos de deploy pendientes
