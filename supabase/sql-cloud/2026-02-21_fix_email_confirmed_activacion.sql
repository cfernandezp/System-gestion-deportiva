-- ============================================
-- FIX: email_confirmed_at NULL impide login
-- Fecha: 2026-02-21
-- ============================================
-- BUG: Cuando un jugador activa su cuenta via activar_cuenta_jugador,
--       o cuando un admin se registra via registrar_administrador,
--       el signUp() de Supabase Auth crea el registro en auth.users
--       pero como el email es ficticio (celular@gestiondeportiva.app),
--       email_confirmed_at queda NULL.
--       Luego signInWithPassword() rechaza el login con
--       "Invalid login credentials" porque el email no esta confirmado.
--
-- SOLUCION: Agregar UPDATE a auth.users seteando email_confirmed_at
--           en ambas funciones RPC. Ademas, corregir usuarios existentes
--           que ya se registraron sin confirmacion.
-- ============================================

-- ============================================
-- PASO 1: Funcion activar_cuenta_jugador CORREGIDA
-- Cambio: Agrega UPDATE auth.users SET email_confirmed_at
--         despues del UPDATE a tabla usuarios (linea marcada con -- FIX)
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

-- ============================================
-- PASO 2: Funcion registrar_administrador CORREGIDA
-- Cambio: Agrega UPDATE auth.users SET email_confirmed_at
--         despues del INSERT en tabla usuarios (linea marcada con -- FIX)
-- ============================================
CREATE OR REPLACE FUNCTION registrar_administrador(
    p_auth_user_id UUID,
    p_celular VARCHAR(9),
    p_nombre_completo TEXT,
    p_pregunta_seguridad TEXT,
    p_respuesta_seguridad TEXT,
    p_email_respaldo TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_error_hint TEXT;
    v_celular_limpio VARCHAR(9);
    v_respuesta_limpia TEXT;
BEGIN
    -- =============================================
    -- Validaciones de entrada
    -- =============================================

    -- CA-005 / RN: Nombre obligatorio, minimo 2 caracteres
    IF p_nombre_completo IS NULL OR LENGTH(TRIM(p_nombre_completo)) < 2 THEN
        v_error_hint := 'nombre_invalido';
        RAISE EXCEPTION 'El nombre debe tener al menos 2 caracteres';
    END IF;

    -- Limpiar celular (solo digitos)
    v_celular_limpio := REGEXP_REPLACE(p_celular, '[^0-9]', '', 'g');

    -- CA-003 / RN-002: Validar formato celular Peru
    -- Exactamente 9 digitos, debe iniciar con 9
    IF LENGTH(v_celular_limpio) != 9 THEN
        v_error_hint := 'celular_formato_invalido';
        RAISE EXCEPTION 'El celular debe tener exactamente 9 digitos';
    END IF;

    IF LEFT(v_celular_limpio, 1) != '9' THEN
        v_error_hint := 'celular_formato_invalido';
        RAISE EXCEPTION 'El celular debe iniciar con el digito 9';
    END IF;

    -- CA-002 / RN-001: Verificar celular no duplicado
    IF EXISTS (SELECT 1 FROM usuarios WHERE celular = v_celular_limpio) THEN
        v_error_hint := 'celular_duplicado';
        RAISE EXCEPTION 'Este numero de celular ya esta registrado en el sistema';
    END IF;

    -- CA-006 / RN-004: Pregunta de seguridad obligatoria
    IF p_pregunta_seguridad IS NULL OR TRIM(p_pregunta_seguridad) = '' THEN
        v_error_hint := 'pregunta_seguridad_requerida';
        RAISE EXCEPTION 'Debe seleccionar una pregunta de seguridad';
    END IF;

    -- CA-006 / RN-004: Respuesta de seguridad obligatoria
    IF p_respuesta_seguridad IS NULL OR TRIM(p_respuesta_seguridad) = '' THEN
        v_error_hint := 'respuesta_seguridad_requerida';
        RAISE EXCEPTION 'Debe proporcionar una respuesta a la pregunta de seguridad';
    END IF;

    -- RN-004: Almacenar respuesta en minusculas para comparacion case-insensitive
    v_respuesta_limpia := LOWER(TRIM(p_respuesta_seguridad));

    -- RN-005: Validar formato email de respaldo si se proporciona
    IF p_email_respaldo IS NOT NULL AND TRIM(p_email_respaldo) != '' THEN
        IF p_email_respaldo !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
            v_error_hint := 'email_formato_invalido';
            RAISE EXCEPTION 'El formato del email de respaldo no es valido';
        END IF;
    END IF;

    -- =============================================
    -- Crear perfil de usuario administrador
    -- RN-006: Estado aprobado inmediatamente (admin no requiere aprobacion)
    -- =============================================
    INSERT INTO usuarios (
        auth_user_id,
        nombre_completo,
        celular,
        email,
        pregunta_seguridad,
        respuesta_seguridad,
        email_respaldo,
        estado,
        rol,
        created_at,
        updated_at
    ) VALUES (
        p_auth_user_id,
        TRIM(p_nombre_completo),
        v_celular_limpio,
        v_celular_limpio || '@gestiondeportiva.app',
        TRIM(p_pregunta_seguridad),
        v_respuesta_limpia,
        CASE
            WHEN p_email_respaldo IS NOT NULL AND TRIM(p_email_respaldo) != ''
            THEN LOWER(TRIM(p_email_respaldo))
            ELSE NULL
        END,
        'aprobado',
        'admin',
        NOW(),
        NOW()
    )
    RETURNING id INTO v_usuario_id;

    -- FIX: Confirmar email en auth.users para que signInWithPassword funcione
    -- El email es ficticio (celular@gestiondeportiva.app) asi que nunca
    -- se confirmaria por flujo normal de Supabase Auth
    UPDATE auth.users
    SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
    WHERE id = p_auth_user_id;

    -- =============================================
    -- Retornar resultado exitoso
    -- CA-001: Registro exitoso
    -- CA-008: Datos para redireccion post-registro
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Cuenta de administrador creada exitosamente',
        'data', json_build_object(
            'usuario_id', v_usuario_id,
            'auth_user_id', p_auth_user_id,
            'celular', v_celular_limpio,
            'nombre_completo', TRIM(p_nombre_completo),
            'estado', 'aprobado',
            'rol', 'admin',
            'requiere_crear_grupo', TRUE
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Capturar cualquier error y retornar formato estandar
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

-- Permisos: permitir a usuarios autenticados llamar esta funcion
GRANT EXECUTE ON FUNCTION registrar_administrador TO authenticated;
GRANT EXECUTE ON FUNCTION registrar_administrador TO anon;

-- ============================================
-- PASO 3: Corregir usuarios existentes que ya se registraron
--         con email ficticio y email_confirmed_at = NULL
-- ============================================
UPDATE auth.users
SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE email LIKE '%@gestiondeportiva.app'
  AND email_confirmed_at IS NULL;

-- ============================================
-- PASO 4: Verificar correccion
-- ============================================
SELECT
    au.id,
    au.email,
    au.email_confirmed_at,
    u.nombre_completo,
    u.estado
FROM auth.users au
LEFT JOIN usuarios u ON u.auth_user_id = au.id
WHERE au.email LIKE '%@gestiondeportiva.app'
ORDER BY au.created_at DESC;
