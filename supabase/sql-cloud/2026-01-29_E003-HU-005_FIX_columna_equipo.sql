-- ============================================
-- E003-HU-005: FIX - Corregir funciones que usan columna 'equipo'
-- Fecha: 2026-01-29
-- Descripcion: Las funciones fueron creadas con columna 'equipo'
--              pero la migracion la renombro a 'color_equipo'
-- ============================================
--
-- PROBLEMA: Error "column ae.equipo does not exist"
-- SOLUCION: Actualizar funciones para usar 'color_equipo'
--
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- ============================================
-- FUNCION 1: obtener_asignaciones (CORREGIDA)
-- ============================================
CREATE OR REPLACE FUNCTION obtener_asignaciones(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_jugadores JSON;
    v_equipos_resumen JSON;
    v_total_inscritos INTEGER;
    v_total_asignados INTEGER;
    v_colores_disponibles TEXT[];
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
    -- Validacion: Parametro obligatorio
    -- ========================================
    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    -- ========================================
    -- Obtener usuario actual
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
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
    -- Determinar colores disponibles segun num_equipos
    -- ========================================
    IF v_fecha.num_equipos = 2 THEN
        v_colores_disponibles := ARRAY['naranja', 'verde'];
    ELSE -- 3 equipos
        v_colores_disponibles := ARRAY['naranja', 'verde', 'azul'];
    END IF;

    -- ========================================
    -- Obtener lista de jugadores inscritos con su asignacion
    -- FIX: Usar color_equipo en lugar de equipo
    -- ========================================
    SELECT json_agg(jugador_data ORDER BY equipo_orden, nombre_completo)
    INTO v_jugadores
    FROM (
        SELECT
            json_build_object(
                'usuario_id', i.usuario_id,
                'nombre_completo', u.nombre_completo,
                'inscrito_at', i.created_at AT TIME ZONE 'America/Lima',
                'inscrito_formato', TO_CHAR(i.created_at AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                'equipo', ae.color_equipo,  -- FIX: era ae.equipo
                'numero_equipo', ae.numero_equipo,
                'asignacion_id', ae.id,
                'asignado', ae.id IS NOT NULL
            ) as jugador_data,
            -- Para ordenar: primero sin asignar (NULL), luego por equipo
            CASE
                WHEN ae.color_equipo IS NULL THEN 0  -- FIX: era ae.equipo
                WHEN ae.color_equipo = 'naranja' THEN 1
                WHEN ae.color_equipo = 'verde' THEN 2
                WHEN ae.color_equipo = 'azul' THEN 3
                ELSE 4
            END as equipo_orden,
            u.nombre_completo
        FROM inscripciones i
        JOIN usuarios u ON u.id = i.usuario_id
        LEFT JOIN asignaciones_equipos ae ON ae.fecha_id = i.fecha_id AND ae.usuario_id = i.usuario_id
        WHERE i.fecha_id = p_fecha_id
        AND i.estado = 'inscrito'
    ) subquery;

    -- ========================================
    -- Resumen de equipos (conteo por equipo)
    -- FIX: Usar color_equipo en lugar de equipo
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'equipo', color_equipo,  -- FIX: era equipo
            'numero_equipo', numero_equipo,
            'cantidad', cantidad,
            'jugadores', jugadores
        ) ORDER BY
            CASE color_equipo
                WHEN 'naranja' THEN 1
                WHEN 'verde' THEN 2
                WHEN 'azul' THEN 3
                ELSE 4
            END
    )
    INTO v_equipos_resumen
    FROM (
        SELECT
            ae.color_equipo,  -- FIX: era ae.equipo
            ae.numero_equipo,
            COUNT(*) as cantidad,
            json_agg(
                json_build_object(
                    'usuario_id', u.id,
                    'nombre_completo', u.nombre_completo
                ) ORDER BY u.nombre_completo
            ) as jugadores
        FROM asignaciones_equipos ae
        JOIN usuarios u ON u.id = ae.usuario_id
        WHERE ae.fecha_id = p_fecha_id
        GROUP BY ae.color_equipo, ae.numero_equipo  -- FIX: era ae.equipo
    ) eq_summary;

    -- ========================================
    -- Contar totales
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    SELECT COUNT(*) INTO v_total_asignados
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha', json_build_object(
                'id', v_fecha.id,
                'fecha_hora_inicio', v_fecha.fecha_hora_inicio,
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'hora_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'lugar', v_fecha.lugar,
                'duracion_horas', v_fecha.duracion_horas,
                'num_equipos', v_fecha.num_equipos,
                'estado', v_fecha.estado,
                'puede_asignar', v_fecha.estado = 'cerrada' AND v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado'
            ),
            'colores_disponibles', v_colores_disponibles,
            'jugadores', COALESCE(v_jugadores, '[]'::json),
            'equipos', COALESCE(v_equipos_resumen, '[]'::json),
            'resumen', json_build_object(
                'total_inscritos', v_total_inscritos,
                'total_asignados', v_total_asignados,
                'sin_asignar', v_total_inscritos - v_total_asignados,
                'todos_asignados', v_total_asignados >= v_total_inscritos
            )
        ),
        'message', CASE
            WHEN v_total_inscritos = 0 THEN 'No hay jugadores inscritos para esta fecha'
            WHEN v_total_asignados = 0 THEN 'Hay ' || v_total_inscritos || ' jugadores sin asignar'
            WHEN v_total_asignados < v_total_inscritos THEN
                v_total_asignados || ' de ' || v_total_inscritos || ' jugadores asignados'
            ELSE
                'Todos los ' || v_total_inscritos || ' jugadores han sido asignados a equipos'
        END
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
-- FUNCION 2: confirmar_equipos (CORREGIDA)
-- ============================================
CREATE OR REPLACE FUNCTION confirmar_equipos(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_total_inscritos INTEGER;
    v_total_asignados INTEGER;
    v_equipo_counts JSON;
    v_max_count INTEGER;
    v_min_count INTEGER;
    v_diferencia_max INTEGER;
    v_desbalanceado BOOLEAN;
    v_jugador RECORD;
    v_companeros TEXT;
    v_mensaje_equipo TEXT;
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
    -- Validacion: Parametro obligatorio
    -- ========================================
    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    -- ========================================
    -- Obtener usuario actual y validar admin
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_current_user.rol != 'admin' THEN
        v_error_hint := 'no_autorizado';
        RAISE EXCEPTION 'Solo los administradores pueden confirmar equipos';
    END IF;

    IF v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'usuario_no_aprobado';
        RAISE EXCEPTION 'Tu cuenta debe estar aprobada para realizar esta accion';
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
    -- Validar estado de la fecha
    -- ========================================
    IF v_fecha.estado != 'cerrada' THEN
        v_error_hint := 'fecha_no_cerrada';
        RAISE EXCEPTION 'Solo se pueden confirmar equipos cuando las inscripciones estan cerradas (estado actual: %)', v_fecha.estado;
    END IF;

    -- ========================================
    -- Validar que hay asignaciones
    -- ========================================
    SELECT COUNT(*) INTO v_total_asignados
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id;

    IF v_total_asignados = 0 THEN
        v_error_hint := 'sin_asignaciones';
        RAISE EXCEPTION 'No hay jugadores asignados a equipos. Primero asigna los jugadores.';
    END IF;

    -- ========================================
    -- Conteo de inscritos
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- ========================================
    -- Validar balance de equipos (advertencia, no error)
    -- FIX: Usar color_equipo en lugar de equipo
    -- ========================================
    SELECT json_agg(
        json_build_object('equipo', color_equipo, 'cantidad', cnt)
    )
    INTO v_equipo_counts
    FROM (
        SELECT color_equipo, COUNT(*) as cnt  -- FIX: era equipo
        FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
        GROUP BY color_equipo  -- FIX: era equipo
        ORDER BY color_equipo
    ) counts;

    -- Obtener max y min para calcular diferencia
    SELECT MAX(cnt), MIN(cnt)
    INTO v_max_count, v_min_count
    FROM (
        SELECT COUNT(*) as cnt
        FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
        GROUP BY color_equipo  -- FIX: era equipo
    ) eq_counts;

    v_diferencia_max := COALESCE(v_max_count - v_min_count, 0);
    v_desbalanceado := v_diferencia_max > 1;

    -- ========================================
    -- Crear notificaciones para cada jugador con equipo y companeros
    -- FIX: Usar color_equipo en lugar de equipo
    -- ========================================
    FOR v_jugador IN
        SELECT
            ae.usuario_id,
            ae.color_equipo,  -- FIX: era ae.equipo
            ae.numero_equipo,
            u.nombre_completo
        FROM asignaciones_equipos ae
        JOIN usuarios u ON u.id = ae.usuario_id
        WHERE ae.fecha_id = p_fecha_id
    LOOP
        -- Obtener lista de companeros (mismo equipo, excluyendo al jugador)
        SELECT string_agg(u.nombre_completo, ', ' ORDER BY u.nombre_completo)
        INTO v_companeros
        FROM asignaciones_equipos ae
        JOIN usuarios u ON u.id = ae.usuario_id
        WHERE ae.fecha_id = p_fecha_id
        AND ae.color_equipo = v_jugador.color_equipo  -- FIX: era ae.equipo
        AND ae.usuario_id != v_jugador.usuario_id;

        -- Construir mensaje
        v_mensaje_equipo := 'Has sido asignado al equipo ' || UPPER(v_jugador.color_equipo::TEXT) ||  -- FIX
            ' para la pichanga del ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
            ' a las ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') ||
            ' en ' || v_fecha.lugar || '.';

        IF v_companeros IS NOT NULL AND v_companeros != '' THEN
            v_mensaje_equipo := v_mensaje_equipo || ' Tus companeros: ' || v_companeros || '.';
        END IF;

        -- Insertar notificacion
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            metadata
        ) VALUES (
            v_jugador.usuario_id,
            'general',
            'Equipo asignado: ' || UPPER(v_jugador.color_equipo::TEXT),  -- FIX
            v_mensaje_equipo,
            jsonb_build_object(
                'fecha_id', p_fecha_id,
                'tipo_evento', 'asignacion_equipo',
                'equipo', v_jugador.color_equipo,  -- FIX
                'numero_equipo', v_jugador.numero_equipo,
                'companeros', v_companeros,
                'confirmado_por', v_current_user.id,
                'confirmado_por_nombre', v_current_user.nombre_completo
            )
        );
    END LOOP;

    -- ========================================
    -- Retorno exitoso con resumen
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'num_equipos', v_fecha.num_equipos,
            'total_jugadores', v_total_asignados,
            'equipos', v_equipo_counts,
            'balance', json_build_object(
                'desbalanceado', v_desbalanceado,
                'diferencia_maxima', v_diferencia_max,
                'advertencia', CASE
                    WHEN v_desbalanceado THEN
                        'Equipos desbalanceados: diferencia de ' || v_diferencia_max || ' jugadores'
                    ELSE NULL
                END
            ),
            'notificaciones_enviadas', v_total_asignados,
            'confirmado_por', v_current_user.id,
            'confirmado_por_nombre', v_current_user.nombre_completo,
            'confirmado_at', NOW() AT TIME ZONE 'America/Lima',
            'confirmado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        ),
        'message', CASE
            WHEN v_desbalanceado THEN
                'Equipos confirmados con advertencia: Los equipos estan desbalanceados (diferencia de ' ||
                v_diferencia_max || ' jugadores). Se ha notificado a ' || v_total_asignados || ' jugadores.'
            ELSE
                'Equipos confirmados exitosamente. Se ha notificado a ' || v_total_asignados || ' jugadores.'
        END
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
-- FUNCION 3: asignar_jugador_equipo (CORREGIDA)
-- ============================================
CREATE OR REPLACE FUNCTION asignar_jugador_equipo(
    p_fecha_id UUID,
    p_usuario_id UUID,
    p_equipo TEXT,  -- Ahora recibe TEXT y se convierte internamente
    p_numero_equipo INTEGER DEFAULT 1
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_usuario_inscrito BOOLEAN;
    v_asignacion_id UUID;
    v_equipo_enum color_equipo;
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
    -- Convertir texto a enum
    -- ========================================
    BEGIN
        v_equipo_enum := p_equipo::color_equipo;
    EXCEPTION
        WHEN invalid_text_representation THEN
            v_error_hint := 'equipo_invalido';
            RAISE EXCEPTION 'Equipo invalido: %. Valores permitidos: naranja, verde, azul, rojo, amarillo, blanco', p_equipo;
    END;

    -- ========================================
    -- Obtener usuario actual y validar admin
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_current_user.rol != 'admin' THEN
        v_error_hint := 'no_autorizado';
        RAISE EXCEPTION 'Solo los administradores pueden asignar equipos';
    END IF;

    IF v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'usuario_no_aprobado';
        RAISE EXCEPTION 'Tu cuenta debe estar aprobada para realizar esta accion';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- Validar estado de la fecha
    -- ========================================
    IF v_fecha.estado != 'cerrada' THEN
        v_error_hint := 'fecha_no_cerrada';
        RAISE EXCEPTION 'Solo se pueden asignar equipos cuando las inscripciones estan cerradas (estado actual: %)', v_fecha.estado;
    END IF;

    -- ========================================
    -- Validar que el usuario esta inscrito
    -- ========================================
    SELECT EXISTS (
        SELECT 1 FROM inscripciones
        WHERE fecha_id = p_fecha_id
        AND usuario_id = p_usuario_id
        AND estado = 'inscrito'
    ) INTO v_usuario_inscrito;

    IF NOT v_usuario_inscrito THEN
        v_error_hint := 'usuario_no_inscrito';
        RAISE EXCEPTION 'El usuario no esta inscrito a esta fecha';
    END IF;

    -- ========================================
    -- Insertar o actualizar asignacion
    -- Usar color_equipo (nombre correcto de la columna)
    -- ========================================
    INSERT INTO asignaciones_equipos (
        fecha_id,
        usuario_id,
        color_equipo,
        numero_equipo,
        asignado_por,
        asignado_at
    ) VALUES (
        p_fecha_id,
        p_usuario_id,
        v_equipo_enum,
        p_numero_equipo,
        v_current_user.id,
        NOW()
    )
    ON CONFLICT (fecha_id, usuario_id)
    DO UPDATE SET
        color_equipo = EXCLUDED.color_equipo,
        numero_equipo = EXCLUDED.numero_equipo,
        asignado_por = EXCLUDED.asignado_por,
        asignado_at = NOW()
    RETURNING id INTO v_asignacion_id;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'asignacion_id', v_asignacion_id,
            'fecha_id', p_fecha_id,
            'usuario_id', p_usuario_id,
            'equipo', p_equipo,
            'numero_equipo', p_numero_equipo,
            'asignado_por', v_current_user.id,
            'asignado_por_nombre', v_current_user.nombre_completo
        ),
        'message', 'Jugador asignado exitosamente al equipo ' || UPPER(p_equipo)
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
GRANT EXECUTE ON FUNCTION obtener_asignaciones TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION confirmar_equipos TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION asignar_jugador_equipo TO authenticated, service_role;

-- ============================================
-- VERIFICACION
-- ============================================
SELECT 'Funciones actualizadas exitosamente' as resultado;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
