SELECT aud.generar_trigger('public', 'cliente');

INSERT INTO public.cliente (nombre, telefono) VALUES ('Ana', '5555-1234');

UPDATE public.cliente SET telefono = '4444-0000' WHERE nombre = 'Ana';
DELETE FROM public.cliente WHERE nombre = 'Ana';

SELECT b.id, t.nombre AS tabla, c.nombre AS columna, e.codigo AS evento,
       u.nombre AS usuario, s.ip, b.pk_registro,
       b.valor_antiguo, b.valor_nuevo, b.fecha_hora
FROM aud.bitacora b
JOIN aud.configuracion cf ON cf.id = b.configuracion_id
JOIN aud.columna c ON c.id = cf.columna_id
JOIN aud.tabla   t ON t.id = c.tabla_id
JOIN aud.evento  e ON e.id = cf.evento_id
JOIN aud.usuario u ON u.id = b.usuario_id
JOIN aud.estacion s ON s.id = b.estacion_id
ORDER BY b.id;