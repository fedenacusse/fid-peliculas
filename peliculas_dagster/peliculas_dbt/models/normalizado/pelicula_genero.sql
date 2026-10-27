-- Tabla puente de la relación N:M película-género
select
    pg.pelicula_id,
    g.genero_id
from {{ ref('stg_peliculas_generos') }} pg
join {{ ref('genero') }} g on g.nombre = pg.genero
