-- S6. Género mejor y peor votado
with g as (
    select
        genero,
        count(*)                 as votos,
        round(avg(puntaje), 2)   as promedio
    from {{ ref('int_votos_genero') }}
    group by genero
)
(select 'mejor' as extremo, * from g order by promedio desc limit 1)
union all
(select 'peor'  as extremo, * from g order by promedio asc  limit 1)
