-- ============================================
-- HU-005: Gestion de Roles
-- Fecha: 2026-01-14
-- Descripcion: Funciones RPC para listar usuarios y cambiar roles
--              Solo administradores pueden gestionar roles
-- ============================================

-- ============================================
-- PARTE 1: ACTUALIZAR ENUM rol_usuario
-- Agregar 'entrenador' si no existe (RN-001)
-- ============================================

-- Verificar y agregar 'entrenador' al ENUM si no existe
DO $$
BEGIN
    -- Intentar agregar 'entrenador' al enum
    ALTER TYPE rol_usuario ADD VALUE IF NOT EXISTS 'entrenador';
EXCEPTION
    WHEN duplicate_object THEN
        NULL; -- Ya existe, ignorar
END $$;

-- ============================================
-- PARTE 2: FUNCIONES RPC
-- ============================================

-- ============================================
-- Funcion: listar_usuarios
-- Descripcion: Lista todos los usuarios con su rol actual
-- Reglas: RN-002 (solo admin), RN-006 (todos visibles), RN-007 (busqueda)
-- CAs: CA-001, CA-005, CA-006
-- ============================================
CREATE OR REPLACE FUNCTION listar_usuarios(
    p_busqueda TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_usuarios JSON;
    v_busqueda_normalizada TEXT;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Verificar que sea admin (RN-002)
    SELECT id, rol, estado
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_current_user.rol != 'admin' OR v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo los administradores pueden acceder a la gestion de roles';
    END IF;

    -- Normalizar busqueda (RN-007: case-insensitive)
    v_busqueda_normalizada := LOWER(TRIM(COALESCE(p_busqueda, '')));

    -- Obtener usuarios (RN-006: todos visibles, incluyendo inactivos/suspendidos)
    SELECT json_agg(
        json_build_object(
            'id', u.id,
            'nombre_completo', u.nombre_completo,
            'email', u.email,
            'rol', u.rol,
            'estado', u.estado,
            'created_at', u.created_at AT TIME ZONE 'America/Lima'
        ) ORDER BY u.nombre_completo ASC
    )
    INTO v_usuarios
    FROM usuarios u
    WHERE (
        v_busqueda_normalizada = ''
        OR LOWER(u.nombre_completo) LIKE '%' || v_busqueda_normalizada || '%'
        OR LOWER(u.email) LIKE '%' || v_busqueda_normalizada || '%'
    );

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuarios', COALESCE(v_usuarios, '[]'::json),
            'total', (
                SELECT COUNT(*) FROM usuarios
                WHERE (
                    v_busqueda_normalizada = ''
                    OR LOWER(nombre_completo) LIKE '%' || v_busqueda_normalizada || '%'
                    OR LOWER(email) LIKE '%' || v_busqueda_normalizada || '%'
                )
            )
        ),
        'message', 'Lista de usuarios obtenida exitosamente'
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
-- Funcion: cambiar_rol_usuario
-- Descripcion: Cambia el rol de un usuario
-- Reglas: RN-001 (roles validos), RN-002 (solo admin),
--         RN-003 (no auto-degradacion), RN-004 (minimo 1 admin),
--         RN-005 (efecto inmediato)
-- CAs: CA-002, CA-003, CA-004
-- ============================================
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
    -- El tipo rol_usuario ya valida esto, pero agregamos mensaje claro
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
                'message', 'El rol especificado no es valido. Roles permitidos: admin, entrenador, jugador, arbitro',
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

-- ============================================
-- PARTE 3: PERMISOS
-- ============================================

-- Permisos para funciones RPC
GRANT EXECUTE ON FUNCTION listar_usuarios TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION cambiar_rol_usuario TO authenticated, service_role;

-- ============================================
-- PARTE 4: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION listar_usuarios IS 'HU-005: Lista usuarios con rol actual, busqueda por nombre/email (RN-002, RN-006, RN-007)';
COMMENT ON FUNCTION cambiar_rol_usuario IS 'HU-005: Cambia rol de usuario con validaciones de seguridad (RN-001 a RN-005)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
