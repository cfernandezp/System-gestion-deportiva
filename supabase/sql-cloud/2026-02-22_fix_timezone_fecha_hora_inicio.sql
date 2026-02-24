-- ============================================
-- FIX: Timezone - timestamps en json_build_object sin indicador UTC
-- Fecha: 2026-02-22
-- ============================================
--
-- BUG: PostgreSQL serializa timestamptz dentro de json_build_object()
--      como string SIN indicador de zona horaria.
--      Ejemplo: "2026-02-28T02:00:00" en vez de "2026-02-28T02:00:00+00:00"
--      Dart parsea ese string como hora local del dispositivo (Peru UTC-5),
--      lo que produce un desfase de -5 horas.
--      Resultado visible: 21:00 Peru se muestra como 16:00.
--
-- SOLUCION: Usar TO_CHAR(..., 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"')
--           para forzar el sufijo +00:00 en el string JSON.
--           Dart lo parsea correctamente como UTC y luego convierte a hora local.
--
-- FUNCIONES AFECTADAS:
--   1. crear_fecha     - campo fecha_hora_inicio, fecha_hora_local, created_at
--   2. editar_fecha    - campo fecha_hora_inicio, fecha_hora_local
--   3. listar_fechas_por_rol - campo fecha_hora_inicio (5 secciones)
--
-- NOTA: No se cambia NADA de la logica, solo el formato de serializacion
--       de timestamps dentro de json_build_object.
-- ============================================


-- ============================================
-- FUNCION 1: crear_fecha
-- Campos corregidos:
--   - fecha_hora_inicio: raw timestamptz -> TO_CHAR con +00:00
--   - fecha_hora_local: raw AT TIME ZONE -> TO_CHAR con -05:00
--   - created_at: raw NOW() -> TO_CHAR con +00:00
-- ============================================
CREATE OR REPLACE FUNCTION crear_fecha(
    p_fecha_hora_inicio  TIMESTAMPTZ,
    p_duracion_horas     NUMERIC(3,1),
    p_lugar              TEXT,
    p_num_equipos        INTEGER DEFAULT 2,
    p_costo_por_jugador  NUMERIC(10,2) DEFAULT 0.00
) RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_auth_uid UUID;
    v_fecha_id UUID;
    v_lugar_limpio TEXT;
    v_max_equipos INTEGER;
    v_plan_nombre TEXT;
    v_formato_juego TEXT;
    v_error_hint TEXT;
BEGIN
    -- =============================================
    -- Verificar autenticacion
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para crear una fecha';
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- =============================================
    -- Verificar rol: admin o coadmin en algun grupo activo
    -- =============================================
    IF NOT EXISTS (
        SELECT 1 FROM miembros_grupo
        WHERE usuario_id = v_usuario_id
        AND rol IN ('admin', 'coadmin')
        AND activo = TRUE
    ) THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores o co-administradores pueden crear fechas';
    END IF;

    -- =============================================
    -- Validar duracion_horas
    -- Valores permitidos: 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
    -- =============================================
    IF p_duracion_horas NOT IN (1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0) THEN
        v_error_hint := 'duracion_invalida';
        RAISE EXCEPTION 'La duracion debe ser 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5 o 5.0 horas';
    END IF;

    -- =============================================
    -- Validar lugar (min 3 caracteres)
    -- =============================================
    v_lugar_limpio := TRIM(p_lugar);

    IF v_lugar_limpio IS NULL OR LENGTH(v_lugar_limpio) < 3 THEN
        v_error_hint := 'lugar_invalido';
        RAISE EXCEPTION 'El lugar debe tener al menos 3 caracteres';
    END IF;

    -- =============================================
    -- Validar num_equipos (2 a 4)
    -- =============================================
    IF p_num_equipos < 2 OR p_num_equipos > 4 THEN
        v_error_hint := 'num_equipos_invalido';
        RAISE EXCEPTION 'El numero de equipos debe ser entre 2 y 4';
    END IF;

    -- =============================================
    -- Validar num_equipos contra plan del usuario
    -- =============================================
    SELECT p.max_equipos_por_fecha, p.nombre
    INTO v_max_equipos, v_plan_nombre
    FROM usuarios u
    JOIN planes p ON p.id = u.plan_id
    WHERE u.id = v_usuario_id;

    -- Si no tiene plan asignado, usar plan Gratis
    IF v_max_equipos IS NULL THEN
        SELECT p.max_equipos_por_fecha, p.nombre
        INTO v_max_equipos, v_plan_nombre
        FROM planes p
        WHERE p.slug = 'gratis'
        LIMIT 1;
    END IF;

    IF p_num_equipos > v_max_equipos THEN
        v_error_hint := 'limite_plan_equipos';
        RAISE EXCEPTION 'Tu plan (%) permite maximo % equipos por fecha. Actualiza tu plan para usar mas equipos.',
            v_plan_nombre, v_max_equipos;
    END IF;

    -- =============================================
    -- Validar costo_por_jugador (0.00 a 100.00)
    -- =============================================
    IF p_costo_por_jugador < 0.00 OR p_costo_por_jugador > 100.00 THEN
        v_error_hint := 'costo_invalido';
        RAISE EXCEPTION 'El costo por jugador debe ser entre S/ 0.00 y S/ 100.00';
    END IF;

    -- =============================================
    -- Validar fecha futura (hora Peru: UTC-5)
    -- =============================================
    IF p_fecha_hora_inicio <= NOW() THEN
        v_error_hint := 'fecha_pasada';
        RAISE EXCEPTION 'La fecha y hora de inicio debe ser futura';
    END IF;

    -- =============================================
    -- Determinar formato de juego (solo informativo)
    -- =============================================
    IF p_num_equipos = 2 THEN
        v_formato_juego := '2 equipos - Partido continuo';
    ELSE
        v_formato_juego := p_num_equipos || ' equipos - Rotacion';
    END IF;

    -- =============================================
    -- INSERT en tabla fechas
    -- Sin auto-calculo: usa los valores directos del admin
    -- =============================================
    INSERT INTO fechas (
        fecha_hora_inicio,
        duracion_horas,
        lugar,
        num_equipos,
        costo_por_jugador,
        estado,
        created_by,
        created_at,
        updated_at
    ) VALUES (
        p_fecha_hora_inicio,
        p_duracion_horas,
        v_lugar_limpio,
        p_num_equipos,
        p_costo_por_jugador,
        'abierta',
        v_usuario_id,
        NOW(),
        NOW()
    )
    RETURNING id INTO v_fecha_id;

    -- =============================================
    -- Retornar resultado exitoso
    -- FIX TIMEZONE: Usar TO_CHAR para forzar sufijo de zona horaria
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Fecha creada exitosamente',
        'data', json_build_object(
            'fecha_id', v_fecha_id,
            'fecha_hora_inicio', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
            'fecha_hora_local', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'YYYY-MM-DD"T"HH24:MI:SS"-05:00"'),
            'fecha_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
            'hora_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
            'duracion_horas', p_duracion_horas,
            'lugar', v_lugar_limpio,
            'num_equipos', p_num_equipos,
            'costo_por_jugador', p_costo_por_jugador,
            'costo_formato', 'S/ ' || TO_CHAR(p_costo_por_jugador, 'FM999,999,990.00'),
            'estado', 'abierta',
            'formato_juego', v_formato_juego,
            'created_by', v_usuario_id,
            'created_by_nombre', (SELECT nombre_completo FROM usuarios WHERE id = v_usuario_id),
            'created_at', TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"')
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

-- Permisos crear_fecha
GRANT EXECUTE ON FUNCTION crear_fecha(TIMESTAMPTZ, NUMERIC, TEXT, INTEGER, NUMERIC) TO authenticated;

COMMENT ON FUNCTION crear_fecha IS 'Crea una fecha/pichanga. Admin elige duracion, equipos y costo independientemente. FIX 2026-02-22: timezone en json_build_object.';


-- ============================================
-- FUNCION 2: editar_fecha
-- Campos corregidos:
--   - fecha_hora_inicio: raw timestamptz -> TO_CHAR con +00:00
--   - fecha_hora_local: raw AT TIME ZONE -> TO_CHAR con -05:00
-- ============================================
CREATE OR REPLACE FUNCTION editar_fecha(
    p_fecha_id           UUID,
    p_fecha_hora_inicio  TIMESTAMPTZ,
    p_duracion_horas     NUMERIC(3,1),
    p_lugar              TEXT,
    p_num_equipos        INTEGER DEFAULT 2,
    p_costo_por_jugador  NUMERIC(10,2) DEFAULT 0.00
) RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_auth_uid UUID;
    v_fecha RECORD;
    v_lugar_limpio TEXT;
    v_max_equipos INTEGER;
    v_plan_nombre TEXT;
    v_formato_juego TEXT;
    v_cambio_fecha BOOLEAN := FALSE;
    v_cambio_hora BOOLEAN := FALSE;
    v_cambio_duracion BOOLEAN := FALSE;
    v_cambio_lugar BOOLEAN := FALSE;
    v_cambio_costo BOOLEAN := FALSE;
    v_cambio_equipos BOOLEAN := FALSE;
    v_costo_anterior NUMERIC(10,2);
    v_deudas_actualizadas INTEGER := 0;
    v_inscritos_count INTEGER := 0;
    v_resumen_cambios TEXT := '';
    v_cambios_realizados BOOLEAN := FALSE;
    v_error_hint TEXT;
BEGIN
    -- =============================================
    -- Verificar autenticacion
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para editar una fecha';
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- =============================================
    -- Obtener fecha actual
    -- =============================================
    SELECT f.id, f.fecha_hora_inicio, f.duracion_horas, f.lugar,
           f.num_equipos, f.costo_por_jugador, f.estado, f.created_by
    INTO v_fecha
    FROM fechas f
    WHERE f.id = p_fecha_id;

    IF v_fecha IS NULL THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'No se encontro la fecha indicada';
    END IF;

    -- =============================================
    -- Verificar estado: solo fechas 'abierta' se pueden editar
    -- =============================================
    IF v_fecha.estado != 'abierta' THEN
        v_error_hint := 'fecha_no_editable';
        RAISE EXCEPTION 'Solo se pueden editar fechas con estado "abierta". Estado actual: %', v_fecha.estado;
    END IF;

    -- =============================================
    -- Verificar permisos: admin o coadmin del grupo
    -- El creador de la fecha siempre puede editar,
    -- o cualquier admin/coadmin de un grupo activo
    -- =============================================
    IF v_fecha.created_by != v_usuario_id THEN
        IF NOT EXISTS (
            SELECT 1 FROM miembros_grupo
            WHERE usuario_id = v_usuario_id
            AND rol IN ('admin', 'coadmin')
            AND activo = TRUE
        ) THEN
            v_error_hint := 'sin_permisos';
            RAISE EXCEPTION 'Solo el creador o un administrador/co-administrador puede editar esta fecha';
        END IF;
    END IF;

    -- =============================================
    -- Validar duracion_horas
    -- =============================================
    IF p_duracion_horas NOT IN (1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0) THEN
        v_error_hint := 'duracion_invalida';
        RAISE EXCEPTION 'La duracion debe ser 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5 o 5.0 horas';
    END IF;

    -- =============================================
    -- Validar lugar (min 3 caracteres)
    -- =============================================
    v_lugar_limpio := TRIM(p_lugar);

    IF v_lugar_limpio IS NULL OR LENGTH(v_lugar_limpio) < 3 THEN
        v_error_hint := 'lugar_invalido';
        RAISE EXCEPTION 'El lugar debe tener al menos 3 caracteres';
    END IF;

    -- =============================================
    -- Validar num_equipos (2 a 4)
    -- =============================================
    IF p_num_equipos < 2 OR p_num_equipos > 4 THEN
        v_error_hint := 'num_equipos_invalido';
        RAISE EXCEPTION 'El numero de equipos debe ser entre 2 y 4';
    END IF;

    -- =============================================
    -- Validar num_equipos contra plan del usuario
    -- =============================================
    SELECT p.max_equipos_por_fecha, p.nombre
    INTO v_max_equipos, v_plan_nombre
    FROM usuarios u
    JOIN planes p ON p.id = u.plan_id
    WHERE u.id = v_usuario_id;

    IF v_max_equipos IS NULL THEN
        SELECT p.max_equipos_por_fecha, p.nombre
        INTO v_max_equipos, v_plan_nombre
        FROM planes p
        WHERE p.slug = 'gratis'
        LIMIT 1;
    END IF;

    IF p_num_equipos > v_max_equipos THEN
        v_error_hint := 'limite_plan_equipos';
        RAISE EXCEPTION 'Tu plan (%) permite maximo % equipos por fecha. Actualiza tu plan para usar mas equipos.',
            v_plan_nombre, v_max_equipos;
    END IF;

    -- =============================================
    -- Validar costo_por_jugador (0.00 a 100.00)
    -- =============================================
    IF p_costo_por_jugador < 0.00 OR p_costo_por_jugador > 100.00 THEN
        v_error_hint := 'costo_invalido';
        RAISE EXCEPTION 'El costo por jugador debe ser entre S/ 0.00 y S/ 100.00';
    END IF;

    -- =============================================
    -- Validar fecha futura
    -- =============================================
    IF p_fecha_hora_inicio <= NOW() THEN
        v_error_hint := 'fecha_pasada';
        RAISE EXCEPTION 'La fecha y hora de inicio debe ser futura';
    END IF;

    -- =============================================
    -- Detectar cambios
    -- =============================================
    -- Comparar dia (fecha sin hora)
    v_cambio_fecha := (p_fecha_hora_inicio AT TIME ZONE 'America/Lima')::date
                   != (v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima')::date;

    -- Comparar hora (hora:minuto)
    v_cambio_hora := TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI')
                  != TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI');

    v_cambio_duracion := p_duracion_horas != v_fecha.duracion_horas;
    v_cambio_lugar := v_lugar_limpio != v_fecha.lugar;
    v_cambio_costo := p_costo_por_jugador != v_fecha.costo_por_jugador;
    v_cambio_equipos := p_num_equipos != v_fecha.num_equipos;

    v_cambios_realizados := v_cambio_fecha OR v_cambio_hora OR v_cambio_duracion
                         OR v_cambio_lugar OR v_cambio_costo OR v_cambio_equipos;

    -- Guardar costo anterior si cambio
    IF v_cambio_costo THEN
        v_costo_anterior := v_fecha.costo_por_jugador;
    END IF;

    -- =============================================
    -- UPDATE en tabla fechas
    -- =============================================
    UPDATE fechas SET
        fecha_hora_inicio = p_fecha_hora_inicio,
        duracion_horas    = p_duracion_horas,
        lugar             = v_lugar_limpio,
        num_equipos       = p_num_equipos,
        costo_por_jugador = p_costo_por_jugador,
        updated_at        = NOW()
    WHERE id = p_fecha_id;

    -- =============================================
    -- Si cambio el costo, actualizar deudas pendientes en pagos
    -- Solo actualiza pagos con estado 'pendiente' de esta fecha
    -- =============================================
    IF v_cambio_costo THEN
        UPDATE pagos SET
            monto = p_costo_por_jugador,
            notas = COALESCE(notas, '') ||
                    CASE WHEN notas IS NOT NULL AND notas != '' THEN ' | ' ELSE '' END ||
                    'Costo actualizado de S/' || TO_CHAR(v_costo_anterior, 'FM990.00') ||
                    ' a S/' || TO_CHAR(p_costo_por_jugador, 'FM990.00') ||
                    ' el ' || TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            updated_at = NOW()
        WHERE fecha_id = p_fecha_id
        AND estado = 'pendiente';

        GET DIAGNOSTICS v_deudas_actualizadas = ROW_COUNT;
    END IF;

    -- =============================================
    -- Contar inscritos (para informar)
    -- =============================================
    SELECT COUNT(*) INTO v_inscritos_count
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- =============================================
    -- Construir resumen de cambios
    -- =============================================
    IF v_cambio_fecha THEN
        v_resumen_cambios := v_resumen_cambios || 'Fecha cambiada. ';
    END IF;
    IF v_cambio_hora THEN
        v_resumen_cambios := v_resumen_cambios || 'Hora cambiada. ';
    END IF;
    IF v_cambio_duracion THEN
        v_resumen_cambios := v_resumen_cambios || 'Duracion cambiada a ' || p_duracion_horas || 'h. ';
    END IF;
    IF v_cambio_lugar THEN
        v_resumen_cambios := v_resumen_cambios || 'Lugar cambiado. ';
    END IF;
    IF v_cambio_equipos THEN
        v_resumen_cambios := v_resumen_cambios || 'Equipos cambiados a ' || p_num_equipos || '. ';
    END IF;
    IF v_cambio_costo THEN
        v_resumen_cambios := v_resumen_cambios || 'Costo cambiado de S/' ||
            TO_CHAR(v_costo_anterior, 'FM990.00') || ' a S/' ||
            TO_CHAR(p_costo_por_jugador, 'FM990.00') || '. ';
        IF v_deudas_actualizadas > 0 THEN
            v_resumen_cambios := v_resumen_cambios || v_deudas_actualizadas || ' deuda(s) actualizada(s). ';
        END IF;
    END IF;

    IF NOT v_cambios_realizados THEN
        v_resumen_cambios := 'Sin cambios detectados.';
    END IF;

    -- =============================================
    -- Determinar formato de juego
    -- =============================================
    IF p_num_equipos = 2 THEN
        v_formato_juego := '2 equipos - Partido continuo';
    ELSE
        v_formato_juego := p_num_equipos || ' equipos - Rotacion';
    END IF;

    -- =============================================
    -- Retornar resultado exitoso
    -- FIX TIMEZONE: Usar TO_CHAR para forzar sufijo de zona horaria
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', CASE
            WHEN v_cambios_realizados THEN 'Fecha actualizada exitosamente'
            ELSE 'No se detectaron cambios'
        END,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'cambios_realizados', v_cambios_realizados,
            'fecha_hora_inicio', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
            'fecha_hora_local', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'YYYY-MM-DD"T"HH24:MI:SS"-05:00"'),
            'fecha_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
            'hora_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
            'duracion_horas', p_duracion_horas,
            'lugar', v_lugar_limpio,
            'num_equipos', p_num_equipos,
            'costo_por_jugador', p_costo_por_jugador,
            'costo_formato', 'S/ ' || TO_CHAR(p_costo_por_jugador, 'FM999,999,990.00'),
            'estado', v_fecha.estado,
            'formato_juego', v_formato_juego,
            'cambios', json_build_object(
                'fecha', v_cambio_fecha,
                'hora', v_cambio_hora,
                'duracion', v_cambio_duracion,
                'lugar', v_cambio_lugar,
                'costo', v_cambio_costo,
                'equipos', v_cambio_equipos
            ),
            'costo_anterior', v_costo_anterior,
            'deudas_actualizadas', v_deudas_actualizadas,
            'inscritos_notificados', v_inscritos_count,
            'resumen_cambios', TRIM(v_resumen_cambios)
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

-- Permisos editar_fecha
GRANT EXECUTE ON FUNCTION editar_fecha(UUID, TIMESTAMPTZ, NUMERIC, TEXT, INTEGER, NUMERIC) TO authenticated;

COMMENT ON FUNCTION editar_fecha IS 'Edita una fecha/pichanga abierta. Admin define duracion, equipos y costo independientemente. Actualiza deudas pendientes si cambia el costo. FIX 2026-02-22: timezone en json_build_object.';


-- ============================================
-- FUNCION 3: listar_fechas_por_rol
-- Campos corregidos en las 5 secciones:
--   - fecha_hora_inicio: raw f.fecha_hora_inicio -> TO_CHAR con +00:00
-- ============================================
CREATE OR REPLACE FUNCTION listar_fechas_por_rol(
    p_seccion TEXT DEFAULT 'proximas',
    p_filtro_estado TEXT DEFAULT NULL,
    p_fecha_desde TEXT DEFAULT NULL,
    p_fecha_hasta TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_rol TEXT;
    v_estado_usuario TEXT;
    v_error_hint TEXT;
    v_fechas JSON;
    v_total INT;
    v_es_admin BOOLEAN;
    v_mensaje TEXT;
    v_orden TEXT;
    v_fecha_desde_parsed TIMESTAMPTZ;
    v_fecha_hasta_parsed TIMESTAMPTZ;
BEGIN
    -- ========================================
    -- 1. Validar autenticacion
    -- ========================================
    v_auth_uid := auth.uid();

    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- ========================================
    -- 2. Obtener datos del usuario
    -- ========================================
    SELECT id, rol::TEXT, estado::TEXT
    INTO v_usuario_id, v_rol, v_estado_usuario
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_estado_usuario != 'aprobado' THEN
        v_error_hint := 'usuario_no_aprobado';
        RAISE EXCEPTION 'Usuario no tiene estado aprobado';
    END IF;

    v_es_admin := (v_rol = 'admin');

    -- ========================================
    -- 3. Validar seccion segun rol
    -- ========================================
    -- Secciones permitidas para admin: proximas, en_curso, historial, todas
    -- Secciones permitidas para jugador: proximas, inscrito, historial
    IF v_es_admin THEN
        IF p_seccion NOT IN ('proximas', 'en_curso', 'historial', 'todas') THEN
            v_error_hint := 'seccion_invalida';
            RAISE EXCEPTION 'Seccion invalida para admin: %', p_seccion;
        END IF;
    ELSE
        IF p_seccion NOT IN ('proximas', 'inscrito', 'historial') THEN
            IF p_seccion IN ('en_curso', 'todas') THEN
                v_error_hint := 'seccion_no_permitida';
                RAISE EXCEPTION 'Seccion "%" solo disponible para administradores', p_seccion;
            ELSE
                v_error_hint := 'seccion_invalida';
                RAISE EXCEPTION 'Seccion invalida: %', p_seccion;
            END IF;
        END IF;
    END IF;

    -- ========================================
    -- 4. Parsear fechas de filtro (solo admin)
    -- ========================================
    IF p_fecha_desde IS NOT NULL THEN
        BEGIN
            v_fecha_desde_parsed := p_fecha_desde::TIMESTAMPTZ;
        EXCEPTION WHEN OTHERS THEN
            v_fecha_desde_parsed := (p_fecha_desde || ' 00:00:00')::TIMESTAMPTZ;
        END;
    END IF;

    IF p_fecha_hasta IS NOT NULL THEN
        BEGIN
            v_fecha_hasta_parsed := p_fecha_hasta::TIMESTAMPTZ;
        EXCEPTION WHEN OTHERS THEN
            -- Si es solo fecha, agregar fin del dia
            v_fecha_hasta_parsed := (p_fecha_hasta || ' 23:59:59')::TIMESTAMPTZ;
        END;
    END IF;

    -- ========================================
    -- 5. Construir query segun seccion y rol
    -- ========================================

    -- ----------------------------------------
    -- SECCION: proximas (admin y jugador)
    -- Fechas abiertas con fecha futura
    -- RN-001: estado = 'abierta' AND fecha_hora_inicio > NOW()
    -- Orden: fecha_hora_inicio ASC (mas cercana primero)
    -- ----------------------------------------
    IF p_seccion = 'proximas' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort ASC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS(
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.usuario_id = v_usuario_id
                          AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', (
                        f.estado::TEXT = 'abierta'
                        AND f.fecha_hora_inicio > NOW()
                        AND NOT EXISTS(
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                              AND i.usuario_id = v_usuario_id
                              AND i.estado = 'inscrito'
                        )
                    ),
                    'puede_cancelar', (
                        f.estado::TEXT = 'abierta'
                        AND EXISTS(
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                              AND i.usuario_id = v_usuario_id
                              AND i.estado = 'inscrito'
                        )
                    ),
                    'indicador', json_build_object(
                        'tipo', 'abierta',
                        'texto', 'Inscripciones Abiertas',
                        'color', '#4CAF50',
                        'icono', 'group'
                    )
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE f.estado = 'abierta'
              AND f.fecha_hora_inicio > NOW()
        ) sub;

    -- ----------------------------------------
    -- SECCION: inscrito (solo jugador)
    -- Fechas cerradas/en_juego donde el jugador tiene inscripcion activa
    -- RN-002: estado IN ('cerrada', 'en_juego') con inscripcion activa
    -- Orden: fecha_hora_inicio ASC
    -- ----------------------------------------
    ELSIF p_seccion = 'inscrito' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort ASC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', true,
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', false,
                    'puede_cancelar', (f.estado::TEXT = 'cerrada'),
                    'indicador', CASE f.estado::TEXT
                        WHEN 'cerrada' THEN json_build_object(
                            'tipo', 'cerrada',
                            'texto', 'Inscripciones Cerradas',
                            'color', '#FFC107',
                            'icono', 'lock'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'tipo', 'en_juego',
                            'texto', 'En Juego',
                            'color', '#2196F3',
                            'icono', 'sports_soccer'
                        )
                        ELSE json_build_object(
                            'tipo', f.estado::TEXT,
                            'texto', f.estado::TEXT,
                            'color', '#9E9E9E',
                            'icono', 'info'
                        )
                    END
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE f.estado IN ('cerrada', 'en_juego')
              AND EXISTS(
                  SELECT 1 FROM inscripciones i
                  WHERE i.fecha_id = f.id
                    AND i.usuario_id = v_usuario_id
                    AND i.estado = 'inscrito'
              )
        ) sub;

    -- ----------------------------------------
    -- SECCION: en_curso (solo admin)
    -- Fechas cerradas/en_juego (todas, sin filtro de inscripcion)
    -- Orden: fecha_hora_inicio ASC
    -- ----------------------------------------
    ELSIF p_seccion = 'en_curso' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort ASC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS(
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.usuario_id = v_usuario_id
                          AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', false,
                    'puede_cancelar', false,
                    'indicador', CASE f.estado::TEXT
                        WHEN 'cerrada' THEN json_build_object(
                            'tipo', 'cerrada',
                            'texto', 'Inscripciones Cerradas',
                            'color', '#FFC107',
                            'icono', 'lock'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'tipo', 'en_juego',
                            'texto', 'En Juego',
                            'color', '#2196F3',
                            'icono', 'sports_soccer'
                        )
                        ELSE json_build_object(
                            'tipo', f.estado::TEXT,
                            'texto', f.estado::TEXT,
                            'color', '#9E9E9E',
                            'icono', 'info'
                        )
                    END
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE f.estado IN ('cerrada', 'en_juego')
        ) sub;

    -- ----------------------------------------
    -- SECCION: historial
    -- Admin: todas las fechas finalizadas
    -- Jugador: solo fechas finalizadas donde participo (inscripcion activa)
    -- RN-003: Jugador con inscripcion estado = 'inscrito' en fecha finalizada
    -- RN-006: Jugador NO ve fechas finalizadas donde no participo
    -- Orden: fecha_hora_inicio DESC (mas reciente primero)
    -- ----------------------------------------
    ELSIF p_seccion = 'historial' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort DESC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS(
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.usuario_id = v_usuario_id
                          AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', false,
                    'puede_cancelar', false,
                    'indicador', json_build_object(
                        'tipo', 'finalizada',
                        'texto', 'Finalizada',
                        'color', '#9E9E9E',
                        'icono', 'check_circle'
                    )
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE f.estado = 'finalizada'
              -- RN-003/RN-006: Jugador solo ve fechas donde participo
              AND (
                  v_es_admin = true
                  OR EXISTS(
                      SELECT 1 FROM inscripciones i
                      WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_usuario_id
                        AND i.estado = 'inscrito'
                  )
              )
        ) sub;

    -- ----------------------------------------
    -- SECCION: todas (solo admin)
    -- Todas las fechas con filtros opcionales
    -- RN-004: Admin ve todas sin restriccion
    -- RN-005: Filtros exclusivos de admin
    -- Orden: fecha_hora_inicio DESC
    -- ----------------------------------------
    ELSIF p_seccion = 'todas' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort DESC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS(
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.usuario_id = v_usuario_id
                          AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', (
                        f.estado::TEXT = 'abierta'
                        AND f.fecha_hora_inicio > NOW()
                        AND NOT EXISTS(
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                              AND i.usuario_id = v_usuario_id
                              AND i.estado = 'inscrito'
                        )
                    ),
                    'puede_cancelar', (
                        f.estado::TEXT IN ('abierta', 'cerrada')
                        AND EXISTS(
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                              AND i.usuario_id = v_usuario_id
                              AND i.estado = 'inscrito'
                        )
                    ),
                    'indicador', CASE f.estado::TEXT
                        WHEN 'abierta' THEN json_build_object(
                            'tipo', 'abierta',
                            'texto', 'Inscripciones Abiertas',
                            'color', '#4CAF50',
                            'icono', 'group'
                        )
                        WHEN 'cerrada' THEN json_build_object(
                            'tipo', 'cerrada',
                            'texto', 'Inscripciones Cerradas',
                            'color', '#FFC107',
                            'icono', 'lock'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'tipo', 'en_juego',
                            'texto', 'En Juego',
                            'color', '#2196F3',
                            'icono', 'sports_soccer'
                        )
                        WHEN 'finalizada' THEN json_build_object(
                            'tipo', 'finalizada',
                            'texto', 'Finalizada',
                            'color', '#9E9E9E',
                            'icono', 'check_circle'
                        )
                        WHEN 'cancelada' THEN json_build_object(
                            'tipo', 'cancelada',
                            'texto', 'Cancelada',
                            'color', '#F44336',
                            'icono', 'cancel'
                        )
                        ELSE json_build_object(
                            'tipo', f.estado::TEXT,
                            'texto', f.estado::TEXT,
                            'color', '#9E9E9E',
                            'icono', 'info'
                        )
                    END
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE
                -- Filtro por estado (opcional, solo admin)
                (p_filtro_estado IS NULL OR f.estado::TEXT = p_filtro_estado)
                -- Filtro por fecha desde (opcional)
                AND (v_fecha_desde_parsed IS NULL OR f.fecha_hora_inicio >= v_fecha_desde_parsed)
                -- Filtro por fecha hasta (opcional)
                AND (v_fecha_hasta_parsed IS NULL OR f.fecha_hora_inicio <= v_fecha_hasta_parsed)
        ) sub;

    END IF;

    -- ========================================
    -- 6. Manejar caso sin resultados
    -- ========================================
    IF v_total IS NULL OR v_total = 0 THEN
        v_total := 0;
        v_fechas := '[]'::JSON;

        -- CA-010: Mensajes contextuales segun seccion
        CASE p_seccion
            WHEN 'proximas' THEN v_mensaje := 'No hay pichangas programadas';
            WHEN 'inscrito' THEN v_mensaje := 'No tienes inscripciones activas';
            WHEN 'historial' THEN v_mensaje := 'Aun no has participado en pichangas';
            WHEN 'en_curso' THEN v_mensaje := 'No hay pichangas en curso';
            WHEN 'todas' THEN v_mensaje := 'No se encontraron fechas con los filtros aplicados';
            ELSE v_mensaje := 'No hay fechas disponibles';
        END CASE;
    ELSE
        v_mensaje := v_total || ' fecha' || CASE WHEN v_total > 1 THEN 's' ELSE '' END || ' encontrada' || CASE WHEN v_total > 1 THEN 's' ELSE '' END;
    END IF;

    -- ========================================
    -- 7. Retornar respuesta exitosa
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fechas', v_fechas,
            'seccion', p_seccion,
            'total', v_total,
            'es_admin', v_es_admin,
            'filtros_aplicados', CASE
                WHEN p_seccion = 'todas' AND v_es_admin THEN
                    json_build_object(
                        'estado', p_filtro_estado,
                        'fecha_desde', p_fecha_desde,
                        'fecha_hasta', p_fecha_hasta
                    )
                ELSE NULL
            END
        ),
        'message', v_mensaje
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

-- Permisos
GRANT EXECUTE ON FUNCTION listar_fechas_por_rol TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION listar_fechas_por_rol IS 'E003-HU-009: Lista fechas con visibilidad por rol. FIX 2026-02-22: timezone en json_build_object - fecha_hora_inicio con sufijo +00:00.';


-- ============================================
-- FUNCION 4: obtener_mi_actividad_vivo
-- Campos corregidos:
--   - hora_inicio: raw AT TIME ZONE -> TO_CHAR con +00:00
--   - hora_fin_estimada: raw AT TIME ZONE -> TO_CHAR con +00:00
--   - iniciado_at: raw AT TIME ZONE -> TO_CHAR con +00:00
-- ============================================
CREATE OR REPLACE FUNCTION obtener_mi_actividad_vivo()
RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_fecha_activa RECORD;
    v_mi_equipo RECORD;
    v_mis_goles_totales INTEGER;
    v_partidos JSON;
    v_partido_en_curso JSON;
    v_error_hint TEXT;
    v_colores_hex CONSTANT JSON := '{
        "naranja": "#FF9800",
        "verde": "#4CAF50",
        "azul": "#2196F3",
        "rojo": "#F44336",
        "amarillo": "#FFEB3B",
        "blanco": "#FFFFFF"
    }'::JSON;
BEGIN
    -- ============================================
    -- Obtener usuario autenticado
    -- ============================================
    IF auth.uid() IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- Obtener el usuario_id de la tabla usuarios basado en auth_user_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = auth.uid();

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en tabla usuarios';
    END IF;

    -- ============================================
    -- RN-001: Buscar pichanga activa donde estoy inscrito
    -- ============================================
    SELECT f.*
    INTO v_fecha_activa
    FROM fechas f
    INNER JOIN inscripciones i ON i.fecha_id = f.id
    WHERE f.estado = 'en_juego'
    AND i.usuario_id = v_usuario_id
    AND i.estado = 'inscrito'
    ORDER BY f.fecha_hora_inicio DESC
    LIMIT 1;

    -- ============================================
    -- CA-010: Si no hay pichanga activa, retornar null
    -- ============================================
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'pichanga_activa', NULL,
                'mensaje', 'No hay pichanga activa donde estes inscrito'
            ),
            'message', 'Sin actividad'
        );
    END IF;

    -- ============================================
    -- Obtener mi equipo asignado (color_equipo)
    -- ============================================
    SELECT
        ae.color_equipo,
        ae.numero_equipo
    INTO v_mi_equipo
    FROM asignaciones_equipos ae
    WHERE ae.fecha_id = v_fecha_activa.id
    AND ae.usuario_id = v_usuario_id
    LIMIT 1;

    -- ============================================
    -- CA-006 / RN-003: Calcular mis goles totales de la jornada
    -- ============================================
    SELECT COALESCE(COUNT(*), 0)
    INTO v_mis_goles_totales
    FROM goles g
    INNER JOIN partidos p ON p.id = g.partido_id
    WHERE p.fecha_id = v_fecha_activa.id
    AND g.jugador_id = v_usuario_id
    AND g.anulado = false
    AND g.es_autogol = false;

    -- ============================================
    -- CA-003, CA-004, CA-005, CA-007, RN-002, RN-004:
    -- Lista de todos los partidos de la jornada
    -- FIX TIMEZONE: hora_inicio y hora_fin_estimada con TO_CHAR +00:00
    -- ============================================
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'partido_id', p.id,
                'equipo_local', p.equipo_local::text,
                'equipo_visitante', p.equipo_visitante::text,
                'goles_local', p.goles_local,
                'goles_visitante', p.goles_visitante,
                'estado', p.estado::text,
                'duracion_minutos', p.duracion_minutos,
                'tiempo_pausado_segundos', p.tiempo_pausado_segundos,
                'hora_inicio', CASE
                    WHEN p.hora_inicio IS NOT NULL THEN
                        TO_CHAR(p.hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"')
                    ELSE NULL
                END,
                'hora_fin_estimada', CASE
                    WHEN p.hora_fin_estimada IS NOT NULL THEN
                        TO_CHAR(p.hora_fin_estimada AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"')
                    ELSE NULL
                END,
                -- RN-002: Es mi partido si mi color_equipo coincide
                'es_mi_partido', CASE
                    WHEN v_mi_equipo.color_equipo IS NOT NULL AND
                         (p.equipo_local::text = v_mi_equipo.color_equipo::text OR
                          p.equipo_visitante::text = v_mi_equipo.color_equipo::text)
                    THEN true
                    ELSE false
                END,
                -- CA-007: Contar mis goles en este partido especifico
                'mis_goles', COALESCE((
                    SELECT COUNT(*)
                    FROM goles g
                    WHERE g.partido_id = p.id
                    AND g.jugador_id = v_usuario_id
                    AND g.anulado = false
                    AND g.es_autogol = false
                ), 0),
                -- CA-007: Detalle de mis goles por partido (minuto)
                'mis_goles_detalle', COALESCE((
                    SELECT json_agg(
                        json_build_object(
                            'minuto', g.minuto,
                            'es_autogol', g.es_autogol
                        ) ORDER BY g.minuto
                    )
                    FROM goles g
                    WHERE g.partido_id = p.id
                    AND g.jugador_id = v_usuario_id
                    AND g.anulado = false
                ), '[]'::json)
            ) ORDER BY
                -- RN-004: Orden logico
                CASE WHEN p.estado = 'en_curso' THEN 1
                     WHEN p.estado = 'finalizado' THEN 2
                     ELSE 3
                END,
                p.hora_fin_estimada DESC NULLS LAST,
                p.hora_inicio NULLS LAST,
                p.created_at
        ),
        '[]'::json
    ) INTO v_partidos
    FROM partidos p
    WHERE p.fecha_id = v_fecha_activa.id;

    -- ============================================
    -- Identificar partido en curso (si existe)
    -- ============================================
    SELECT json_build_object(
        'partido_id', p.id,
        'estoy_jugando', CASE
            WHEN v_mi_equipo.color_equipo IS NOT NULL AND
                 (p.equipo_local::text = v_mi_equipo.color_equipo::text OR
                  p.equipo_visitante::text = v_mi_equipo.color_equipo::text)
            THEN true
            ELSE false
        END
    ) INTO v_partido_en_curso
    FROM partidos p
    WHERE p.fecha_id = v_fecha_activa.id
    AND p.estado = 'en_curso'
    ORDER BY p.hora_inicio DESC NULLS LAST
    LIMIT 1;

    -- ============================================
    -- Retornar actividad completa
    -- FIX TIMEZONE: iniciado_at con TO_CHAR +00:00
    -- ============================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            -- CA-002: Informacion de la pichanga activa
            'pichanga_activa', json_build_object(
                'fecha_id', v_fecha_activa.id,
                'fecha', TO_CHAR(v_fecha_activa.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'fecha_hora', TO_CHAR(v_fecha_activa.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                'lugar', v_fecha_activa.lugar,
                'estado', v_fecha_activa.estado::text,
                'iniciado_at', CASE
                    WHEN v_fecha_activa.iniciado_at IS NOT NULL THEN
                        TO_CHAR(v_fecha_activa.iniciado_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"')
                    ELSE NULL
                END
            ),
            -- CA-002: Mi equipo asignado
            'mi_equipo', CASE
                WHEN v_mi_equipo.color_equipo IS NOT NULL THEN
                    json_build_object(
                        'color', v_mi_equipo.color_equipo::text,
                        'color_hex', COALESCE(
                            (v_colores_hex->>v_mi_equipo.color_equipo::text),
                            '#CCCCCC'
                        ),
                        'numero', v_mi_equipo.numero_equipo
                    )
                ELSE NULL
            END,
            -- CA-006: Mis goles totales
            'mis_goles_totales', v_mis_goles_totales,
            -- CA-003, CA-004, CA-005, CA-007: Lista de partidos
            'partidos', v_partidos,
            -- Partido en curso (si existe)
            'partido_en_curso', v_partido_en_curso
        ),
        'message', 'Actividad en vivo obtenida'
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

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_mi_actividad_vivo() TO anon, authenticated, service_role;

COMMENT ON FUNCTION obtener_mi_actividad_vivo IS 'E004-HU-008: Retorna la actividad en vivo del jugador actual. FIX 2026-02-22: timezone en json_build_object.';


-- ============================================
-- FUNCION 5: obtener_resumen_jornada
-- Campos corregidos:
--   - fecha_programada: raw AT TIME ZONE -> TO_CHAR con +00:00
--   - hora_inicio en partidos: raw AT TIME ZONE -> TO_CHAR con +00:00
-- ============================================
CREATE OR REPLACE FUNCTION obtener_resumen_jornada(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_fecha RECORD;
    v_partidos JSON;
    v_tabla_posiciones JSON;
    v_goleadores JSON;
    v_goleador_fecha JSON;
    v_estadisticas JSON;
    v_hay_partidos BOOLEAN;
    v_total_partidos INTEGER;
    v_partidos_finalizados INTEGER;
    v_total_goles INTEGER;
    v_promedio_goles NUMERIC(4,2);
    v_partido_mas_goles JSON;
    v_max_goles INTEGER;
    v_error_hint TEXT;
BEGIN
    -- ============================================
    -- Validar que la fecha existe
    -- ============================================
    SELECT * INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha no encontrada: %', p_fecha_id;
    END IF;

    -- ============================================
    -- Contar partidos para validacion RN-007
    -- ============================================
    SELECT COUNT(*) INTO v_total_partidos
    FROM partidos
    WHERE fecha_id = p_fecha_id;

    v_hay_partidos := (v_total_partidos > 0);

    -- ============================================
    -- Si no hay partidos, retornar estructura vacia (RN-007)
    -- FIX TIMEZONE: fecha_programada con TO_CHAR +00:00
    -- ============================================
    IF NOT v_hay_partidos THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'fecha', json_build_object(
                    'id', v_fecha.id,
                    'lugar', v_fecha.lugar,
                    'fecha_programada', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
                    'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                    'estado', v_fecha.estado::text,
                    'num_equipos', v_fecha.num_equipos
                ),
                'partidos', '[]'::json,
                'tabla_posiciones', '[]'::json,
                'goleadores', '[]'::json,
                'goleador_fecha', NULL,
                'estadisticas', json_build_object(
                    'total_partidos', 0,
                    'partidos_finalizados', 0,
                    'total_goles', 0,
                    'promedio_goles_partido', 0,
                    'partido_mas_goles', NULL
                ),
                'hay_partidos', false
            ),
            'message', 'No hay partidos programados para esta fecha'
        );
    END IF;

    -- ============================================
    -- CA-001: Obtener lista de partidos con goleadores
    -- FIX TIMEZONE: hora_inicio con TO_CHAR +00:00
    -- ============================================
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'id', p.id,
                'equipo_local', json_build_object(
                    'color', p.equipo_local::text,
                    'goles', p.goles_local
                ),
                'equipo_visitante', json_build_object(
                    'color', p.equipo_visitante::text,
                    'goles', p.goles_visitante
                ),
                'marcador', p.goles_local || ' - ' || p.goles_visitante,
                'goles_local', p.goles_local,
                'goles_visitante', p.goles_visitante,
                'estado', p.estado::text,
                'duracion_minutos', p.duracion_minutos,
                'hora_inicio', CASE
                    WHEN p.hora_inicio IS NOT NULL THEN
                        TO_CHAR(p.hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"')
                    ELSE NULL
                END,
                'goleadores', COALESCE(
                    (
                        SELECT json_agg(
                            json_build_object(
                                'jugador_id', g.jugador_id,
                                'jugador_nombre', COALESCE(u.nombre_completo, 'Desconocido'),
                                'equipo', g.equipo_anotador::text,
                                'minuto', g.minuto,
                                'es_autogol', g.es_autogol
                            ) ORDER BY g.minuto
                        )
                        FROM goles g
                        LEFT JOIN usuarios u ON u.id = g.jugador_id
                        WHERE g.partido_id = p.id
                        AND g.anulado = false
                    ),
                    '[]'::json
                )
            ) ORDER BY p.hora_inicio NULLS LAST, p.created_at
        ),
        '[]'::json
    ) INTO v_partidos
    FROM partidos p
    WHERE p.fecha_id = p_fecha_id;

    -- ============================================
    -- CA-002, RN-002, RN-008: Tabla de posiciones
    -- ============================================
    WITH partidos_finalizados AS (
        SELECT *
        FROM partidos
        WHERE fecha_id = p_fecha_id
        AND estado = 'finalizado'
    ),
    equipos_fecha AS (
        SELECT DISTINCT equipo
        FROM (
            SELECT equipo_local AS equipo FROM partidos WHERE fecha_id = p_fecha_id
            UNION
            SELECT equipo_visitante AS equipo FROM partidos WHERE fecha_id = p_fecha_id
        ) equipos
    ),
    estadisticas_equipo AS (
        SELECT
            e.equipo,
            COALESCE((
                SELECT COUNT(*)
                FROM partidos_finalizados p
                WHERE p.equipo_local = e.equipo OR p.equipo_visitante = e.equipo
            ), 0) AS pj,
            COALESCE((
                SELECT COUNT(*)
                FROM partidos_finalizados p
                WHERE (p.equipo_local = e.equipo AND p.goles_local > p.goles_visitante)
                   OR (p.equipo_visitante = e.equipo AND p.goles_visitante > p.goles_local)
            ), 0) AS pg,
            COALESCE((
                SELECT COUNT(*)
                FROM partidos_finalizados p
                WHERE (p.equipo_local = e.equipo OR p.equipo_visitante = e.equipo)
                  AND p.goles_local = p.goles_visitante
            ), 0) AS pe,
            COALESCE((
                SELECT COUNT(*)
                FROM partidos_finalizados p
                WHERE (p.equipo_local = e.equipo AND p.goles_local < p.goles_visitante)
                   OR (p.equipo_visitante = e.equipo AND p.goles_visitante < p.goles_local)
            ), 0) AS pp,
            COALESCE((
                SELECT SUM(
                    CASE
                        WHEN p.equipo_local = e.equipo THEN p.goles_local
                        ELSE p.goles_visitante
                    END
                )
                FROM partidos_finalizados p
                WHERE p.equipo_local = e.equipo OR p.equipo_visitante = e.equipo
            ), 0) AS gf,
            COALESCE((
                SELECT SUM(
                    CASE
                        WHEN p.equipo_local = e.equipo THEN p.goles_visitante
                        ELSE p.goles_local
                    END
                )
                FROM partidos_finalizados p
                WHERE p.equipo_local = e.equipo OR p.equipo_visitante = e.equipo
            ), 0) AS gc
        FROM equipos_fecha e
    ),
    tabla_calculada AS (
        SELECT
            equipo::text AS equipo,
            pj::integer,
            pg::integer,
            pe::integer,
            pp::integer,
            gf::integer,
            gc::integer,
            (gf - gc)::integer AS dif,
            (pg * 3 + pe)::integer AS pts
        FROM estadisticas_equipo
    )
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'equipo', t.equipo,
                'pj', t.pj,
                'pg', t.pg,
                'pe', t.pe,
                'pp', t.pp,
                'gf', t.gf,
                'gc', t.gc,
                'dif', t.dif,
                'pts', t.pts,
                'posicion', row_number
            )
        ),
        '[]'::json
    ) INTO v_tabla_posiciones
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                ORDER BY pts DESC, dif DESC, gf DESC, equipo
            ) AS row_number
        FROM tabla_calculada
    ) t;

    -- ============================================
    -- CA-003, RN-003: Ranking de goleadores
    -- ============================================
    WITH goles_por_jugador AS (
        SELECT
            g.jugador_id,
            u.nombre_completo AS jugador_nombre,
            g.equipo_anotador::text AS equipo,
            COUNT(*) AS goles
        FROM goles g
        JOIN partidos p ON p.id = g.partido_id
        LEFT JOIN usuarios u ON u.id = g.jugador_id
        WHERE p.fecha_id = p_fecha_id
        AND g.anulado = false
        AND g.es_autogol = false
        AND g.jugador_id IS NOT NULL
        GROUP BY g.jugador_id, u.nombre_completo, g.equipo_anotador
    )
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'jugador_id', jugador_id,
                'jugador_nombre', COALESCE(jugador_nombre, 'Desconocido'),
                'equipo', equipo,
                'goles', goles,
                'posicion', row_number
            )
        ),
        '[]'::json
    ) INTO v_goleadores
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY goles DESC, jugador_nombre) AS row_number
        FROM goles_por_jugador
    ) ranking;

    -- ============================================
    -- CA-005: Goleador de la fecha
    -- ============================================
    WITH goles_por_jugador AS (
        SELECT
            g.jugador_id,
            u.nombre_completo AS jugador_nombre,
            g.equipo_anotador::text AS equipo,
            COUNT(*) AS goles
        FROM goles g
        JOIN partidos p ON p.id = g.partido_id
        LEFT JOIN usuarios u ON u.id = g.jugador_id
        WHERE p.fecha_id = p_fecha_id
        AND g.anulado = false
        AND g.es_autogol = false
        AND g.jugador_id IS NOT NULL
        GROUP BY g.jugador_id, u.nombre_completo, g.equipo_anotador
    ),
    max_goles AS (
        SELECT MAX(goles) AS max_goles FROM goles_por_jugador
    )
    SELECT
        CASE
            WHEN (SELECT max_goles FROM max_goles) IS NULL THEN NULL
            ELSE (
                SELECT json_agg(
                    json_build_object(
                        'jugador_id', jugador_id,
                        'jugador_nombre', COALESCE(jugador_nombre, 'Desconocido'),
                        'equipo', equipo,
                        'goles', goles
                    )
                )
                FROM goles_por_jugador
                WHERE goles = (SELECT max_goles FROM max_goles)
            )
        END
    INTO v_goleador_fecha;

    -- ============================================
    -- Estadisticas generales
    -- ============================================
    SELECT COUNT(*) INTO v_partidos_finalizados
    FROM partidos
    WHERE fecha_id = p_fecha_id
    AND estado = 'finalizado';

    SELECT COALESCE(SUM(goles_local + goles_visitante), 0) INTO v_total_goles
    FROM partidos
    WHERE fecha_id = p_fecha_id
    AND estado != 'cancelado';

    IF v_partidos_finalizados > 0 THEN
        SELECT ROUND(
            SUM(goles_local + goles_visitante)::NUMERIC / v_partidos_finalizados,
            2
        ) INTO v_promedio_goles
        FROM partidos
        WHERE fecha_id = p_fecha_id
        AND estado = 'finalizado';
    ELSE
        v_promedio_goles := 0;
    END IF;

    SELECT json_build_object(
        'partido_id', p.id,
        'equipo_local', p.equipo_local::text,
        'equipo_visitante', p.equipo_visitante::text,
        'goles_local', p.goles_local,
        'goles_visitante', p.goles_visitante,
        'total_goles', p.goles_local + p.goles_visitante
    ) INTO v_partido_mas_goles
    FROM partidos p
    WHERE p.fecha_id = p_fecha_id
    AND p.estado != 'cancelado'
    ORDER BY (p.goles_local + p.goles_visitante) DESC, p.created_at
    LIMIT 1;

    v_estadisticas := json_build_object(
        'total_partidos', v_total_partidos,
        'partidos_finalizados', v_partidos_finalizados,
        'total_goles', v_total_goles,
        'promedio_goles_partido', COALESCE(v_promedio_goles, 0),
        'partido_mas_goles', v_partido_mas_goles
    );

    -- ============================================
    -- Retornar resumen completo
    -- FIX TIMEZONE: fecha_programada con TO_CHAR +00:00
    -- ============================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha', json_build_object(
                'id', v_fecha.id,
                'lugar', v_fecha.lugar,
                'fecha_programada', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"'),
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                'estado', v_fecha.estado::text,
                'num_equipos', v_fecha.num_equipos,
                'duracion_horas', v_fecha.duracion_horas,
                'costo_por_jugador', v_fecha.costo_por_jugador
            ),
            'partidos', v_partidos,
            'tabla_posiciones', v_tabla_posiciones,
            'goleadores', v_goleadores,
            'goleador_fecha', v_goleador_fecha,
            'estadisticas', v_estadisticas,
            'hay_partidos', v_hay_partidos
        ),
        'message', 'Resumen de jornada generado'
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

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_resumen_jornada(UUID) TO anon, authenticated, service_role;

COMMENT ON FUNCTION obtener_resumen_jornada IS 'E004-HU-007: Retorna el resumen completo de una fecha/jornada. FIX 2026-02-22: timezone en json_build_object.';


-- ============================================
-- VERIFICACION
-- ============================================
-- Ejecutar despues para confirmar que las funciones se actualizaron:
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'crear_fecha',
    'editar_fecha',
    'listar_fechas_por_rol',
    'obtener_mi_actividad_vivo',
    'obtener_resumen_jornada'
)
ORDER BY routine_name;
