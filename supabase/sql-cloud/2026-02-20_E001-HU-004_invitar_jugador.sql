-- ============================================
-- E001-HU-004: Invitar Jugador al Grupo
-- Fecha: 2026-02-20
-- Crea RPC invitar_jugador_grupo y obtener_miembros_grupo
-- Dependencia: tablas usuarios, grupos, miembros_grupo, planes
-- ============================================

-- ============================================
-- PASO 1: RPC invitar_jugador_grupo
-- CA-001 a CA-004, CA-006, CA-007
-- RN-001 a RN-006
-- ============================================
CREATE OR REPLACE FUNCTION invitar_jugador_grupo(
    p_grupo_id UUID,
    p_celular VARCHAR(9)
) RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_invitador_id UUID;
    v_invitador_rol rol_en_grupo;
    v_celular_limpio VARCHAR(9);
    v_usuario_existente_id UUID;
    v_usuario_estado estado_usuario;
    v_nuevo_usuario_id UUID;
    v_limite_jugadores INTEGER;
    v_total_miembros INTEGER;
    v_nombre_usuario TEXT;
    v_error_hint TEXT;
BEGIN
    -- =============================================
    -- Verificar autenticacion
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para invitar jugadores';
    END IF;

    -- Obtener invitador
    SELECT id INTO v_invitador_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_invitador_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- =============================================
    -- RN-001: Verificar rol admin o co-admin en el grupo
    -- =============================================
    SELECT rol INTO v_invitador_rol
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id
    AND usuario_id = v_invitador_id
    AND activo = TRUE;

    IF v_invitador_rol IS NULL THEN
        v_error_hint := 'no_es_miembro';
        RAISE EXCEPTION 'No eres miembro de este grupo';
    END IF;

    IF v_invitador_rol NOT IN ('admin', 'coadmin') THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores y co-administradores pueden invitar jugadores';
    END IF;

    -- =============================================
    -- CA-006: Validar formato celular Peru
    -- =============================================
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
    -- CA-004 / RN-002: Verificar limite de jugadores
    -- =============================================
    SELECT g.limite_jugadores INTO v_limite_jugadores
    FROM grupos g
    WHERE g.id = p_grupo_id AND g.activo = TRUE;

    IF v_limite_jugadores IS NULL THEN
        v_error_hint := 'grupo_no_encontrado';
        RAISE EXCEPTION 'El grupo no existe o no esta activo';
    END IF;

    -- Contar miembros actuales (activos, incluye todos los roles)
    SELECT COUNT(*) INTO v_total_miembros
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id AND activo = TRUE;

    IF v_total_miembros >= v_limite_jugadores THEN
        v_error_hint := 'limite_jugadores_alcanzado';
        RAISE EXCEPTION 'Se alcanzo el limite de % jugadores del grupo. Actualiza tu plan para agregar mas.', v_limite_jugadores;
    END IF;

    -- =============================================
    -- Buscar si el celular ya existe en el sistema
    -- =============================================
    SELECT id, estado, nombre_completo INTO v_usuario_existente_id, v_usuario_estado, v_nombre_usuario
    FROM usuarios
    WHERE celular = v_celular_limpio;

    IF v_usuario_existente_id IS NOT NULL THEN
        -- =============================================
        -- CA-003 / RN-005: Verificar si ya es miembro del grupo
        -- =============================================
        IF EXISTS (
            SELECT 1 FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
            AND usuario_id = v_usuario_existente_id
            AND activo = TRUE
        ) THEN
            v_error_hint := 'ya_es_miembro';
            RAISE EXCEPTION 'Este jugador ya pertenece al grupo';
        END IF;

        -- =============================================
        -- CA-002 / RN-003: Asociar usuario existente al grupo
        -- Si fue miembro antes (activo=false), reactivar
        -- =============================================
        INSERT INTO miembros_grupo (grupo_id, usuario_id, rol, activo, created_at, updated_at)
        VALUES (p_grupo_id, v_usuario_existente_id, 'jugador', TRUE, NOW(), NOW())
        ON CONFLICT (grupo_id, usuario_id)
        DO UPDATE SET activo = TRUE, rol = 'jugador', updated_at = NOW();

        RETURN json_build_object(
            'success', TRUE,
            'message', 'Jugador agregado al grupo exitosamente',
            'data', json_build_object(
                'usuario_id', v_usuario_existente_id,
                'celular', v_celular_limpio,
                'nombre', COALESCE(v_nombre_usuario, ''),
                'estado_usuario', v_usuario_estado::TEXT,
                'es_nuevo', FALSE
            )
        );
    ELSE
        -- =============================================
        -- CA-001 / RN-004: Crear usuario pendiente de activacion
        -- Sin nombre, sin contrasena, sin auth_user_id
        -- =============================================
        INSERT INTO usuarios (
            nombre_completo,
            celular,
            email,
            estado,
            rol,
            created_at,
            updated_at
        ) VALUES (
            '',
            v_celular_limpio,
            v_celular_limpio || '@gestiondeportiva.app',
            'pendiente_aprobacion',
            'jugador',
            NOW(),
            NOW()
        )
        RETURNING id INTO v_nuevo_usuario_id;

        -- Asociar al grupo
        INSERT INTO miembros_grupo (grupo_id, usuario_id, rol, activo, created_at, updated_at)
        VALUES (p_grupo_id, v_nuevo_usuario_id, 'jugador', TRUE, NOW(), NOW());

        -- =============================================
        -- CA-007 / RN-006: Retornar confirmacion con recordatorio
        -- =============================================
        RETURN json_build_object(
            'success', TRUE,
            'message', 'Jugador invitado exitosamente. Recuerda notificarle por WhatsApp, llamada o en persona para que descargue la app y active su cuenta.',
            'data', json_build_object(
                'usuario_id', v_nuevo_usuario_id,
                'celular', v_celular_limpio,
                'nombre', '',
                'estado_usuario', 'pendiente_aprobacion',
                'es_nuevo', TRUE
            )
        );
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'Este jugador ya pertenece al grupo',
                'code', SQLSTATE,
                'hint', 'ya_es_miembro'
            )
        );
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

-- Permisos
GRANT EXECUTE ON FUNCTION invitar_jugador_grupo TO authenticated;

-- ============================================
-- PASO 2: RPC obtener_miembros_grupo
-- CA-005: Ver lista de jugadores con estado
-- ============================================
CREATE OR REPLACE FUNCTION obtener_miembros_grupo(
    p_grupo_id UUID
) RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_es_miembro BOOLEAN;
    v_miembros JSON;
    v_error_hint TEXT;
BEGIN
    -- Verificar autenticacion
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion';
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- Verificar que es miembro del grupo
    SELECT EXISTS (
        SELECT 1 FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
        AND usuario_id = v_usuario_id
        AND activo = TRUE
    ) INTO v_es_miembro;

    IF NOT v_es_miembro THEN
        v_error_hint := 'no_es_miembro';
        RAISE EXCEPTION 'No eres miembro de este grupo';
    END IF;

    -- Obtener miembros con datos del usuario
    SELECT json_agg(
        json_build_object(
            'miembro_id', mg.id,
            'usuario_id', mg.usuario_id,
            'grupo_id', mg.grupo_id,
            'rol', mg.rol::TEXT,
            'activo', mg.activo,
            'nombre', COALESCE(NULLIF(u.nombre_completo, ''), NULL),
            'celular', u.celular,
            'estado_usuario', u.estado::TEXT,
            'apodo', u.apodo,
            'foto_url', u.foto_url,
            'created_at', mg.created_at
        )
        ORDER BY
            CASE mg.rol
                WHEN 'admin' THEN 1
                WHEN 'coadmin' THEN 2
                WHEN 'jugador' THEN 3
                WHEN 'invitado' THEN 4
            END,
            u.nombre_completo
    ) INTO v_miembros
    FROM miembros_grupo mg
    JOIN usuarios u ON mg.usuario_id = u.id
    WHERE mg.grupo_id = p_grupo_id
    AND mg.activo = TRUE;

    RETURN json_build_object(
        'success', TRUE,
        'data', COALESCE(v_miembros, '[]'::JSON)
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

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_miembros_grupo TO authenticated;

-- ============================================
-- PASO 3: RLS update para miembros_grupo
-- Permitir reactivar miembros que fueron removidos
-- ============================================
DROP POLICY IF EXISTS "miembros_update_admin" ON miembros_grupo;
CREATE POLICY "miembros_update_admin" ON miembros_grupo
    FOR UPDATE TO authenticated
    USING (TRUE)
    WITH CHECK (TRUE);
