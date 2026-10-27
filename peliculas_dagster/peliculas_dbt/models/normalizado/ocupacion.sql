-- La ocupación deja de ser texto repetido en cada usuario (3FN).
-- El id sale de ordenar por nombre: siempre da el mismo resultado (idempotente).
select
    row_number() over (order by ocupacion)::int as ocupacion_id,
    ocupacion                                    as nombre
from (select distinct ocupacion from {{ ref('stg_usuarios') }}) o
