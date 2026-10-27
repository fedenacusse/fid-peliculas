-- S9. Promedio general de todos los votos
select
    count(*)                 as votos,
    round(avg(puntaje), 3)   as promedio_general
from {{ ref('calificacion') }}
