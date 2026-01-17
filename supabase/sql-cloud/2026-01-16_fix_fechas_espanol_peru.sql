-- ============================================
-- FIX: Fechas en Español para Perú
-- Fecha: 2026-01-16
-- Descripción: Crea función auxiliar para formatear fechas en español
--              ya que el servidor PostgreSQL no tiene locale es_PE
-- ============================================

-- ============================================
-- FUNCIÓN AUXILIAR: formato_fecha_espanol
-- Convierte una fecha a formato "DD de Mes de YYYY" en español
-- ============================================
CREATE OR REPLACE FUNCTION formato_fecha_espanol(p_fecha TIMESTAMP WITH TIME ZONE)
RETURNS TEXT AS $$
DECLARE
    v_dia TEXT;
    v_mes TEXT;
    v_anio TEXT;
    v_mes_num INT;
BEGIN
    -- Convertir a zona horaria de Perú
    v_dia := TO_CHAR(p_fecha AT TIME ZONE 'America/Lima', 'DD');
    v_mes_num := EXTRACT(MONTH FROM p_fecha AT TIME ZONE 'America/Lima')::INT;
    v_anio := TO_CHAR(p_fecha AT TIME ZONE 'America/Lima', 'YYYY');

    -- Traducir mes a español
    v_mes := CASE v_mes_num
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
        ELSE 'Desconocido'
    END;

    RETURN v_dia || ' de ' || v_mes || ' de ' || v_anio;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Permisos
GRANT EXECUTE ON FUNCTION formato_fecha_espanol(TIMESTAMP WITH TIME ZONE) TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION formato_fecha_espanol IS 'Formatea fecha en español para Perú: "DD de Mes de YYYY"';

-- ============================================
-- ACTUALIZAR: obtener_perfil_propio
-- Usar la nueva función para fechas en español
-- ============================================
CREATE OR REPLACE FUNCTION obtener_perfil_propio()
RETURNS JSON AS $$
DECLARE
    v_current_user_id UUID;
    v_usuario RECORD;
    v_antiguedad_texto TEXT;
    v_meses_antiguedad INT;
    v_dias_antiguedad INT;
BEGIN
    -- Obtener usuario autenticado
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'AUTH_REQUIRED',
                'message', 'Debes iniciar sesion para ver tu perfil',
                'hint', 'no_autenticado'
            )
        );
    END IF;

    -- Obtener datos del usuario
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
    INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF v_usuario.id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'USER_NOT_FOUND',
                'message', 'No se encontro tu perfil en el sistema',
                'hint', 'usuario_no_encontrado'
            )
        );
    END IF;

    -- Calcular antiguedad
    v_meses_antiguedad := EXTRACT(MONTH FROM AGE(NOW(), v_usuario.created_at))::INT
                        + (EXTRACT(YEAR FROM AGE(NOW(), v_usuario.created_at))::INT * 12);
    v_dias_antiguedad := EXTRACT(DAY FROM AGE(NOW(), v_usuario.created_at))::INT;

    IF v_meses_antiguedad >= 12 THEN
        v_antiguedad_texto := (v_meses_antiguedad / 12)::TEXT || ' ano(s)';
    ELSIF v_meses_antiguedad >= 1 THEN
        v_antiguedad_texto := v_meses_antiguedad::TEXT || ' mes(es)';
    ELSE
        v_antiguedad_texto := v_dias_antiguedad::TEXT || ' dia(s)';
    END IF;

    -- Retornar perfil
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario.id,
            'nombre_completo', v_usuario.nombre_completo,
            'apodo', v_usuario.apodo,
            'email', v_usuario.email,
            'telefono', v_usuario.telefono,
            'posicion_preferida', v_usuario.posicion_preferida,
            'foto_url', v_usuario.foto_url,
            'fecha_ingreso', v_usuario.created_at AT TIME ZONE 'America/Lima',
            'fecha_ingreso_formato', formato_fecha_espanol(v_usuario.created_at),
            'antiguedad', v_antiguedad_texto,
            'estado', v_usuario.estado,
            'rol', v_usuario.rol
        ),
        'message', 'Perfil obtenido exitosamente'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_perfil_propio() TO authenticated;

-- Comentario
COMMENT ON FUNCTION obtener_perfil_propio IS 'E002-HU-001: Obtiene perfil del usuario autenticado con fechas en español';

-- ============================================
-- ACTUALIZAR: actualizar_perfil_propio
-- Usar la nueva función para fechas en español
-- ============================================
DROP FUNCTION IF EXISTS actualizar_perfil_propio(VARCHAR, VARCHAR, posicion_jugador, TEXT);

CREATE OR REPLACE FUNCTION actualizar_perfil_propio(
    p_nombre_completo VARCHAR(100),
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
    v_nombre_limpio VARCHAR(100);
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
    -- Validacion de Nombre Completo (2-100 caracteres)
    -- ========================================
    v_nombre_limpio := TRIM(p_nombre_completo);

    IF v_nombre_limpio IS NULL OR LENGTH(v_nombre_limpio) = 0 THEN
        v_error_hint := 'nombre_vacio';
        RAISE EXCEPTION 'El nombre completo no puede estar vacio';
    END IF;

    IF LENGTH(v_nombre_limpio) < 2 THEN
        v_error_hint := 'nombre_muy_corto';
        RAISE EXCEPTION 'El nombre completo debe tener al menos 2 caracteres';
    END IF;

    IF LENGTH(v_nombre_limpio) > 100 THEN
        v_error_hint := 'nombre_muy_largo';
        RAISE EXCEPTION 'El nombre completo no puede tener mas de 100 caracteres';
    END IF;

    -- ========================================
    -- RN-004: Formato del Apodo (2-30 caracteres)
    -- ========================================
    v_apodo_limpio := TRIM(p_apodo);

    IF v_apodo_limpio IS NULL OR LENGTH(v_apodo_limpio) = 0 THEN
        v_error_hint := 'apodo_vacio';
        RAISE EXCEPTION 'El apodo no puede estar vacio';
    END IF;

    IF LENGTH(v_apodo_limpio) < 2 THEN
        v_error_hint := 'apodo_muy_corto';
        RAISE EXCEPTION 'El apodo debe tener al menos 2 caracteres';
    END IF;

    IF LENGTH(v_apodo_limpio) > 30 THEN
        v_error_hint := 'apodo_muy_largo';
        RAISE EXCEPTION 'El apodo no puede tener mas de 30 caracteres';
    END IF;

    -- ========================================
    -- RN-001: Unicidad del Apodo
    -- ========================================
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
    -- RN-002: Campos de Edicion (actualizado 2026-01-16)
    -- ========================================
    UPDATE usuarios
    SET
        nombre_completo = v_nombre_limpio,
        apodo = v_apodo_limpio,
        telefono = NULLIF(TRIM(COALESCE(p_telefono, '')), ''),
        posicion_preferida = p_posicion_preferida,
        foto_url = NULLIF(TRIM(COALESCE(p_foto_url, '')), ''),
        updated_at = NOW()
    WHERE id = v_usuario_id;

    -- Obtener datos actualizados
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

    -- Calcular antiguedad
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

    -- Retornar perfil actualizado con fecha en español
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
            'fecha_ingreso_formato', formato_fecha_espanol(v_usuario_actualizado.created_at),
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

-- Permisos
GRANT EXECUTE ON FUNCTION actualizar_perfil_propio(VARCHAR, VARCHAR, VARCHAR, posicion_jugador, TEXT) TO authenticated;

-- Comentario
COMMENT ON FUNCTION actualizar_perfil_propio IS 'E002-HU-002: Actualiza perfil con fechas en español. Incluye nombre_completo.';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
