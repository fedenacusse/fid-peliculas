-- Cada voto con los datos de quién votó y qué película.
-- Lo usan casi todas las consultas: se escribe una vez y se reutiliza con ref().
select
    c.usuario_id,
    c.pelicula_id,
    c.puntaje,
    c.fecha,
    o.nombre        as ocupacion,
    p.titulo,
    p.anio_titulo,
    p.fecha_estreno
from {{ ref('calificacion') }} c
join {{ ref('usuario') }}   u using (usuario_id)
join {{ ref('ocupacion') }} o using (ocupacion_id)
join {{ ref('pelicula') }}  p using (pelicula_id)
