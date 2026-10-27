-- U3. Rating promedio que da cada ocupación
select
    ocupacion,
    count(distinct usuario_id)  as usuarios,
    count(*)                    as votos,
    round(avg(puntaje), 2)      as promedio
from {{ ref('int_votos') }}
group by ocupacion
order by promedio desc
