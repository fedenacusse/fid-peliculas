select
    usuario_id,
    pelicula_id,
    puntaje,
    fecha
from {{ ref('stg_scores') }}
