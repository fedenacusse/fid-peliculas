-- S7. Películas que nunca recibieron un voto
select
    p.pelicula_id,
    p.titulo,
    p.fecha_estreno
from {{ ref('pelicula') }} p
where not exists (
    select 1 from {{ ref('calificacion') }} c where c.pelicula_id = p.pelicula_id
)
order by p.titulo
