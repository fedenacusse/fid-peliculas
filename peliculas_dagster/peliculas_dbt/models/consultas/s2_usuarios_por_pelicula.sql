-- S2. "Usuarios con más votos / película".
-- Cada usuario vota una sola vez por película, así que se muestra cuántos
-- usuarios distintos votó cada película y qué ocupación aportó más votos.
with por_ocupacion as (
    select
        pelicula_id,
        ocupacion,
        count(*) as votos,
        rank() over (partition by pelicula_id order by count(*) desc) as r
    from {{ ref('int_votos') }}
    group by pelicula_id, ocupacion
)
select
    s.titulo,
    s.votos                                                  as usuarios,
    string_agg(po.ocupacion, ', ' order by po.ocupacion)     as ocupacion_que_mas_voto
from {{ ref('int_stats_pelicula') }} s
join por_ocupacion po on po.pelicula_id = s.pelicula_id and po.r = 1
group by s.pelicula_id, s.titulo, s.votos
order by usuarios desc
limit 20
