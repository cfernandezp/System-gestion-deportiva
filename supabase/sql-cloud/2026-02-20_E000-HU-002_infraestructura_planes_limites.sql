-- ============================================
-- E000-HU-002: Infraestructura de Planes y Limites
-- Fecha: 2026-02-20
-- Descripcion: Tabla de planes con limites numericos y feature flags,
--              seed data para 5 planes, columna plan_id en usuarios,
--              funciones RPC para consultar planes y validar permisos.
-- CAs: CA-001 a CA-015
-- RNs: RN-001 a RN-012
-- ============================================

-- =============================================
-- PASO 1: Tabla de planes
-- CA-001: Planes definidos en el sistema
-- RN-001: Limites numericos + feature flags
-- RN-005: Planes escalan por cantidad de grupos
-- =============================================
CREATE TABLE IF NOT EXISTS planes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(20) NOT NULL UNIQUE,
    precio_mensual NUMERIC(10,2) NOT NULL DEFAULT 0,
    -- Limites numericos (RN-001, RN-006)
    max_grupos_por_admin INT NOT NULL,
    max_jugadores_por_grupo INT NOT NULL,
    max_invitados_por_grupo INT NOT NULL,
    max_coadmins_por_grupo INT NOT NULL,
    max_equipos_por_fecha INT NOT NULL,
    max_tamano_logo_mb INT NOT NULL DEFAULT 2,
    -- Feature flags (RN-001, RN-007, RN-008)
    estadisticas_avanzadas BOOLEAN NOT NULL DEFAULT FALSE,
    temas_personalizados_grupo BOOLEAN NOT NULL DEFAULT FALSE,
    -- Metadata
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    orden INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice para consultas de planes activos ordenados
CREATE INDEX IF NOT EXISTS idx_planes_activo_orden ON planes (activo, orden);

-- =============================================
-- PASO 2: Seed data - 5 planes
-- CA-001 a CA-008: Limites y features por plan
-- RN-006: Limites plan Gratis
-- RN-007: Features plan Gratis
-- RN-008: Features escalonadas en planes de pago
-- RN-011: Precios en Soles peruanos
-- RN-012: Logo tamano fijo en todos los planes
-- =============================================
INSERT INTO planes (nombre, slug, precio_mensual, max_grupos_por_admin, max_jugadores_por_grupo, max_invitados_por_grupo, max_coadmins_por_grupo, max_equipos_por_fecha, max_tamano_logo_mb, estadisticas_avanzadas, temas_personalizados_grupo, activo, orden)
VALUES
    -- CA-002 / RN-006 / RN-007: Plan Gratis
    ('Gratis', 'gratis', 0.00, 1, 25, 1, 1, 2, 2, FALSE, FALSE, TRUE, 0),
    -- CA-003 / RN-008: Plan 5 (estadisticas_avanzadas SI, temas NO)
    ('Plan 5', 'plan_5', 9.90, 5, 50, 3, 3, 3, 2, TRUE, FALSE, TRUE, 1),
    -- CA-004 / RN-008: Plan 10 (estadisticas SI, temas SI)
    ('Plan 10', 'plan_10', 19.90, 10, 50, 5, 6, 4, 2, TRUE, TRUE, TRUE, 2),
    -- CA-005: Plan 15
    ('Plan 15', 'plan_15', 29.90, 15, 70, 8, 9, 4, 2, TRUE, TRUE, TRUE, 3),
    -- CA-006: Plan 20
    ('Plan 20', 'plan_20', 39.90, 20, 70, 10, 9, 4, 2, TRUE, TRUE, TRUE, 4)
ON CONFLICT (slug) DO NOTHING;

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

-- =============================================
-- PASO 8: RLS para tabla planes (lectura publica)
-- Todos pueden leer planes, nadie puede modificar desde cliente
-- =============================================
ALTER TABLE planes ENABLE ROW LEVEL SECURITY;

-- Politica de lectura: todos los usuarios autenticados pueden leer planes activos
CREATE POLICY planes_select_policy ON planes
    FOR SELECT
    USING (activo = TRUE);

-- No se crean politicas INSERT/UPDATE/DELETE: solo modificable via SQL/service_role

-- Verificar
SELECT nombre, slug, precio_mensual, max_grupos_por_admin, max_jugadores_por_grupo,
       estadisticas_avanzadas, temas_personalizados_grupo
FROM planes ORDER BY orden;
