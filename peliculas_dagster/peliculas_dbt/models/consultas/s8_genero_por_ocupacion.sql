-- S8. Género mejor votado por cada ocupación (mínimo 20 votos)
with stats as (
    select
        ocupacion,
        genero,
        count(*)                 as votos,
        round(avg(puntaje), 2)   as promedio
    from {{ ref('int_votos_genero') }}
    group by ocupacion, genero
    having count(*) >= 20
)
select distinct on (ocupacion) ocupacion, genero, promedio, votos
from stats
order by ocupacion, promedio desc, votos desc
