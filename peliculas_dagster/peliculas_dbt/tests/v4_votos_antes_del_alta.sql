-- V4b. Fechas: votos anteriores a la fecha de alta del usuario
select
    c.usuario_id,
    u.alta,
    c.fecha as fecha_voto
from {{ ref('calificacion') }} c
join {{ ref('usuario') }} u using (usuario_id)
where c.fecha < u.alta
