-- ============================================
-- FIX DEFINITIVO: Autenticacion con Supabase Auth Nativo
-- Fecha: 2026-01-15
-- ============================================
-- Este script soluciona TODOS los problemas de autenticacion:
-- 1. Elimina usuarios corruptos (sin auth.identities)
-- 2. Crea las funciones necesarias para el nuevo flujo
-- 3. Configura permisos correctamente
--
-- EJECUTAR UNA SOLA VEZ en Supabase SQL Editor
-- ============================================

-- ============================================
-- PARTE 1: LIMPIEZA DE DATOS CORRUPTOS
-- ============================================

-- Eliminar intentos de login
DELETE FROM intentos_login WHERE 1=1;

-- Eliminar notificaciones huerfanas
DELETE FROM notificaciones WHERE usuario_id NOT IN (SELECT id FROM usuarios);

-- Eliminar registros de sesiones huerfanos
DELETE FROM sesiones_log WHERE auth_user_id NOT IN (SELECT id FROM auth.users);

-- Eliminar usuarios de la tabla usuarios que no tienen identity en auth
DELETE FROM usuarios
WHERE auth_user_id IN (
    SELECT u.auth_user_id
    FROM usuarios u
    LEFT JOIN auth.identities i ON i.user_id = u.auth_user_id
    WHERE i.id IS NULL
);

-- Eliminar usuarios de auth.users que no tienen identity
DELETE FROM auth.users
WHERE id NOT IN (SELECT user_id FROM auth.identities WHERE user_id IS NOT NULL);

-- ============================================
-- PARTE 2: FUNCION completar_registro_usuario
-- ============================================
-- Esta funcion se llama DESPUES de supabase.auth.signUp()
-- para crear el perfil en la tabla usuarios

DROP FUNCTION IF EXISTS completar_registro_usuario(UUID, TEXT, TEXT);

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
-- PARTE 3: FUNCION verificar_sesion_usuario
-- ============================================
-- Se llama DESPUES de signInWithPassword() exitoso
-- para verificar estado y obtener datos del usuario

DROP FUNCTION IF EXISTS verificar_sesion_usuario(UUID);

CREATE OR REPLACE FUNCTION verificar_sesion_usuario(
    p_auth_user_id UUID DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_auth_id UUID;
    v_usuario RECORD;
BEGIN
    -- Obtener el auth_user_id del contexto de autenticacion o del parametro
    v_auth_id := COALESCE(p_auth_user_id, auth.uid());

    IF v_auth_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'NOT_AUTHENTICATED',
                'message', 'Usuario no autenticado',
                'hint', v_error_hint
            )
        );
    END IF;

    -- Buscar usuario en tabla usuarios
    SELECT id, auth_user_id, nombre_completo, email, estado, rol
    INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_auth_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'USER_NOT_FOUND',
                'message', 'Usuario no encontrado en el sistema',
                'hint', v_error_hint
            )
        );
    END IF;

    -- Verificar estado de la cuenta (RN-002)
    IF v_usuario.estado = 'pendiente_aprobacion' THEN
        v_error_hint := 'cuenta_pendiente';
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'PENDING_APPROVAL',
                'message', 'Tu cuenta esta pendiente de aprobacion por un administrador.',
                'hint', v_error_hint
            )
        );
    END IF;

    IF v_usuario.estado = 'rechazado' THEN
        v_error_hint := 'cuenta_rechazada';
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'ACCOUNT_REJECTED',
                'message', 'Tu solicitud de registro fue rechazada. Contacta al administrador para mas informacion.',
                'hint', v_error_hint
            )
        );
    END IF;

    -- Limpiar intentos fallidos si existen (login exitoso)
    DELETE FROM intentos_login WHERE LOWER(email) = LOWER(v_usuario.email);

    -- Retornar datos del usuario
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario.id,
            'auth_user_id', v_usuario.auth_user_id,
            'nombre_completo', v_usuario.nombre_completo,
            'email', v_usuario.email,
            'rol', v_usuario.rol,
            'estado', v_usuario.estado,
            'puede_acceder', true
        ),
        'message', 'Sesion verificada exitosamente'
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
-- PARTE 4: FUNCION registrar_intento_fallido
-- ============================================

DROP FUNCTION IF EXISTS registrar_intento_fallido(TEXT);

CREATE OR REPLACE FUNCTION registrar_intento_fallido(
    p_email TEXT
) RETURNS JSON AS $$
DECLARE
    v_email_normalizado TEXT;
    v_intentos RECORD;
    v_max_intentos CONSTANT INT := 5;
    v_tiempo_bloqueo CONSTANT INTERVAL := '15 minutes';
    v_minutos_restantes INT;
BEGIN
    v_email_normalizado := LOWER(TRIM(p_email));

    IF v_email_normalizado IS NULL OR v_email_normalizado = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'INVALID_INPUT',
                'message', 'Email requerido',
                'hint', 'campo_requerido'
            )
        );
    END IF;

    -- Buscar registro existente
    SELECT id, intentos_fallidos, bloqueado_hasta
    INTO v_intentos
    FROM intentos_login
    WHERE LOWER(email) = v_email_normalizado;

    IF NOT FOUND THEN
        -- Primer intento fallido
        INSERT INTO intentos_login (email, intentos_fallidos, ultimo_intento_at)
        VALUES (v_email_normalizado, 1, NOW());

        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'bloqueado', false,
                'intentos_fallidos', 1,
                'intentos_restantes', v_max_intentos - 1
            ),
            'message', 'Intento registrado'
        );
    END IF;

    -- Verificar si ya esta bloqueado
    IF v_intentos.bloqueado_hasta IS NOT NULL AND v_intentos.bloqueado_hasta > NOW() THEN
        v_minutos_restantes := CEIL(EXTRACT(EPOCH FROM (v_intentos.bloqueado_hasta - NOW())) / 60);

        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'bloqueado', true,
                'minutos_restantes', v_minutos_restantes
            ),
            'message', 'Cuenta bloqueada'
        );
    END IF;

    -- Incrementar contador
    UPDATE intentos_login
    SET
        intentos_fallidos = intentos_fallidos + 1,
        ultimo_intento_at = NOW(),
        bloqueado_hasta = CASE
            WHEN intentos_fallidos + 1 >= v_max_intentos
            THEN NOW() + v_tiempo_bloqueo
            ELSE NULL
        END
    WHERE id = v_intentos.id
    RETURNING intentos_fallidos, bloqueado_hasta INTO v_intentos.intentos_fallidos, v_intentos.bloqueado_hasta;

    IF v_intentos.bloqueado_hasta IS NOT NULL THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'bloqueado', true,
                'minutos_restantes', 15
            ),
            'message', 'Cuenta bloqueada por demasiados intentos'
        );
    END IF;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'bloqueado', false,
            'intentos_fallidos', v_intentos.intentos_fallidos,
            'intentos_restantes', v_max_intentos - v_intentos.intentos_fallidos
        ),
        'message', 'Intento registrado'
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
-- PARTE 5: PERMISOS
-- ============================================

-- completar_registro_usuario: anon para permitir registro
GRANT EXECUTE ON FUNCTION completar_registro_usuario TO anon, authenticated, service_role;

-- verificar_sesion_usuario: Solo usuarios autenticados
GRANT EXECUTE ON FUNCTION verificar_sesion_usuario TO authenticated, service_role;

-- registrar_intento_fallido: anon para registrar antes de autenticarse
GRANT EXECUTE ON FUNCTION registrar_intento_fallido TO anon, authenticated, service_role;

-- ============================================
-- PARTE 6: VERIFICACION FINAL
-- ============================================

-- Mostrar funciones creadas
SELECT
    proname as funcion,
    'CREADA' as estado
FROM pg_proc
WHERE proname IN (
    'completar_registro_usuario',
    'verificar_sesion_usuario',
    'registrar_intento_fallido'
)
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Mostrar estado de limpieza
SELECT
    'auth.users sin identity' as tipo,
    COUNT(*) as cantidad
FROM auth.users u
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE i.id IS NULL

UNION ALL

SELECT
    'usuarios en tabla usuarios' as tipo,
    COUNT(*) as cantidad
FROM usuarios;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
-- Despues de ejecutar:
-- 1. Ve a la app Flutter
-- 2. Registrate (sera el primer usuario = admin automatico)
-- 3. Haz login con las mismas credenciales
-- ============================================
