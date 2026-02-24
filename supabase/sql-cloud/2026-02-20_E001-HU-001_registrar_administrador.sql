-- ============================================
-- E001-HU-001: Registro de Administrador
-- Fecha: 2026-02-20
-- Descripcion: Migracion para soporte de registro con celular como
--              identificador principal, pregunta de seguridad y email de respaldo.
--              Funcion RPC para registrar administrador con activacion inmediata.
-- ============================================

-- =============================================
-- PASO 1: Agregar columnas nuevas a tabla usuarios
-- RN-001: celular como identificador unico global
-- RN-004: pregunta de seguridad obligatoria
-- RN-005: email de respaldo opcional
-- =============================================

-- Celular: 9 digitos, formato Peru (RN-002)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS celular VARCHAR(9);

-- Pregunta y respuesta de seguridad (RN-004)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS pregunta_seguridad TEXT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS respuesta_seguridad TEXT;

-- Email de respaldo opcional (RN-005)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS email_respaldo VARCHAR(255);

-- RN-001: Unique constraint en celular (solo si no es null)
CREATE UNIQUE INDEX IF NOT EXISTS idx_usuarios_celular_unique
ON usuarios (celular)
WHERE celular IS NOT NULL;

-- Indice para busqueda por celular
CREATE INDEX IF NOT EXISTS idx_usuarios_celular
ON usuarios (celular)
WHERE celular IS NOT NULL;

-- =============================================
-- PASO 2: Funcion RPC registrar_administrador
-- CA-001: Registro exitoso con datos validos
-- CA-002: Celular ya registrado
-- CA-003: Validacion de formato celular
-- CA-004: Validacion de contrasena (delegada a validar_password)
-- CA-005: Nombre obligatorio
-- CA-006: Pregunta de seguridad obligatoria
-- CA-007: Email de respaldo opcional
-- CA-008: Redireccion post-registro (retorna datos para frontend)
-- RN-001: Celular como identificador unico
-- RN-002: Formato celular Peru (9 digitos, inicia con 9)
-- RN-003: Requisitos de contrasena (delegados a validar_password)
-- RN-004: Pregunta de seguridad obligatoria
-- RN-005: Email de respaldo opcional
-- RN-006: Cuenta activa inmediatamente
-- =============================================
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
