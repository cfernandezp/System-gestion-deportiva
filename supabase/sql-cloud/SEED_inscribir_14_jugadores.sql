-- ============================================
-- SEED: Inscribir 14 jugadores a una fecha (2 equipos)
-- Fecha: 2026-01-30
-- ============================================
-- INSTRUCCIONES:
-- 1. Cambia el UUID de v_fecha_id por tu fecha real
-- 2. La fecha debe estar en estado 'abierta'
-- 3. Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
-- ============================================

DO $$
DECLARE
    -- ========================================
    -- VARIABLE: Cambiar este UUID por tu fecha
    -- ========================================
    v_fecha_id UUID := '09b20f4f-1f32-42a4-9829-b498488ecccf';  -- 04/02/2026 Perú
    -- ========================================

    v_usuario RECORD;
    v_inscripcion_id UUID;
    v_contador INTEGER := 0;
    v_fecha RECORD;
BEGIN
    -- Verificar que la fecha existe
    SELECT id, estado, num_equipos, costo_por_jugador, lugar,
           TO_CHAR(fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI') as fecha_formato
    INTO v_fecha
    FROM fechas WHERE id = v_fecha_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fecha no encontrada: %', v_fecha_id;
    END IF;

    RAISE NOTICE '========================================';
    RAISE NOTICE 'Fecha: % - %', v_fecha.fecha_formato, v_fecha.lugar;
    RAISE NOTICE 'Estado: % | Equipos: %', v_fecha.estado, v_fecha.num_equipos;
    RAISE NOTICE '========================================';

    -- Verificar estado abierta
    IF v_fecha.estado != 'abierta' THEN
        RAISE EXCEPTION 'La fecha debe estar ABIERTA para inscribir. Estado actual: %', v_fecha.estado;
    END IF;

    -- Inscribir los primeros 14 jugadores de prueba
    FOR v_usuario IN
        SELECT u.id, u.nombre_completo
        FROM usuarios u
        WHERE u.email LIKE 'jugador%@test.local'
        AND u.estado = 'aprobado'
        ORDER BY u.nombre_completo
        LIMIT 14  -- Solo 14 para 2 equipos
    LOOP
        -- Solo inscribir si no esta ya inscrito
        IF NOT EXISTS (
            SELECT 1 FROM inscripciones
            WHERE fecha_id = v_fecha_id
            AND usuario_id = v_usuario.id
            AND estado = 'inscrito'
        ) THEN
            -- Crear inscripcion
            INSERT INTO inscripciones (fecha_id, usuario_id, estado)
            VALUES (v_fecha_id, v_usuario.id, 'inscrito')
            RETURNING id INTO v_inscripcion_id;

            -- Crear deuda (pago pendiente)
            INSERT INTO pagos (inscripcion_id, fecha_id, usuario_id, monto, estado)
            VALUES (v_inscripcion_id, v_fecha_id, v_usuario.id, v_fecha.costo_por_jugador, 'pendiente');

            v_contador := v_contador + 1;
            RAISE NOTICE 'Inscrito #%: %', v_contador, v_usuario.nombre_completo;
        ELSE
            RAISE NOTICE 'Ya inscrito: %', v_usuario.nombre_completo;
        END IF;
    END LOOP;

    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total inscritos: % jugadores', v_contador;
    RAISE NOTICE '========================================';
END $$;

-- Verificar inscritos
SELECT
    u.nombre_completo,
    i.estado as estado_inscripcion,
    p.estado as estado_pago,
    i.created_at::date as fecha_inscripcion
FROM inscripciones i
JOIN usuarios u ON u.id = i.usuario_id
LEFT JOIN pagos p ON p.inscripcion_id = i.id
WHERE i.fecha_id = '09b20f4f-1f32-42a4-9829-b498488ecccf'  -- Cambiar UUID
AND i.estado = 'inscrito'
ORDER BY u.nombre_completo;
