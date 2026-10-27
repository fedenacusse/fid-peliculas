-- S10. Promedio de rating por género
select
    genero,
    count(*)                 as votos,
    round(avg(puntaje), 2)   as promedio
from {{ ref('int_votos_genero') }}
group by genero
order by promedio desc
