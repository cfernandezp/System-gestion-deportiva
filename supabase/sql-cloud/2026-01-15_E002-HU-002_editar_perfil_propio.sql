-- ============================================
-- E002-HU-002: Editar Perfil Propio
-- Fecha: 2026-01-15
-- Descripcion: Funcion RPC para actualizar perfil del usuario autenticado
--              con validacion de apodo unico y restricciones de campos
-- ============================================

-- ============================================
-- FUNCION RPC: actualizar_perfil_propio
-- ============================================

-- ============================================
-- Funcion: actualizar_perfil_propio
-- Descripcion: Actualiza el perfil del usuario autenticado
-- Parametros:
--   p_apodo: Nuevo apodo (2-30 caracteres, unico)
--   p_telefono: Nuevo telefono (opcional)
--   p_posicion_preferida: Nueva posicion (opcional, enum posicion_jugador)
--   p_foto_url: Nueva URL de foto (opcional)
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005
-- CA: CA-001, CA-002, CA-003, CA-004, CA-005, CA-006
-- ============================================
CREATE OR REPLACE FUNCTION actualizar_perfil_propio(
    p_apodo VARCHAR(50),
    p_telefono VARCHAR(20) DEFAULT NULL,
    p_posicion_preferida posicion_jugador DEFAULT NULL,
    p_foto_url TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_usuario_id UUID;
    v_apodo_actual VARCHAR(50);
    v_apodo_limpio VARCHAR(50);
    v_existe_apodo BOOLEAN;
    v_usuario_actualizado RECORD;
    v_antiguedad_texto TEXT;
    v_meses_antiguedad INT;
    v_dias_antiguedad INT;
BEGIN
    -- ========================================
    -- RN-003: Solo puede editar su propio perfil
    -- ========================================
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para editar tu perfil';
    END IF;

    -- Obtener ID del usuario y apodo actual
    SELECT id, apodo INTO v_usuario_id, v_apodo_actual
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro tu perfil en el sistema';
    END IF;

    -- ========================================
    -- RN-004: Formato del Apodo (2-30 caracteres)
    -- ========================================
    -- Limpiar apodo de espacios al inicio y final
    v_apodo_limpio := TRIM(p_apodo);

    -- Validar que no este vacio o solo espacios
    IF v_apodo_limpio IS NULL OR LENGTH(v_apodo_limpio) = 0 THEN
        v_error_hint := 'apodo_vacio';
        RAISE EXCEPTION 'El apodo no puede estar vacio';
    END IF;

    -- Validar longitud minima (2 caracteres)
    IF LENGTH(v_apodo_limpio) < 2 THEN
        v_error_hint := 'apodo_muy_corto';
        RAISE EXCEPTION 'El apodo debe tener al menos 2 caracteres';
    END IF;

    -- Validar longitud maxima (30 caracteres)
    IF LENGTH(v_apodo_limpio) > 30 THEN
        v_error_hint := 'apodo_muy_largo';
        RAISE EXCEPTION 'El apodo no puede tener mas de 30 caracteres';
    END IF;

    -- ========================================
    -- RN-001: Unicidad del Apodo
    -- ========================================
    -- Solo validar unicidad si el apodo cambio
    IF v_apodo_limpio <> COALESCE(v_apodo_actual, '') THEN
        SELECT EXISTS(
            SELECT 1 FROM usuarios
            WHERE LOWER(TRIM(apodo)) = LOWER(v_apodo_limpio)
              AND id <> v_usuario_id
        ) INTO v_existe_apodo;

        IF v_existe_apodo THEN
            v_error_hint := 'apodo_duplicado';
            RAISE EXCEPTION 'El apodo "%" ya esta en uso por otro jugador', v_apodo_limpio;
        END IF;
    END IF;

    -- ========================================
    -- RN-002: Campos de Edicion Restringida
    -- Solo se actualizan: apodo, telefono, posicion_preferida, foto_url
    -- NO se pueden editar: nombre_completo, email (CA-003)
    -- ========================================
    UPDATE usuarios
    SET
        apodo = v_apodo_limpio,
        telefono = NULLIF(TRIM(COALESCE(p_telefono, '')), ''),
        posicion_preferida = p_posicion_preferida,
        foto_url = NULLIF(TRIM(COALESCE(p_foto_url, '')), ''),
        updated_at = NOW()
    WHERE id = v_usuario_id;

    -- Obtener datos actualizados para retornar
    SELECT
        id,
        nombre_completo,
        apodo,
        email,
        telefono,
        posicion_preferida,
        foto_url,
        created_at,
        estado,
        rol
    INTO v_usuario_actualizado
    FROM usuarios
    WHERE id = v_usuario_id;

    -- Calcular antiguedad para respuesta
    v_meses_antiguedad := EXTRACT(MONTH FROM AGE(NOW(), v_usuario_actualizado.created_at))::INT
                        + (EXTRACT(YEAR FROM AGE(NOW(), v_usuario_actualizado.created_at))::INT * 12);
    v_dias_antiguedad := EXTRACT(DAY FROM AGE(NOW(), v_usuario_actualizado.created_at))::INT;

    IF v_meses_antiguedad >= 12 THEN
        v_antiguedad_texto := (v_meses_antiguedad / 12)::TEXT || ' ano(s)';
    ELSIF v_meses_antiguedad >= 1 THEN
        v_antiguedad_texto := v_meses_antiguedad::TEXT || ' mes(es)';
    ELSE
        v_antiguedad_texto := v_dias_antiguedad::TEXT || ' dia(s)';
    END IF;

    -- ========================================
    -- CA-004: Retornar confirmacion con perfil actualizado
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario_actualizado.id,
            'nombre_completo', v_usuario_actualizado.nombre_completo,
            'apodo', v_usuario_actualizado.apodo,
            'email', v_usuario_actualizado.email,
            'telefono', v_usuario_actualizado.telefono,
            'posicion_preferida', v_usuario_actualizado.posicion_preferida,
            'foto_url', v_usuario_actualizado.foto_url,
            'fecha_ingreso', v_usuario_actualizado.created_at AT TIME ZONE 'America/Lima',
            'fecha_ingreso_formato', TO_CHAR(v_usuario_actualizado.created_at AT TIME ZONE 'America/Lima', 'DD "de" TMMonth "de" YYYY'),
            'antiguedad', v_antiguedad_texto,
            'estado', v_usuario_actualizado.estado,
            'rol', v_usuario_actualizado.rol
        ),
        'message', 'Perfil actualizado exitosamente'
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
-- PERMISOS
-- ============================================

-- Solo usuarios autenticados pueden actualizar su perfil
GRANT EXECUTE ON FUNCTION actualizar_perfil_propio(VARCHAR, VARCHAR, posicion_jugador, TEXT) TO authenticated;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON FUNCTION actualizar_perfil_propio IS 'E002-HU-002: Actualiza perfil propio del usuario autenticado. Valida apodo unico (RN-001), campos restringidos (RN-002), propiedad (RN-003), formato apodo (RN-004). CA-001 a CA-006';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
