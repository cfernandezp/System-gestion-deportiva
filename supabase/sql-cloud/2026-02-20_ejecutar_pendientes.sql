-- ============================================
-- SCRIPT CONSOLIDADO: Pendientes de ejecucion
-- Fecha: 2026-02-20
-- Descripcion: Agrupa TODOS los scripts SQL pendientes de ejecutar
--              en Supabase Cloud, en el orden correcto.
--
-- CONTENIDO:
--   PARTE 1: Fix registrar_administrador (enums corregidos)
--   PARTE 2: E000-HU-002 pasos 3-8 (plan_id, trigger, RPCs, RLS)
--
-- NOTA: Los pasos 1-2 de E000-HU-002 (tabla planes + seed data)
--       YA fueron ejecutados exitosamente. NO se incluyen aqui.
-- ============================================

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- PARTE 1: Fix registrar_administrador
-- Problema original: usaba 'activo' (no existe) y 'administrador' (no existe)
-- Correccion: 'activo' -> 'aprobado', 'administrador' -> 'admin'
-- Enums validos:
--   estado_usuario: pendiente_aprobacion, aprobado, rechazado
--   rol_usuario: admin, jugador
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

CREATE OR REPLACE FUNCTION registrar_administrador(
    p_auth_user_id UUID,
    p_celular VARCHAR(9),
    p_nombre_completo TEXT,
    p_pregunta_seguridad TEXT,
    p_respuesta_seguridad TEXT,
    p_email_respaldo TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_error_hint TEXT;
    v_celular_limpio VARCHAR(9);
    v_respuesta_limpia TEXT;
BEGIN
    -- =============================================
    -- Validaciones de entrada
    -- =============================================

    -- CA-005 / RN: Nombre obligatorio, minimo 2 caracteres
    IF p_nombre_completo IS NULL OR LENGTH(TRIM(p_nombre_completo)) < 2 THEN
        v_error_hint := 'nombre_invalido';
        RAISE EXCEPTION 'El nombre debe tener al menos 2 caracteres';
    END IF;

    -- Limpiar celular (solo digitos)
    v_celular_limpio := REGEXP_REPLACE(p_celular, '[^0-9]', '', 'g');

    -- CA-003 / RN-002: Validar formato celular Peru
    IF LENGTH(v_celular_limpio) != 9 THEN
        v_error_hint := 'celular_formato_invalido';
        RAISE EXCEPTION 'El celular debe tener exactamente 9 digitos';
    END IF;

    IF LEFT(v_celular_limpio, 1) != '9' THEN
        v_error_hint := 'celular_formato_invalido';
        RAISE EXCEPTION 'El celular debe iniciar con el digito 9';
    END IF;

    -- CA-002 / RN-001: Verificar celular no duplicado
    IF EXISTS (SELECT 1 FROM usuarios WHERE celular = v_celular_limpio) THEN
        v_error_hint := 'celular_duplicado';
        RAISE EXCEPTION 'Este numero de celular ya esta registrado en el sistema';
    END IF;

    -- CA-006 / RN-004: Pregunta de seguridad obligatoria
    IF p_pregunta_seguridad IS NULL OR TRIM(p_pregunta_seguridad) = '' THEN
        v_error_hint := 'pregunta_seguridad_requerida';
        RAISE EXCEPTION 'Debe seleccionar una pregunta de seguridad';
    END IF;

    -- CA-006 / RN-004: Respuesta de seguridad obligatoria
    IF p_respuesta_seguridad IS NULL OR TRIM(p_respuesta_seguridad) = '' THEN
        v_error_hint := 'respuesta_seguridad_requerida';
        RAISE EXCEPTION 'Debe proporcionar una respuesta a la pregunta de seguridad';
    END IF;

    -- RN-004: Almacenar respuesta en minusculas para comparacion case-insensitive
    v_respuesta_limpia := LOWER(TRIM(p_respuesta_seguridad));

    -- RN-005: Validar formato email de respaldo si se proporciona
    IF p_email_respaldo IS NOT NULL AND TRIM(p_email_respaldo) != '' THEN
        IF p_email_respaldo !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
            v_error_hint := 'email_formato_invalido';
            RAISE EXCEPTION 'El formato del email de respaldo no es valido';
        END IF;
    END IF;

    -- =============================================
    -- Crear perfil de usuario administrador
    -- RN-006: Estado aprobado inmediatamente (admin no requiere aprobacion)
    -- ENUM CORRECTO: estado='aprobado', rol='admin'
    -- =============================================
    INSERT INTO usuarios (
        auth_user_id,
        nombre_completo,
        celular,
        email,
        pregunta_seguridad,
        respuesta_seguridad,
        email_respaldo,
        estado,
        rol,
        created_at,
        updated_at
    ) VALUES (
        p_auth_user_id,
        TRIM(p_nombre_completo),
        v_celular_limpio,
        v_celular_limpio || '@gestiondeportiva.app',
        TRIM(p_pregunta_seguridad),
        v_respuesta_limpia,
        CASE
            WHEN p_email_respaldo IS NOT NULL AND TRIM(p_email_respaldo) != ''
            THEN LOWER(TRIM(p_email_respaldo))
            ELSE NULL
        END,
        'aprobado',
        'admin',
        NOW(),
        NOW()
    )
    RETURNING id INTO v_usuario_id;

    -- =============================================
    -- Retornar resultado exitoso
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Cuenta de administrador creada exitosamente',
        'data', json_build_object(
            'usuario_id', v_usuario_id,
            'auth_user_id', p_auth_user_id,
            'celular', v_celular_limpio,
            'nombre_completo', TRIM(p_nombre_completo),
            'estado', 'aprobado',
            'rol', 'admin',
            'requiere_crear_grupo', TRUE
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', SQLSTATE,
                'hint', COALESCE(v_error_hint, 'error_desconocido')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION registrar_administrador TO authenticated;
GRANT EXECUTE ON FUNCTION registrar_administrador TO anon;

COMMENT ON FUNCTION registrar_administrador IS 'E001-HU-001: Registrar administrador con celular como identificador. Fix: enums corregidos a aprobado/admin';

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- PARTE 2: E000-HU-002 - Pasos 3-8 (pendientes)
-- Pasos 1-2 (tabla planes + seed) YA ejecutados.
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- =============================================
-- PASO 3: Agregar plan_id a usuarios
-- CA-009: Asignacion automatica de plan Gratis
-- RN-002: Plan Gratis es el default universal
-- RN-004: max_grupos_por_admin se valida a nivel de admin
-- =============================================
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS plan_id UUID REFERENCES planes(id);

-- Asignar plan Gratis a admins existentes que no tienen plan
UPDATE usuarios
SET plan_id = (SELECT id FROM planes WHERE slug = 'gratis' LIMIT 1)
WHERE plan_id IS NULL
  AND rol = 'admin';

-- =============================================
-- PASO 4: Trigger para auto-asignar plan Gratis
-- CA-009 / RN-002: Todo admin nuevo recibe plan Gratis automaticamente
-- =============================================
CREATE OR REPLACE FUNCTION trigger_asignar_plan_gratis()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo asignar si es admin y no tiene plan
    IF NEW.plan_id IS NULL AND NEW.rol = 'admin' THEN
        NEW.plan_id := (SELECT id FROM planes WHERE slug = 'gratis' AND activo = TRUE LIMIT 1);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_asignar_plan_gratis ON usuarios;
CREATE TRIGGER trg_asignar_plan_gratis
    BEFORE INSERT ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION trigger_asignar_plan_gratis();

-- =============================================
-- PASO 5: RPC obtener_planes
-- CA-001: Consultar planes disponibles
-- CA-015: Precio asociado a cada plan
-- RN-003: Planes de pago definidos pero no comprables aun
-- RN-011: Precios en Soles
-- =============================================
CREATE OR REPLACE FUNCTION obtener_planes()
RETURNS JSON AS $$
DECLARE
    v_planes JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', p.id,
            'nombre', p.nombre,
            'slug', p.slug,
            'precio_mensual', p.precio_mensual,
            'max_grupos_por_admin', p.max_grupos_por_admin,
            'max_jugadores_por_grupo', p.max_jugadores_por_grupo,
            'max_invitados_por_grupo', p.max_invitados_por_grupo,
            'max_coadmins_por_grupo', p.max_coadmins_por_grupo,
            'max_equipos_por_fecha', p.max_equipos_por_fecha,
            'max_tamano_logo_mb', p.max_tamano_logo_mb,
            'estadisticas_avanzadas', p.estadisticas_avanzadas,
            'temas_personalizados_grupo', p.temas_personalizados_grupo,
            'orden', p.orden
        ) ORDER BY p.orden
    ) INTO v_planes
    FROM planes p
    WHERE p.activo = TRUE;

    RETURN json_build_object(
        'success', TRUE,
        'data', COALESCE(v_planes, '[]'::json)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION obtener_planes() TO authenticated, anon;

COMMENT ON FUNCTION obtener_planes IS 'E000-HU-002: Retorna todos los planes activos con sus limites y features';

-- =============================================
-- PASO 6: RPC verificar_permiso_plan
-- CA-010: Validacion de limite numerico
-- CA-011: Validacion de feature bloqueada
-- CA-012: Validacion de equipos por fecha
-- CA-013: Consulta reutilizable "puede hacer X?"
-- RN-009: Validacion centralizada
-- =============================================
CREATE OR REPLACE FUNCTION verificar_permiso_plan(
    p_plan_id UUID,
    p_tipo_validacion VARCHAR,  -- 'limite' o 'feature'
    p_recurso VARCHAR,          -- nombre del limite o feature
    p_cantidad_actual INT DEFAULT 0
) RETURNS JSON AS $$
DECLARE
    v_plan planes%ROWTYPE;
    v_limite_maximo INT;
    v_feature_habilitada BOOLEAN;
    v_plan_requerido VARCHAR;
BEGIN
    -- Obtener el plan
    SELECT * INTO v_plan FROM planes WHERE id = p_plan_id AND activo = TRUE;

    IF v_plan IS NULL THEN
        RETURN json_build_object(
            'permitido', FALSE,
            'motivo', 'plan_no_encontrado',
            'mensaje', 'El plan no existe o no esta activo'
        );
    END IF;

    -- =============================================
    -- Validacion de LIMITES NUMERICOS
    -- CA-010, CA-012, RN-009
    -- =============================================
    IF p_tipo_validacion = 'limite' THEN
        -- Determinar limite segun recurso
        CASE p_recurso
            WHEN 'grupos_por_admin' THEN v_limite_maximo := v_plan.max_grupos_por_admin;
            WHEN 'jugadores_por_grupo' THEN v_limite_maximo := v_plan.max_jugadores_por_grupo;
            WHEN 'invitados_por_grupo' THEN v_limite_maximo := v_plan.max_invitados_por_grupo;
            WHEN 'coadmins_por_grupo' THEN v_limite_maximo := v_plan.max_coadmins_por_grupo;
            WHEN 'equipos_por_fecha' THEN v_limite_maximo := v_plan.max_equipos_por_fecha;
            WHEN 'tamano_logo_mb' THEN v_limite_maximo := v_plan.max_tamano_logo_mb;
            ELSE
                RETURN json_build_object(
                    'permitido', FALSE,
                    'motivo', 'recurso_no_valido',
                    'mensaje', 'El recurso "' || p_recurso || '" no es valido'
                );
        END CASE;

        -- Comparar cantidad actual con limite
        IF p_cantidad_actual < v_limite_maximo THEN
            RETURN json_build_object(
                'permitido', TRUE,
                'limite_actual', p_cantidad_actual,
                'limite_maximo', v_limite_maximo,
                'plan_nombre', v_plan.nombre
            );
        ELSE
            -- Buscar plan minimo que permita mas (RN-009)
            SELECT nombre INTO v_plan_requerido
            FROM planes
            WHERE activo = TRUE
              AND CASE p_recurso
                    WHEN 'grupos_por_admin' THEN max_grupos_por_admin
                    WHEN 'jugadores_por_grupo' THEN max_jugadores_por_grupo
                    WHEN 'invitados_por_grupo' THEN max_invitados_por_grupo
                    WHEN 'coadmins_por_grupo' THEN max_coadmins_por_grupo
                    WHEN 'equipos_por_fecha' THEN max_equipos_por_fecha
                    WHEN 'tamano_logo_mb' THEN max_tamano_logo_mb
                  END > p_cantidad_actual
            ORDER BY orden ASC
            LIMIT 1;

            RETURN json_build_object(
                'permitido', FALSE,
                'motivo', 'limite_alcanzado',
                'limite_actual', p_cantidad_actual,
                'limite_maximo', v_limite_maximo,
                'plan_nombre', v_plan.nombre,
                'plan_requerido', v_plan_requerido,
                'mensaje', 'Has alcanzado el limite de ' || v_limite_maximo || ' ' || p_recurso || ' en tu plan ' || v_plan.nombre
            );
        END IF;

    -- =============================================
    -- Validacion de FEATURE FLAGS
    -- CA-011, RN-007, RN-008, RN-009
    -- =============================================
    ELSIF p_tipo_validacion = 'feature' THEN
        -- Determinar si la feature esta habilitada
        CASE p_recurso
            WHEN 'estadisticas_avanzadas' THEN v_feature_habilitada := v_plan.estadisticas_avanzadas;
            WHEN 'temas_personalizados_grupo' THEN v_feature_habilitada := v_plan.temas_personalizados_grupo;
            ELSE
                RETURN json_build_object(
                    'permitido', FALSE,
                    'motivo', 'feature_no_valida',
                    'mensaje', 'La feature "' || p_recurso || '" no es valida'
                );
        END CASE;

        IF v_feature_habilitada THEN
            RETURN json_build_object(
                'permitido', TRUE,
                'plan_nombre', v_plan.nombre
            );
        ELSE
            -- Buscar plan minimo que tenga esta feature (RN-009)
            SELECT nombre INTO v_plan_requerido
            FROM planes
            WHERE activo = TRUE
              AND CASE p_recurso
                    WHEN 'estadisticas_avanzadas' THEN estadisticas_avanzadas
                    WHEN 'temas_personalizados_grupo' THEN temas_personalizados_grupo
                  END = TRUE
            ORDER BY orden ASC
            LIMIT 1;

            RETURN json_build_object(
                'permitido', FALSE,
                'motivo', 'feature_no_disponible',
                'plan_nombre', v_plan.nombre,
                'plan_requerido', v_plan_requerido,
                'mensaje', p_recurso || ' no esta disponible en tu plan ' || v_plan.nombre || '. Disponible desde ' || COALESCE(v_plan_requerido, 'un plan de pago')
            );
        END IF;

    ELSE
        RETURN json_build_object(
            'permitido', FALSE,
            'motivo', 'tipo_no_valido',
            'mensaje', 'El tipo de validacion debe ser "limite" o "feature"'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION verificar_permiso_plan(UUID, VARCHAR, VARCHAR, INT) TO authenticated;

COMMENT ON FUNCTION verificar_permiso_plan IS 'E000-HU-002: Valida si un plan permite un recurso (limite numerico o feature flag)';

-- =============================================
-- PASO 7: RPC obtener_plan_admin
-- Obtiene el plan del admin autenticado
-- RN-002: Default a Gratis si no tiene plan asignado
-- =============================================
CREATE OR REPLACE FUNCTION obtener_plan_admin()
RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_plan_id UUID;
    v_plan planes%ROWTYPE;
BEGIN
    -- Obtener usuario autenticado
    SELECT id, plan_id INTO v_usuario_id, v_plan_id
    FROM usuarios
    WHERE auth_user_id = auth.uid();

    IF v_usuario_id IS NULL THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'code', 'usuario_no_encontrado',
                'message', 'No se encontro el usuario autenticado',
                'hint', 'usuario_no_encontrado'
            )
        );
    END IF;

    -- Obtener plan (default a Gratis si no tiene asignado) RN-002
    IF v_plan_id IS NULL THEN
        SELECT * INTO v_plan FROM planes WHERE slug = 'gratis' AND activo = TRUE;
    ELSE
        SELECT * INTO v_plan FROM planes WHERE id = v_plan_id AND activo = TRUE;
    END IF;

    IF v_plan IS NULL THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'code', 'plan_no_encontrado',
                'message', 'No se encontro un plan activo',
                'hint', 'plan_no_encontrado'
            )
        );
    END IF;

    RETURN json_build_object(
        'success', TRUE,
        'data', json_build_object(
            'plan_id', v_plan.id,
            'nombre', v_plan.nombre,
            'slug', v_plan.slug,
            'precio_mensual', v_plan.precio_mensual,
            'max_grupos_por_admin', v_plan.max_grupos_por_admin,
            'max_jugadores_por_grupo', v_plan.max_jugadores_por_grupo,
            'max_invitados_por_grupo', v_plan.max_invitados_por_grupo,
            'max_coadmins_por_grupo', v_plan.max_coadmins_por_grupo,
            'max_equipos_por_fecha', v_plan.max_equipos_por_fecha,
            'max_tamano_logo_mb', v_plan.max_tamano_logo_mb,
            'estadisticas_avanzadas', v_plan.estadisticas_avanzadas,
            'temas_personalizados_grupo', v_plan.temas_personalizados_grupo
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION obtener_plan_admin() TO authenticated;

COMMENT ON FUNCTION obtener_plan_admin IS 'E000-HU-002: Retorna el plan del admin autenticado, default a Gratis si no tiene asignado';

-- =============================================
-- PASO 8: RLS para tabla planes (lectura publica)
-- Todos pueden leer planes, nadie puede modificar desde cliente
-- =============================================
ALTER TABLE planes ENABLE ROW LEVEL SECURITY;

-- Politica de lectura: todos los usuarios autenticados pueden leer planes activos
DROP POLICY IF EXISTS planes_select_policy ON planes;
CREATE POLICY planes_select_policy ON planes
    FOR SELECT
    USING (activo = TRUE);

-- No se crean politicas INSERT/UPDATE/DELETE: solo modificable via SQL/service_role

-- =============================================
-- VERIFICACION FINAL
-- Ejecuta estas queries para confirmar que todo se aplico correctamente
-- =============================================

-- Verificar que plan_id existe en usuarios
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'usuarios' AND column_name = 'plan_id';

-- Verificar planes cargados
SELECT nombre, slug, precio_mensual, max_grupos_por_admin, max_jugadores_por_grupo,
       estadisticas_avanzadas, temas_personalizados_grupo
FROM planes ORDER BY orden;

-- Verificar que el trigger existe
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trg_asignar_plan_gratis';

-- Verificar funciones creadas
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('registrar_administrador', 'obtener_planes', 'verificar_permiso_plan', 'obtener_plan_admin', 'trigger_asignar_plan_gratis');
