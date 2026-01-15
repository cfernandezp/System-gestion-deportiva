-- ============================================
-- FIX: Aprobar usuario confirma email automaticamente
-- Fecha: 2026-01-15
-- Descripcion: Modifica aprobar_usuario para confirmar el email
--              en auth.users cuando el admin aprueba la solicitud
-- ============================================
--
-- REGLAS DE NEGOCIO IMPLEMENTADAS:
--
-- RN-011: Confirmacion de Email por Administrador
--   Cuando un administrador aprueba la solicitud de registro,
--   el sistema confirma automaticamente el email del usuario.
--
-- RN-012: Responsabilidad de Verificacion de Identidad
--   El administrador asume la responsabilidad de verificar
--   que el solicitante es quien dice ser (verificacion presencial).
--
-- RN-013: Rechazo Mantiene Email No Confirmado
--   Al rechazar, el usuario permanece con email sin confirmar.
--
-- JUSTIFICACION:
-- - El sistema es para gestion deportiva de equipos locales
-- - El admin conoce personalmente a los jugadores
-- - La verificacion presencial es mas confiable que un email
-- - Unificar aprobacion + confirmacion evita confusion
-- ============================================

-- ============================================
-- Funcion: aprobar_usuario (ACTUALIZADA)
-- Descripcion: Aprueba un usuario pendiente, asigna rol Y confirma email
-- Reglas: RN-008, RN-011, RN-012, CA-009
-- ============================================
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

    -- ============================================
    -- RN-011: Confirmar email en auth.users
    -- Esto permite que el usuario pueda hacer login con Supabase Auth
    -- ============================================
    UPDATE auth.users
    SET
        email_confirmed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_usuario.auth_user_id;

    -- Aprobar usuario en tabla usuarios
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
            'rol_asignado', p_rol,
            'email_confirmado', true
        )
    );

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', p_usuario_id,
            'nombre_completo', v_usuario.nombre_completo,
            'email', v_usuario.email,
            'estado', 'aprobado',
            'rol', p_rol,
            'email_confirmado', true
        ),
        'message', 'Usuario aprobado exitosamente. Email confirmado automaticamente.'
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
-- PERMISOS (re-aplicar por si acaso)
-- ============================================
GRANT EXECUTE ON FUNCTION aprobar_usuario TO authenticated, service_role;

-- ============================================
-- COMENTARIO ACTUALIZADO
-- ============================================
COMMENT ON FUNCTION aprobar_usuario IS 'HU-001: Aprueba solicitud de registro Y confirma email (CA-009, RN-008, RN-011, RN-012)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
--
-- INSTRUCCIONES:
-- 1. Ejecutar este script en Supabase SQL Editor
-- 2. Cuando el admin apruebe un usuario, el email se confirmara automaticamente
-- 3. El usuario podra hacer login inmediatamente despues de ser aprobado
--
-- NOTA: La funcion rechazar_usuario NO confirma email (RN-013)
--       por lo que usuarios rechazados no pueden hacer login.
-- ============================================
