-- ============================================
-- FIX: Corregir usuario en auth para que signInWithPassword funcione
-- Fecha: 2026-01-15
-- ============================================
--
-- PROBLEMA IDENTIFICADO:
-- ======================
-- La funcion registrar_usuario insertaba directamente en auth.users usando:
--   INSERT INTO auth.users (..., encrypted_password = crypt(password, gen_salt('bf')))
--
-- Esto causa DOS problemas:
--
-- 1. NO SE CREA REGISTRO EN auth.identities
--    Supabase Auth requiere un registro en auth.identities para cada metodo
--    de autenticacion (email, google, etc). Sin este registro, signInWithPassword()
--    falla con "Database error querying schema" porque no puede encontrar
--    la identity asociada al usuario.
--
-- 2. FORMATO DE PASSWORD INCORRECTO
--    Supabase Auth usa un formato interno especifico para encrypted_password
--    que puede diferir del formato generado por crypt() + gen_salt('bf').
--
-- SOLUCION:
-- =========
-- Opcion A (RECOMENDADA): Eliminar usuario corrupto y re-registrar via Supabase Auth
-- Opcion B: Reparar el registro agregando la identity faltante
--
-- ============================================

-- ============================================
-- OPCION A: ELIMINAR Y RE-REGISTRAR (RECOMENDADA)
-- ============================================
-- Este enfoque es mas limpio y garantiza que el usuario
-- se cree correctamente via Supabase Auth nativo.
--
-- PASO 1: Verificar el usuario afectado
-- ============================================

-- Ver estado actual del usuario en public.usuarios
SELECT
    u.id AS usuario_id,
    u.auth_user_id,
    u.nombre_completo,
    u.email,
    u.estado,
    u.rol,
    u.created_at
FROM usuarios u
WHERE u.auth_user_id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- ============================================
-- PASO 2: Verificar que NO tiene identity
-- (Este query deberia retornar 0 filas)
-- ============================================
SELECT COUNT(*) AS identities_count
FROM auth.identities
WHERE user_id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- ============================================
-- PASO 3: Guardar datos del usuario antes de eliminar
-- (Copia estos datos para re-registrar despues)
-- ============================================
SELECT
    u.nombre_completo,
    u.email,
    u.rol,
    u.estado
FROM usuarios u
WHERE u.auth_user_id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- ============================================
-- PASO 4: Eliminar usuario de AMBAS tablas
-- (La FK ON DELETE CASCADE se encarga de usuarios)
-- ============================================

-- IMPORTANTE: Ejecutar solo si confirmas que quieres eliminar
-- DELETE FROM auth.users
-- WHERE id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- ============================================
-- PASO 5: Re-registrar via el nuevo flujo
-- En Flutter:
--   1. supabase.auth.signUp(email: 'x@x.com', password: 'Password123!')
--   2. supabase.rpc('completar_registro_usuario', params: {...})
-- ============================================


-- ============================================
-- OPCION B: REPARAR EL REGISTRO EXISTENTE
-- ============================================
-- Si no quieres perder el usuario, puedes intentar crear
-- la identity manualmente. ADVERTENCIA: Esto puede no funcionar
-- si el password hash es incompatible.

-- ============================================
-- PASO B1: Obtener instance_id correcto del proyecto
-- ============================================
SELECT DISTINCT instance_id
FROM auth.users
WHERE instance_id != '00000000-0000-0000-0000-000000000000'
LIMIT 1;
-- Guarda este valor, lo necesitaras abajo

-- ============================================
-- PASO B2: Actualizar instance_id si es incorrecto
-- Reemplaza 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' con el valor real
-- ============================================
/*
UPDATE auth.users
SET instance_id = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
WHERE id = 'c832a51d-3f41-4c50-8785-3139579fbf47'
AND instance_id = '00000000-0000-0000-0000-000000000000';
*/

-- ============================================
-- PASO B3: Crear identity faltante
-- ============================================
/*
INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    id,
    jsonb_build_object(
        'sub', id::text,
        'email', email,
        'email_verified', true
    ),
    'email',
    email,  -- provider_id es el email para provider='email'
    NULL,
    created_at,
    NOW()
FROM auth.users
WHERE id = 'c832a51d-3f41-4c50-8785-3139579fbf47'
AND NOT EXISTS (
    SELECT 1 FROM auth.identities
    WHERE user_id = 'c832a51d-3f41-4c50-8785-3139579fbf47'
    AND provider = 'email'
);
*/

-- ============================================
-- PASO B4: Si el password hash es incompatible,
-- necesitas resetear la contrasena via email o
-- eliminar y re-crear el usuario.
-- ============================================

-- ============================================
-- SCRIPT AUTOMATICO: Reparar TODOS los usuarios sin identity
-- ============================================
-- ADVERTENCIA: Solo ejecutar si entiendes las implicaciones

/*
-- Crear identities para usuarios que no tienen
INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    au.id,
    jsonb_build_object(
        'sub', au.id::text,
        'email', au.email,
        'email_verified', CASE WHEN au.email_confirmed_at IS NOT NULL THEN true ELSE false END
    ),
    'email',
    au.email,
    NULL,
    au.created_at,
    NOW()
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM auth.identities ai
    WHERE ai.user_id = au.id
    AND ai.provider = 'email'
);
*/

-- ============================================
-- VERIFICACION FINAL
-- Despues de aplicar el fix, verificar que la identity existe
-- ============================================
/*
SELECT
    au.id,
    au.email,
    ai.provider,
    ai.provider_id,
    ai.identity_data
FROM auth.users au
LEFT JOIN auth.identities ai ON au.id = ai.user_id
WHERE au.id = 'c832a51d-3f41-4c50-8785-3139579fbf47';
*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
