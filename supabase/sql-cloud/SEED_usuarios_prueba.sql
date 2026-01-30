-- ============================================
-- SEED: Crear 20 usuarios de prueba
-- Fecha: 2026-01-29
-- Descripcion: Inserta usuarios ficticios para testing
-- ============================================
--
-- IMPORTANTE: Este script es SOLO para desarrollo/testing
-- NO ejecutar en produccion
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
-- ============================================

-- ============================================
-- PARTE 1: Crear usuarios en auth.users (Supabase Auth)
-- ============================================

-- Nota: Los usuarios creados aqui NO podran hacer login real
-- porque no tienen password hash valido. Son solo para testing de datos.

DO $$
DECLARE
    v_nombres TEXT[] := ARRAY[
        'Carlos Rodriguez', 'Miguel Torres', 'Jose Garcia', 'Luis Martinez',
        'Pedro Sanchez', 'Juan Perez', 'Diego Flores', 'Andres Lopez',
        'Ricardo Vargas', 'Fernando Castro', 'Pablo Mendoza', 'Oscar Ruiz',
        'Eduardo Diaz', 'Roberto Silva', 'Marco Gonzalez', 'Daniel Herrera',
        'Alejandro Reyes', 'Victor Morales', 'Sergio Jimenez', 'Antonio Romero'
    ];
    v_nombre TEXT;
    v_email TEXT;
    v_auth_user_id UUID;
    v_contador INTEGER := 0;
BEGIN
    FOREACH v_nombre IN ARRAY v_nombres
    LOOP
        v_contador := v_contador + 1;
        v_email := 'jugador' || v_contador || '@test.local';

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

            -- Crear usuario en tabla usuarios
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

    RAISE NOTICE '=== Proceso completado: % usuarios procesados ===', v_contador;
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
ORDER BY u.created_at DESC
LIMIT 25;

-- ============================================
-- PARTE 3 (OPCIONAL): Inscribir todos a una fecha
-- Descomenta y modifica el UUID de la fecha si quieres
-- ============================================

/*
-- Reemplaza 'TU_FECHA_ID_AQUI' con el UUID de la fecha real
DO $$
DECLARE
    v_fecha_id UUID := 'TU_FECHA_ID_AQUI';
    v_usuario RECORD;
    v_contador INTEGER := 0;
BEGIN
    -- Verificar que la fecha existe
    IF NOT EXISTS (SELECT 1 FROM fechas WHERE id = v_fecha_id) THEN
        RAISE EXCEPTION 'Fecha no encontrada: %', v_fecha_id;
    END IF;

    -- Inscribir cada usuario de prueba
    FOR v_usuario IN
        SELECT id, nombre_completo
        FROM usuarios
        WHERE email LIKE '%@test.local'
        AND estado = 'aprobado'
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
            VALUES (v_fecha_id, v_usuario.id, 'inscrito');

            -- Crear deuda
            INSERT INTO pagos (fecha_id, usuario_id, monto, estado)
            SELECT v_fecha_id, v_usuario.id, f.costo_por_jugador, 'pendiente'
            FROM fechas f WHERE f.id = v_fecha_id;

            v_contador := v_contador + 1;
            RAISE NOTICE 'Inscrito: %', v_usuario.nombre_completo;
        END IF;
    END LOOP;

    RAISE NOTICE '=== Total inscritos: % ===', v_contador;
END $$;
*/

-- ============================================
-- PARTE 4: Consulta para obtener ID de fechas
-- ============================================

SELECT
    id,
    TO_CHAR(fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI') as fecha,
    lugar,
    estado,
    (SELECT COUNT(*) FROM inscripciones i WHERE i.fecha_id = f.id AND i.estado = 'inscrito') as inscritos
FROM fechas f
WHERE estado IN ('abierta', 'cerrada')
ORDER BY fecha_hora_inicio DESC
LIMIT 5;

-- ============================================
-- LIMPIEZA (solo si necesitas eliminar los de prueba)
-- ============================================

/*
-- CUIDADO: Esto elimina TODOS los usuarios de prueba y sus datos relacionados

-- 1. Eliminar inscripciones de usuarios de prueba
DELETE FROM inscripciones
WHERE usuario_id IN (SELECT id FROM usuarios WHERE email LIKE '%@test.local');

-- 2. Eliminar pagos de usuarios de prueba
DELETE FROM pagos
WHERE usuario_id IN (SELECT id FROM usuarios WHERE email LIKE '%@test.local');

-- 3. Eliminar asignaciones de usuarios de prueba
DELETE FROM asignaciones_equipos
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
