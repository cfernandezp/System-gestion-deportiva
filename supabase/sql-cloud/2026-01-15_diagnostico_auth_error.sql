-- ============================================
-- DIAGNOSTICO: Error "Database error querying schema"
-- Fecha: 2026-01-15
-- Descripcion: Script para diagnosticar por que signInWithPassword()
--              falla con error 500 "Database error querying schema"
-- ============================================

-- ============================================
-- IMPORTANTE: EJECUTAR ESTAS CONSULTAS UNA POR UNA
-- Y COMPARTIR LOS RESULTADOS
-- ============================================

-- ============================================
-- 1. VERIFICAR TRIGGERS EN auth.users
-- Si hay triggers custom, pueden causar el error
-- ============================================
SELECT
    tgname AS trigger_name,
    tgtype AS trigger_type,
    proname AS function_name,
    nspname AS function_schema
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_namespace pn ON p.pronamespace = pn.oid
WHERE n.nspname = 'auth'
AND c.relname = 'users'
AND NOT t.tgisinternal;

-- ============================================
-- 2. VERIFICAR TRIGGERS EN public.usuarios
-- Triggers en tabla usuarios pueden ejecutarse al hacer login
-- ============================================
SELECT
    tgname AS trigger_name,
    tgtype AS trigger_type,
    proname AS function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE n.nspname = 'public'
AND c.relname = 'usuarios'
AND NOT t.tgisinternal;

-- ============================================
-- 3. VERIFICAR EL REGISTRO ESPECIFICO EN auth.users
-- Verificar si el usuario tiene todos los campos necesarios
-- ============================================
SELECT
    id,
    email,
    email_confirmed_at,
    phone_confirmed_at,
    confirmation_token IS NOT NULL AS has_confirmation_token,
    recovery_token IS NOT NULL AS has_recovery_token,
    aud,
    role,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    instance_id,
    encrypted_password IS NOT NULL AS has_password,
    LENGTH(encrypted_password) AS password_length
FROM auth.users
WHERE id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- ============================================
-- 4. VERIFICAR instance_id CORRECTO
-- Obtener el instance_id real del proyecto
-- ============================================
SELECT DISTINCT instance_id
FROM auth.users
WHERE instance_id != '00000000-0000-0000-0000-000000000000'
LIMIT 5;

-- ============================================
-- 5. VERIFICAR SI HAY USUARIOS CON instance_id INCORRECTO
-- Usuarios creados manualmente pueden tener instance_id malo
-- ============================================
SELECT id, email, instance_id, created_at
FROM auth.users
WHERE instance_id = '00000000-0000-0000-0000-000000000000';

-- ============================================
-- 6. VERIFICAR IDENTITIES DEL USUARIO
-- Supabase Auth usa la tabla auth.identities
-- Si falta el registro de identity, el login falla
-- ============================================
SELECT
    i.id,
    i.user_id,
    i.identity_data,
    i.provider,
    i.provider_id,
    i.last_sign_in_at,
    i.created_at,
    i.updated_at
FROM auth.identities i
WHERE i.user_id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- ============================================
-- 7. VERIFICAR SESIONES EXISTENTES
-- ============================================
SELECT
    id,
    user_id,
    created_at,
    updated_at,
    aal,
    factor_id
FROM auth.sessions
WHERE user_id = 'c832a51d-3f41-4c50-8785-3139579fbf47';

-- ============================================
-- 8. VERIFICAR CONFIGURACION DE AUTH HOOKS
-- Si hay funciones custom que se ejecutan en auth
-- ============================================
SELECT
    hook_table_id,
    hook_name,
    hook_function_schema,
    hook_function_name,
    created_at
FROM auth.flow_state
LIMIT 10;

-- ============================================
-- 9. VERIFICAR SI HAY EXTENSIONES REQUERIDAS
-- pgcrypto es necesaria para crypt()
-- ============================================
SELECT
    extname,
    extversion
FROM pg_extension
WHERE extname IN ('pgcrypto', 'uuid-ossp', 'pgjwt');

-- ============================================
-- 10. COMPARAR CON UN USUARIO CREADO POR SUPABASE AUTH NATIVO
-- Si hay otros usuarios en el sistema, comparar estructura
-- ============================================
SELECT
    id,
    email,
    instance_id,
    aud,
    role,
    LENGTH(encrypted_password) AS password_length,
    raw_app_meta_data,
    confirmation_token IS NOT NULL AS has_confirmation,
    created_at
FROM auth.users
LIMIT 5;

-- ============================================
-- FIN DEL DIAGNOSTICO
-- ============================================
