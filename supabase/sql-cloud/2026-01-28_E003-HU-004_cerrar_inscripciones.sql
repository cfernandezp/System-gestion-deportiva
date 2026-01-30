-- ============================================
-- E003-HU-004: Cerrar Inscripciones
-- Fecha: 2026-01-28
-- Descripcion: Implementacion de funciones RPC para cerrar y reabrir
--              inscripciones de fechas de pichanga con auditoria
-- ============================================

-- ============================================
-- PARTE 1: ALTER TABLE - Agregar columnas de auditoria
-- ============================================

-- Agregar columnas para auditoria de cierre (si no existen)
DO $$
BEGIN
    -- Columna cerrado_por
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'cerrado_por'
    ) THEN
        ALTER TABLE fechas ADD COLUMN cerrado_por UUID REFERENCES usuarios(id);
        COMMENT ON COLUMN fechas.cerrado_por IS 'ID del admin que cerro las inscripciones';
    END IF;

    -- Columna cerrado_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'cerrado_at'
    ) THEN
        ALTER TABLE fechas ADD COLUMN cerrado_at TIMESTAMPTZ;
        COMMENT ON COLUMN fechas.cerrado_at IS 'Timestamp de cierre de inscripciones (UTC)';
    END IF;

    -- Columna reabierto_por
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'reabierto_por'
    ) THEN
        ALTER TABLE fechas ADD COLUMN reabierto_por UUID REFERENCES usuarios(id);
        COMMENT ON COLUMN fechas.reabierto_por IS 'ID del admin que reabrio las inscripciones';
    END IF;

    -- Columna reabierto_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'reabierto_at'
    ) THEN
        ALTER TABLE fechas ADD COLUMN reabierto_at TIMESTAMPTZ;
        COMMENT ON COLUMN fechas.reabierto_at IS 'Timestamp de reapertura de inscripciones (UTC)';
    END IF;
END $$;

-- ============================================
-- PARTE 2: FUNCION RPC cerrar_inscripciones
-- ============================================

-- ============================================
-- Funcion: cerrar_inscripciones
-- Descripcion: Cierra las inscripciones de una fecha de pichanga
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-006
-- CA: CA-001, CA-002, CA-003, CA-004, CA-005, CA-007
-- ============================================
CREATE OR REPLACE FUNCTION cerrar_inscripciones(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_total_inscritos INTEGER;
    v_advertencia_minimo BOOLEAN;
    v_formato_juego TEXT;
    v_inscrito RECORD;
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
    -- RN-001: Solo admin aprobado puede cerrar inscripciones
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden cerrar inscripciones';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos,
           costo_por_jugador, estado, created_by
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- RN-002: Solo se pueden cerrar fechas con estado 'abierta'
    -- ========================================
    IF v_fecha.estado != 'abierta' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'Solo se pueden cerrar fechas con estado "abierta". Estado actual: %', v_fecha.estado;
    END IF;

    -- ========================================
    -- RN-003: Contar inscritos activos y advertir si < 6
    -- (No es bloqueante, solo advertencia)
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    v_advertencia_minimo := v_total_inscritos < 6;

    -- ========================================
    -- Determinar formato de juego para el resumen
    -- ========================================
    v_formato_juego := CASE
        WHEN v_fecha.num_equipos = 2 THEN '2 equipos'
        WHEN v_fecha.num_equipos = 3 THEN '3 equipos'
        ELSE v_fecha.num_equipos || ' equipos'
    END;

    -- ========================================
    -- RN-004: Actualizar estado a 'cerrada' con auditoria
    -- ========================================
    UPDATE fechas
    SET estado = 'cerrada',
        cerrado_por = v_current_user.id,
        cerrado_at = NOW()
    WHERE id = p_fecha_id;

    -- ========================================
    -- CA-007: Crear notificaciones para inscritos
    -- Mensaje: "Inscripciones cerradas. Pronto se asignaran equipos"
    -- ========================================
    FOR v_inscrito IN
        SELECT i.usuario_id, u.nombre_completo
        FROM inscripciones i
        JOIN usuarios u ON u.id = i.usuario_id
        WHERE i.fecha_id = p_fecha_id
        AND i.estado = 'inscrito'
    LOOP
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            metadata
        ) VALUES (
            v_inscrito.usuario_id,
            'general',
            'Inscripciones cerradas',
            'Las inscripciones para la pichanga del ' ||
                TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
                ' a las ' ||
                TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') ||
                ' han sido cerradas. Pronto se asignaran los equipos.',
            jsonb_build_object(
                'fecha_id', p_fecha_id,
                'tipo_evento', 'cierre_inscripciones',
                'cerrado_por', v_current_user.id,
                'cerrado_por_nombre', v_current_user.nombre_completo,
                'total_inscritos', v_total_inscritos
            )
        );
    END LOOP;

    -- ========================================
    -- Retorno exitoso con resumen
    -- CA-002: Resumen con cantidad de inscritos y formato
    -- CA-003: Advertencia si < 6 jugadores (no bloqueante)
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'estado_anterior', 'abierta',
            'estado_nuevo', 'cerrada',
            'total_inscritos', v_total_inscritos,
            'formato_juego', v_formato_juego,
            'advertencia_minimo', v_advertencia_minimo,
            'cerrado_por', v_current_user.id,
            'cerrado_por_nombre', v_current_user.nombre_completo,
            'cerrado_at', NOW() AT TIME ZONE 'America/Lima',
            'cerrado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        ),
        'message', CASE
            WHEN v_advertencia_minimo THEN
                'Inscripciones cerradas con advertencia: Solo hay ' || v_total_inscritos ||
                ' jugadores. Se recomiendan minimo 6. Se ha notificado a los inscritos.'
            ELSE
                'Inscripciones cerradas exitosamente con ' || v_total_inscritos ||
                ' jugadores para ' || v_formato_juego || '. Se ha notificado a los inscritos.'
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
-- PARTE 3: FUNCION RPC reabrir_inscripciones
-- ============================================

-- ============================================
-- Funcion: reabrir_inscripciones
-- Descripcion: Reabre las inscripciones de una fecha cerrada
-- Reglas: RN-001, RN-005, RN-006
-- CA: CA-006
-- ============================================
CREATE OR REPLACE FUNCTION reabrir_inscripciones(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_total_inscritos INTEGER;
    v_asignaciones_eliminadas INTEGER;
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
    -- RN-001: Solo admin aprobado puede reabrir inscripciones
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden reabrir inscripciones';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos,
           costo_por_jugador, estado, created_by, cerrado_por, cerrado_at
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- RN-005: Solo se pueden reabrir fechas con estado 'cerrada'
    -- No se permite reabrir si esta en_juego o finalizada
    -- ========================================
    IF v_fecha.estado != 'cerrada' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'Solo se pueden reabrir fechas con estado "cerrada". Estado actual: %', v_fecha.estado;
    END IF;

    -- ========================================
    -- RN-005: Eliminar asignaciones de equipo si existen
    -- La tabla asignaciones_equipos se creara en HU futura
    -- Verificamos si existe la tabla antes de intentar eliminar
    -- ========================================
    v_asignaciones_eliminadas := 0;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'asignaciones_equipos'
    ) THEN
        -- Eliminar asignaciones de equipo para esta fecha
        DELETE FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id;

        GET DIAGNOSTICS v_asignaciones_eliminadas = ROW_COUNT;
    END IF;

    -- ========================================
    -- RN-006: Las inscripciones existentes se mantienen
    -- Las deudas permanecen activas
    -- Solo cambiamos el estado de la fecha
    -- ========================================

    -- ========================================
    -- Actualizar estado a 'abierta' con auditoria
    -- ========================================
    UPDATE fechas
    SET estado = 'abierta',
        reabierto_por = v_current_user.id,
        reabierto_at = NOW()
    WHERE id = p_fecha_id;

    -- ========================================
    -- Contar inscritos actuales (para informar en respuesta)
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'estado_anterior', 'cerrada',
            'estado_nuevo', 'abierta',
            'total_inscritos', v_total_inscritos,
            'inscripciones_mantenidas', true,
            'deudas_mantenidas', true,
            'asignaciones_eliminadas', v_asignaciones_eliminadas,
            'reabierto_por', v_current_user.id,
            'reabierto_por_nombre', v_current_user.nombre_completo,
            'reabierto_at', NOW() AT TIME ZONE 'America/Lima',
            'reabierto_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        ),
        'message', 'Inscripciones reabiertas exitosamente. Se mantienen ' || v_total_inscritos ||
            ' inscripciones y sus deudas.' ||
            CASE
                WHEN v_asignaciones_eliminadas > 0 THEN
                    ' Se eliminaron ' || v_asignaciones_eliminadas || ' asignaciones de equipo.'
                ELSE ''
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
-- PARTE 4: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION cerrar_inscripciones TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION reabrir_inscripciones TO authenticated, service_role;

-- ============================================
-- PARTE 5: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION cerrar_inscripciones IS 'E003-HU-004: Cierra inscripciones de una fecha (RN-001 a RN-004, RN-006, CA-001 a CA-007)';
COMMENT ON FUNCTION reabrir_inscripciones IS 'E003-HU-004: Reabre inscripciones de una fecha cerrada (RN-001, RN-005, RN-006, CA-006)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
