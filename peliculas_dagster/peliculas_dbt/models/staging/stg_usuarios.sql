select
    id::int                                       as usuario_id,
    lower(trim("Occupation"))                     as ocupacion,
    nullif(trim("Active_Since"), '')::timestamp   as alta
from {{ source('raw', 'usuarios') }}
