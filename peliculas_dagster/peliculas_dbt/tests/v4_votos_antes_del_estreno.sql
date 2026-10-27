-- V4a. Fechas: votos a películas que todavía no se habían estrenado
select
    c.usuario_id,
    p.titulo,
    p.fecha_estreno,
    c.fecha as fecha_voto
from {{ ref('calificacion') }} c
join {{ ref('pelicula') }} p using (pelicula_id)
where c.fecha::date < p.fecha_estreno
