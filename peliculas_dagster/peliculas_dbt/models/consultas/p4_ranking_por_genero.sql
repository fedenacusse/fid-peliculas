-- P4. Ranking por género: top 3 de cada género (mínimo 20 votos)
with stats as (
    select
        genero,
        titulo,
        count(*)                 as votos,
        round(avg(puntaje), 2)   as promedio
    from {{ ref('int_votos_genero') }}
    group by genero, pelicula_id, titulo
    having count(*) >= 20
),
ranking as (
    select *, rank() over (partition by genero order by promedio desc, votos desc) as puesto
    from stats
)
select genero, puesto, titulo, promedio, votos
from ranking
where puesto <= 3
order by genero, puesto
