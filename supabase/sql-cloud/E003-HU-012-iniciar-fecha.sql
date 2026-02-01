-- =============================================
-- E003-HU-012: Iniciar Fecha (Iniciar Pichanga)
-- Funcion RPC para cambiar estado de fecha a 'en_juego'
-- =============================================
-- INSTRUCCIONES:
-- 1. Ejecutar este script en Supabase SQL Editor
-- 2. URL: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
-- =============================================

-- Paso 1: Agregar columnas de auditoria de inicio si no existen
-- RN-004: Registrar quien y cuando inicio la pichanga
DO $$
BEGIN
  -- Columna iniciado_por (UUID del admin que inicio)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'fechas' AND column_name = 'iniciado_por'
  ) THEN
    ALTER TABLE fechas ADD COLUMN iniciado_por UUID REFERENCES usuarios(id);
    COMMENT ON COLUMN fechas.iniciado_por IS 'UUID del admin que inicio la pichanga';
  END IF;

  -- Columna iniciado_at (timestamp real de inicio)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'fechas' AND column_name = 'iniciado_at'
  ) THEN
    ALTER TABLE fechas ADD COLUMN iniciado_at TIMESTAMPTZ;
    COMMENT ON COLUMN fechas.iniciado_at IS 'Timestamp real de inicio de la pichanga';
  END IF;
END $$;

-- Paso 2: Crear o reemplazar la funcion RPC iniciar_fecha
CREATE OR REPLACE FUNCTION iniciar_fecha(p_fecha_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_user_rol TEXT;
  v_user_estado TEXT;
  v_user_nombre TEXT;
  v_fecha RECORD;
  v_total_equipos INT;
  v_total_jugadores INT;
  v_equipos_detalle JSONB;
  v_warning_sin_equipos BOOLEAN;
  v_notificaciones_creadas INT := 0;
  v_inscrito RECORD;
BEGIN
  -- ========================================
  -- VALIDACIONES
  -- ========================================

  -- Validar autenticacion
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'AUTH_ERROR',
        'message', 'No autenticado',
        'hint', 'no_autenticado'
      )
    );
  END IF;

  -- Validar parametro fecha_id
  IF p_fecha_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_PARAM',
        'message', 'El ID de la fecha es requerido',
        'hint', 'fecha_id_requerido'
      )
    );
  END IF;

  -- Obtener datos del usuario
  SELECT rol, estado, nombre_completo
  INTO v_user_rol, v_user_estado, v_user_nombre
  FROM usuarios
  WHERE id = v_user_id;

  IF v_user_rol IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'Usuario no encontrado en el sistema',
        'hint', 'usuario_no_encontrado'
      )
    );
  END IF;

  -- Obtener datos de la fecha
  SELECT
    f.id,
    f.fecha_hora_inicio,
    f.duracion_horas,
    f.lugar,
    f.estado,
    f.created_by,
    f.costo_total,
    f.num_equipos,
    TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI') as fecha_formato,
    TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') as hora_pactada
  INTO v_fecha
  FROM fechas f
  WHERE f.id = p_fecha_id;

  IF v_fecha.id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_FOUND',
        'message', 'Fecha no encontrada',
        'hint', 'fecha_no_encontrada'
      )
    );
  END IF;

  -- RN-001: Validar permisos (admin aprobado o creador de la fecha)
  IF NOT (
    (LOWER(v_user_rol) IN ('admin', 'administrador') AND LOWER(v_user_estado) = 'aprobado')
    OR v_fecha.created_by = v_user_id
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'FORBIDDEN',
        'message', 'No tienes permisos para iniciar esta pichanga. Solo el administrador o el organizador pueden hacerlo.',
        'hint', 'sin_permisos'
      )
    );
  END IF;

  -- RN-002: Validar que el estado sea 'cerrada'
  IF v_fecha.estado != 'cerrada' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_STATE',
        'message', 'Solo se puede iniciar una pichanga con inscripciones cerradas. Estado actual: ' || v_fecha.estado,
        'hint', 'estado_invalido'
      )
    );
  END IF;

  -- ========================================
  -- RECOPILAR INFORMACION DE EQUIPOS
  -- ========================================

  -- RN-003: Contar equipos con jugadores asignados
  SELECT
    COUNT(DISTINCT i.equipo_asignado) FILTER (WHERE i.equipo_asignado IS NOT NULL),
    COUNT(*) FILTER (WHERE i.estado = 'inscrito')
  INTO v_total_equipos, v_total_jugadores
  FROM inscripciones i
  WHERE i.fecha_id = p_fecha_id;

  -- Warning si no hay equipos asignados
  v_warning_sin_equipos := (v_total_equipos < 2);

  -- Construir detalle de equipos
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'color', equipo,
        'jugadores', cant
      )
      ORDER BY equipo
    ),
    '[]'::jsonb
  )
  INTO v_equipos_detalle
  FROM (
    SELECT
      i.equipo_asignado as equipo,
      COUNT(*) as cant
    FROM inscripciones i
    WHERE i.fecha_id = p_fecha_id
      AND i.estado = 'inscrito'
      AND i.equipo_asignado IS NOT NULL
    GROUP BY i.equipo_asignado
  ) sub;

  -- ========================================
  -- ACTUALIZAR ESTADO DE LA FECHA
  -- ========================================

  -- CA-004, RN-004: Cambiar estado y registrar auditoria
  UPDATE fechas
  SET
    estado = 'en_juego',
    iniciado_por = v_user_id,
    iniciado_at = NOW(),
    updated_at = NOW()
  WHERE id = p_fecha_id;

  -- ========================================
  -- CREAR NOTIFICACIONES PARA INSCRITOS
  -- ========================================

  -- RN-005: Notificar a todos los jugadores inscritos
  FOR v_inscrito IN
    SELECT i.usuario_id
    FROM inscripciones i
    WHERE i.fecha_id = p_fecha_id
      AND i.estado = 'inscrito'
  LOOP
    -- Solo notificar si no es el mismo admin que inicia
    IF v_inscrito.usuario_id != v_user_id THEN
      INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        fecha_id,
        leida,
        created_at
      ) VALUES (
        v_inscrito.usuario_id,
        'fecha_iniciada',
        'Pichanga iniciada',
        'La pichanga del ' || v_fecha.fecha_formato || ' en ' || v_fecha.lugar || ' ha comenzado!',
        p_fecha_id,
        false,
        NOW()
      );
      v_notificaciones_creadas := v_notificaciones_creadas + 1;
    END IF;
  END LOOP;

  -- ========================================
  -- RETORNAR RESPUESTA EXITOSA
  -- ========================================

  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'fecha_id', p_fecha_id,
      'fecha_formato', v_fecha.fecha_formato,
      'lugar', v_fecha.lugar,
      'estado_anterior', 'cerrada',
      'estado_nuevo', 'en_juego',
      'hora_pactada', v_fecha.hora_pactada,
      'hora_inicio_real', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI'),
      'iniciado_por', v_user_id,
      'iniciado_por_nombre', v_user_nombre,
      'iniciado_at', NOW(),
      'iniciado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
      'total_equipos', v_total_equipos,
      'total_jugadores', v_total_jugadores,
      'equipos_detalle', v_equipos_detalle,
      'warning_sin_equipos', v_warning_sin_equipos,
      'notificaciones_enviadas', v_notificaciones_creadas
    ),
    'message', CASE
      WHEN v_notificaciones_creadas > 0
      THEN 'Pichanga iniciada exitosamente. Se notifico a ' || v_notificaciones_creadas || ' jugador(es).'
      ELSE 'Pichanga iniciada exitosamente.'
    END
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'SERVER_ERROR',
        'message', 'Error interno: ' || SQLERRM,
        'hint', 'error_interno'
      )
    );
END;
$$;

-- Paso 3: Otorgar permisos de ejecucion
GRANT EXECUTE ON FUNCTION iniciar_fecha(UUID) TO authenticated;

-- Paso 4: Agregar comentario descriptivo
COMMENT ON FUNCTION iniciar_fecha(UUID) IS
'E003-HU-012: Inicia una pichanga (cambia estado de cerrada a en_juego).
Valida permisos de admin/organizador, registra hora real de inicio,
y notifica a todos los jugadores inscritos.
Parametros:
- p_fecha_id: UUID de la fecha a iniciar
Retorna: JSON con datos de la fecha iniciada o error';

-- =============================================
-- FIN DEL SCRIPT
-- =============================================
