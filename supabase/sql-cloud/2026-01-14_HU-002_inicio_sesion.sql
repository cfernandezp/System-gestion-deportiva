-- ============================================
-- HU-002: Inicio de Sesion
-- Fecha: 2026-01-14
-- Descripcion: Implementacion del flujo de inicio de sesion con
--              control de intentos fallidos y verificacion de estado
-- ============================================

-- ============================================
-- PARTE 1: TABLA DE INTENTOS DE LOGIN
-- ============================================

-- Tabla: intentos_login
-- Descripcion: Registra intentos fallidos de login para proteccion contra fuerza bruta (RN-007)
CREATE TABLE IF NOT EXISTS intentos_login (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    intentos_fallidos INT NOT NULL DEFAULT 0,
    bloqueado_hasta TIMESTAMPTZ,
    ultimo_intento_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice unico para email (un registro por email)
CREATE UNIQUE INDEX IF NOT EXISTS idx_intentos_login_email ON intentos_login(LOWER(email));

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_intentos_login_updated_at ON intentos_login;
CREATE TRIGGER trigger_intentos_login_updated_at
    BEFORE UPDATE ON intentos_login
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 2: FUNCIONES RPC
-- ============================================

-- ============================================
-- Funcion: iniciar_sesion
-- Descripcion: Autentica usuario verificando credenciales, estado de cuenta y bloqueo
-- Reglas: RN-002, RN-003, RN-004, RN-005, RN-007
-- Criterios: CA-002, CA-003
-- ============================================
CREATE OR REPLACE FUNCTION iniciar_sesion(
    p_email TEXT,
    p_password TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_email_normalizado TEXT;
    v_intentos RECORD;
    v_auth_user RECORD;
    v_usuario RECORD;
    v_minutos_restantes INT;
    v_max_intentos CONSTANT INT := 5;
    v_tiempo_bloqueo CONSTANT INTERVAL := '15 minutes';
BEGIN
    -- Normalizar email
    v_email_normalizado := LOWER(TRIM(p_email));

    -- Validar campos obligatorios (RN-001)
    IF v_email_normalizado IS NULL OR v_email_normalizado = '' THEN
        v_error_hint := 'campo_requerido';
        RAISE EXCEPTION 'El email es requerido';
    END IF;

    IF p_password IS NULL OR p_password = '' THEN
        v_error_hint := 'campo_requerido';
        RAISE EXCEPTION 'La contrasena es requerida';
    END IF;

    -- ============================================
    -- PASO 1: Verificar bloqueo por intentos fallidos (RN-007)
    -- ============================================
    SELECT id, intentos_fallidos, bloqueado_hasta
    INTO v_intentos
    FROM intentos_login
    WHERE LOWER(email) = v_email_normalizado;

    IF FOUND AND v_intentos.bloqueado_hasta IS NOT NULL THEN
        -- Verificar si el bloqueo sigue vigente
        IF v_intentos.bloqueado_hasta > NOW() THEN
            -- Calcular minutos restantes
            v_minutos_restantes := CEIL(EXTRACT(EPOCH FROM (v_intentos.bloqueado_hasta - NOW())) / 60);

            RETURN json_build_object(
                'success', false,
                'error', json_build_object(
                    'code', 'ACCOUNT_LOCKED',
                    'message', 'Demasiados intentos fallidos. Intenta nuevamente en ' || v_minutos_restantes || ' minutos.',
                    'hint', 'cuenta_bloqueada',
                    'minutos_restantes', v_minutos_restantes
                )
            );
        ELSE
            -- El bloqueo expiro, reiniciar contador
            UPDATE intentos_login
            SET
                intentos_fallidos = 0,
                bloqueado_hasta = NULL,
                ultimo_intento_at = NOW()
            WHERE id = v_intentos.id;

            -- Recargar registro
            SELECT id, intentos_fallidos, bloqueado_hasta
            INTO v_intentos
            FROM intentos_login
            WHERE LOWER(email) = v_email_normalizado;
        END IF;
    END IF;

    -- ============================================
    -- PASO 2: Verificar credenciales en auth.users (RN-003)
    -- ============================================
    SELECT id, email, encrypted_password
    INTO v_auth_user
    FROM auth.users
    WHERE email = v_email_normalizado;

    -- Usuario no existe o contrasena incorrecta
    IF NOT FOUND OR v_auth_user.encrypted_password != crypt(p_password, v_auth_user.encrypted_password) THEN
        -- Registrar intento fallido (RN-007)
        IF v_intentos.id IS NULL THEN
            -- Primer intento fallido, crear registro
            INSERT INTO intentos_login (email, intentos_fallidos, ultimo_intento_at)
            VALUES (v_email_normalizado, 1, NOW());
        ELSE
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
            WHERE id = v_intentos.id;
        END IF;

        -- Verificar si con este intento se activa el bloqueo
        SELECT intentos_fallidos INTO v_intentos.intentos_fallidos
        FROM intentos_login
        WHERE LOWER(email) = v_email_normalizado;

        IF v_intentos.intentos_fallidos >= v_max_intentos THEN
            v_error_hint := 'cuenta_bloqueada';
            RETURN json_build_object(
                'success', false,
                'error', json_build_object(
                    'code', 'ACCOUNT_LOCKED',
                    'message', 'Demasiados intentos fallidos. Tu cuenta ha sido bloqueada por 15 minutos.',
                    'hint', v_error_hint,
                    'minutos_restantes', 15
                )
            );
        END IF;

        -- Mensaje generico por seguridad (RN-004)
        v_error_hint := 'credenciales_invalidas';
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'INVALID_CREDENTIALS',
                'message', 'Email o contrasena incorrectos',
                'hint', v_error_hint,
                'intentos_restantes', v_max_intentos - COALESCE(v_intentos.intentos_fallidos, 0)
            )
        );
    END IF;

    -- ============================================
    -- PASO 3: Verificar estado de cuenta en tabla usuarios (RN-002)
    -- ============================================
    SELECT id, auth_user_id, nombre_completo, email, estado, rol
    INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_auth_user.id;

    IF NOT FOUND THEN
        -- Usuario existe en auth pero no en tabla usuarios (caso raro)
        v_error_hint := 'credenciales_invalidas';
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'INVALID_CREDENTIALS',
                'message', 'Email o contrasena incorrectos',
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

    -- ============================================
    -- PASO 4: Login exitoso - Limpiar intentos fallidos (RN-007)
    -- ============================================
    IF v_intentos.id IS NOT NULL THEN
        DELETE FROM intentos_login WHERE id = v_intentos.id;
    END IF;

    -- ============================================
    -- PASO 5: Retornar datos del usuario con rol (RN-005, CA-002)
    -- ============================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario.id,
            'auth_user_id', v_usuario.auth_user_id,
            'nombre_completo', v_usuario.nombre_completo,
            'email', v_usuario.email,
            'rol', v_usuario.rol,
            'estado', v_usuario.estado
        ),
        'message', 'Inicio de sesion exitoso'
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
-- Funcion: verificar_bloqueo_login
-- Descripcion: Verifica si un email esta bloqueado por intentos fallidos
-- Uso: Para mostrar mensaje antes de intentar login
-- ============================================
CREATE OR REPLACE FUNCTION verificar_bloqueo_login(
    p_email TEXT
) RETURNS JSON AS $$
DECLARE
    v_email_normalizado TEXT;
    v_intentos RECORD;
    v_minutos_restantes INT;
BEGIN
    v_email_normalizado := LOWER(TRIM(p_email));

    SELECT intentos_fallidos, bloqueado_hasta
    INTO v_intentos
    FROM intentos_login
    WHERE LOWER(email) = v_email_normalizado;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'bloqueado', false,
                'intentos_fallidos', 0,
                'intentos_restantes', 5
            ),
            'message', 'No hay bloqueo activo'
        );
    END IF;

    IF v_intentos.bloqueado_hasta IS NOT NULL AND v_intentos.bloqueado_hasta > NOW() THEN
        v_minutos_restantes := CEIL(EXTRACT(EPOCH FROM (v_intentos.bloqueado_hasta - NOW())) / 60);

        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'bloqueado', true,
                'minutos_restantes', v_minutos_restantes,
                'bloqueado_hasta', v_intentos.bloqueado_hasta AT TIME ZONE 'America/Lima'
            ),
            'message', 'Cuenta bloqueada por ' || v_minutos_restantes || ' minutos'
        );
    END IF;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'bloqueado', false,
            'intentos_fallidos', v_intentos.intentos_fallidos,
            'intentos_restantes', 5 - v_intentos.intentos_fallidos
        ),
        'message', 'No hay bloqueo activo'
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
-- Funcion: limpiar_intentos_expirados
-- Descripcion: Limpia registros de intentos con bloqueo expirado (mantenimiento)
-- Uso: Ejecutar periodicamente o manualmente
-- ============================================
CREATE OR REPLACE FUNCTION limpiar_intentos_expirados()
RETURNS JSON AS $$
DECLARE
    v_eliminados INT;
BEGIN
    DELETE FROM intentos_login
    WHERE bloqueado_hasta IS NOT NULL
    AND bloqueado_hasta < NOW() - INTERVAL '1 hour';

    GET DIAGNOSTICS v_eliminados = ROW_COUNT;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'registros_eliminados', v_eliminados
        ),
        'message', 'Limpieza completada'
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
-- iniciar_sesion: Disponible para usuarios no autenticados (anon)
GRANT EXECUTE ON FUNCTION iniciar_sesion TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION verificar_bloqueo_login TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION limpiar_intentos_expirados TO service_role;

-- ============================================
-- PARTE 4: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tabla intentos_login
ALTER TABLE intentos_login ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "No acceso directo a intentos_login" ON intentos_login;
DROP POLICY IF EXISTS "Service role acceso completo" ON intentos_login;

-- No permitir acceso directo a la tabla desde clientes
-- Solo las funciones SECURITY DEFINER pueden acceder
CREATE POLICY "No acceso directo a intentos_login"
ON intentos_login FOR ALL
TO anon, authenticated
USING (false);

-- Service role tiene acceso completo (para mantenimiento)
CREATE POLICY "Service role acceso completo"
ON intentos_login FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- PARTE 5: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE intentos_login IS 'HU-002: Registro de intentos fallidos de login para proteccion contra fuerza bruta (RN-007)';
COMMENT ON FUNCTION iniciar_sesion IS 'HU-002: Autentica usuario verificando credenciales, estado y bloqueo (CA-002, CA-003, RN-002 a RN-007)';
COMMENT ON FUNCTION verificar_bloqueo_login IS 'HU-002: Verifica si un email esta bloqueado por intentos fallidos';
COMMENT ON FUNCTION limpiar_intentos_expirados IS 'HU-002: Limpia registros de bloqueo expirados (mantenimiento)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
