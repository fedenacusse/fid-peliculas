select
    u.usuario_id,
    o.ocupacion_id,
    u.alta
from {{ ref('stg_usuarios') }} u
join {{ ref('ocupacion') }} o on o.nombre = u.ocupacion
