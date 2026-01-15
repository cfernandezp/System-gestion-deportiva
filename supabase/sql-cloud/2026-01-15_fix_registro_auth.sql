-- ============================================
-- FIX: Registro usando Supabase Auth nativo
-- Fecha: 2026-01-15
-- Descripcion: Corrige el flujo de registro para usar
--              supabase.auth.signUp() en lugar de INSERT
--              directo en auth.users con crypt()
--
-- PROBLEMA: La funcion registrar_usuario insertaba directamente
--           en auth.users usando crypt(), pero Supabase Auth usa
--           un formato interno diferente para el hash de contrasena.
--           Por eso signInWithPassword() fallaba con credenciales invalidas.
--
-- SOLUCION:
--   1. Flutter llama supabase.auth.signUp() (crea usuario en auth.users)
--   2. Flutter llama RPC completar_registro_usuario() (crea registro en usuarios)
-- ============================================

-- ============================================
-- Funcion: completar_registro_usuario
-- Descripcion: Completa el registro de un usuario ya creado en auth.users
--              por Supabase Auth nativo (signUp)
-- Reglas: RN-001, RN-004, RN-005, RN-006, RN-009
-- ============================================
CREATE OR REPLACE FUNCTION completar_registro_usuario(
    p_auth_user_id UUID,
    p_nombre_completo TEXT,
    p_email TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_usuario_id UUID;
    v_admin_record RECORD;
    v_es_primer_usuario BOOLEAN;
BEGIN
    -- Validar que se proporcionen los parametros
    IF p_auth_user_id IS NULL THEN
        v_error_hint := 'auth_user_id_requerido';
        RAISE EXCEPTION 'El auth_user_id es requerido';
    END IF;

    -- Validar nombre completo (RN-009)
    IF p_nombre_completo IS NULL OR LENGTH(TRIM(p_nombre_completo)) < 2 THEN
        v_error_hint := 'nombre_invalido';
        RAISE EXCEPTION 'El nombre completo debe tener al menos 2 caracteres';
    END IF;

    -- Validar formato de email
    IF p_email IS NULL OR p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        v_error_hint := 'email_formato_invalido';
        RAISE EXCEPTION 'El formato del email no es valido';
    END IF;

    -- Verificar que el auth_user_id exista en auth.users
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_auth_user_id) THEN
        v_error_hint := 'auth_user_no_existe';
        RAISE EXCEPTION 'El usuario no existe en auth.users';
    END IF;

    -- Verificar que no exista ya un registro en usuarios para este auth_user_id
    IF EXISTS (SELECT 1 FROM usuarios WHERE auth_user_id = p_auth_user_id) THEN
        v_error_hint := 'usuario_ya_registrado';
        RAISE EXCEPTION 'El usuario ya tiene un registro en el sistema';
    END IF;

    -- Validar email unico - excluir rechazados (RN-001)
    IF EXISTS (
        SELECT 1 FROM usuarios
        WHERE LOWER(email) = LOWER(p_email)
        AND estado != 'rechazado'
    ) THEN
        v_error_hint := 'email_duplicado';
        RAISE EXCEPTION 'El email ya esta registrado en el sistema';
    END IF;

    -- Verificar si es el primer usuario (sera admin automatico)
    SELECT NOT EXISTS (SELECT 1 FROM usuarios WHERE estado = 'aprobado') INTO v_es_primer_usuario;

    -- Crear registro en tabla usuarios (RN-004, RN-005)
    INSERT INTO usuarios (
        auth_user_id,
        nombre_completo,
        email,
        estado,
        rol
    ) VALUES (
        p_auth_user_id,
        TRIM(p_nombre_completo),
        LOWER(p_email),
        CASE WHEN v_es_primer_usuario THEN 'aprobado'::estado_usuario ELSE 'pendiente_aprobacion'::estado_usuario END,
        CASE WHEN v_es_primer_usuario THEN 'admin'::rol_usuario ELSE 'jugador'::rol_usuario END
    )
    RETURNING id INTO v_usuario_id;

    -- Si es primer usuario, no notificar (es admin)
    IF v_es_primer_usuario THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'usuario_id', v_usuario_id,
                'auth_user_id', p_auth_user_id,
                'email', LOWER(p_email),
                'estado', 'aprobado',
                'rol', 'admin',
                'es_primer_usuario', true
            ),
            'message', 'Usuario administrador creado exitosamente. Ya puedes iniciar sesion.'
        );
    END IF;

    -- Notificar a todos los administradores (RN-006)
    FOR v_admin_record IN
        SELECT id, nombre_completo
        FROM usuarios
        WHERE rol = 'admin' AND estado = 'aprobado'
    LOOP
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            metadata
        ) VALUES (
            v_admin_record.id,
            'nuevo_registro',
            'Nueva solicitud de registro',
            'El usuario ' || TRIM(p_nombre_completo) || ' (' || LOWER(p_email) || ') ha solicitado acceso al sistema.',
            jsonb_build_object(
                'solicitante_id', v_usuario_id,
                'solicitante_nombre', TRIM(p_nombre_completo),
                'solicitante_email', LOWER(p_email)
            )
        );
    END LOOP;

    -- Retorno exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario_id,
            'auth_user_id', p_auth_user_id,
            'email', LOWER(p_email),
            'estado', 'pendiente_aprobacion',
            'rol', 'jugador',
            'es_primer_usuario', false
        ),
        'message', 'Registro exitoso. Tu cuenta esta pendiente de aprobacion por un administrador.'
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'UNIQUE_VIOLATION',
                'message', 'El email ya esta registrado en el sistema',
                'hint', 'email_duplicado'
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
-- Funcion auxiliar: eliminar_usuario_auth
-- Descripcion: Elimina un usuario de auth.users (para rollback si falla)
-- Uso: Solo desde service_role cuando completar_registro falla
-- ============================================
CREATE OR REPLACE FUNCTION eliminar_usuario_auth(
    p_auth_user_id UUID
) RETURNS JSON AS $$
BEGIN
    -- Solo permitir si el usuario no tiene registro en usuarios
    -- (para evitar eliminar usuarios ya registrados)
    IF EXISTS (SELECT 1 FROM usuarios WHERE auth_user_id = p_auth_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'USER_HAS_PROFILE',
                'message', 'No se puede eliminar: el usuario tiene un perfil asociado',
                'hint', 'usuario_con_perfil'
            )
        );
    END IF;

    -- Eliminar de auth.users
    DELETE FROM auth.users WHERE id = p_auth_user_id;

    RETURN json_build_object(
        'success', true,
        'message', 'Usuario eliminado de auth.users'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', 'error_eliminando_auth'
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PERMISOS
-- ============================================

-- completar_registro_usuario: anon para permitir registro sin auth previo
GRANT EXECUTE ON FUNCTION completar_registro_usuario TO anon, authenticated, service_role;

-- eliminar_usuario_auth: solo service_role (uso interno para rollback)
GRANT EXECUTE ON FUNCTION eliminar_usuario_auth TO service_role;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON FUNCTION completar_registro_usuario IS 'FIX-2026-01-15: Completa registro de usuario creado por Supabase Auth signUp(). Reemplaza INSERT directo en auth.users.';
COMMENT ON FUNCTION eliminar_usuario_auth IS 'FIX-2026-01-15: Elimina usuario de auth.users para rollback si completar_registro falla.';

-- ============================================
-- NOTA: La funcion registrar_usuario original queda obsoleta
-- pero no la eliminamos para no romper nada existente.
-- El frontend debe usar el nuevo flujo:
--   1. supabase.auth.signUp()
--   2. RPC completar_registro_usuario()
-- ============================================

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
