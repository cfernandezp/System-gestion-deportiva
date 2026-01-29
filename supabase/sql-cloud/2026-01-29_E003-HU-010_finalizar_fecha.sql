-- ============================================
-- E003-HU-010: Finalizar Fecha
-- Fecha: 2026-01-29
-- Descripcion: Implementacion de funcion RPC para finalizar
--              una fecha de pichanga, completando el ciclo de vida
--              abierta -> cerrada -> en_juego -> finalizada
-- ============================================

-- ============================================
-- PARTE 1: ALTER TABLE - Agregar columnas de finalizacion
-- ============================================

-- Agregar columnas para auditoria de finalizacion (si no existen)
DO $$
BEGIN
    -- Columna finalizado_por
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'finalizado_por'
    ) THEN
        ALTER TABLE fechas ADD COLUMN finalizado_por UUID REFERENCES usuarios(id);
        COMMENT ON COLUMN fechas.finalizado_por IS 'ID del admin que finalizo la fecha';
    END IF;

    -- Columna finalizado_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'finalizado_at'
    ) THEN
        ALTER TABLE fechas ADD COLUMN finalizado_at TIMESTAMPTZ;
        COMMENT ON COLUMN fechas.finalizado_at IS 'Timestamp de finalizacion (UTC)';
    END IF;

    -- Columna comentarios_finalizacion
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'comentarios_finalizacion'
    ) THEN
        ALTER TABLE fechas ADD COLUMN comentarios_finalizacion TEXT;
        COMMENT ON COLUMN fechas.comentarios_finalizacion IS 'Observaciones opcionales del admin al finalizar';
    END IF;

    -- Columna hubo_incidente
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'hubo_incidente'
    ) THEN
        ALTER TABLE fechas ADD COLUMN hubo_incidente BOOLEAN DEFAULT FALSE;
        COMMENT ON COLUMN fechas.hubo_incidente IS 'Flag que indica si hubo algun incidente durante la pichanga';
    END IF;

    -- Columna descripcion_incidente
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'fechas'
        AND column_name = 'descripcion_incidente'
    ) THEN
        ALTER TABLE fechas ADD COLUMN descripcion_incidente TEXT;
        COMMENT ON COLUMN fechas.descripcion_incidente IS 'Descripcion del incidente si hubo_incidente = true';
    END IF;
END $$;

-- ============================================
-- PARTE 2: FUNCION RPC finalizar_fecha
-- ============================================

-- ============================================
-- Funcion: finalizar_fecha
-- Descripcion: Finaliza una fecha de pichanga, marcandola como completada
--              y registrando observaciones e incidentes opcionales
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007
-- CA: CA-001 a CA-010
-- ============================================
CREATE OR REPLACE FUNCTION finalizar_fecha(
    p_fecha_id UUID,
    p_comentarios TEXT DEFAULT NULL,
    p_hubo_incidente BOOLEAN DEFAULT FALSE,
    p_descripcion_incidente TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_total_participantes INTEGER;
    v_estado_anterior TEXT;
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
    -- RN-001: Solo admin aprobado puede finalizar
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden finalizar fechas de pichanga';
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

    -- Guardar estado anterior para la respuesta
    v_estado_anterior := v_fecha.estado::TEXT;

    -- ========================================
    -- RN-002: Solo se pueden finalizar fechas con estado 'en_juego' o 'cerrada'
    -- RN-003: No se puede finalizar una fecha ya finalizada
    -- ========================================
    IF v_fecha.estado NOT IN ('en_juego', 'cerrada') THEN
        v_error_hint := 'estado_invalido';
        IF v_fecha.estado = 'finalizada' THEN
            RAISE EXCEPTION 'Esta fecha ya ha sido finalizada. El estado "finalizada" es permanente';
        ELSIF v_fecha.estado = 'cancelada' THEN
            RAISE EXCEPTION 'No se puede finalizar una fecha cancelada';
        ELSIF v_fecha.estado = 'abierta' THEN
            RAISE EXCEPTION 'No se puede finalizar una fecha con inscripciones abiertas. Primero debe cerrar las inscripciones';
        ELSE
            RAISE EXCEPTION 'Solo se pueden finalizar fechas con estado "en_juego" o "cerrada". Estado actual: %', v_fecha.estado;
        END IF;
    END IF;

    -- ========================================
    -- RN-005: Si hubo_incidente = true, descripcion_incidente es obligatoria
    -- ========================================
    IF p_hubo_incidente = TRUE AND (p_descripcion_incidente IS NULL OR TRIM(p_descripcion_incidente) = '') THEN
        v_error_hint := 'descripcion_incidente_requerida';
        RAISE EXCEPTION 'Si se reporta un incidente, la descripcion es obligatoria';
    END IF;

    -- ========================================
    -- RN-006: Contar participantes (solo inscripciones activas)
    -- ========================================
    SELECT COUNT(*) INTO v_total_participantes
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- ========================================
    -- RN-004: Actualizar estado a 'finalizada' con auditoria
    -- RN-007: Preservar todos los datos existentes
    -- ========================================
    UPDATE fechas
    SET estado = 'finalizada',
        finalizado_por = v_current_user.id,
        finalizado_at = NOW(),
        comentarios_finalizacion = NULLIF(TRIM(COALESCE(p_comentarios, '')), ''),
        hubo_incidente = COALESCE(p_hubo_incidente, FALSE),
        descripcion_incidente = CASE
            WHEN COALESCE(p_hubo_incidente, FALSE) = TRUE THEN TRIM(p_descripcion_incidente)
            ELSE NULL
        END
    WHERE id = p_fecha_id;

    -- ========================================
    -- Notificar a todos los participantes que la fecha fue finalizada
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
            'Pichanga finalizada',
            'La pichanga del ' ||
                TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
                ' en ' || v_fecha.lugar ||
                ' ha sido finalizada. Puedes verla en tu historial de participaciones.',
            jsonb_build_object(
                'fecha_id', p_fecha_id,
                'tipo_evento', 'finalizacion_fecha',
                'finalizado_por', v_current_user.id,
                'finalizado_por_nombre', v_current_user.nombre_completo
            )
        );
    END LOOP;

    -- ========================================
    -- Retorno exitoso con resumen completo
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'estado_anterior', v_estado_anterior,
            'estado_nuevo', 'finalizada',
            'total_participantes', v_total_participantes,
            'comentarios', NULLIF(TRIM(COALESCE(p_comentarios, '')), ''),
            'hubo_incidente', COALESCE(p_hubo_incidente, FALSE),
            'descripcion_incidente', CASE
                WHEN COALESCE(p_hubo_incidente, FALSE) = TRUE THEN TRIM(p_descripcion_incidente)
                ELSE NULL
            END,
            'finalizado_por', v_current_user.id,
            'finalizado_por_nombre', v_current_user.nombre_completo,
            'finalizado_at', NOW(),
            'finalizado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        ),
        'message', 'Pichanga finalizada exitosamente' ||
            CASE
                WHEN v_total_participantes > 0 THEN
                    '. Ahora aparece en el historial de los ' || v_total_participantes || ' participantes'
                ELSE ''
            END ||
            CASE
                WHEN COALESCE(p_hubo_incidente, FALSE) = TRUE THEN
                    '. Se ha registrado un incidente'
                ELSE ''
            END || '.'
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

GRANT EXECUTE ON FUNCTION finalizar_fecha TO authenticated, service_role;

-- ============================================
-- PARTE 4: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION finalizar_fecha IS 'E003-HU-010: Finaliza una fecha de pichanga, registrando quien/cuando finalizo, comentarios opcionales e incidentes (RN-001 a RN-007, CA-001 a CA-010)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
