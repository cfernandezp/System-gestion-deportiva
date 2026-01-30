-- ============================================
-- E003-HU-005: Funcion desasignar_equipo
-- Fecha: 2026-01-29
-- Descripcion: Permite desasignar un jugador de su equipo
--              devolviendolo a la lista de "Sin Asignar"
-- ============================================
--
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- ============================================
-- FUNCION: desasignar_equipo
-- ============================================
CREATE OR REPLACE FUNCTION desasignar_equipo(
    p_fecha_id UUID,
    p_usuario_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_usuario_destino RECORD;
    v_asignacion RECORD;
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

    -- ========================================
    -- RN-001: Solo admin aprobado puede desasignar equipos
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden desasignar equipos';
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
    -- RN-002 y RN-008: Solo se puede desasignar si fecha.estado = 'cerrada'
    -- ========================================
    IF v_fecha.estado != 'cerrada' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'Solo se pueden modificar equipos cuando las inscripciones estan cerradas. Estado actual: %', v_fecha.estado;
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
        RAISE EXCEPTION 'Usuario a desasignar no encontrado';
    END IF;

    -- ========================================
    -- Verificar que existe la asignacion
    -- ========================================
    SELECT id, color_equipo
    INTO v_asignacion
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id
    AND usuario_id = p_usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'sin_asignacion';
        RAISE EXCEPTION 'El usuario % no tiene asignacion de equipo para esta fecha', v_usuario_destino.nombre_completo;
    END IF;

    -- ========================================
    -- Eliminar la asignacion
    -- ========================================
    DELETE FROM asignaciones_equipos
    WHERE id = v_asignacion.id;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'usuario_id', p_usuario_id,
            'usuario_nombre', v_usuario_destino.nombre_completo,
            'equipo_anterior', v_asignacion.color_equipo::TEXT,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar
        ),
        'message', v_usuario_destino.nombre_completo || ' removido del equipo ' || v_asignacion.color_equipo::TEXT
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
GRANT EXECUTE ON FUNCTION desasignar_equipo TO authenticated, service_role;

-- ============================================
-- VERIFICACION
-- ============================================
SELECT 'Funcion desasignar_equipo creada exitosamente' as resultado;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
