-- S4. Película mejor votada por cada ocupación (mínimo 5 votos de esa ocupación)
with stats as (
    select
        ocupacion,
        titulo,
        count(*)                 as votos,
        round(avg(puntaje), 2)   as promedio
    from {{ ref('int_votos') }}
    group by ocupacion, pelicula_id, titulo
    having count(*) >= 5
)
select distinct on (ocupacion) ocupacion, titulo, promedio, votos
from stats
order by ocupacion, promedio desc, votos desc
