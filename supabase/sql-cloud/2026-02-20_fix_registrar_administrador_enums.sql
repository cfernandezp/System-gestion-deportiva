-- ============================================
-- FIX: Corregir valores de enum en registrar_administrador
-- Fecha: 2026-02-20
-- Problema: La funcion usaba 'activo' (no existe en estado_usuario)
--           y 'administrador' (no existe en rol_usuario)
-- Correccion: 'activo' → 'aprobado', 'administrador' → 'admin'
-- Enums validos:
--   estado_usuario: pendiente_aprobacion, aprobado, rechazado
--   rol_usuario: admin, jugador
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
    -- FIX: 'activo' → 'aprobado', 'administrador' → 'admin'
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

    -- =============================================
    -- Retornar resultado exitoso
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

GRANT EXECUTE ON FUNCTION registrar_administrador TO authenticated;
GRANT EXECUTE ON FUNCTION registrar_administrador TO anon;
