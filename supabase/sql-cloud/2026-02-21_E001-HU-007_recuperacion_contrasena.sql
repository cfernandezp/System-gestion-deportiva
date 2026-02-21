-- ============================================
-- E001-HU-007: Recuperacion de Contrasena
-- Fecha: 2026-02-21
-- Descripcion: Tablas y RPCs para recuperacion de contrasena.
--   - Jugadores: codigo temporal generado por admin/coadmin
--   - Admins: pregunta de seguridad + fallback por email de respaldo
-- Dependencias: tablas usuarios, miembros_grupo, extension pgcrypto
-- CAs cubiertos: CA-001 a CA-011
-- RNs cubiertos: RN-001 a RN-006
-- ============================================

-- Asegurar pgcrypto disponible
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- PASO 1: Tabla codigos_recuperacion
-- Almacena codigos de 6 digitos hasheados
-- ============================================
CREATE TABLE IF NOT EXISTS codigos_recuperacion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    codigo_hash TEXT NOT NULL,
    generado_por UUID REFERENCES usuarios(id),       -- NULL si auto-generado (email fallback admin)
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('admin_para_jugador', 'email_admin')),
    expira_at TIMESTAMPTZ NOT NULL,
    usado BOOLEAN NOT NULL DEFAULT FALSE,
    usado_at TIMESTAMPTZ,
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_codigos_recup_usuario
    ON codigos_recuperacion(usuario_id);
CREATE INDEX IF NOT EXISTS idx_codigos_recup_vigentes
    ON codigos_recuperacion(usuario_id, usado, expira_at)
    WHERE usado = FALSE;

-- RLS deshabilitado: acceso solo via RPC SECURITY DEFINER
ALTER TABLE codigos_recuperacion ENABLE ROW LEVEL SECURITY;
-- Sin policies = nadie accede directamente, solo las funciones SECURITY DEFINER

-- ============================================
-- PASO 2: Tabla intentos_recuperacion (rate limiting)
-- RN-005: Maximo 5 intentos con bloqueo 15 min
-- ============================================
CREATE TABLE IF NOT EXISTS intentos_recuperacion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    celular VARCHAR(9) NOT NULL,
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,
    bloqueado_hasta TIMESTAMPTZ,
    ultimo_intento_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice unico por celular
CREATE UNIQUE INDEX IF NOT EXISTS idx_intentos_recup_celular
    ON intentos_recuperacion(celular);

-- RLS deshabilitado: acceso solo via RPC SECURITY DEFINER
ALTER TABLE intentos_recuperacion ENABLE ROW LEVEL SECURITY;

-- ============================================
-- FUNCION AUXILIAR: _validar_celular_peru
-- Reutilizada por multiples RPCs de esta HU
-- ============================================
CREATE OR REPLACE FUNCTION _validar_celular_peru(p_celular TEXT)
RETURNS VARCHAR(9) AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
BEGIN
    v_celular_limpio := REGEXP_REPLACE(COALESCE(p_celular, ''), '[^0-9]', '', 'g');

    IF LENGTH(v_celular_limpio) != 9 THEN
        RAISE EXCEPTION 'El celular debe tener exactamente 9 digitos'
            USING HINT = 'celular_formato_invalido';
    END IF;

    IF LEFT(v_celular_limpio, 1) != '9' THEN
        RAISE EXCEPTION 'El celular debe iniciar con el digito 9'
            USING HINT = 'celular_formato_invalido';
    END IF;

    RETURN v_celular_limpio;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- FUNCION AUXILIAR: _verificar_rate_limit_recuperacion
-- RN-005: Revisa y gestiona bloqueo por intentos
-- Retorna TRUE si esta bloqueado, FALSE si puede continuar
-- ============================================
CREATE OR REPLACE FUNCTION _verificar_rate_limit_recuperacion(
    p_celular VARCHAR(9)
) RETURNS BOOLEAN AS $$
DECLARE
    v_intentos INTEGER;
    v_bloqueado_hasta TIMESTAMPTZ;
BEGIN
    SELECT intentos_fallidos, bloqueado_hasta
    INTO v_intentos, v_bloqueado_hasta
    FROM intentos_recuperacion
    WHERE celular = p_celular;

    -- Si no hay registro, no esta bloqueado
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Si hay bloqueo activo
    IF v_bloqueado_hasta IS NOT NULL AND v_bloqueado_hasta > NOW() THEN
        RETURN TRUE;
    END IF;

    -- Si el bloqueo ya expiro, resetear contador
    IF v_bloqueado_hasta IS NOT NULL AND v_bloqueado_hasta <= NOW() THEN
        UPDATE intentos_recuperacion
        SET intentos_fallidos = 0,
            bloqueado_hasta = NULL,
            updated_at = NOW()
        WHERE celular = p_celular;
    END IF;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCION AUXILIAR: _registrar_intento_fallido_recuperacion
-- RN-005: Incrementa contador y bloquea si llega a 5
-- ============================================
CREATE OR REPLACE FUNCTION _registrar_intento_fallido_recuperacion(
    p_celular VARCHAR(9)
) RETURNS VOID AS $$
DECLARE
    v_intentos INTEGER;
BEGIN
    INSERT INTO intentos_recuperacion (celular, intentos_fallidos, ultimo_intento_at, updated_at)
    VALUES (p_celular, 1, NOW(), NOW())
    ON CONFLICT (celular)
    DO UPDATE SET
        intentos_fallidos = intentos_recuperacion.intentos_fallidos + 1,
        ultimo_intento_at = NOW(),
        updated_at = NOW();

    -- Leer el contador actualizado
    SELECT intentos_fallidos INTO v_intentos
    FROM intentos_recuperacion
    WHERE celular = p_celular;

    -- RN-005: Bloquear 15 minutos al llegar a 5
    IF v_intentos >= 5 THEN
        UPDATE intentos_recuperacion
        SET bloqueado_hasta = NOW() + INTERVAL '15 minutes',
            updated_at = NOW()
        WHERE celular = p_celular;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCION AUXILIAR: _resetear_intentos_recuperacion
-- Limpia el contador tras exito
-- ============================================
CREATE OR REPLACE FUNCTION _resetear_intentos_recuperacion(
    p_celular VARCHAR(9)
) RETURNS VOID AS $$
BEGIN
    UPDATE intentos_recuperacion
    SET intentos_fallidos = 0,
        bloqueado_hasta = NULL,
        updated_at = NOW()
    WHERE celular = p_celular;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCION AUXILIAR: _validar_password_requisitos
-- Valida que la contrasena cumpla requisitos minimos
-- CA-009: min 6 caracteres
-- ============================================
CREATE OR REPLACE FUNCTION _validar_password_requisitos(
    p_password TEXT
) RETURNS VOID AS $$
BEGIN
    IF p_password IS NULL OR LENGTH(TRIM(p_password)) < 6 THEN
        RAISE EXCEPTION 'La contrasena debe tener al menos 6 caracteres'
            USING HINT = 'password_muy_corta';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- RPC 1: identificar_tipo_recuperacion
-- Determina el flujo de recuperacion segun el rol del usuario
-- Retorna tipo: 'admin', 'jugador' o 'no_encontrado'
-- SECURITY DEFINER - anon
-- ============================================
CREATE OR REPLACE FUNCTION identificar_tipo_recuperacion(
    p_celular TEXT
) RETURNS JSON AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
    v_usuario_id UUID;
    v_rol rol_usuario;
    v_pregunta TEXT;
    v_email_respaldo VARCHAR;
    v_email_mascara TEXT;
    v_error_hint TEXT;
BEGIN
    -- Validar formato celular
    BEGIN
        v_celular_limpio := _validar_celular_peru(p_celular);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'CELULAR_INVALIDO',
                'hint', 'celular_formato_invalido'
            )
        );
    END;

    -- Buscar usuario aprobado con cuenta auth
    SELECT id, rol, pregunta_seguridad, email_respaldo
    INTO v_usuario_id, v_rol, v_pregunta, v_email_respaldo
    FROM usuarios
    WHERE celular = v_celular_limpio
      AND estado = 'aprobado'
      AND auth_user_id IS NOT NULL;

    -- Si no encontrado, retornar mensaje generico (seguridad: no revelar si existe)
    IF v_usuario_id IS NULL THEN
        RETURN json_build_object(
            'success', TRUE,
            'data', json_build_object(
                'tipo', 'no_encontrado',
                'mensaje', 'Si tu numero esta registrado, recibiras instrucciones de recuperacion.'
            )
        );
    END IF;

    -- Admin: retornar pregunta de seguridad y datos de email
    IF v_rol = 'admin' THEN
        -- Generar mascara del email: j***@gmail.com
        IF v_email_respaldo IS NOT NULL AND LENGTH(v_email_respaldo) > 0 THEN
            v_email_mascara := LEFT(v_email_respaldo, 1)
                || '***@'
                || SPLIT_PART(v_email_respaldo, '@', 2);
        ELSE
            v_email_mascara := NULL;
        END IF;

        RETURN json_build_object(
            'success', TRUE,
            'data', json_build_object(
                'tipo', 'admin',
                'pregunta_seguridad', v_pregunta,
                'tiene_email_respaldo', (v_email_respaldo IS NOT NULL AND LENGTH(v_email_respaldo) > 0),
                'email_respaldo_mascara', v_email_mascara
            )
        );
    END IF;

    -- Jugador
    RETURN json_build_object(
        'success', TRUE,
        'data', json_build_object(
            'tipo', 'jugador',
            'mensaje', 'Contacta al administrador de tu grupo para que genere un codigo de recuperacion.'
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

-- Accesible sin autenticacion (pantalla pre-login)
GRANT EXECUTE ON FUNCTION identificar_tipo_recuperacion TO anon;
GRANT EXECUTE ON FUNCTION identificar_tipo_recuperacion TO authenticated;
REVOKE EXECUTE ON FUNCTION identificar_tipo_recuperacion FROM public;

COMMENT ON FUNCTION identificar_tipo_recuperacion IS 'E001-HU-007: Identifica el tipo de recuperacion segun rol del usuario (admin/jugador/no_encontrado)';

-- ============================================
-- RPC 2: generar_codigo_recuperacion
-- CA-001, RN-001, RN-004
-- Admin/Coadmin genera codigo para un jugador de su grupo
-- SECURITY DEFINER - authenticated
-- ============================================
CREATE OR REPLACE FUNCTION generar_codigo_recuperacion(
    p_celular_jugador TEXT
) RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_caller_id UUID;
    v_celular_limpio VARCHAR(9);
    v_jugador_id UUID;
    v_jugador_auth_id UUID;
    v_es_admin_o_coadmin BOOLEAN;
    v_codigo TEXT;
    v_codigo_hash TEXT;
    v_error_hint TEXT;
BEGIN
    -- =============================================
    -- Verificar autenticacion del caller
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para generar codigos de recuperacion';
    END IF;

    -- Obtener usuario_id del caller
    SELECT id INTO v_caller_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_caller_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- =============================================
    -- Validar formato celular del jugador
    -- =============================================
    BEGIN
        v_celular_limpio := _validar_celular_peru(p_celular_jugador);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'CELULAR_INVALIDO',
                'hint', 'celular_formato_invalido'
            )
        );
    END;

    -- =============================================
    -- Buscar jugador aprobado con cuenta auth
    -- =============================================
    SELECT id, auth_user_id INTO v_jugador_id, v_jugador_auth_id
    FROM usuarios
    WHERE celular = v_celular_limpio
      AND estado = 'aprobado'
      AND auth_user_id IS NOT NULL;

    IF v_jugador_id IS NULL THEN
        v_error_hint := 'jugador_no_encontrado';
        RAISE EXCEPTION 'No se encontro un jugador activo con ese numero de celular';
    END IF;

    -- No puede generar codigo para si mismo
    IF v_jugador_id = v_caller_id THEN
        v_error_hint := 'codigo_para_si_mismo';
        RAISE EXCEPTION 'No puedes generar un codigo de recuperacion para tu propia cuenta';
    END IF;

    -- =============================================
    -- RN-001: Verificar que el caller es admin o coadmin
    -- de al menos un grupo donde el jugador es miembro
    -- =============================================
    SELECT EXISTS (
        SELECT 1
        FROM miembros_grupo mg_caller
        JOIN miembros_grupo mg_jugador
            ON mg_caller.grupo_id = mg_jugador.grupo_id
        WHERE mg_caller.usuario_id = v_caller_id
          AND mg_caller.rol IN ('admin', 'coadmin')
          AND mg_caller.activo = TRUE
          AND mg_jugador.usuario_id = v_jugador_id
          AND mg_jugador.activo = TRUE
    ) INTO v_es_admin_o_coadmin;

    IF NOT v_es_admin_o_coadmin THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo puedes generar codigos para jugadores de tus grupos donde eres admin o co-admin';
    END IF;

    -- =============================================
    -- RN-004: Invalidar codigos anteriores del jugador
    -- =============================================
    UPDATE codigos_recuperacion
    SET usado = TRUE,
        usado_at = NOW()
    WHERE usuario_id = v_jugador_id
      AND usado = FALSE;

    -- =============================================
    -- Generar codigo de 6 digitos aleatorio
    -- =============================================
    v_codigo := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

    -- Hash del codigo con bcrypt
    v_codigo_hash := crypt(v_codigo, gen_salt('bf'));

    -- Guardar codigo con expiracion de 30 minutos
    INSERT INTO codigos_recuperacion (
        usuario_id,
        codigo_hash,
        generado_por,
        tipo,
        expira_at,
        usado,
        intentos_fallidos,
        created_at
    ) VALUES (
        v_jugador_id,
        v_codigo_hash,
        v_caller_id,
        'admin_para_jugador',
        NOW() + INTERVAL '30 minutes',
        FALSE,
        0,
        NOW()
    );

    -- =============================================
    -- CA-001: Retornar codigo en texto plano para que el admin
    -- lo comunique al jugador (WhatsApp, verbal, etc.)
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Codigo de recuperacion generado exitosamente. Valido por 30 minutos.',
        'data', json_build_object(
            'codigo', v_codigo,
            'celular_jugador', v_celular_limpio,
            'expira_en_minutos', 30,
            'mensaje_para_jugador', 'Tu codigo de recuperacion es: ' || v_codigo || '. Ingresalo en la app junto con tu celular para crear una nueva contrasena. Valido por 30 minutos.'
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

-- Solo usuarios autenticados (admin/coadmin)
GRANT EXECUTE ON FUNCTION generar_codigo_recuperacion TO authenticated;
REVOKE EXECUTE ON FUNCTION generar_codigo_recuperacion FROM anon;
REVOKE EXECUTE ON FUNCTION generar_codigo_recuperacion FROM public;

COMMENT ON FUNCTION generar_codigo_recuperacion IS 'E001-HU-007 CA-001: Admin/coadmin genera codigo de 6 digitos para que un jugador recupere su contrasena';

-- ============================================
-- RPC 3: obtener_pregunta_seguridad
-- Retorna la pregunta de seguridad de un admin
-- SECURITY DEFINER - anon
-- ============================================
CREATE OR REPLACE FUNCTION obtener_pregunta_seguridad(
    p_celular TEXT
) RETURNS JSON AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
    v_pregunta TEXT;
    v_error_hint TEXT;
BEGIN
    -- Validar formato celular
    BEGIN
        v_celular_limpio := _validar_celular_peru(p_celular);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'CELULAR_INVALIDO',
                'hint', 'celular_formato_invalido'
            )
        );
    END;

    -- Buscar admin con ese celular
    SELECT pregunta_seguridad INTO v_pregunta
    FROM usuarios
    WHERE celular = v_celular_limpio
      AND rol = 'admin'
      AND estado = 'aprobado'
      AND auth_user_id IS NOT NULL
      AND pregunta_seguridad IS NOT NULL;

    IF v_pregunta IS NULL THEN
        v_error_hint := 'sin_pregunta_seguridad';
        RAISE EXCEPTION 'No se encontro una pregunta de seguridad para este numero';
    END IF;

    RETURN json_build_object(
        'success', TRUE,
        'data', json_build_object(
            'pregunta_seguridad', v_pregunta
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

GRANT EXECUTE ON FUNCTION obtener_pregunta_seguridad TO anon;
GRANT EXECUTE ON FUNCTION obtener_pregunta_seguridad TO authenticated;
REVOKE EXECUTE ON FUNCTION obtener_pregunta_seguridad FROM public;

COMMENT ON FUNCTION obtener_pregunta_seguridad IS 'E001-HU-007: Retorna la pregunta de seguridad de un administrador';

-- ============================================
-- RPC 4: validar_codigo_recuperacion
-- CA-002, CA-003, CA-004, CA-011
-- RN-005: Rate limiting 5 intentos / 15 min bloqueo
-- Solo VALIDA, no cambia contrasena
-- SECURITY DEFINER - anon
-- ============================================
CREATE OR REPLACE FUNCTION validar_codigo_recuperacion(
    p_celular TEXT,
    p_codigo TEXT
) RETURNS JSON AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
    v_usuario_id UUID;
    v_codigo_id UUID;
    v_codigo_hash TEXT;
    v_expira_at TIMESTAMPTZ;
    v_bloqueado BOOLEAN;
    v_intentos_restantes INTEGER;
    v_error_hint TEXT;
BEGIN
    -- Validar formato celular
    BEGIN
        v_celular_limpio := _validar_celular_peru(p_celular);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'CELULAR_INVALIDO',
                'hint', 'celular_formato_invalido'
            )
        );
    END;

    -- Validar que se proporciono un codigo
    IF p_codigo IS NULL OR TRIM(p_codigo) = '' THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'Debes ingresar el codigo de recuperacion',
                'code', 'CODIGO_REQUERIDO',
                'hint', 'codigo_requerido'
            )
        );
    END IF;

    -- =============================================
    -- CA-011 / RN-005: Verificar rate limiting
    -- =============================================
    v_bloqueado := _verificar_rate_limit_recuperacion(v_celular_limpio);
    IF v_bloqueado THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'Demasiados intentos fallidos. Intenta nuevamente en 15 minutos.',
                'code', 'RATE_LIMIT',
                'hint', 'cuenta_bloqueada_temporalmente'
            )
        );
    END IF;

    -- =============================================
    -- Buscar usuario por celular
    -- =============================================
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE celular = v_celular_limpio
      AND estado = 'aprobado'
      AND auth_user_id IS NOT NULL;

    IF v_usuario_id IS NULL THEN
        -- Registrar intento fallido igualmente (anti-enumeracion)
        PERFORM _registrar_intento_fallido_recuperacion(v_celular_limpio);
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Codigo invalido o expirado. Solicita un nuevo codigo a tu administrador.';
    END IF;

    -- =============================================
    -- CA-003, CA-004: Buscar codigo vigente, no usado, no expirado
    -- =============================================
    SELECT id, codigo_hash, expira_at
    INTO v_codigo_id, v_codigo_hash, v_expira_at
    FROM codigos_recuperacion
    WHERE usuario_id = v_usuario_id
      AND usado = FALSE
      AND expira_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_codigo_id IS NULL THEN
        PERFORM _registrar_intento_fallido_recuperacion(v_celular_limpio);
        v_error_hint := 'codigo_invalido_o_expirado';
        RAISE EXCEPTION 'Codigo invalido o expirado. Solicita un nuevo codigo a tu administrador.';
    END IF;

    -- =============================================
    -- Validar codigo contra hash
    -- =============================================
    IF crypt(TRIM(p_codigo), v_codigo_hash) != v_codigo_hash THEN
        -- Incrementar intentos fallidos del codigo
        UPDATE codigos_recuperacion
        SET intentos_fallidos = intentos_fallidos + 1
        WHERE id = v_codigo_id;

        -- Registrar en rate limiting global
        PERFORM _registrar_intento_fallido_recuperacion(v_celular_limpio);

        -- Calcular intentos restantes
        SELECT (5 - intentos_fallidos)
        INTO v_intentos_restantes
        FROM intentos_recuperacion
        WHERE celular = v_celular_limpio;

        v_error_hint := 'codigo_incorrecto';
        RAISE EXCEPTION 'Codigo incorrecto. Te quedan % intentos antes del bloqueo temporal.',
            GREATEST(v_intentos_restantes, 0);
    END IF;

    -- =============================================
    -- Codigo valido: NO marcar como usado todavia
    -- Solo validamos, la accion se completa en restablecer_contrasena_con_codigo
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Codigo validado correctamente. Ahora puedes crear tu nueva contrasena.',
        'data', json_build_object(
            'codigo_valido', TRUE,
            'celular', v_celular_limpio
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

GRANT EXECUTE ON FUNCTION validar_codigo_recuperacion TO anon;
GRANT EXECUTE ON FUNCTION validar_codigo_recuperacion TO authenticated;
REVOKE EXECUTE ON FUNCTION validar_codigo_recuperacion FROM public;

COMMENT ON FUNCTION validar_codigo_recuperacion IS 'E001-HU-007 CA-002/CA-003/CA-004/CA-011: Valida codigo de recuperacion sin cambiar contrasena';

-- ============================================
-- RPC 5: restablecer_contrasena_con_codigo
-- CA-002, CA-009, CA-010, RN-004, RN-006
-- Valida codigo + cambia contrasena + invalida sesiones
-- SECURITY DEFINER - anon
-- ============================================
CREATE OR REPLACE FUNCTION restablecer_contrasena_con_codigo(
    p_celular TEXT,
    p_codigo TEXT,
    p_nueva_contrasena TEXT,
    p_confirmar_contrasena TEXT
) RETURNS JSON AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
    v_usuario_id UUID;
    v_auth_user_id UUID;
    v_codigo_id UUID;
    v_codigo_hash TEXT;
    v_bloqueado BOOLEAN;
    v_error_hint TEXT;
BEGIN
    -- Validar formato celular
    BEGIN
        v_celular_limpio := _validar_celular_peru(p_celular);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'CELULAR_INVALIDO',
                'hint', 'celular_formato_invalido'
            )
        );
    END;

    -- =============================================
    -- Validar que las contrasenas coincidan
    -- =============================================
    IF p_nueva_contrasena IS NULL OR p_confirmar_contrasena IS NULL THEN
        v_error_hint := 'contrasena_requerida';
        RAISE EXCEPTION 'Debes ingresar la nueva contrasena y su confirmacion';
    END IF;

    IF p_nueva_contrasena != p_confirmar_contrasena THEN
        v_error_hint := 'contrasenas_no_coinciden';
        RAISE EXCEPTION 'Las contrasenas no coinciden';
    END IF;

    -- CA-009: Validar requisitos de contrasena
    BEGIN
        PERFORM _validar_password_requisitos(p_nueva_contrasena);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'PASSWORD_INVALIDA',
                'hint', 'password_muy_corta'
            )
        );
    END;

    -- =============================================
    -- RN-005: Verificar rate limiting
    -- =============================================
    v_bloqueado := _verificar_rate_limit_recuperacion(v_celular_limpio);
    IF v_bloqueado THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'Demasiados intentos fallidos. Intenta nuevamente en 15 minutos.',
                'code', 'RATE_LIMIT',
                'hint', 'cuenta_bloqueada_temporalmente'
            )
        );
    END IF;

    -- =============================================
    -- Buscar usuario
    -- =============================================
    SELECT id, auth_user_id INTO v_usuario_id, v_auth_user_id
    FROM usuarios
    WHERE celular = v_celular_limpio
      AND estado = 'aprobado'
      AND auth_user_id IS NOT NULL;

    IF v_usuario_id IS NULL OR v_auth_user_id IS NULL THEN
        PERFORM _registrar_intento_fallido_recuperacion(v_celular_limpio);
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Codigo invalido o expirado. Solicita un nuevo codigo a tu administrador.';
    END IF;

    -- =============================================
    -- Buscar y validar codigo vigente
    -- =============================================
    SELECT id, codigo_hash
    INTO v_codigo_id, v_codigo_hash
    FROM codigos_recuperacion
    WHERE usuario_id = v_usuario_id
      AND usado = FALSE
      AND expira_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_codigo_id IS NULL THEN
        PERFORM _registrar_intento_fallido_recuperacion(v_celular_limpio);
        v_error_hint := 'codigo_invalido_o_expirado';
        RAISE EXCEPTION 'Codigo invalido o expirado. Solicita un nuevo codigo a tu administrador.';
    END IF;

    -- Validar codigo contra hash
    IF crypt(TRIM(p_codigo), v_codigo_hash) != v_codigo_hash THEN
        UPDATE codigos_recuperacion
        SET intentos_fallidos = intentos_fallidos + 1
        WHERE id = v_codigo_id;

        PERFORM _registrar_intento_fallido_recuperacion(v_celular_limpio);
        v_error_hint := 'codigo_incorrecto';
        RAISE EXCEPTION 'Codigo incorrecto';
    END IF;

    -- =============================================
    -- RN-004: Marcar codigo como usado (uso unico)
    -- =============================================
    UPDATE codigos_recuperacion
    SET usado = TRUE,
        usado_at = NOW()
    WHERE id = v_codigo_id;

    -- =============================================
    -- CA-010 / RN-006: Actualizar contrasena en auth.users
    -- La contrasena anterior queda invalidada por este UPDATE
    -- =============================================
    UPDATE auth.users
    SET encrypted_password = crypt(p_nueva_contrasena, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_auth_user_id;

    -- =============================================
    -- RN-006 (caso especial): Invalidar sesiones activas
    -- Eliminar de auth.sessions para forzar re-login
    -- =============================================
    DELETE FROM auth.sessions
    WHERE user_id = v_auth_user_id;

    -- Registrar evento en sesiones_log
    INSERT INTO sesiones_log (usuario_id, auth_user_id, evento, fecha_evento, created_at)
    VALUES (v_usuario_id, v_auth_user_id, 'password_reset_codigo', NOW(), NOW());

    -- Resetear intentos fallidos
    PERFORM _resetear_intentos_recuperacion(v_celular_limpio);

    -- =============================================
    -- Retornar exito
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Contrasena restablecida exitosamente. Inicia sesion con tu nueva contrasena.',
        'data', json_build_object(
            'contrasena_actualizada', TRUE,
            'sesiones_cerradas', TRUE
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

GRANT EXECUTE ON FUNCTION restablecer_contrasena_con_codigo TO anon;
GRANT EXECUTE ON FUNCTION restablecer_contrasena_con_codigo TO authenticated;
REVOKE EXECUTE ON FUNCTION restablecer_contrasena_con_codigo FROM public;

COMMENT ON FUNCTION restablecer_contrasena_con_codigo IS 'E001-HU-007 CA-002/CA-009/CA-010/RN-004/RN-006: Restablece contrasena usando codigo de recuperacion';

-- ============================================
-- RPC 6: restablecer_contrasena_con_pregunta
-- CA-005, CA-006, CA-007, CA-009, CA-010, RN-002, RN-006
-- Admin responde pregunta de seguridad para cambiar contrasena
-- SECURITY DEFINER - anon
-- ============================================
CREATE OR REPLACE FUNCTION restablecer_contrasena_con_pregunta(
    p_celular TEXT,
    p_respuesta TEXT,
    p_nueva_contrasena TEXT,
    p_confirmar_contrasena TEXT
) RETURNS JSON AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
    v_usuario_id UUID;
    v_auth_user_id UUID;
    v_respuesta_almacenada TEXT;
    v_email_respaldo VARCHAR;
    v_email_mascara TEXT;
    v_bloqueado BOOLEAN;
    v_error_hint TEXT;
BEGIN
    -- Validar formato celular
    BEGIN
        v_celular_limpio := _validar_celular_peru(p_celular);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'CELULAR_INVALIDO',
                'hint', 'celular_formato_invalido'
            )
        );
    END;

    -- =============================================
    -- Validar que las contrasenas coincidan
    -- =============================================
    IF p_nueva_contrasena IS NULL OR p_confirmar_contrasena IS NULL THEN
        v_error_hint := 'contrasena_requerida';
        RAISE EXCEPTION 'Debes ingresar la nueva contrasena y su confirmacion';
    END IF;

    IF p_nueva_contrasena != p_confirmar_contrasena THEN
        v_error_hint := 'contrasenas_no_coinciden';
        RAISE EXCEPTION 'Las contrasenas no coinciden';
    END IF;

    -- CA-009: Validar requisitos de contrasena
    BEGIN
        PERFORM _validar_password_requisitos(p_nueva_contrasena);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'PASSWORD_INVALIDA',
                'hint', 'password_muy_corta'
            )
        );
    END;

    -- =============================================
    -- RN-005: Verificar rate limiting
    -- =============================================
    v_bloqueado := _verificar_rate_limit_recuperacion(v_celular_limpio);
    IF v_bloqueado THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'Demasiados intentos fallidos. Intenta nuevamente en 15 minutos.',
                'code', 'RATE_LIMIT',
                'hint', 'cuenta_bloqueada_temporalmente'
            )
        );
    END IF;

    -- Validar respuesta proporcionada
    IF p_respuesta IS NULL OR TRIM(p_respuesta) = '' THEN
        v_error_hint := 'respuesta_requerida';
        RAISE EXCEPTION 'Debes ingresar tu respuesta a la pregunta de seguridad';
    END IF;

    -- =============================================
    -- Buscar admin con ese celular
    -- =============================================
    SELECT id, auth_user_id, respuesta_seguridad, email_respaldo
    INTO v_usuario_id, v_auth_user_id, v_respuesta_almacenada, v_email_respaldo
    FROM usuarios
    WHERE celular = v_celular_limpio
      AND rol = 'admin'
      AND estado = 'aprobado'
      AND auth_user_id IS NOT NULL;

    IF v_usuario_id IS NULL OR v_auth_user_id IS NULL THEN
        PERFORM _registrar_intento_fallido_recuperacion(v_celular_limpio);
        v_error_hint := 'admin_no_encontrado';
        RAISE EXCEPTION 'No se encontro una cuenta de administrador con ese numero';
    END IF;

    -- =============================================
    -- CA-005 / RN-002: Comparar respuesta (case insensitive, trim)
    -- La respuesta se almaceno en LOWER(TRIM()) al registrarse
    -- =============================================
    IF LOWER(TRIM(p_respuesta)) != v_respuesta_almacenada THEN
        -- Registrar intento fallido
        PERFORM _registrar_intento_fallido_recuperacion(v_celular_limpio);

        -- CA-006 / CA-007: Informar sobre email de respaldo como alternativa
        IF v_email_respaldo IS NOT NULL AND LENGTH(v_email_respaldo) > 0 THEN
            v_email_mascara := LEFT(v_email_respaldo, 1)
                || '***@'
                || SPLIT_PART(v_email_respaldo, '@', 2);

            RETURN json_build_object(
                'success', FALSE,
                'error', json_build_object(
                    'message', 'Respuesta incorrecta',
                    'code', 'RESPUESTA_INCORRECTA',
                    'hint', 'respuesta_incorrecta_con_email',
                    'tiene_email_respaldo', TRUE,
                    'email_respaldo_mascara', v_email_mascara
                )
            );
        ELSE
            -- CA-007: Sin email de respaldo
            RETURN json_build_object(
                'success', FALSE,
                'error', json_build_object(
                    'message', 'Respuesta incorrecta. No tienes email de respaldo configurado. Contacta a soporte o crea una cuenta nueva.',
                    'code', 'RESPUESTA_INCORRECTA',
                    'hint', 'respuesta_incorrecta_sin_email',
                    'tiene_email_respaldo', FALSE
                )
            );
        END IF;
    END IF;

    -- =============================================
    -- Respuesta correcta: actualizar contrasena
    -- CA-010 / RN-006: Contrasena anterior invalidada
    -- =============================================
    UPDATE auth.users
    SET encrypted_password = crypt(p_nueva_contrasena, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_auth_user_id;

    -- RN-006 (caso especial): Invalidar sesiones activas
    DELETE FROM auth.sessions
    WHERE user_id = v_auth_user_id;

    -- Registrar evento
    INSERT INTO sesiones_log (usuario_id, auth_user_id, evento, fecha_evento, created_at)
    VALUES (v_usuario_id, v_auth_user_id, 'password_reset_pregunta', NOW(), NOW());

    -- Resetear intentos fallidos
    PERFORM _resetear_intentos_recuperacion(v_celular_limpio);

    -- =============================================
    -- Retornar exito
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Contrasena restablecida exitosamente. Inicia sesion con tu nueva contrasena.',
        'data', json_build_object(
            'contrasena_actualizada', TRUE,
            'sesiones_cerradas', TRUE
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

GRANT EXECUTE ON FUNCTION restablecer_contrasena_con_pregunta TO anon;
GRANT EXECUTE ON FUNCTION restablecer_contrasena_con_pregunta TO authenticated;
REVOKE EXECUTE ON FUNCTION restablecer_contrasena_con_pregunta FROM public;

COMMENT ON FUNCTION restablecer_contrasena_con_pregunta IS 'E001-HU-007 CA-005/CA-009/CA-010/RN-002/RN-006: Admin restablece contrasena respondiendo pregunta de seguridad';

-- ============================================
-- RPC 7: solicitar_recuperacion_email_admin
-- CA-006, RN-003
-- Genera codigo y lo prepara para envio por email de respaldo
-- En desarrollo retorna el codigo en texto plano para testing
-- SECURITY DEFINER - anon
-- ============================================
CREATE OR REPLACE FUNCTION solicitar_recuperacion_email_admin(
    p_celular TEXT
) RETURNS JSON AS $$
DECLARE
    v_celular_limpio VARCHAR(9);
    v_usuario_id UUID;
    v_email_respaldo VARCHAR;
    v_email_mascara TEXT;
    v_codigo TEXT;
    v_codigo_hash TEXT;
    v_bloqueado BOOLEAN;
    v_error_hint TEXT;
BEGIN
    -- Validar formato celular
    BEGIN
        v_celular_limpio := _validar_celular_peru(p_celular);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', 'CELULAR_INVALIDO',
                'hint', 'celular_formato_invalido'
            )
        );
    END;

    -- RN-005: Verificar rate limiting
    v_bloqueado := _verificar_rate_limit_recuperacion(v_celular_limpio);
    IF v_bloqueado THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'Demasiados intentos. Intenta nuevamente en 15 minutos.',
                'code', 'RATE_LIMIT',
                'hint', 'cuenta_bloqueada_temporalmente'
            )
        );
    END IF;

    -- =============================================
    -- Buscar admin con email de respaldo
    -- =============================================
    SELECT id, email_respaldo
    INTO v_usuario_id, v_email_respaldo
    FROM usuarios
    WHERE celular = v_celular_limpio
      AND rol = 'admin'
      AND estado = 'aprobado'
      AND auth_user_id IS NOT NULL;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'admin_no_encontrado';
        RAISE EXCEPTION 'No se encontro una cuenta de administrador con ese numero';
    END IF;

    -- RN-003: Verificar que tiene email de respaldo
    IF v_email_respaldo IS NULL OR LENGTH(v_email_respaldo) = 0 THEN
        v_error_hint := 'sin_email_respaldo';
        RAISE EXCEPTION 'No tienes un email de respaldo configurado. Contacta a soporte o crea una cuenta nueva.';
    END IF;

    -- =============================================
    -- Invalidar codigos anteriores del admin
    -- =============================================
    UPDATE codigos_recuperacion
    SET usado = TRUE,
        usado_at = NOW()
    WHERE usuario_id = v_usuario_id
      AND usado = FALSE;

    -- =============================================
    -- Generar codigo de 6 digitos
    -- =============================================
    v_codigo := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    v_codigo_hash := crypt(v_codigo, gen_salt('bf'));

    -- Guardar con expiracion de 30 minutos
    INSERT INTO codigos_recuperacion (
        usuario_id,
        codigo_hash,
        generado_por,
        tipo,
        expira_at,
        usado,
        intentos_fallidos,
        created_at
    ) VALUES (
        v_usuario_id,
        v_codigo_hash,
        NULL,              -- auto-generado (no lo genero otro usuario)
        'email_admin',
        NOW() + INTERVAL '30 minutes',
        FALSE,
        0,
        NOW()
    );

    -- Mascara del email
    v_email_mascara := LEFT(v_email_respaldo, 1)
        || '***@'
        || SPLIT_PART(v_email_respaldo, '@', 2);

    -- =============================================
    -- Retornar resultado
    -- NOTA: En produccion, el envio del email se haria via Edge Function
    -- En desarrollo, retornamos el codigo para testing
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Se ha enviado un codigo de recuperacion a tu email de respaldo.',
        'data', json_build_object(
            'email_respaldo_mascara', v_email_mascara,
            'expira_en_minutos', 30,
            -- SOLO para desarrollo/testing. Remover en produccion.
            '_debug_codigo', v_codigo
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

GRANT EXECUTE ON FUNCTION solicitar_recuperacion_email_admin TO anon;
GRANT EXECUTE ON FUNCTION solicitar_recuperacion_email_admin TO authenticated;
REVOKE EXECUTE ON FUNCTION solicitar_recuperacion_email_admin FROM public;

COMMENT ON FUNCTION solicitar_recuperacion_email_admin IS 'E001-HU-007 CA-006/RN-003: Genera codigo de recuperacion para admin y lo prepara para envio por email de respaldo';

-- ============================================
-- VERIFICACION: Listar todo lo creado
-- Ejecutar este SELECT al final para confirmar
-- ============================================
SELECT 'TABLAS CREADAS' AS seccion, tablename AS nombre
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('codigos_recuperacion', 'intentos_recuperacion')

UNION ALL

SELECT 'FUNCIONES CREADAS' AS seccion, p.proname AS nombre
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'identificar_tipo_recuperacion',
    'generar_codigo_recuperacion',
    'obtener_pregunta_seguridad',
    'validar_codigo_recuperacion',
    'restablecer_contrasena_con_codigo',
    'restablecer_contrasena_con_pregunta',
    'solicitar_recuperacion_email_admin',
    '_validar_celular_peru',
    '_verificar_rate_limit_recuperacion',
    '_registrar_intento_fallido_recuperacion',
    '_resetear_intentos_recuperacion',
    '_validar_password_requisitos'
  )
ORDER BY seccion, nombre;
