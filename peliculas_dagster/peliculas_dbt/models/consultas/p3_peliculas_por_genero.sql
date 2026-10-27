-- P3. Cantidad de películas por género
select
    g.nombre   as genero,
    count(*)   as peliculas
from {{ ref('pelicula_genero') }} pg
join {{ ref('genero') }} g using (genero_id)
group by g.nombre
order by peliculas desc
