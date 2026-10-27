-- U2. Usuarios con más votos
select
    usuario_id,
    ocupacion,
    count(*)                 as votos,
    round(avg(puntaje), 2)   as promedio_que_da
from {{ ref('int_votos') }}
group by usuario_id, ocupacion
order by votos desc
limit 20
