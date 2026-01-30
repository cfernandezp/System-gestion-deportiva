-- ============================================
-- E003-HU-005: FIX - Corregir funcion asignar_equipo
-- Fecha: 2026-01-29
-- Descripcion: La funcion asignar_equipo usa columna 'equipo'
--              pero debe usar 'color_equipo' (nombre correcto)
-- ============================================
--
-- PROBLEMA: Error "column 'equipo' does not exist"
-- CAUSA: La funcion asignar_equipo usa 'equipo' en:
--        - SELECT (linea 281)
--        - UPDATE SET (linea 295)
--        - INSERT (linea 302)
-- SOLUCION: Recrear funcion con 'color_equipo'
--
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- ============================================
-- FUNCION: asignar_equipo (CORREGIDA)
-- ============================================
CREATE OR REPLACE FUNCTION asignar_equipo(
    p_fecha_id UUID,
    p_usuario_id UUID,
    p_equipo TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_usuario_destino RECORD;
    v_inscripcion RECORD;
    v_equipo_enum color_equipo;
    v_asignacion_id UUID;
    v_es_actualizacion BOOLEAN;
    v_equipo_anterior color_equipo;
    v_colores_validos TEXT[];
BEGIN
    -- ========================================
    -- Validacion: Usuario autenticado
    -- ========================================
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- ========================================
    -- Validacion: Parametros obligatorios
    -- ========================================
    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    IF p_usuario_id IS NULL THEN
        v_error_hint := 'usuario_id_requerido';
        RAISE EXCEPTION 'El ID del usuario es obligatorio';
    END IF;

    IF p_equipo IS NULL OR TRIM(p_equipo) = '' THEN
        v_error_hint := 'equipo_requerido';
        RAISE EXCEPTION 'El equipo es obligatorio';
    END IF;

    -- ========================================
    -- RN-001: Solo admin aprobado puede asignar equipos
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_current_user.rol != 'admin' OR v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo los administradores aprobados pueden asignar equipos';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- RN-002 y RN-008: Solo se puede asignar si fecha.estado = 'cerrada'
    -- ========================================
    IF v_fecha.estado != 'cerrada' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'Solo se pueden asignar equipos cuando las inscripciones estan cerradas. Estado actual: %', v_fecha.estado;
    END IF;

    -- ========================================
    -- Verificar que el usuario destino existe
    -- ========================================
    SELECT id, nombre_completo, estado
    INTO v_usuario_destino
    FROM usuarios
    WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_destino_no_encontrado';
        RAISE EXCEPTION 'Usuario a asignar no encontrado';
    END IF;

    -- ========================================
    -- Verificar que el usuario esta inscrito a la fecha
    -- ========================================
    SELECT id, estado
    INTO v_inscripcion
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND usuario_id = p_usuario_id
    AND estado = 'inscrito';

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_inscrito';
        RAISE EXCEPTION 'El usuario % no esta inscrito a esta fecha', v_usuario_destino.nombre_completo;
    END IF;

    -- ========================================
    -- RN-004: Validar color del equipo
    -- ========================================
    BEGIN
        v_equipo_enum := p_equipo::color_equipo;
    EXCEPTION
        WHEN invalid_text_representation THEN
            v_error_hint := 'color_invalido';
            RAISE EXCEPTION 'Color de equipo invalido: %. Colores validos: naranja, verde, azul, rojo, amarillo, blanco', p_equipo;
    END;

    -- ========================================
    -- RN-003/RN-004: Validar que el color es apropiado segun num_equipos
    -- 2 equipos: naranja, verde
    -- 3 equipos: naranja, verde, azul
    -- ========================================
    IF v_fecha.num_equipos = 2 THEN
        v_colores_validos := ARRAY['naranja', 'verde'];
    ELSE -- 3 equipos
        v_colores_validos := ARRAY['naranja', 'verde', 'azul'];
    END IF;

    IF NOT (p_equipo = ANY(v_colores_validos)) THEN
        v_error_hint := 'color_no_permitido';
        RAISE EXCEPTION 'Para esta fecha de % equipo(s) solo se permiten los colores: %',
            v_fecha.num_equipos,
            array_to_string(v_colores_validos, ', ');
    END IF;

    -- ========================================
    -- Verificar si ya existe asignacion (para upsert)
    -- FIX: Usar color_equipo en lugar de equipo
    -- ========================================
    SELECT id, color_equipo
    INTO v_asignacion_id, v_equipo_anterior
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id
    AND usuario_id = p_usuario_id;

    v_es_actualizacion := FOUND;

    -- ========================================
    -- INSERT o UPDATE (upsert)
    -- FIX: Usar color_equipo en lugar de equipo
    -- ========================================
    IF v_es_actualizacion THEN
        -- Actualizar asignacion existente
        UPDATE asignaciones_equipos
        SET color_equipo = v_equipo_enum
        WHERE id = v_asignacion_id;
    ELSE
        -- Insertar nueva asignacion
        INSERT INTO asignaciones_equipos (
            fecha_id,
            usuario_id,
            color_equipo
        ) VALUES (
            p_fecha_id,
            p_usuario_id,
            v_equipo_enum
        )
        RETURNING id INTO v_asignacion_id;
    END IF;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'asignacion_id', v_asignacion_id,
            'fecha_id', p_fecha_id,
            'usuario_id', p_usuario_id,
            'usuario_nombre', v_usuario_destino.nombre_completo,
            'equipo', v_equipo_enum,
            'equipo_anterior', CASE WHEN v_es_actualizacion THEN v_equipo_anterior::TEXT ELSE NULL END,
            'es_actualizacion', v_es_actualizacion,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar
        ),
        'message', CASE
            WHEN v_es_actualizacion THEN
                v_usuario_destino.nombre_completo || ' cambiado de equipo ' ||
                v_equipo_anterior::TEXT || ' a ' || v_equipo_enum::TEXT
            ELSE
                v_usuario_destino.nombre_completo || ' asignado al equipo ' || v_equipo_enum::TEXT
        END
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'UNIQUE_VIOLATION',
                'message', 'El usuario ya tiene una asignacion para esta fecha',
                'hint', 'asignacion_duplicada'
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
-- PERMISOS
-- ============================================
GRANT EXECUTE ON FUNCTION asignar_equipo TO authenticated, service_role;

-- ============================================
-- VERIFICACION
-- ============================================
SELECT 'Funcion asignar_equipo actualizada exitosamente para usar color_equipo' as resultado;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
