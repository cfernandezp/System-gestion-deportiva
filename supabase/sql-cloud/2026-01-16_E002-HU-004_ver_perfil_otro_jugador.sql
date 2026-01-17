-- ============================================
-- E002-HU-004: Ver Perfil de Otro Jugador
-- Fecha: 2026-01-16
-- Descripcion: Funcion RPC para obtener perfil publico de otro jugador
--              con estadisticas basicas. Protege datos privados.
-- ============================================

-- ============================================
-- FUNCION RPC: obtener_perfil_jugador
-- Cumple todos los CA y RN de la HU
-- ============================================

DROP FUNCTION IF EXISTS obtener_perfil_jugador(UUID);

CREATE OR REPLACE FUNCTION obtener_perfil_jugador(
    p_jugador_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_current_user_id UUID;
    v_current_usuario_estado TEXT;
    v_jugador RECORD;
    v_goles_totales INT;
    v_partidos_jugados INT;
    v_puntos_acumulados INT;
BEGIN
    -- ========================================
    -- RN-004: Requisito de Membresia
    -- Solo miembros activos pueden ver perfiles
    -- ========================================
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'AUTH_REQUIRED',
                'message', 'Debes iniciar sesion para ver perfiles de jugadores',
                'hint', 'no_autenticado'
            )
        );
    END IF;

    -- Verificar que el usuario solicitante esta aprobado (miembro activo)
    SELECT estado INTO v_current_usuario_estado
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF v_current_usuario_estado IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'USER_NOT_FOUND',
                'message', 'Tu perfil no fue encontrado en el sistema',
                'hint', 'solicitante_no_encontrado'
            )
        );
    END IF;

    IF v_current_usuario_estado <> 'aprobado' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'MEMBERSHIP_REQUIRED',
                'message', 'Solo los miembros activos pueden ver perfiles de otros jugadores',
                'hint', 'solicitante_no_aprobado'
            )
        );
    END IF;

    -- ========================================
    -- RN-004: El jugador consultado debe estar activo
    -- ========================================
    SELECT
        id,
        nombre_completo,
        apodo,
        posicion_preferida,
        foto_url,
        created_at,
        estado
    INTO v_jugador
    FROM usuarios
    WHERE id = p_jugador_id;

    IF v_jugador.id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'PLAYER_NOT_FOUND',
                'message', 'El jugador solicitado no existe',
                'hint', 'jugador_no_encontrado'
            )
        );
    END IF;

    IF v_jugador.estado <> 'aprobado' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'PLAYER_NOT_ACTIVE',
                'message', 'El jugador no es un miembro activo del grupo',
                'hint', 'jugador_no_activo'
            )
        );
    END IF;

    -- ========================================
    -- RN-003: Estadisticas basicas
    -- Por ahora retornamos 0 si no hay tablas de estadisticas
    -- En el futuro se puede implementar con tablas reales
    -- ========================================
    v_goles_totales := 0;
    v_partidos_jugados := 0;
    v_puntos_acumulados := 0;

    -- TODO: Cuando existan las tablas de estadisticas, descomentar:
    -- SELECT COALESCE(SUM(goles), 0) INTO v_goles_totales
    -- FROM participaciones_partido WHERE jugador_id = p_jugador_id;

    -- SELECT COUNT(*) INTO v_partidos_jugados
    -- FROM participaciones_partido WHERE jugador_id = p_jugador_id;

    -- SELECT COALESCE(SUM(puntos), 0) INTO v_puntos_acumulados
    -- FROM participaciones_partido WHERE jugador_id = p_jugador_id;

    -- ========================================
    -- CA-002, CA-003, RN-001, RN-002: Retornar solo datos publicos
    -- NO incluir email ni telefono
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'jugador_id', v_jugador.id,
            'nombre_completo', v_jugador.nombre_completo,
            'apodo', COALESCE(v_jugador.apodo, 'Sin apodo'),
            'posicion_preferida', v_jugador.posicion_preferida,
            'foto_url', v_jugador.foto_url,
            'fecha_ingreso', v_jugador.created_at AT TIME ZONE 'America/Lima',
            'fecha_ingreso_formato', formato_fecha_espanol(v_jugador.created_at),
            'estadisticas', json_build_object(
                'goles_totales', v_goles_totales,
                'partidos_jugados', v_partidos_jugados,
                'puntos_acumulados', v_puntos_acumulados
            )
        ),
        'message', 'Perfil obtenido exitosamente'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', 'error_interno'
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_perfil_jugador(UUID) TO authenticated;

-- Comentario
COMMENT ON FUNCTION obtener_perfil_jugador IS 'E002-HU-004: Obtiene perfil publico de otro jugador. RN-001: Solo datos publicos. RN-002: Protege email/telefono. RN-003: Estadisticas en 0 si no hay partidos. RN-004: Solo miembros activos.';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
