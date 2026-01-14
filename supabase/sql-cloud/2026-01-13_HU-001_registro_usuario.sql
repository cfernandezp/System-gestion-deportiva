-- ============================================
-- HU-001: Registro de Usuario
-- Fecha: 2026-01-13
-- Descripcion: Implementacion completa del flujo de registro,
--              aprobacion y rechazo de usuarios con notificaciones
-- ============================================

-- ============================================
-- PARTE 1: TABLAS Y TIPOS
-- ============================================

-- Tipo ENUM para estados de usuario
DO $$ BEGIN
    CREATE TYPE estado_usuario AS ENUM (
        'pendiente_aprobacion',
        'aprobado',
        'rechazado'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Tipo ENUM para roles de usuario
DO $$ BEGIN
    CREATE TYPE rol_usuario AS ENUM (
        'admin',
        'jugador',
        'arbitro',
        'delegado'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Tipo ENUM para tipos de notificacion
DO $$ BEGIN
    CREATE TYPE tipo_notificacion AS ENUM (
        'nuevo_registro',
        'cuenta_aprobada',
        'cuenta_rechazada',
        'general'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Tabla: usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre_completo VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    estado estado_usuario NOT NULL DEFAULT 'pendiente_aprobacion',
    rol rol_usuario NOT NULL DEFAULT 'jugador',
    motivo_rechazo TEXT,
    aprobado_por UUID REFERENCES usuarios(id),
    aprobado_rechazado_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice para busquedas por email
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
-- Indice para busquedas por estado
CREATE INDEX IF NOT EXISTS idx_usuarios_estado ON usuarios(estado);
-- Indice para busquedas por auth_user_id
CREATE INDEX IF NOT EXISTS idx_usuarios_auth_user_id ON usuarios(auth_user_id);

-- Tabla: notificaciones
CREATE TABLE IF NOT EXISTS notificaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo tipo_notificacion NOT NULL DEFAULT 'general',
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    leida BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice para busquedas por usuario y estado de lectura
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_leida ON notificaciones(usuario_id, leida);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_usuarios_updated_at ON usuarios;
CREATE TRIGGER trigger_usuarios_updated_at
    BEFORE UPDATE ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 2: FUNCIONES RPC
-- ============================================

-- ============================================
-- Funcion: validar_password
-- Descripcion: Valida que la contrasena cumpla requisitos de seguridad
-- Reglas: RN-002
-- ============================================
CREATE OR REPLACE FUNCTION validar_password(p_password TEXT)
RETURNS JSON AS $$
DECLARE
    v_errors TEXT[] := '{}';
BEGIN
    -- Minimo 8 caracteres
    IF LENGTH(p_password) < 8 THEN
        v_errors := array_append(v_errors, 'Minimo 8 caracteres');
    END IF;

    -- Al menos una mayuscula
    IF p_password !~ '[A-Z]' THEN
        v_errors := array_append(v_errors, 'Al menos una letra mayuscula');
    END IF;

    -- Al menos una minuscula
    IF p_password !~ '[a-z]' THEN
        v_errors := array_append(v_errors, 'Al menos una letra minuscula');
    END IF;

    -- Al menos un numero
    IF p_password !~ '[0-9]' THEN
        v_errors := array_append(v_errors, 'Al menos un numero');
    END IF;

    -- Al menos un caracter especial
    IF p_password !~ '[!@#$%^&*]' THEN
        v_errors := array_append(v_errors, 'Al menos un caracter especial (!@#$%^&*)');
    END IF;

    IF array_length(v_errors, 1) > 0 THEN
        RETURN json_build_object(
            'valid', false,
            'errors', v_errors
        );
    END IF;

    RETURN json_build_object(
        'valid', true,
        'errors', '{}'::TEXT[]
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Funcion: registrar_usuario
-- Descripcion: Registra un nuevo usuario en auth.users y tabla usuarios
-- Reglas: RN-001, RN-002, RN-004, RN-005, RN-006, RN-009, RN-010
-- ============================================
CREATE OR REPLACE FUNCTION registrar_usuario(
    p_nombre_completo TEXT,
    p_email TEXT,
    p_password TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_auth_user_id UUID;
    v_usuario_id UUID;
    v_password_validation JSON;
    v_admin_record RECORD;
    v_es_primer_usuario BOOLEAN;
BEGIN
    -- Validar nombre completo (RN-009)
    IF p_nombre_completo IS NULL OR LENGTH(TRIM(p_nombre_completo)) < 2 THEN
        v_error_hint := 'nombre_invalido';
        RAISE EXCEPTION 'El nombre completo debe tener al menos 2 caracteres';
    END IF;

    -- Validar formato de email (RN-010)
    IF p_email IS NULL OR p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        v_error_hint := 'email_formato_invalido';
        RAISE EXCEPTION 'El formato del email no es valido';
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

    -- Validar password (RN-002)
    v_password_validation := validar_password(p_password);
    IF NOT (v_password_validation->>'valid')::BOOLEAN THEN
        v_error_hint := 'password_invalido';
        RAISE EXCEPTION 'La contrasena no cumple los requisitos: %',
            array_to_string((SELECT array_agg(x) FROM json_array_elements_text(v_password_validation->'errors') x), ', ');
    END IF;

    -- Verificar si es el primer usuario (sera admin)
    SELECT NOT EXISTS (SELECT 1 FROM usuarios WHERE estado = 'aprobado') INTO v_es_primer_usuario;

    -- Crear usuario en auth.users usando la funcion de Supabase
    v_auth_user_id := (
        SELECT id FROM auth.users
        WHERE email = LOWER(p_email)
    );

    -- Si ya existe en auth pero fue rechazado, reutilizar
    IF v_auth_user_id IS NOT NULL THEN
        -- Verificar que sea un rechazado
        IF NOT EXISTS (
            SELECT 1 FROM usuarios
            WHERE auth_user_id = v_auth_user_id
            AND estado = 'rechazado'
        ) THEN
            v_error_hint := 'email_duplicado';
            RAISE EXCEPTION 'El email ya esta registrado en el sistema';
        END IF;

        -- Eliminar el registro anterior rechazado
        DELETE FROM usuarios WHERE auth_user_id = v_auth_user_id;
    ELSE
        -- Crear nuevo usuario en auth.users
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            aud,
            role,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            '00000000-0000-0000-0000-000000000000',
            LOWER(p_email),
            crypt(p_password, gen_salt('bf')),
            NOW(), -- Email confirmado automaticamente
            '{"provider":"email","providers":["email"]}'::jsonb,
            jsonb_build_object('nombre_completo', p_nombre_completo),
            'authenticated',
            'authenticated',
            NOW(),
            NOW()
        )
        RETURNING id INTO v_auth_user_id;
    END IF;

    -- Crear registro en tabla usuarios (RN-004, RN-005)
    INSERT INTO usuarios (
        auth_user_id,
        nombre_completo,
        email,
        estado,
        rol
    ) VALUES (
        v_auth_user_id,
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
                'auth_user_id', v_auth_user_id,
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
            'auth_user_id', v_auth_user_id,
            'email', LOWER(p_email),
            'estado', 'pendiente_aprobacion',
            'rol', 'jugador'
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
-- Funcion: verificar_estado_usuario
-- Descripcion: Verifica el estado de un usuario para permitir/denegar acceso
-- Reglas: RN-007, CA-008
-- ============================================
CREATE OR REPLACE FUNCTION verificar_estado_usuario(
    p_auth_user_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_usuario RECORD;
BEGIN
    -- Buscar usuario por auth_user_id
    SELECT id, nombre_completo, email, estado, rol
    INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = p_auth_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    -- Verificar estado
    IF v_usuario.estado = 'pendiente_aprobacion' THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'puede_acceder', false,
                'usuario_id', v_usuario.id,
                'estado', v_usuario.estado,
                'rol', v_usuario.rol
            ),
            'message', 'Tu cuenta esta pendiente de aprobacion por un administrador.'
        );
    ELSIF v_usuario.estado = 'rechazado' THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'puede_acceder', false,
                'usuario_id', v_usuario.id,
                'estado', v_usuario.estado,
                'rol', v_usuario.rol
            ),
            'message', 'Tu solicitud de registro fue rechazada. Contacta al administrador para mas informacion.'
        );
    END IF;

    -- Usuario aprobado
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'puede_acceder', true,
            'usuario_id', v_usuario.id,
            'nombre_completo', v_usuario.nombre_completo,
            'email', v_usuario.email,
            'estado', v_usuario.estado,
            'rol', v_usuario.rol
        ),
        'message', 'Acceso permitido'
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
-- Funcion: obtener_usuarios_pendientes
-- Descripcion: Obtiene lista de usuarios pendientes de aprobacion (solo admin)
-- Reglas: RN-008
-- ============================================
CREATE OR REPLACE FUNCTION obtener_usuarios_pendientes()
RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_usuarios JSON;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Verificar que sea admin
    SELECT id, rol, estado
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND OR v_current_user.rol != 'admin' OR v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'No tienes permisos para realizar esta accion';
    END IF;

    -- Obtener usuarios pendientes
    SELECT json_agg(
        json_build_object(
            'id', u.id,
            'nombre_completo', u.nombre_completo,
            'email', u.email,
            'estado', u.estado,
            'created_at', u.created_at AT TIME ZONE 'America/Lima',
            'dias_pendiente', EXTRACT(DAY FROM NOW() - u.created_at)::INT
        ) ORDER BY u.created_at ASC
    )
    INTO v_usuarios
    FROM usuarios u
    WHERE u.estado = 'pendiente_aprobacion';

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuarios', COALESCE(v_usuarios, '[]'::json),
            'total', (SELECT COUNT(*) FROM usuarios WHERE estado = 'pendiente_aprobacion')
        ),
        'message', 'Lista de usuarios pendientes obtenida exitosamente'
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
-- Funcion: aprobar_usuario
-- Descripcion: Aprueba un usuario pendiente y asigna rol
-- Reglas: RN-008, CA-009
-- ============================================
CREATE OR REPLACE FUNCTION aprobar_usuario(
    p_usuario_id UUID,
    p_rol rol_usuario DEFAULT 'jugador'
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_usuario RECORD;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Verificar que sea admin
    SELECT id, rol, estado
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND OR v_current_user.rol != 'admin' OR v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'No tienes permisos para realizar esta accion';
    END IF;

    -- Verificar que el usuario a aprobar existe y esta pendiente
    SELECT id, nombre_completo, email, estado, auth_user_id
    INTO v_usuario
    FROM usuarios
    WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    IF v_usuario.estado != 'pendiente_aprobacion' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'El usuario no esta en estado pendiente de aprobacion';
    END IF;

    -- Verificar que no se apruebe a si mismo
    IF v_usuario.id = v_current_user.id THEN
        v_error_hint := 'auto_aprobacion';
        RAISE EXCEPTION 'No puedes aprobar tu propia solicitud';
    END IF;

    -- Aprobar usuario
    UPDATE usuarios
    SET
        estado = 'aprobado',
        rol = p_rol,
        aprobado_por = v_current_user.id,
        aprobado_rechazado_at = NOW()
    WHERE id = p_usuario_id;

    -- Crear notificacion para el usuario aprobado
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        metadata
    ) VALUES (
        p_usuario_id,
        'cuenta_aprobada',
        'Tu cuenta ha sido aprobada',
        'Tu solicitud de registro ha sido aprobada. Ya puedes iniciar sesion con el rol de ' || p_rol::TEXT || '.',
        jsonb_build_object(
            'aprobado_por', v_current_user.id,
            'rol_asignado', p_rol
        )
    );

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', p_usuario_id,
            'nombre_completo', v_usuario.nombre_completo,
            'email', v_usuario.email,
            'estado', 'aprobado',
            'rol', p_rol
        ),
        'message', 'Usuario aprobado exitosamente'
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
-- Funcion: rechazar_usuario
-- Descripcion: Rechaza un usuario pendiente con motivo opcional
-- Reglas: RN-008, CA-010
-- ============================================
CREATE OR REPLACE FUNCTION rechazar_usuario(
    p_usuario_id UUID,
    p_motivo TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_usuario RECORD;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Verificar que sea admin
    SELECT id, rol, estado
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND OR v_current_user.rol != 'admin' OR v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'No tienes permisos para realizar esta accion';
    END IF;

    -- Verificar que el usuario a rechazar existe y esta pendiente
    SELECT id, nombre_completo, email, estado, auth_user_id
    INTO v_usuario
    FROM usuarios
    WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    IF v_usuario.estado != 'pendiente_aprobacion' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'El usuario no esta en estado pendiente de aprobacion';
    END IF;

    -- Verificar que no se rechace a si mismo
    IF v_usuario.id = v_current_user.id THEN
        v_error_hint := 'auto_rechazo';
        RAISE EXCEPTION 'No puedes rechazar tu propia solicitud';
    END IF;

    -- Rechazar usuario
    UPDATE usuarios
    SET
        estado = 'rechazado',
        motivo_rechazo = NULLIF(TRIM(p_motivo), ''),
        aprobado_por = v_current_user.id,
        aprobado_rechazado_at = NOW()
    WHERE id = p_usuario_id;

    -- Crear notificacion para el usuario rechazado
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        metadata
    ) VALUES (
        p_usuario_id,
        'cuenta_rechazada',
        'Tu solicitud de registro fue rechazada',
        CASE
            WHEN p_motivo IS NOT NULL AND TRIM(p_motivo) != ''
            THEN 'Tu solicitud de registro ha sido rechazada. Motivo: ' || TRIM(p_motivo)
            ELSE 'Tu solicitud de registro ha sido rechazada. Contacta al administrador para mas informacion.'
        END,
        jsonb_build_object(
            'rechazado_por', v_current_user.id,
            'motivo', NULLIF(TRIM(p_motivo), '')
        )
    );

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', p_usuario_id,
            'nombre_completo', v_usuario.nombre_completo,
            'email', v_usuario.email,
            'estado', 'rechazado',
            'motivo', NULLIF(TRIM(p_motivo), '')
        ),
        'message', 'Usuario rechazado exitosamente'
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
-- Funcion: obtener_notificaciones
-- Descripcion: Obtiene notificaciones del usuario actual
-- ============================================
CREATE OR REPLACE FUNCTION obtener_notificaciones(
    p_solo_no_leidas BOOLEAN DEFAULT FALSE,
    p_limite INT DEFAULT 50
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_usuario_id UUID;
    v_notificaciones JSON;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    -- Obtener notificaciones
    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'tipo', n.tipo,
            'titulo', n.titulo,
            'mensaje', n.mensaje,
            'metadata', n.metadata,
            'leida', n.leida,
            'created_at', n.created_at AT TIME ZONE 'America/Lima'
        ) ORDER BY n.created_at DESC
    )
    INTO v_notificaciones
    FROM notificaciones n
    WHERE n.usuario_id = v_usuario_id
    AND (NOT p_solo_no_leidas OR n.leida = FALSE)
    LIMIT p_limite;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'notificaciones', COALESCE(v_notificaciones, '[]'::json),
            'no_leidas', (SELECT COUNT(*) FROM notificaciones WHERE usuario_id = v_usuario_id AND leida = FALSE)
        ),
        'message', 'Notificaciones obtenidas exitosamente'
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
-- Funcion: marcar_notificacion_leida
-- Descripcion: Marca una notificacion como leida
-- ============================================
CREATE OR REPLACE FUNCTION marcar_notificacion_leida(
    p_notificacion_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_usuario_id UUID;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    -- Verificar que la notificacion pertenece al usuario
    IF NOT EXISTS (
        SELECT 1 FROM notificaciones
        WHERE id = p_notificacion_id
        AND usuario_id = v_usuario_id
    ) THEN
        v_error_hint := 'notificacion_no_encontrada';
        RAISE EXCEPTION 'Notificacion no encontrada';
    END IF;

    -- Marcar como leida
    UPDATE notificaciones
    SET leida = TRUE
    WHERE id = p_notificacion_id;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'notificacion_id', p_notificacion_id
        ),
        'message', 'Notificacion marcada como leida'
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
-- PARTE 3: PERMISOS
-- ============================================

-- Permisos para funciones RPC
GRANT EXECUTE ON FUNCTION validar_password TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION registrar_usuario TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION verificar_estado_usuario TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_usuarios_pendientes TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION aprobar_usuario TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION rechazar_usuario TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_notificaciones TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION marcar_notificacion_leida TO authenticated, service_role;

-- ============================================
-- PARTE 4: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tablas
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;

-- Politicas para usuarios
CREATE POLICY "Usuarios pueden ver su propio perfil"
ON usuarios FOR SELECT
TO authenticated
USING (auth_user_id = auth.uid());

CREATE POLICY "Admins pueden ver todos los usuarios"
ON usuarios FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

CREATE POLICY "Admins pueden actualizar usuarios"
ON usuarios FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- Politicas para notificaciones
CREATE POLICY "Usuarios pueden ver sus propias notificaciones"
ON notificaciones FOR SELECT
TO authenticated
USING (
    usuario_id IN (
        SELECT id FROM usuarios
        WHERE auth_user_id = auth.uid()
    )
);

CREATE POLICY "Usuarios pueden actualizar sus propias notificaciones"
ON notificaciones FOR UPDATE
TO authenticated
USING (
    usuario_id IN (
        SELECT id FROM usuarios
        WHERE auth_user_id = auth.uid()
    )
);

-- ============================================
-- PARTE 5: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE usuarios IS 'HU-001: Tabla principal de usuarios del sistema';
COMMENT ON TABLE notificaciones IS 'HU-001: Tabla de notificaciones para usuarios';
COMMENT ON FUNCTION validar_password IS 'HU-001: Valida requisitos de seguridad de contrasena (RN-002)';
COMMENT ON FUNCTION registrar_usuario IS 'HU-001: Registra nuevo usuario con estado pendiente (RN-001 a RN-006)';
COMMENT ON FUNCTION verificar_estado_usuario IS 'HU-001: Verifica si usuario puede acceder al sistema (RN-007)';
COMMENT ON FUNCTION obtener_usuarios_pendientes IS 'HU-001: Lista usuarios pendientes para admin (RN-008)';
COMMENT ON FUNCTION aprobar_usuario IS 'HU-001: Aprueba solicitud de registro (CA-009, RN-008)';
COMMENT ON FUNCTION rechazar_usuario IS 'HU-001: Rechaza solicitud de registro (CA-010, RN-008)';
COMMENT ON FUNCTION obtener_notificaciones IS 'HU-001: Obtiene notificaciones del usuario';
COMMENT ON FUNCTION marcar_notificacion_leida IS 'HU-001: Marca notificacion como leida';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
