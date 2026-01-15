-- ============================================
-- MIGRACION: Simplificacion de Roles (4 a 2)
-- Fecha: 2026-01-15
-- Descripcion: Migra el sistema de 4 roles (admin, entrenador, jugador, arbitro)
--              a solo 2 roles (admin, jugador)
-- ============================================

-- ============================================
-- PARTE 0: DIAGNOSTICO (EJECUTAR PRIMERO)
-- Copia y ejecuta SOLO esta seccion para ver usuarios afectados
-- ============================================

/*
-- QUERY DE DIAGNOSTICO: Ver usuarios con roles que seran migrados
SELECT
    id,
    nombre_completo,
    email,
    rol,
    estado,
    created_at AT TIME ZONE 'America/Lima' as fecha_registro
FROM usuarios
WHERE rol IN ('entrenador', 'arbitro', 'delegado')
ORDER BY rol, nombre_completo;

-- Conteo por rol actual
SELECT
    rol,
    COUNT(*) as cantidad
FROM usuarios
GROUP BY rol
ORDER BY rol;
*/

-- ============================================
-- PARTE 1: MIGRACION DE DATOS
-- Convertir usuarios con roles obsoletos a 'jugador'
-- ============================================

-- Migrar entrenadores a jugador
UPDATE usuarios
SET rol = 'jugador'
WHERE rol = 'entrenador';

-- Migrar arbitros a jugador
UPDATE usuarios
SET rol = 'arbitro'::rol_usuario -- Cast explicito por si existe
WHERE false; -- Por seguridad, se ejecuta solo si existe el valor

-- Intentar migrar 'arbitro' si existe en el enum
DO $$
BEGIN
    UPDATE usuarios SET rol = 'jugador' WHERE rol::text = 'arbitro';
EXCEPTION
    WHEN invalid_text_representation THEN
        NULL; -- El valor no existe en el enum, ignorar
END $$;

-- Intentar migrar 'delegado' si existe en el enum
DO $$
BEGIN
    UPDATE usuarios SET rol = 'jugador' WHERE rol::text = 'delegado';
EXCEPTION
    WHEN invalid_text_representation THEN
        NULL; -- El valor no existe en el enum, ignorar
END $$;

-- ============================================
-- PARTE 2: RECREAR ENUM CON SOLO 2 VALORES
-- PostgreSQL no permite eliminar valores de ENUM directamente
-- Se debe: 1) Crear nuevo ENUM, 2) Migrar columna, 3) Eliminar viejo
-- ============================================

-- Paso 1: Crear nuevo ENUM con solo 2 valores
CREATE TYPE rol_usuario_nuevo AS ENUM ('admin', 'jugador');

-- Paso 2: Alterar la columna para usar el nuevo tipo
ALTER TABLE usuarios
    ALTER COLUMN rol TYPE rol_usuario_nuevo
    USING rol::text::rol_usuario_nuevo;

-- Paso 3: Eliminar el ENUM viejo
DROP TYPE rol_usuario;

-- Paso 4: Renombrar el nuevo ENUM al nombre original
ALTER TYPE rol_usuario_nuevo RENAME TO rol_usuario;

-- ============================================
-- PARTE 3: ACTUALIZAR FUNCION cambiar_rol_usuario
-- Actualizar mensaje de error y logica
-- ============================================

CREATE OR REPLACE FUNCTION cambiar_rol_usuario(
    p_usuario_id UUID,
    p_nuevo_rol rol_usuario
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_usuario_destino RECORD;
    v_total_admins INT;
BEGIN
    -- Obtener usuario actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- Verificar que el usuario actual sea admin (RN-002)
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
        RAISE EXCEPTION 'Solo los administradores pueden cambiar roles de usuarios';
    END IF;

    -- Validar rol (RN-001: solo roles validos del catalogo)
    IF p_nuevo_rol IS NULL THEN
        v_error_hint := 'rol_invalido';
        RAISE EXCEPTION 'Debe especificar un rol valido';
    END IF;

    -- Verificar que el usuario destino existe
    SELECT id, rol, estado, nombre_completo, auth_user_id
    INTO v_usuario_destino
    FROM usuarios
    WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'El usuario a modificar no fue encontrado';
    END IF;

    -- Verificar auto-degradacion (RN-003)
    -- Un admin no puede quitarse a si mismo el rol de admin
    IF v_usuario_destino.id = v_current_user.id AND p_nuevo_rol != 'admin' THEN
        v_error_hint := 'auto_degradacion';
        RAISE EXCEPTION 'No puedes quitarte el rol de administrador a ti mismo';
    END IF;

    -- Verificar minimo un admin activo (RN-004)
    -- Solo aplica si estamos quitando el rol admin a alguien
    IF v_usuario_destino.rol = 'admin' AND p_nuevo_rol != 'admin' THEN
        SELECT COUNT(*) INTO v_total_admins
        FROM usuarios
        WHERE rol = 'admin'
        AND estado = 'aprobado'
        AND id != v_usuario_destino.id;

        IF v_total_admins < 1 THEN
            v_error_hint := 'ultimo_admin';
            RAISE EXCEPTION 'No se puede cambiar el rol del ultimo administrador. Debe existir al menos un administrador en el sistema';
        END IF;
    END IF;

    -- Verificar si hay cambio real
    IF v_usuario_destino.rol = p_nuevo_rol THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'usuario_id', v_usuario_destino.id,
                'nombre_completo', v_usuario_destino.nombre_completo,
                'rol_anterior', v_usuario_destino.rol,
                'rol_nuevo', p_nuevo_rol,
                'sin_cambios', true
            ),
            'message', 'El usuario ya tiene el rol especificado'
        );
    END IF;

    -- Actualizar rol (RN-005: efecto inmediato)
    UPDATE usuarios
    SET rol = p_nuevo_rol
    WHERE id = p_usuario_id;

    -- Retorno exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario_destino.id,
            'nombre_completo', v_usuario_destino.nombre_completo,
            'rol_anterior', v_usuario_destino.rol,
            'rol_nuevo', p_nuevo_rol,
            'sin_cambios', false
        ),
        'message', 'Rol de usuario actualizado exitosamente'
    );

EXCEPTION
    WHEN invalid_text_representation THEN
        -- Error cuando el valor del enum no es valido
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'INVALID_ROLE',
                'message', 'El rol especificado no es valido. Roles permitidos: admin, jugador',
                'hint', 'rol_invalido'
            )
        );
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
-- PARTE 4: PERMISOS (re-aplicar por seguridad)
-- ============================================

GRANT EXECUTE ON FUNCTION cambiar_rol_usuario TO authenticated, service_role;

-- ============================================
-- PARTE 5: COMENTARIOS ACTUALIZADOS
-- ============================================

COMMENT ON FUNCTION cambiar_rol_usuario IS 'HU-005: Cambia rol de usuario (admin/jugador) con validaciones de seguridad (RN-001 a RN-005)';

-- ============================================
-- PARTE 6: VERIFICACION POST-MIGRACION
-- Ejecuta estos queries despues de la migracion para verificar
-- ============================================

/*
-- Verificar que el ENUM solo tiene 2 valores
SELECT enumlabel
FROM pg_enum
WHERE enumtypid = 'rol_usuario'::regtype
ORDER BY enumsortorder;

-- Verificar conteo de usuarios por rol (solo debe haber admin y jugador)
SELECT rol, COUNT(*) as cantidad
FROM usuarios
GROUP BY rol
ORDER BY rol;

-- Verificar que no hay roles obsoletos
SELECT COUNT(*) as usuarios_con_rol_obsoleto
FROM usuarios
WHERE rol::text NOT IN ('admin', 'jugador');
*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
