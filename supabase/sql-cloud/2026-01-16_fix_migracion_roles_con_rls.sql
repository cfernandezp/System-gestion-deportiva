-- ============================================
-- FIX: Migracion de Roles con manejo de RLS + DEFAULT + Funciones dependientes
-- Fecha: 2026-01-16
-- Descripcion: Corrige error 2BP01 - no se puede eliminar tipo porque
--              hay funciones que dependen de el.
--              Migra ENUM rol_usuario de 4 valores a 2 (admin, jugador)
-- ============================================

-- ============================================
-- PROBLEMA IDENTIFICADO:
-- 1. La columna `rol` esta siendo usada en politicas RLS
-- 2. Las funciones `aprobar_usuario` y `cambiar_rol_usuario` usan
--    el tipo `rol_usuario` como parametro
--
-- PostgreSQL no permite DROP TYPE cuando hay funciones que dependen de el.
--
-- SOLUCION (en orden):
-- 1. Eliminar politicas RLS que usan columna rol
-- 2. Eliminar funciones que dependen del tipo ENUM
-- 3. Eliminar DEFAULT de columna rol
-- 4. Migrar datos obsoletos
-- 5. Crear nuevo ENUM
-- 6. Cambiar tipo de columna
-- 7. Eliminar ENUM viejo
-- 8. Renombrar nuevo ENUM
-- 9. Restaurar DEFAULT
-- 10. Recrear funciones
-- 11. Recrear politicas RLS
-- ============================================

-- ============================================
-- PARTE 1: ELIMINAR POLITICAS RLS QUE USAN COLUMNA ROL
-- ============================================

-- Eliminar politica: Admins pueden ver todos los usuarios
DROP POLICY IF EXISTS "Admins pueden ver todos los usuarios" ON usuarios;

-- Eliminar politica: Admins pueden actualizar usuarios
DROP POLICY IF EXISTS "Admins pueden actualizar usuarios" ON usuarios;

-- NOTA: Estas politicas usan la columna rol en su condicion:
-- WHERE u.rol = 'admin' AND u.estado = 'aprobado'

-- ============================================
-- PARTE 2: ELIMINAR FUNCIONES QUE DEPENDEN DEL TIPO ENUM
-- ============================================

-- CRITICO: Estas funciones usan rol_usuario como parametro
-- Deben eliminarse ANTES de poder modificar el tipo ENUM
DROP FUNCTION IF EXISTS aprobar_usuario(UUID, rol_usuario);
DROP FUNCTION IF EXISTS cambiar_rol_usuario(UUID, rol_usuario);

-- Tambien eliminar versiones sin parametro tipado (si existen)
DROP FUNCTION IF EXISTS aprobar_usuario(UUID);
DROP FUNCTION IF EXISTS cambiar_rol_usuario(UUID);

-- ============================================
-- PARTE 3: ELIMINAR DEFAULT DE COLUMNA ROL
-- ============================================

ALTER TABLE usuarios ALTER COLUMN rol DROP DEFAULT;

-- ============================================
-- PARTE 4: MIGRACION DE DATOS (por seguridad)
-- Convertir usuarios con roles obsoletos a 'jugador'
-- ============================================

-- Migrar cualquier rol obsoleto a 'jugador' antes del cambio
-- Esto asegura que no haya valores que no existan en el nuevo ENUM
DO $$
BEGIN
    -- Migrar 'entrenador' si existe
    UPDATE usuarios SET rol = 'jugador' WHERE rol::text = 'entrenador';
EXCEPTION
    WHEN invalid_text_representation THEN
        NULL; -- El valor no existe en el enum, ignorar
END $$;

DO $$
BEGIN
    -- Migrar 'arbitro' si existe
    UPDATE usuarios SET rol = 'jugador' WHERE rol::text = 'arbitro';
EXCEPTION
    WHEN invalid_text_representation THEN
        NULL;
END $$;

DO $$
BEGIN
    -- Migrar 'delegado' si existe
    UPDATE usuarios SET rol = 'jugador' WHERE rol::text = 'delegado';
EXCEPTION
    WHEN invalid_text_representation THEN
        NULL;
END $$;

-- ============================================
-- PARTE 5: CREAR NUEVO ENUM
-- ============================================

-- Eliminar tipo temporal si quedo de un intento anterior
DROP TYPE IF EXISTS rol_usuario_nuevo CASCADE;

-- Crear nuevo ENUM con solo 2 valores
CREATE TYPE rol_usuario_nuevo AS ENUM ('admin', 'jugador');

-- ============================================
-- PARTE 6: CAMBIAR TIPO DE COLUMNA
-- ============================================

ALTER TABLE usuarios
    ALTER COLUMN rol TYPE rol_usuario_nuevo
    USING rol::text::rol_usuario_nuevo;

-- ============================================
-- PARTE 7: ELIMINAR ENUM VIEJO
-- ============================================

-- Ahora que no hay funciones ni columnas usando el tipo viejo, se puede eliminar
DROP TYPE IF EXISTS rol_usuario;

-- ============================================
-- PARTE 8: RENOMBRAR NUEVO ENUM
-- ============================================

ALTER TYPE rol_usuario_nuevo RENAME TO rol_usuario;

-- ============================================
-- PARTE 9: RESTAURAR DEFAULT
-- ============================================

ALTER TABLE usuarios ALTER COLUMN rol SET DEFAULT 'jugador'::rol_usuario;

-- ============================================
-- PARTE 10: RECREAR FUNCIONES
-- ============================================

-- Funcion: cambiar_rol_usuario
CREATE OR REPLACE FUNCTION cambiar_rol_usuario(
    p_usuario_id UUID,
    p_nuevo_rol rol_usuario
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_usuario_destino RECORD;
    v_total_admins INT;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Verificar que el usuario actual sea admin (RN-002)
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_current_user.rol != 'admin' OR v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo los administradores pueden cambiar roles de usuarios';
    END IF;

    -- Validar rol (RN-001: solo roles validos del catalogo)
    IF p_nuevo_rol IS NULL THEN
        v_error_hint := 'rol_invalido';
        RAISE EXCEPTION 'Debe especificar un rol valido';
    END IF;

    -- Verificar que el usuario destino existe
    SELECT id, rol, estado, nombre_completo, auth_user_id
    INTO v_usuario_destino
    FROM usuarios
    WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'El usuario a modificar no fue encontrado';
    END IF;

    -- Verificar auto-degradacion (RN-003)
    -- Un admin no puede quitarse a si mismo el rol de admin
    IF v_usuario_destino.id = v_current_user.id AND p_nuevo_rol != 'admin' THEN
        v_error_hint := 'auto_degradacion';
        RAISE EXCEPTION 'No puedes quitarte el rol de administrador a ti mismo';
    END IF;

    -- Verificar minimo un admin activo (RN-004)
    -- Solo aplica si estamos quitando el rol admin a alguien
    IF v_usuario_destino.rol = 'admin' AND p_nuevo_rol != 'admin' THEN
        SELECT COUNT(*) INTO v_total_admins
        FROM usuarios
        WHERE rol = 'admin'
        AND estado = 'aprobado'
        AND id != v_usuario_destino.id;

        IF v_total_admins < 1 THEN
            v_error_hint := 'ultimo_admin';
            RAISE EXCEPTION 'No se puede cambiar el rol del ultimo administrador. Debe existir al menos un administrador en el sistema';
        END IF;
    END IF;

    -- Verificar si hay cambio real
    IF v_usuario_destino.rol = p_nuevo_rol THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'usuario_id', v_usuario_destino.id,
                'nombre_completo', v_usuario_destino.nombre_completo,
                'rol_anterior', v_usuario_destino.rol,
                'rol_nuevo', p_nuevo_rol,
                'sin_cambios', true
            ),
            'message', 'El usuario ya tiene el rol especificado'
        );
    END IF;

    -- Actualizar rol (RN-005: efecto inmediato)
    UPDATE usuarios
    SET rol = p_nuevo_rol
    WHERE id = p_usuario_id;

    -- Retorno exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario_destino.id,
            'nombre_completo', v_usuario_destino.nombre_completo,
            'rol_anterior', v_usuario_destino.rol,
            'rol_nuevo', p_nuevo_rol,
            'sin_cambios', false
        ),
        'message', 'Rol de usuario actualizado exitosamente'
    );

EXCEPTION
    WHEN invalid_text_representation THEN
        -- Error cuando el valor del enum no es valido
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'INVALID_ROLE',
                'message', 'El rol especificado no es valido. Roles permitidos: admin, jugador',
                'hint', 'rol_invalido'
            )
        );
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', COALESCE(v_error_hint, 'unknown')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion: aprobar_usuario
CREATE OR REPLACE FUNCTION aprobar_usuario(
    p_usuario_id UUID,
    p_rol rol_usuario DEFAULT 'jugador'
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_usuario RECORD;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Verificar que sea admin
    SELECT id, rol, estado
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND OR v_current_user.rol != 'admin' OR v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'No tienes permisos para realizar esta accion';
    END IF;

    -- Verificar que el usuario a aprobar existe y esta pendiente
    SELECT id, nombre_completo, email, estado, auth_user_id
    INTO v_usuario
    FROM usuarios
    WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    IF v_usuario.estado != 'pendiente_aprobacion' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'El usuario no esta en estado pendiente de aprobacion';
    END IF;

    -- Verificar que no se apruebe a si mismo
    IF v_usuario.id = v_current_user.id THEN
        v_error_hint := 'auto_aprobacion';
        RAISE EXCEPTION 'No puedes aprobar tu propia solicitud';
    END IF;

    -- Confirmar email en auth.users al aprobar
    UPDATE auth.users
    SET
        email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
        updated_at = NOW()
    WHERE id = v_usuario.auth_user_id;

    -- Aprobar usuario
    UPDATE usuarios
    SET
        estado = 'aprobado',
        rol = p_rol,
        aprobado_por = v_current_user.id,
        aprobado_rechazado_at = NOW()
    WHERE id = p_usuario_id;

    -- Crear notificacion para el usuario aprobado
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        metadata
    ) VALUES (
        p_usuario_id,
        'cuenta_aprobada',
        'Tu cuenta ha sido aprobada',
        'Tu solicitud de registro ha sido aprobada. Ya puedes iniciar sesion con el rol de ' || p_rol::TEXT || '.',
        jsonb_build_object(
            'aprobado_por', v_current_user.id,
            'rol_asignado', p_rol
        )
    );

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', p_usuario_id,
            'nombre_completo', v_usuario.nombre_completo,
            'email', v_usuario.email,
            'estado', 'aprobado',
            'rol', p_rol
        ),
        'message', 'Usuario aprobado exitosamente'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', COALESCE(v_error_hint, 'unknown')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PARTE 11: RECREAR POLITICAS RLS
-- ============================================

-- Recrear politica: Admins pueden ver todos los usuarios
CREATE POLICY "Admins pueden ver todos los usuarios"
ON usuarios FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- Recrear politica: Admins pueden actualizar usuarios
CREATE POLICY "Admins pueden actualizar usuarios"
ON usuarios FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- ============================================
-- PARTE 12: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION cambiar_rol_usuario TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION aprobar_usuario TO authenticated, service_role;

-- ============================================
-- PARTE 13: COMENTARIOS
-- ============================================

COMMENT ON FUNCTION cambiar_rol_usuario IS 'HU-005: Cambia rol de usuario (admin/jugador) con validaciones de seguridad (RN-001 a RN-005)';
COMMENT ON FUNCTION aprobar_usuario IS 'HU-001: Aprueba solicitud de registro con rol (admin/jugador)';

-- ============================================
-- PARTE 14: VERIFICACION POST-MIGRACION
-- Ejecuta estos queries DESPUES de la migracion para verificar
-- ============================================

/*
-- 1. Verificar que el ENUM solo tiene 2 valores
SELECT enumlabel
FROM pg_enum
WHERE enumtypid = 'rol_usuario'::regtype
ORDER BY enumsortorder;
-- Esperado: admin, jugador

-- 2. Verificar que el DEFAULT esta correctamente configurado
SELECT column_name, column_default, data_type
FROM information_schema.columns
WHERE table_name = 'usuarios' AND column_name = 'rol';
-- Esperado: column_default = 'jugador'::rol_usuario

-- 3. Verificar conteo de usuarios por rol
SELECT rol, COUNT(*) as cantidad
FROM usuarios
GROUP BY rol
ORDER BY rol;
-- Esperado: Solo admin y jugador

-- 4. Verificar que las politicas RLS fueron recreadas
SELECT
    policyname,
    cmd,
    qual::text as using_expression
FROM pg_policies
WHERE tablename = 'usuarios'
AND schemaname = 'public';
-- Esperado: Debe incluir las 2 politicas de admin recreadas

-- 5. Verificar que las funciones fueron recreadas
SELECT routine_name, data_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('aprobar_usuario', 'cambiar_rol_usuario');
-- Esperado: Ambas funciones deben existir
*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
