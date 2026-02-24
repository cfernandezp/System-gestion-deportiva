-- ============================================
-- Migracion: Actualizar cuenta admin existente al nuevo sistema de celular
-- Fecha: 2026-02-20
-- Descripcion: Actualiza la cuenta del admin que fue creada con email real
--              al nuevo patron de email derivado (celular@gestiondeportiva.app)
-- ============================================

-- IMPORTANTE: Ejecutar con permisos de service_role o desde Supabase Dashboard SQL Editor

-- Paso 1: Actualizar tabla usuarios con el celular
UPDATE usuarios
SET celular = '939079213'
WHERE email = 'fer.per.cristian@gmail.com'
  AND celular IS NULL;

-- Paso 2: Actualizar email en tabla usuarios al formato derivado
UPDATE usuarios
SET email = '939079213@gestiondeportiva.app'
WHERE email = 'fer.per.cristian@gmail.com';

-- Paso 3: Actualizar email en auth.users al formato derivado
-- Esto permite que el login con celular encuentre la cuenta
UPDATE auth.users
SET email = '939079213@gestiondeportiva.app',
    raw_user_meta_data = raw_user_meta_data || '{"celular": "939079213"}'::jsonb
WHERE email = 'fer.per.cristian@gmail.com';

-- Verificar resultado
SELECT u.id, u.nombre_completo, u.email, u.celular, u.rol,
       au.email as auth_email
FROM usuarios u
JOIN auth.users au ON u.auth_user_id = au.id
WHERE u.celular = '939079213';
