| seccion  | tipo_enum          | valores                                                    |
| -------- | ------------------ | ---------------------------------------------------------- |
| ## ENUMs | color_equipo       | naranja, verde, azul, rojo, amarillo, blanco               |
| ## ENUMs | estado_fecha       | abierta, cerrada, en_juego, finalizada, cancelada          |
| ## ENUMs | estado_inscripcion | inscrito, cancelado                                        |
| ## ENUMs | estado_pago        | pendiente, pagado, anulado                                 |
| ## ENUMs | estado_partido     | pendiente, en_curso, pausado, finalizado, cancelado        |
| ## ENUMs | estado_usuario     | pendiente_aprobacion, aprobado, rechazado                  |
| ## ENUMs | posicion_jugador   | arquero, defensa, mediocampista, delantero                 |
| ## ENUMs | rol_usuario        | admin, jugador                                             |
| ## ENUMs | tipo_notificacion  | nuevo_registro, cuenta_aprobada, cuenta_rechazada, general |


| seccion   | table_name           | column_name              | data_type                | tipo_real          | is_nullable | column_default                 |
| --------- | -------------------- | ------------------------ | ------------------------ | ------------------ | ----------- | ------------------------------ |
| ## Tablas | asignaciones_equipos | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | asignaciones_equipos | fecha_id                 | uuid                     | uuid               | NO          | null                           |
| ## Tablas | asignaciones_equipos | usuario_id               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | asignaciones_equipos | color_equipo             | USER-DEFINED             | color_equipo       | NO          | null                           |
| ## Tablas | asignaciones_equipos | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | asignaciones_equipos | updated_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | asignaciones_equipos | numero_equipo            | integer                  | int4               | NO          | 1                              |
| ## Tablas | asignaciones_equipos | asignado_por             | uuid                     | uuid               | YES         | null                           |
| ## Tablas | asignaciones_equipos | asignado_at              | timestamp with time zone | timestamptz        | YES         | now()                          |
| ## Tablas | fechas               | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | fechas               | fecha_hora_inicio        | timestamp with time zone | timestamptz        | NO          | null                           |
| ## Tablas | fechas               | duracion_horas           | integer                  | int4               | NO          | null                           |
| ## Tablas | fechas               | lugar                    | text                     | text               | NO          | null                           |
| ## Tablas | fechas               | num_equipos              | integer                  | int4               | NO          | null                           |
| ## Tablas | fechas               | costo_por_jugador        | numeric                  | numeric            | NO          | null                           |
| ## Tablas | fechas               | estado                   | USER-DEFINED             | estado_fecha       | NO          | 'abierta'::estado_fecha        |
| ## Tablas | fechas               | created_by               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | fechas               | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | fechas               | updated_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | fechas               | cerrado_por              | uuid                     | uuid               | YES         | null                           |
| ## Tablas | fechas               | cerrado_at               | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | fechas               | reabierto_por            | uuid                     | uuid               | YES         | null                           |
| ## Tablas | fechas               | reabierto_at             | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | fechas               | finalizado_por           | uuid                     | uuid               | YES         | null                           |
| ## Tablas | fechas               | finalizado_at            | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | fechas               | comentarios_finalizacion | text                     | text               | YES         | null                           |
| ## Tablas | fechas               | hubo_incidente           | boolean                  | bool               | YES         | false                          |
| ## Tablas | fechas               | descripcion_incidente    | text                     | text               | YES         | null                           |
| ## Tablas | fechas               | limite_jugadores         | integer                  | int4               | YES         | null                           |
| ## Tablas | fechas               | iniciado_por             | uuid                     | uuid               | YES         | null                           |
| ## Tablas | fechas               | iniciado_at              | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | goles                | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | goles                | partido_id               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | goles                | equipo_anotador          | USER-DEFINED             | color_equipo       | NO          | null                           |
| ## Tablas | goles                | jugador_id               | uuid                     | uuid               | YES         | null                           |
| ## Tablas | goles                | minuto                   | integer                  | int4               | NO          | null                           |
| ## Tablas | goles                | es_autogol               | boolean                  | bool               | NO          | false                          |
| ## Tablas | goles                | created_by               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | goles                | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | goles                | anulado                  | boolean                  | bool               | NO          | false                          |
| ## Tablas | goles                | anulado_at               | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | goles                | anulado_por              | uuid                     | uuid               | YES         | null                           |
| ## Tablas | inscripciones        | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | inscripciones        | fecha_id                 | uuid                     | uuid               | NO          | null                           |
| ## Tablas | inscripciones        | usuario_id               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | inscripciones        | estado                   | USER-DEFINED             | estado_inscripcion | NO          | 'inscrito'::estado_inscripcion |
| ## Tablas | inscripciones        | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | inscripciones        | updated_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | inscripciones        | cancelado_at             | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | inscripciones        | cancelado_por            | uuid                     | uuid               | YES         | null                           |
| ## Tablas | inscripciones        | inscrito_por             | uuid                     | uuid               | YES         | null                           |
| ## Tablas | intentos_login       | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | intentos_login       | email                    | character varying        | varchar            | NO          | null                           |
| ## Tablas | intentos_login       | intentos_fallidos        | integer                  | int4               | NO          | 0                              |
| ## Tablas | intentos_login       | bloqueado_hasta          | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | intentos_login       | ultimo_intento_at        | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | intentos_login       | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | intentos_login       | updated_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | notificaciones       | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | notificaciones       | usuario_id               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | notificaciones       | tipo                     | USER-DEFINED             | tipo_notificacion  | NO          | 'general'::tipo_notificacion   |
| ## Tablas | notificaciones       | titulo                   | character varying        | varchar            | NO          | null                           |
| ## Tablas | notificaciones       | mensaje                  | text                     | text               | NO          | null                           |
| ## Tablas | notificaciones       | metadata                 | jsonb                    | jsonb              | YES         | '{}'::jsonb                    |
| ## Tablas | notificaciones       | leida                    | boolean                  | bool               | NO          | false                          |
| ## Tablas | notificaciones       | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | pagos                | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | pagos                | inscripcion_id           | uuid                     | uuid               | NO          | null                           |
| ## Tablas | pagos                | usuario_id               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | pagos                | fecha_id                 | uuid                     | uuid               | NO          | null                           |
| ## Tablas | pagos                | monto                    | numeric                  | numeric            | NO          | null                           |
| ## Tablas | pagos                | estado                   | USER-DEFINED             | estado_pago        | NO          | 'pendiente'::estado_pago       |
| ## Tablas | pagos                | fecha_pago               | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | pagos                | registrado_por           | uuid                     | uuid               | YES         | null                           |
| ## Tablas | pagos                | notas                    | text                     | text               | YES         | null                           |
| ## Tablas | pagos                | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | pagos                | updated_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | partidos             | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | partidos             | fecha_id                 | uuid                     | uuid               | NO          | null                           |
| ## Tablas | partidos             | equipo_local             | USER-DEFINED             | color_equipo       | NO          | null                           |
| ## Tablas | partidos             | equipo_visitante         | USER-DEFINED             | color_equipo       | NO          | null                           |
| ## Tablas | partidos             | duracion_minutos         | integer                  | int4               | NO          | null                           |
| ## Tablas | partidos             | estado                   | USER-DEFINED             | estado_partido     | NO          | 'pendiente'::estado_partido    |
| ## Tablas | partidos             | hora_inicio              | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | partidos             | hora_fin_estimada        | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | partidos             | tiempo_pausado_segundos  | integer                  | int4               | NO          | 0                              |
| ## Tablas | partidos             | pausado_at               | timestamp with time zone | timestamptz        | YES         | null                           |
| ## Tablas | partidos             | created_by               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | partidos             | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | partidos             | updated_at               | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | partidos             | goles_local              | integer                  | int4               | NO          | 0                              |
| ## Tablas | partidos             | goles_visitante          | integer                  | int4               | NO          | 0                              |
| ## Tablas | sesiones_log         | id                       | uuid                     | uuid               | NO          | gen_random_uuid()              |
| ## Tablas | sesiones_log         | usuario_id               | uuid                     | uuid               | NO          | null                           |
| ## Tablas | sesiones_log         | auth_user_id             | uuid                     | uuid               | NO          | null                           |
| ## Tablas | sesiones_log         | evento                   | character varying        | varchar            | NO          | null                           |
| ## Tablas | sesiones_log         | ip_address               | inet                     | inet               | YES         | null                           |
| ## Tablas | sesiones_log         | user_agent               | text                     | text               | YES         | null                           |
| ## Tablas | sesiones_log         | fecha_evento             | timestamp with time zone | timestamptz        | NO          | now()                          |
| ## Tablas | sesiones_log         | created_at               | timestamp with time zone | timestamptz        | NO          | now()                          |