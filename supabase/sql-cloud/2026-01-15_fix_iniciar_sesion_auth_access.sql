-- ============================================
-- FIX: iniciar_sesion - Error "Database error querying schema"
-- Fecha: 2026-01-15
-- Problema: Error 500 al llamar RPC iniciar_sesion
-- ============================================

-- DIAGNOSTICO DEL PROBLEMA:
-- ========================
-- El error "Database error querying schema" ocurre porque:
--
-- 1. La funcion intenta acceder a `auth.users` para leer `encrypted_password`
-- 2. Aunque SECURITY DEFINER permite acceso, la tabla auth.users tiene
--    restricciones especiales en Supabase Cloud
-- 3. La funcion `crypt()` requiere la extension pgcrypto
-- 4. El schema `auth` es interno de Supabase y NO debe accederse directamente
--
-- SOLUCION:
-- =========
-- NO usar auth.users directamente para validar contrasenas.
-- En su lugar, usar el flujo nativo de Supabase Auth:
--   - La APP llama a supabase.auth.signInWithPassword()
--   - Supabase Auth valida las credenciales internamente
--   - Luego la APP llama a nuestra funcion RPC para verificar estado y obtener datos
--
-- Nueva arquitectura:
--   1. APP -> supabase.auth.signInWithPassword() -> Supabase Auth valida credenciales
--   2. Si OK -> APP -> RPC verificar_sesion_usuario() -> Verifica estado y retorna datos

-- ============================================
-- PASO 1: Eliminar la funcion problematica
-- ============================================
DROP FUNCTION IF EXISTS iniciar_sesion(TEXT, TEXT);

-- ============================================
-- PASO 2: Nueva funcion - verificar_sesion_usuario
-- Descripcion: Verifica el estado del usuario DESPUES de que Supabase Auth
--              haya validado las credenciales exitosamente
-- Uso: Llamar desde la APP despues de signInWithPassword() exitoso
-- ============================================
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
            'estado', v_usuario.estado
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
-- PASO 3: Funcion para registrar intento fallido (llamada desde APP)
-- Descripcion: La APP llama esto cuando signInWithPassword falla
-- ============================================
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
-- PASO 4: Permisos
-- ============================================

-- verificar_sesion_usuario: Solo usuarios autenticados
GRANT EXECUTE ON FUNCTION verificar_sesion_usuario TO authenticated, service_role;

-- registrar_intento_fallido: Disponible para anon (antes de autenticarse)
GRANT EXECUTE ON FUNCTION registrar_intento_fallido TO anon, authenticated, service_role;

-- verificar_bloqueo_login: Ya existe, mantener permisos
GRANT EXECUTE ON FUNCTION verificar_bloqueo_login TO anon, authenticated, service_role;

-- ============================================
-- PASO 5: Comentarios
-- ============================================

COMMENT ON FUNCTION verificar_sesion_usuario IS 'HU-002: Verifica estado del usuario despues de autenticacion exitosa con Supabase Auth';
COMMENT ON FUNCTION registrar_intento_fallido IS 'HU-002: Registra intento fallido de login para control de bloqueo (RN-007)';

-- ============================================
-- FIN DEL FIX
-- ============================================

-- ============================================
-- INSTRUCCIONES PARA LA APP (Flutter/Dart):
-- ============================================
--
-- FLUJO DE LOGIN ACTUALIZADO:
--
-- 1. Verificar bloqueo ANTES de intentar login:
--    final bloqueoResponse = await supabase.rpc('verificar_bloqueo_login', params: {'p_email': email});
--    if (bloqueoResponse['data']['bloqueado'] == true) {
--      // Mostrar mensaje de cuenta bloqueada
--      return;
--    }
--
-- 2. Intentar login con Supabase Auth:
--    try {
--      final authResponse = await supabase.auth.signInWithPassword(
--        email: email,
--        password: password,
--      );
--    } catch (e) {
--      // Credenciales incorrectas - registrar intento fallido
--      await supabase.rpc('registrar_intento_fallido', params: {'p_email': email});
--      return;
--    }
--
-- 3. Si auth exitoso, verificar estado del usuario:
--    final sessionResponse = await supabase.rpc('verificar_sesion_usuario');
--    if (sessionResponse['success'] != true) {
--      // Usuario pendiente/rechazado - cerrar sesion
--      await supabase.auth.signOut();
--      // Mostrar mensaje segun sessionResponse['error']['code']
--      return;
--    }
--
-- 4. Login completo - usar datos de sessionResponse['data']
--
