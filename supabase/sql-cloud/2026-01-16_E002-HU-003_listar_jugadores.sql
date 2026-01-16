-- ============================================
-- E002-HU-003: Lista de Jugadores
-- Fecha: 2026-01-16
-- Descripcion: Funcion RPC para listar jugadores aprobados del grupo
--              con busqueda y ordenamiento
-- ============================================

-- ============================================
-- FUNCION RPC: listar_jugadores
-- Cumple todos los CA y RN de la HU
-- ============================================

DROP FUNCTION IF EXISTS listar_jugadores(TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION listar_jugadores(
    p_busqueda TEXT DEFAULT NULL,
    p_orden_campo TEXT DEFAULT 'nombre',
    p_orden_direccion TEXT DEFAULT 'asc'
)
RETURNS JSON AS $$
DECLARE
    v_current_user_id UUID;
    v_jugadores JSON;
    v_total INT;
    v_orden_sql TEXT;
    v_busqueda_limpia TEXT;
BEGIN
    -- ========================================
    -- RN-005: Solo usuarios autenticados
    -- ========================================
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'AUTH_REQUIRED',
                'message', 'Debes iniciar sesion para ver la lista de jugadores',
                'hint', 'no_autenticado'
            )
        );
    END IF;

    -- ========================================
    -- RN-004: Validar ordenamiento
    -- Solo nombre o fecha_ingreso, asc o desc
    -- ========================================
    IF p_orden_campo NOT IN ('nombre', 'fecha_ingreso') THEN
        p_orden_campo := 'nombre';
    END IF;

    IF p_orden_direccion NOT IN ('asc', 'desc') THEN
        p_orden_direccion := 'asc';
    END IF;

    -- Limpiar busqueda para RN-003 (insensible a mayusculas)
    v_busqueda_limpia := LOWER(TRIM(COALESCE(p_busqueda, '')));

    -- ========================================
    -- RN-001: Solo jugadores aprobados
    -- RN-002: Solo informacion publica
    -- RN-003: Busqueda por nombre/apodo parcial
    -- ========================================

    -- Construir JSON con jugadores filtrados y ordenados
    WITH jugadores_filtrados AS (
        SELECT
            u.id AS jugador_id,
            u.nombre_completo,
            u.apodo,
            u.posicion_preferida,
            u.foto_url,
            u.created_at AS fecha_ingreso,
            formato_fecha_espanol(u.created_at) AS fecha_ingreso_formato
        FROM usuarios u
        WHERE u.estado = 'aprobado'
          AND (
              v_busqueda_limpia = ''
              OR LOWER(u.nombre_completo) LIKE '%' || v_busqueda_limpia || '%'
              OR LOWER(COALESCE(u.apodo, '')) LIKE '%' || v_busqueda_limpia || '%'
          )
        ORDER BY
            CASE
                WHEN p_orden_campo = 'nombre' AND p_orden_direccion = 'asc'
                THEN LOWER(u.nombre_completo)
            END ASC,
            CASE
                WHEN p_orden_campo = 'nombre' AND p_orden_direccion = 'desc'
                THEN LOWER(u.nombre_completo)
            END DESC,
            CASE
                WHEN p_orden_campo = 'fecha_ingreso' AND p_orden_direccion = 'asc'
                THEN u.created_at
            END ASC,
            CASE
                WHEN p_orden_campo = 'fecha_ingreso' AND p_orden_direccion = 'desc'
                THEN u.created_at
            END DESC
    )
    SELECT
        COALESCE(
            json_agg(
                json_build_object(
                    'jugador_id', jf.jugador_id,
                    'nombre_completo', jf.nombre_completo,
                    'apodo', COALESCE(jf.apodo, 'Sin apodo'),
                    'posicion_preferida', jf.posicion_preferida,
                    'foto_url', jf.foto_url,
                    'fecha_ingreso', jf.fecha_ingreso AT TIME ZONE 'America/Lima',
                    'fecha_ingreso_formato', jf.fecha_ingreso_formato
                )
            ),
            '[]'::json
        ),
        COUNT(*)
    INTO v_jugadores, v_total
    FROM jugadores_filtrados jf;

    -- Retornar resultado exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'jugadores', v_jugadores,
            'total', v_total,
            'filtros', json_build_object(
                'busqueda', p_busqueda,
                'orden_campo', p_orden_campo,
                'orden_direccion', p_orden_direccion
            )
        ),
        'message', CASE
            WHEN v_total = 0 THEN 'No se encontraron jugadores'
            WHEN v_total = 1 THEN 'Se encontro 1 jugador'
            ELSE 'Se encontraron ' || v_total || ' jugadores'
        END
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
GRANT EXECUTE ON FUNCTION listar_jugadores(TEXT, TEXT, TEXT) TO authenticated;

-- Comentario
COMMENT ON FUNCTION listar_jugadores IS 'E002-HU-003: Lista jugadores aprobados con busqueda y ordenamiento. RN-001 a RN-005.';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
