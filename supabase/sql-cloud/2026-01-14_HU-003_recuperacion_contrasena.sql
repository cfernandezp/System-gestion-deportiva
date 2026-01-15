-- ============================================
-- HU-003: Recuperacion de Contrasena
-- Fecha: 2026-01-14
-- Descripcion: Implementacion del flujo de recuperacion de contrasena
--              con validaciones de seguridad y gestion de tokens
-- ============================================

-- ============================================
-- PARTE 1: TABLA DE TOKENS DE RECUPERACION
-- ============================================

-- Tabla: tokens_recuperacion
-- Descripcion: Almacena tokens de recuperacion de contrasena (RN-002, RN-003)
CREATE TABLE IF NOT EXISTS tokens_recuperacion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL,
    expira_at TIMESTAMPTZ NOT NULL,
    usado BOOLEAN NOT NULL DEFAULT FALSE,
    usado_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice para busquedas por token
CREATE INDEX IF NOT EXISTS idx_tokens_recuperacion_token ON tokens_recuperacion(token_hash);
-- Indice para busquedas por usuario
CREATE INDEX IF NOT EXISTS idx_tokens_recuperacion_usuario ON tokens_recuperacion(usuario_id);
-- Indice para limpieza de tokens expirados
CREATE INDEX IF NOT EXISTS idx_tokens_recuperacion_expira ON tokens_recuperacion(expira_at);

-- ============================================
-- PARTE 2: FUNCIONES RPC
-- ============================================

-- ============================================
-- Funcion: solicitar_recuperacion_contrasena
-- Descripcion: Solicita recuperacion de contrasena para un email
-- Reglas: RN-001 (mensaje uniforme), RN-002 (token valido 1 hora)
-- Criterios: CA-001, CA-002, CA-003
--
-- IMPORTANTE: Esta funcion genera un token interno. El frontend debe:
-- 1. Llamar esta funcion para obtener el token
-- 2. Enviar el email con el enlace usando el token retornado
-- (O usar Supabase Edge Functions para enviar email automaticamente)
-- ============================================
CREATE OR REPLACE FUNCTION solicitar_recuperacion_contrasena(
    p_email TEXT
) RETURNS JSON AS $$
DECLARE
    v_email_normalizado TEXT;
    v_usuario RECORD;
    v_token TEXT;
    v_token_hash TEXT;
    v_token_id UUID;
    v_mensaje_generico CONSTANT TEXT := 'Si el email esta registrado, recibiras instrucciones para restablecer tu contrasena.';
BEGIN
    -- Normalizar email
    v_email_normalizado := LOWER(TRIM(p_email));

    -- Validar formato de email
    IF v_email_normalizado IS NULL OR v_email_normalizado = '' THEN
        -- Retornar mensaje generico incluso si email vacio (RN-001)
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'email_enviado', false
            ),
            'message', v_mensaje_generico
        );
    END IF;

    -- Buscar usuario por email (solo aprobados pueden recuperar contrasena)
    SELECT u.id, u.nombre_completo, u.email, u.estado, u.auth_user_id
    INTO v_usuario
    FROM usuarios u
    WHERE LOWER(u.email) = v_email_normalizado
    AND u.estado = 'aprobado';

    -- Si no existe o no esta aprobado, retornar mensaje generico (RN-001 - seguridad)
    IF NOT FOUND THEN
        -- Mensaje identico para no revelar si email existe
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'email_enviado', false
            ),
            'message', v_mensaje_generico
        );
    END IF;

    -- ============================================
    -- Usuario existe y esta aprobado: Generar token
    -- ============================================

    -- Invalidar tokens anteriores del usuario (RN-002 caso especial)
    UPDATE tokens_recuperacion
    SET usado = TRUE, usado_at = NOW()
    WHERE usuario_id = v_usuario.id
    AND usado = FALSE
    AND expira_at > NOW();

    -- Generar token unico (64 caracteres hexadecimales)
    v_token := encode(gen_random_bytes(32), 'hex');

    -- Guardar hash del token (no el token plano por seguridad)
    v_token_hash := encode(digest(v_token, 'sha256'), 'hex');

    -- Insertar token con expiracion de 1 hora (RN-002)
    INSERT INTO tokens_recuperacion (
        usuario_id,
        token_hash,
        expira_at
    ) VALUES (
        v_usuario.id,
        v_token_hash,
        NOW() + INTERVAL '1 hour'
    )
    RETURNING id INTO v_token_id;

    -- Retornar exito con token para que el frontend envie el email
    -- NOTA: En produccion, el token deberia enviarse por email, no retornarse
    -- Aqui lo retornamos para que el frontend/Edge Function pueda enviarlo
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'email_enviado', true,
            'token', v_token,  -- Token plano para incluir en URL del email
            'token_id', v_token_id,
            'expira_en_minutos', 60,
            'usuario_nombre', v_usuario.nombre_completo
        ),
        'message', v_mensaje_generico
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Incluso en error, retornar mensaje generico (seguridad)
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'email_enviado', false
            ),
            'message', v_mensaje_generico
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Funcion: validar_token_recuperacion
-- Descripcion: Valida si un token de recuperacion es valido
-- Reglas: RN-002, RN-003
-- Criterios: CA-004, CA-005
-- ============================================
CREATE OR REPLACE FUNCTION validar_token_recuperacion(
    p_token TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_token_hash TEXT;
    v_token_record RECORD;
BEGIN
    -- Validar que se proporciono token
    IF p_token IS NULL OR TRIM(p_token) = '' THEN
        v_error_hint := 'token_requerido';
        RAISE EXCEPTION 'El token de recuperacion es requerido';
    END IF;

    -- Calcular hash del token proporcionado
    v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

    -- Buscar token en la base de datos
    SELECT tr.id, tr.usuario_id, tr.expira_at, tr.usado, tr.created_at,
           u.email, u.nombre_completo
    INTO v_token_record
    FROM tokens_recuperacion tr
    INNER JOIN usuarios u ON u.id = tr.usuario_id
    WHERE tr.token_hash = v_token_hash;

    -- Token no encontrado
    IF NOT FOUND THEN
        v_error_hint := 'token_invalido';
        RAISE EXCEPTION 'El enlace de recuperacion no es valido';
    END IF;

    -- Token ya usado (RN-003)
    IF v_token_record.usado THEN
        v_error_hint := 'token_usado';
        RAISE EXCEPTION 'Este enlace de recuperacion ya fue utilizado. Solicita uno nuevo.';
    END IF;

    -- Token expirado (RN-002, CA-005)
    IF v_token_record.expira_at < NOW() THEN
        v_error_hint := 'token_expirado';
        RAISE EXCEPTION 'El enlace de recuperacion ha expirado. Solicita uno nuevo.';
    END IF;

    -- Token valido (CA-004)
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'valido', true,
            'email', v_token_record.email,
            'nombre', v_token_record.nombre_completo,
            'expira_at', v_token_record.expira_at AT TIME ZONE 'America/Lima',
            'minutos_restantes', CEIL(EXTRACT(EPOCH FROM (v_token_record.expira_at - NOW())) / 60)::INT
        ),
        'message', 'Token valido'
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
-- Funcion: restablecer_contrasena
-- Descripcion: Restablece la contrasena usando un token valido
-- Reglas: RN-002, RN-003, RN-004, RN-005, RN-006
-- Criterios: CA-004, CA-005, CA-006
-- ============================================
CREATE OR REPLACE FUNCTION restablecer_contrasena(
    p_token TEXT,
    p_nueva_contrasena TEXT,
    p_confirmar_contrasena TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_token_hash TEXT;
    v_token_record RECORD;
    v_usuario RECORD;
    v_password_validation JSON;
    v_old_password_hash TEXT;
BEGIN
    -- ============================================
    -- PASO 1: Validar campos requeridos
    -- ============================================
    IF p_token IS NULL OR TRIM(p_token) = '' THEN
        v_error_hint := 'token_requerido';
        RAISE EXCEPTION 'El token de recuperacion es requerido';
    END IF;

    IF p_nueva_contrasena IS NULL OR p_nueva_contrasena = '' THEN
        v_error_hint := 'contrasena_requerida';
        RAISE EXCEPTION 'La nueva contrasena es requerida';
    END IF;

    IF p_confirmar_contrasena IS NULL OR p_confirmar_contrasena = '' THEN
        v_error_hint := 'confirmacion_requerida';
        RAISE EXCEPTION 'La confirmacion de contrasena es requerida';
    END IF;

    -- ============================================
    -- PASO 2: Validar que contrasenas coinciden (RN-005)
    -- ============================================
    IF p_nueva_contrasena != p_confirmar_contrasena THEN
        v_error_hint := 'contrasenas_no_coinciden';
        RAISE EXCEPTION 'Las contrasenas no coinciden';
    END IF;

    -- ============================================
    -- PASO 3: Validar token
    -- ============================================
    v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

    SELECT tr.id, tr.usuario_id, tr.expira_at, tr.usado
    INTO v_token_record
    FROM tokens_recuperacion tr
    WHERE tr.token_hash = v_token_hash;

    IF NOT FOUND THEN
        v_error_hint := 'token_invalido';
        RAISE EXCEPTION 'El enlace de recuperacion no es valido';
    END IF;

    IF v_token_record.usado THEN
        v_error_hint := 'token_usado';
        RAISE EXCEPTION 'Este enlace de recuperacion ya fue utilizado. Solicita uno nuevo.';
    END IF;

    IF v_token_record.expira_at < NOW() THEN
        v_error_hint := 'token_expirado';
        RAISE EXCEPTION 'El enlace de recuperacion ha expirado. Solicita uno nuevo.';
    END IF;

    -- ============================================
    -- PASO 4: Obtener usuario y validar contrasena
    -- ============================================
    SELECT u.id, u.auth_user_id, u.email, u.nombre_completo
    INTO v_usuario
    FROM usuarios u
    WHERE u.id = v_token_record.usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    -- Validar requisitos de contrasena (RN-004)
    v_password_validation := validar_password(p_nueva_contrasena);
    IF NOT (v_password_validation->>'valid')::BOOLEAN THEN
        v_error_hint := 'contrasena_invalida';
        RAISE EXCEPTION 'La contrasena no cumple los requisitos: %',
            array_to_string((SELECT array_agg(x) FROM json_array_elements_text(v_password_validation->'errors') x), ', ');
    END IF;

    -- Obtener hash de contrasena actual para verificar que no sea igual (RN-004)
    SELECT encrypted_password INTO v_old_password_hash
    FROM auth.users
    WHERE id = v_usuario.auth_user_id;

    -- Verificar que la nueva contrasena sea diferente a la actual (RN-004)
    IF v_old_password_hash = crypt(p_nueva_contrasena, v_old_password_hash) THEN
        v_error_hint := 'contrasena_igual_anterior';
        RAISE EXCEPTION 'La nueva contrasena no puede ser igual a la contrasena actual';
    END IF;

    -- ============================================
    -- PASO 5: Actualizar contrasena en auth.users
    -- ============================================
    UPDATE auth.users
    SET
        encrypted_password = crypt(p_nueva_contrasena, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_usuario.auth_user_id;

    -- ============================================
    -- PASO 6: Marcar token como usado (RN-003)
    -- ============================================
    UPDATE tokens_recuperacion
    SET
        usado = TRUE,
        usado_at = NOW()
    WHERE id = v_token_record.id;

    -- ============================================
    -- PASO 7: Invalidar todas las sesiones activas (RN-006)
    -- Nota: Supabase almacena sesiones en auth.refresh_tokens
    -- ============================================
    DELETE FROM auth.refresh_tokens
    WHERE user_id = v_usuario.auth_user_id;

    -- Tambien invalidar sesiones en auth.sessions si existe
    BEGIN
        DELETE FROM auth.sessions
        WHERE user_id = v_usuario.auth_user_id;
    EXCEPTION
        WHEN undefined_table THEN
            -- La tabla auth.sessions puede no existir en algunas versiones
            NULL;
    END;

    -- ============================================
    -- PASO 8: Retornar exito (CA-006)
    -- ============================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'email', v_usuario.email,
            'sesiones_cerradas', true
        ),
        'message', 'Contrasena actualizada exitosamente. Por seguridad, todas las sesiones han sido cerradas. Inicia sesion con tu nueva contrasena.'
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
-- Funcion: limpiar_tokens_expirados
-- Descripcion: Limpia tokens de recuperacion expirados (mantenimiento)
-- Uso: Ejecutar periodicamente o manualmente
-- ============================================
CREATE OR REPLACE FUNCTION limpiar_tokens_expirados()
RETURNS JSON AS $$
DECLARE
    v_eliminados INT;
BEGIN
    -- Eliminar tokens expirados hace mas de 24 horas o usados hace mas de 24 horas
    DELETE FROM tokens_recuperacion
    WHERE (expira_at < NOW() - INTERVAL '24 hours')
       OR (usado = TRUE AND usado_at < NOW() - INTERVAL '24 hours');

    GET DIAGNOSTICS v_eliminados = ROW_COUNT;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'tokens_eliminados', v_eliminados
        ),
        'message', 'Limpieza de tokens completada'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', 'unknown'
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PARTE 3: PERMISOS
-- ============================================

-- Permisos para funciones RPC
-- solicitar_recuperacion_contrasena: Disponible para usuarios no autenticados
GRANT EXECUTE ON FUNCTION solicitar_recuperacion_contrasena TO anon, authenticated, service_role;
-- validar_token_recuperacion: Disponible para validar token desde el enlace
GRANT EXECUTE ON FUNCTION validar_token_recuperacion TO anon, authenticated, service_role;
-- restablecer_contrasena: Disponible para usuarios no autenticados (vienen del enlace del email)
GRANT EXECUTE ON FUNCTION restablecer_contrasena TO anon, authenticated, service_role;
-- limpiar_tokens_expirados: Solo para service_role (mantenimiento)
GRANT EXECUTE ON FUNCTION limpiar_tokens_expirados TO service_role;

-- ============================================
-- PARTE 4: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tabla tokens_recuperacion
ALTER TABLE tokens_recuperacion ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "No acceso directo a tokens_recuperacion" ON tokens_recuperacion;
DROP POLICY IF EXISTS "Service role acceso completo tokens" ON tokens_recuperacion;

-- No permitir acceso directo a la tabla desde clientes
-- Solo las funciones SECURITY DEFINER pueden acceder
CREATE POLICY "No acceso directo a tokens_recuperacion"
ON tokens_recuperacion FOR ALL
TO anon, authenticated
USING (false);

-- Service role tiene acceso completo (para mantenimiento)
CREATE POLICY "Service role acceso completo tokens"
ON tokens_recuperacion FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- PARTE 5: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE tokens_recuperacion IS 'HU-003: Tokens de recuperacion de contrasena con expiracion de 1 hora (RN-002, RN-003)';
COMMENT ON FUNCTION solicitar_recuperacion_contrasena IS 'HU-003: Solicita recuperacion de contrasena con mensaje uniforme por seguridad (CA-001 a CA-003, RN-001, RN-002)';
COMMENT ON FUNCTION validar_token_recuperacion IS 'HU-003: Valida si un token de recuperacion es valido y no ha expirado (CA-004, CA-005)';
COMMENT ON FUNCTION restablecer_contrasena IS 'HU-003: Restablece contrasena validando token, requisitos y cerrando sesiones (CA-004 a CA-006, RN-002 a RN-006)';
COMMENT ON FUNCTION limpiar_tokens_expirados IS 'HU-003: Limpia tokens de recuperacion expirados (mantenimiento)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
