-- P5. Películas con más géneros
select
    p.titulo,
    count(*)                                          as cant_generos,
    string_agg(g.nombre, ', ' order by g.nombre)      as generos
from {{ ref('pelicula_genero') }} pg
join {{ ref('pelicula') }} p using (pelicula_id)
join {{ ref('genero') }}   g using (genero_id)
group by p.pelicula_id, p.titulo
order by cant_generos desc, p.titulo
limit 20
