-- ============================================
-- E001-HU-005: Activacion de Cuenta de Jugador Invitado
-- Fecha: 2026-02-20
-- Crea RPCs verificar_invitacion_pendiente y activar_cuenta_jugador
-- Dependencia: tabla usuarios, miembros_grupo
-- ============================================

-- ============================================
-- PASO 1: RPC verificar_invitacion_pendiente
-- CA-001, CA-002, CA-004
-- RN-001, RN-004
-- Funcion publica (anon) para verificar si un celular
-- tiene una invitacion pendiente de activacion
-- ============================================
CREATE OR REPLACE FUNCTION verificar_invitacion_pendiente(
    p_celular VARCHAR(9)
) RETURNS JSON AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
    v_usuario_id UUID;
    v_estado estado_usuario;
    v_grupos_count INTEGER;
    v_error_hint TEXT;
BEGIN
    -- Validar formato celular Peru
    v_celular_limpio := REGEXP_REPLACE(p_celular, '[^0-9]', '', 'g');

    IF LENGTH(v_celular_limpio) != 9 THEN
        v_error_hint := 'celular_formato_invalido';
        RAISE EXCEPTION 'El celular debe tener exactamente 9 digitos';
    END IF;

    IF LEFT(v_celular_limpio, 1) != '9' THEN
        v_error_hint := 'celular_formato_invalido';
        RAISE EXCEPTION 'El celular debe iniciar con el digito 9';
    END IF;

    -- Buscar usuario por celular
    SELECT id, estado INTO v_usuario_id, v_estado
    FROM usuarios
    WHERE celular = v_celular_limpio;

    -- CA-002 / RN-004: Celular no existe en el sistema
    IF v_usuario_id IS NULL THEN
        RETURN json_build_object(
            'success', TRUE,
            'data', json_build_object(
                'tiene_invitacion', FALSE,
                'ya_activo', FALSE,
                'mensaje', 'No tienes invitacion. Contacta al administrador de tu grupo.'
            )
        );
    END IF;

    -- CA-004: Cuenta ya activa
    IF v_estado = 'aprobado' THEN
        RETURN json_build_object(
            'success', TRUE,
            'data', json_build_object(
                'tiene_invitacion', FALSE,
                'ya_activo', TRUE,
                'mensaje', 'Tu cuenta ya esta activa. Inicia sesion con tu celular y contrasena.'
            )
        );
    END IF;

    -- RN-001: Solo pendiente_aprobacion puede activar
    IF v_estado != 'pendiente_aprobacion' THEN
        RETURN json_build_object(
            'success', TRUE,
            'data', json_build_object(
                'tiene_invitacion', FALSE,
                'ya_activo', FALSE,
                'mensaje', 'Tu cuenta no puede ser activada en este momento. Contacta al administrador.'
            )
        );
    END IF;

    -- Contar grupos a los que fue invitado
    SELECT COUNT(*) INTO v_grupos_count
    FROM miembros_grupo
    WHERE usuario_id = v_usuario_id AND activo = TRUE;

    -- CA-001: Tiene invitacion pendiente
    RETURN json_build_object(
        'success', TRUE,
        'data', json_build_object(
            'tiene_invitacion', TRUE,
            'ya_activo', FALSE,
            'grupos_pendientes', v_grupos_count,
            'mensaje', 'Tienes una invitacion pendiente. Completa tu registro para activar tu cuenta.'
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', SQLSTATE,
                'hint', COALESCE(v_error_hint, 'error_desconocido')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accesible sin autenticacion (desde pantalla pre-login)
GRANT EXECUTE ON FUNCTION verificar_invitacion_pendiente TO anon;
GRANT EXECUTE ON FUNCTION verificar_invitacion_pendiente TO authenticated;

-- ============================================
-- PASO 2: RPC activar_cuenta_jugador
-- CA-001, CA-003, CA-005, CA-006
-- RN-001, RN-002, RN-003, RN-005
-- Vincula auth_user_id, nombre y activa la cuenta
-- Se llama DESPUES del signUp exitoso en Flutter
-- ============================================
CREATE OR REPLACE FUNCTION activar_cuenta_jugador(
    p_auth_user_id UUID,
    p_celular VARCHAR(9),
    p_nombre_completo TEXT
) RETURNS JSON AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
    v_usuario_id UUID;
    v_estado estado_usuario;
    v_error_hint TEXT;
    v_grupos_count INTEGER;
BEGIN
    -- =============================================
    -- Validaciones de entrada
    -- =============================================

    -- CA-005 / RN-005: Nombre obligatorio, minimo 2 caracteres
    IF p_nombre_completo IS NULL OR LENGTH(TRIM(p_nombre_completo)) < 2 THEN
        v_error_hint := 'nombre_invalido';
        RAISE EXCEPTION 'El nombre debe tener al menos 2 caracteres';
    END IF;

    -- Limpiar celular
    v_celular_limpio := REGEXP_REPLACE(p_celular, '[^0-9]', '', 'g');

    IF LENGTH(v_celular_limpio) != 9 THEN
        v_error_hint := 'celular_formato_invalido';
        RAISE EXCEPTION 'El celular debe tener exactamente 9 digitos';
    END IF;

    IF LEFT(v_celular_limpio, 1) != '9' THEN
        v_error_hint := 'celular_formato_invalido';
        RAISE EXCEPTION 'El celular debe iniciar con el digito 9';
    END IF;

    -- =============================================
    -- Buscar usuario por celular
    -- =============================================
    SELECT id, estado INTO v_usuario_id, v_estado
    FROM usuarios
    WHERE celular = v_celular_limpio;

    -- RN-004: Sin invitacion no hay activacion
    IF v_usuario_id IS NULL THEN
        v_error_hint := 'sin_invitacion';
        RAISE EXCEPTION 'No tienes invitacion. Contacta al administrador de tu grupo.';
    END IF;

    -- RN-001: Solo pendiente_aprobacion puede activar
    IF v_estado != 'pendiente_aprobacion' THEN
        v_error_hint := 'cuenta_ya_activa';
        RAISE EXCEPTION 'Tu cuenta ya esta activa. Inicia sesion normalmente.';
    END IF;

    -- =============================================
    -- RN-003: Activar cuenta - vincular auth y actualizar datos
    -- =============================================
    UPDATE usuarios SET
        auth_user_id = p_auth_user_id,
        nombre_completo = TRIM(p_nombre_completo),
        estado = 'aprobado',
        updated_at = NOW()
    WHERE id = v_usuario_id;

    -- FIX: Confirmar email en auth.users para que signInWithPassword funcione
    -- El email es ficticio (celular@gestiondeportiva.app) asi que nunca
    -- se confirmaria por flujo normal de Supabase Auth
    UPDATE auth.users
    SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
    WHERE id = p_auth_user_id;

    -- RN-003 (caso especial): Contar grupos activos
    SELECT COUNT(*) INTO v_grupos_count
    FROM miembros_grupo
    WHERE usuario_id = v_usuario_id AND activo = TRUE;

    -- CA-006: Retornar datos para redireccion al login
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Cuenta activada exitosamente. Ya puedes iniciar sesion.',
        'data', json_build_object(
            'usuario_id', v_usuario_id,
            'auth_user_id', p_auth_user_id,
            'celular', v_celular_limpio,
            'nombre_completo', TRIM(p_nombre_completo),
            'estado', 'aprobado',
            'grupos_activos', v_grupos_count
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', SQLSTATE,
                'hint', COALESCE(v_error_hint, 'error_desconocido')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Solo usuarios autenticados (ya hicieron signUp)
GRANT EXECUTE ON FUNCTION activar_cuenta_jugador TO authenticated;
