-- ============================================
-- FIX: Crear auth.identities faltante para usuario
-- Fecha: 2026-01-15
-- Descripcion: Agrega el registro en auth.identities que falta
--              para que signInWithPassword() funcione
-- ============================================

-- ============================================
-- DIAGNOSTICO PRIMERO (ejecutar estos selects)
-- ============================================

-- 1. Ver si el usuario existe en auth.users
SELECT id, email, instance_id, aud, role, created_at
FROM auth.users
WHERE id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- 2. Ver si tiene identity (deberia estar vacio si es el problema)
SELECT id, user_id, provider, provider_id, created_at
FROM auth.identities
WHERE user_id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- 3. Obtener el instance_id correcto del proyecto
SELECT DISTINCT instance_id
FROM auth.users
WHERE instance_id != '00000000-0000-0000-0000-000000000000'
LIMIT 1;

-- ============================================
-- FIX PARTE 1: Actualizar instance_id si es 00000...
-- ============================================
-- Primero obtener el instance_id correcto con el query anterior,
-- luego ejecutar este UPDATE reemplazando el UUID:

-- NOTA: Ejecuta primero el SELECT de arriba para obtener el instance_id real
-- Luego descomenta y ejecuta este UPDATE:

/*
UPDATE auth.users
SET instance_id = (
    SELECT DISTINCT instance_id
    FROM auth.users
    WHERE instance_id != '00000000-0000-0000-0000-000000000000'
    LIMIT 1
)
WHERE id = 'c832a51d-3f41-4c50-8785-3139579fbf47'
AND instance_id = '00000000-0000-0000-0000-000000000000';
*/

-- ============================================
-- FIX PARTE 2: Crear identity faltante
-- ============================================
-- Este es el registro que Supabase Auth necesita para autenticar

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
        'email_verified', true,
        'phone_verified', false
    ),
    'email',
    au.id::text,  -- En Supabase, provider_id para email es el user_id
    NULL,
    au.created_at,
    NOW()
FROM auth.users au
WHERE au.id = 'c832a51d-3f41-4c50-8785-3139579fbf47'
AND NOT EXISTS (
    SELECT 1 FROM auth.identities
    WHERE user_id = 'c832a51d-3f41-4c50-8785-3139579fbf47'
    AND provider = 'email'
);

-- ============================================
-- VERIFICACION: Confirmar que se creo la identity
-- ============================================
SELECT
    au.id AS user_id,
    au.email,
    ai.id AS identity_id,
    ai.provider,
    ai.provider_id,
    ai.identity_data
FROM auth.users au
LEFT JOIN auth.identities ai ON au.id = ai.user_id
WHERE au.id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- ============================================
-- SI AUN FALLA: El problema puede ser el password hash
-- ============================================
-- Si despues de crear la identity el login sigue fallando,
-- el problema es que el encrypted_password fue generado con
-- crypt() que no es compatible con el formato interno de GoTrue.
--
-- En ese caso, las opciones son:
-- 1. Usar "Forgot Password" para que el usuario resetee su contrasena
-- 2. Eliminar el usuario y re-registrar con supabase.auth.signUp()
--
-- Para la opcion 2:
/*
-- Eliminar usuario (CASCADE eliminara el registro en public.usuarios)
DELETE FROM auth.users WHERE id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- Luego el usuario se registra de nuevo desde la app:
-- await supabase.auth.signUp(email: '...', password: '...');
-- await supabase.rpc('completar_registro_usuario', params: {...});
*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
