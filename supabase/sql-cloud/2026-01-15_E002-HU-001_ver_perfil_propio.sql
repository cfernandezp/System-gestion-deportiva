-- ============================================
-- E002-HU-001: Ver Perfil Propio
-- Fecha: 2026-01-15
-- Descripcion: Extiende tabla usuarios con campos de perfil
--              y crea funcion RPC para obtener perfil propio
-- ============================================

-- ============================================
-- PARTE 1: TIPO ENUM PARA POSICIONES
-- ============================================

-- Tipo ENUM para posiciones de futbol (RN-004)
DO $$ BEGIN
    CREATE TYPE posicion_jugador AS ENUM (
        'arquero',
        'defensa',
        'mediocampista',
        'delantero'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- PARTE 2: EXTENDER TABLA USUARIOS
-- ============================================

-- Agregar columnas de perfil a la tabla usuarios existente
-- Campos obligatorios adicionales: apodo (RN-002)
-- Campos opcionales: telefono, posicion_preferida, foto_url (RN-003)

ALTER TABLE usuarios
ADD COLUMN IF NOT EXISTS apodo VARCHAR(50);

ALTER TABLE usuarios
ADD COLUMN IF NOT EXISTS telefono VARCHAR(20);

ALTER TABLE usuarios
ADD COLUMN IF NOT EXISTS posicion_preferida posicion_jugador;

ALTER TABLE usuarios
ADD COLUMN IF NOT EXISTS foto_url TEXT;

-- Actualizar apodo con valor por defecto basado en nombre_completo para registros existentes
UPDATE usuarios
SET apodo = SPLIT_PART(nombre_completo, ' ', 1)
WHERE apodo IS NULL;

-- Comentarios de documentacion
COMMENT ON COLUMN usuarios.apodo IS 'E002-HU-001: Apodo/alias del jugador (obligatorio para perfil)';
COMMENT ON COLUMN usuarios.telefono IS 'E002-HU-001: Telefono de contacto (opcional)';
COMMENT ON COLUMN usuarios.posicion_preferida IS 'E002-HU-001: Posicion preferida de juego (opcional)';
COMMENT ON COLUMN usuarios.foto_url IS 'E002-HU-001: URL de la foto de perfil (opcional)';

-- ============================================
-- PARTE 3: FUNCION RPC - OBTENER PERFIL PROPIO
-- ============================================

-- ============================================
-- Funcion: obtener_perfil_propio
-- Descripcion: Obtiene el perfil del usuario autenticado
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005
-- CA: CA-001, CA-002, CA-003
-- ============================================
CREATE OR REPLACE FUNCTION obtener_perfil_propio()
RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_usuario RECORD;
    v_antiguedad_texto TEXT;
    v_meses_antiguedad INT;
    v_dias_antiguedad INT;
BEGIN
    -- RN-001: Obtener usuario autenticado actual
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para ver tu perfil';
    END IF;

    -- Obtener datos del perfil (solo el propio - RN-001)
    SELECT
        id,
        auth_user_id,
        nombre_completo,
        COALESCE(apodo, 'Dato pendiente de completar') as apodo,
        email,
        COALESCE(telefono, NULL) as telefono,
        posicion_preferida,
        COALESCE(foto_url, NULL) as foto_url,
        created_at,
        estado,
        rol
    INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro tu perfil en el sistema';
    END IF;

    -- RN-005: Calcular antiguedad
    v_meses_antiguedad := EXTRACT(MONTH FROM AGE(NOW(), v_usuario.created_at))::INT
                        + (EXTRACT(YEAR FROM AGE(NOW(), v_usuario.created_at))::INT * 12);
    v_dias_antiguedad := EXTRACT(DAY FROM AGE(NOW(), v_usuario.created_at))::INT;

    IF v_meses_antiguedad >= 12 THEN
        v_antiguedad_texto := (v_meses_antiguedad / 12)::TEXT || ' ano(s)';
    ELSIF v_meses_antiguedad >= 1 THEN
        v_antiguedad_texto := v_meses_antiguedad::TEXT || ' mes(es)';
    ELSE
        v_antiguedad_texto := v_dias_antiguedad::TEXT || ' dia(s)';
    END IF;

    -- Retornar perfil completo
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario.id,
            'nombre_completo', v_usuario.nombre_completo,
            'apodo', v_usuario.apodo,
            'email', v_usuario.email,
            'telefono', v_usuario.telefono,
            'posicion_preferida', v_usuario.posicion_preferida,
            'foto_url', v_usuario.foto_url,
            'fecha_ingreso', v_usuario.created_at AT TIME ZONE 'America/Lima',
            'fecha_ingreso_formato', TO_CHAR(v_usuario.created_at AT TIME ZONE 'America/Lima', 'DD "de" TMMonth "de" YYYY'),
            'antiguedad', v_antiguedad_texto,
            'estado', v_usuario.estado,
            'rol', v_usuario.rol
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
                'hint', COALESCE(v_error_hint, 'unknown')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PARTE 4: PERMISOS
-- ============================================

-- Permisos para funcion RPC
GRANT EXECUTE ON FUNCTION obtener_perfil_propio TO authenticated;

-- ============================================
-- PARTE 5: COMENTARIOS
-- ============================================

COMMENT ON FUNCTION obtener_perfil_propio IS 'E002-HU-001: Obtiene perfil propio del usuario autenticado (RN-001 a RN-005, CA-001 a CA-003)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
