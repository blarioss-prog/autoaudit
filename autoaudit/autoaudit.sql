-- Historial de cambios por usuario (fechas opcionales)
CREATE OR REPLACE FUNCTION aud.historial_usuario(
    p_usuario text,
    p_desde   timestamptz DEFAULT NULL,
    p_hasta   timestamptz DEFAULT NULL)
RETURNS TABLE (fecha_hora timestamptz, usuario text, ip text, esquema text,
               tabla text, columna text, evento text, pk_registro text,
               valor_antiguo text, valor_nuevo text)
LANGUAGE sql STABLE AS $$
    SELECT b.fecha_hora, u.nombre, s.ip, t.esquema, t.nombre, c.nombre,
           e.codigo, b.pk_registro, b.valor_antiguo, b.valor_nuevo
    FROM aud.bitacora b
    JOIN aud.configuracion cf ON cf.id = b.configuracion_id
    JOIN aud.columna c ON c.id = cf.columna_id
    JOIN aud.tabla   t ON t.id = c.tabla_id
    JOIN aud.evento  e ON e.id = cf.evento_id
    JOIN aud.usuario u ON u.id = b.usuario_id
    JOIN aud.estacion s ON s.id = b.estacion_id
    WHERE u.nombre = p_usuario
      AND (p_desde IS NULL OR b.fecha_hora >= p_desde)
      AND (p_hasta IS NULL OR b.fecha_hora <= p_hasta)
    ORDER BY b.fecha_hora, b.id;
$$;

-- Historial de cambios por columna específica
CREATE OR REPLACE FUNCTION aud.historial_columna(
    p_esquema text,
    p_tabla   text,
    p_columna text,
    p_desde   timestamptz DEFAULT NULL,
    p_hasta   timestamptz DEFAULT NULL)
RETURNS TABLE (fecha_hora timestamptz, usuario text, ip text, esquema text,
               tabla text, columna text, evento text, pk_registro text,
               valor_antiguo text, valor_nuevo text)
LANGUAGE sql STABLE AS $$
    SELECT b.fecha_hora, u.nombre, s.ip, t.esquema, t.nombre, c.nombre,
           e.codigo, b.pk_registro, b.valor_antiguo, b.valor_nuevo
    FROM aud.bitacora b
    JOIN aud.configuracion cf ON cf.id = b.configuracion_id
    JOIN aud.columna c ON c.id = cf.columna_id
    JOIN aud.tabla   t ON t.id = c.tabla_id
    JOIN aud.evento  e ON e.id = cf.evento_id
    JOIN aud.usuario u ON u.id = b.usuario_id
    JOIN aud.estacion s ON s.id = b.estacion_id
    WHERE t.esquema = p_esquema AND t.nombre = p_tabla AND c.nombre = p_columna
      AND (p_desde IS NULL OR b.fecha_hora >= p_desde)
      AND (p_hasta IS NULL OR b.fecha_hora <= p_hasta)
    ORDER BY b.fecha_hora, b.id;
$$;