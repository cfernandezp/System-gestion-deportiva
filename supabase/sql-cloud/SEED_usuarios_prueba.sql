-- ============================================
-- SEED: Crear 21 usuarios de prueba
-- Fecha: 2026-01-30
-- Descripcion: Inserta 21 jugadores ficticios para testing
--              (14 para 2 equipos, 21 para 3 equipos)
-- ============================================
--
-- IMPORTANTE: Este script es SOLO para desarrollo/testing
-- NO ejecutar en produccion
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
-- ============================================

-- ============================================
-- PARTE 1: Crear 21 jugadores de prueba
-- ============================================

DO $$
DECLARE
    v_nombre TEXT;
    v_email TEXT;
    v_auth_user_id UUID;
    v_contador INTEGER;
BEGIN
    FOR v_contador IN 1..21
    LOOP
        -- Formato: "Jugador 01", "Jugador 02", etc.
        v_nombre := 'Jugador ' || LPAD(v_contador::TEXT, 2, '0');
        v_email := 'jugador' || LPAD(v_contador::TEXT, 2, '0') || '@test.local';

        -- Verificar si ya existe el email
        IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
            -- Crear usuario en auth.users
            INSERT INTO auth.users (
                id,
                instance_id,
                email,
                encrypted_password,
                email_confirmed_at,
                raw_app_meta_data,
                raw_user_meta_data,
                created_at,
                updated_at,
                role,
                aud
            ) VALUES (
                gen_random_uuid(),
                '00000000-0000-0000-0000-000000000000',
                v_email,
                crypt('TestPassword123!', gen_salt('bf')),
                NOW(),
                '{"provider": "email", "providers": ["email"]}'::jsonb,
                jsonb_build_object('nombre_completo', v_nombre),
                NOW(),
                NOW(),
                'authenticated',
                'authenticated'
            )
            RETURNING id INTO v_auth_user_id;

            -- Crear usuario en tabla usuarios (estado = aprobado para poder inscribir)
            INSERT INTO usuarios (
                auth_user_id,
                nombre_completo,
                email,
                rol,
                estado,
                created_at
            ) VALUES (
                v_auth_user_id,
                v_nombre,
                v_email,
                'jugador',
                'aprobado',
                NOW()
            );

            RAISE NOTICE 'Usuario creado: % (%)', v_nombre, v_email;
        ELSE
            RAISE NOTICE 'Usuario ya existe: %', v_email;
        END IF;
    END LOOP;

    RAISE NOTICE '=== Proceso completado: 21 jugadores creados ===';
END $$;

-- ============================================
-- PARTE 2: Verificar usuarios creados
-- ============================================

SELECT
    u.id,
    u.nombre_completo,
    u.email,
    u.rol,
    u.estado,
    u.created_at::date as fecha_creacion
FROM usuarios u
WHERE u.email LIKE '%@test.local'
ORDER BY u.nombre_completo;

-- ============================================
-- PARTE 3: Inscribir jugadores a una fecha
-- Modifica TU_FECHA_ID_AQUI con el UUID real
-- ============================================

/*
DO $$
DECLARE
    v_fecha_id UUID := 'TU_FECHA_ID_AQUI';
    v_usuario RECORD;
    v_inscripcion_id UUID;
    v_contador INTEGER := 0;
BEGIN
    -- Verificar que la fecha existe y esta abierta
    IF NOT EXISTS (SELECT 1 FROM fechas WHERE id = v_fecha_id AND estado = 'abierta') THEN
        RAISE EXCEPTION 'Fecha no encontrada o no esta abierta: %', v_fecha_id;
    END IF;

    -- Inscribir cada jugador de prueba
    FOR v_usuario IN
        SELECT u.id, u.nombre_completo
        FROM usuarios u
        WHERE u.email LIKE '%@test.local'
        AND u.estado = 'aprobado'
        ORDER BY u.nombre_completo
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
            SELECT v_inscripcion_id, v_fecha_id, v_usuario.id, f.costo_por_jugador, 'pendiente'
            FROM fechas f WHERE f.id = v_fecha_id;

            v_contador := v_contador + 1;
            RAISE NOTICE 'Inscrito: %', v_usuario.nombre_completo;
        END IF;
    END LOOP;

    RAISE NOTICE '=== Total inscritos: % ===', v_contador;
END $$;
*/

-- ============================================
-- PARTE 4: Asignar jugadores a equipos
-- Para 2 equipos: 7 jugadores por equipo (naranja, verde)
-- Para 3 equipos: 7 jugadores por equipo (naranja, verde, azul)
-- Modifica TU_FECHA_ID_AQUI con el UUID real
-- ============================================

/*
DO $$
DECLARE
    v_fecha_id UUID := 'TU_FECHA_ID_AQUI';
    v_fecha RECORD;
    v_usuario RECORD;
    v_contador INTEGER := 0;
    v_equipo color_equipo;
    v_equipos color_equipo[];
    v_jugadores_por_equipo INTEGER := 7;
    v_equipo_actual INTEGER := 1;
    v_contador_equipo INTEGER := 0;
BEGIN
    -- Obtener datos de la fecha
    SELECT id, num_equipos, estado INTO v_fecha
    FROM fechas WHERE id = v_fecha_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fecha no encontrada: %', v_fecha_id;
    END IF;

    -- La fecha debe estar 'cerrada' para asignar equipos
    IF v_fecha.estado != 'cerrada' THEN
        RAISE EXCEPTION 'La fecha debe estar cerrada para asignar equipos. Estado actual: %', v_fecha.estado;
    END IF;

    -- Definir equipos segun num_equipos
    IF v_fecha.num_equipos = 2 THEN
        v_equipos := ARRAY['naranja', 'verde']::color_equipo[];
    ELSE
        v_equipos := ARRAY['naranja', 'verde', 'azul']::color_equipo[];
    END IF;

    -- Asignar jugadores inscritos a equipos
    FOR v_usuario IN
        SELECT u.id, u.nombre_completo
        FROM usuarios u
        JOIN inscripciones i ON i.usuario_id = u.id
        WHERE i.fecha_id = v_fecha_id
        AND i.estado = 'inscrito'
        ORDER BY u.nombre_completo
    LOOP
        -- Determinar equipo actual
        v_equipo := v_equipos[v_equipo_actual];

        -- Insertar o actualizar asignacion
        INSERT INTO asignaciones_equipos (fecha_id, usuario_id, equipo)
        VALUES (v_fecha_id, v_usuario.id, v_equipo)
        ON CONFLICT (fecha_id, usuario_id)
        DO UPDATE SET equipo = v_equipo, updated_at = NOW();

        v_contador := v_contador + 1;
        v_contador_equipo := v_contador_equipo + 1;
        RAISE NOTICE 'Asignado: % -> %', v_usuario.nombre_completo, v_equipo;

        -- Rotar al siguiente equipo cada 7 jugadores
        IF v_contador_equipo >= v_jugadores_por_equipo THEN
            v_equipo_actual := v_equipo_actual + 1;
            v_contador_equipo := 0;
            IF v_equipo_actual > array_length(v_equipos, 1) THEN
                v_equipo_actual := 1; -- Volver al primer equipo si hay mas jugadores
            END IF;
        END IF;
    END LOOP;

    RAISE NOTICE '=== Total asignados: % jugadores ===', v_contador;
END $$;
*/

-- ============================================
-- PARTE 5: Consultas utiles
-- ============================================

-- Ver fechas disponibles
SELECT
    id,
    TO_CHAR(fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI') as fecha,
    lugar,
    estado,
    num_equipos,
    (SELECT COUNT(*) FROM inscripciones i WHERE i.fecha_id = f.id AND i.estado = 'inscrito') as inscritos
FROM fechas f
ORDER BY fecha_hora_inicio DESC
LIMIT 10;

-- Ver inscritos en una fecha (reemplaza TU_FECHA_ID_AQUI)
/*
SELECT
    u.nombre_completo,
    ae.equipo,
    i.created_at::date as fecha_inscripcion
FROM usuarios u
JOIN inscripciones i ON i.usuario_id = u.id
LEFT JOIN asignaciones_equipos ae ON ae.usuario_id = u.id AND ae.fecha_id = i.fecha_id
WHERE i.fecha_id = 'TU_FECHA_ID_AQUI'
AND i.estado = 'inscrito'
ORDER BY ae.equipo, u.nombre_completo;
*/

-- ============================================
-- LIMPIEZA (solo si necesitas eliminar los de prueba)
-- ============================================

/*
-- CUIDADO: Esto elimina TODOS los usuarios de prueba y sus datos relacionados

-- 1. Eliminar asignaciones de usuarios de prueba
DELETE FROM asignaciones_equipos
WHERE usuario_id IN (SELECT id FROM usuarios WHERE email LIKE '%@test.local');

-- 2. Eliminar pagos de usuarios de prueba
DELETE FROM pagos
WHERE usuario_id IN (SELECT id FROM usuarios WHERE email LIKE '%@test.local');

-- 3. Eliminar inscripciones de usuarios de prueba
DELETE FROM inscripciones
WHERE usuario_id IN (SELECT id FROM usuarios WHERE email LIKE '%@test.local');

-- 4. Eliminar notificaciones de usuarios de prueba
DELETE FROM notificaciones
WHERE usuario_id IN (SELECT id FROM usuarios WHERE email LIKE '%@test.local');

-- 5. Eliminar usuarios de tabla usuarios
DELETE FROM usuarios WHERE email LIKE '%@test.local';

-- 6. Eliminar usuarios de auth.users
DELETE FROM auth.users WHERE email LIKE '%@test.local';

SELECT 'Usuarios de prueba eliminados' as resultado;
*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
