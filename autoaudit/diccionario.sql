SELECT aud.configurar('public', 'cliente',
       ARRAY['nombre','telefono'],
       ARRAY['INSERT','UPDATE','DELETE']);

select * from aud.configuracion;


SELECT aud.configurar('public', 'cliente', ARRAY['correo'], ARRAY['INSERT']);