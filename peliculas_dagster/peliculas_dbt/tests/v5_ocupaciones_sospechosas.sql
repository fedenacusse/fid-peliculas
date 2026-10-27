-- V5. Ocupaciones que no parecen ocupaciones o que se pisan entre sí
-- ("itba" es una facultad, "none" y "other" significan lo mismo).
select o.nombre, count(*) as usuarios
from {{ ref('usuario') }} u
join {{ ref('ocupacion') }} o using (ocupacion_id)
where o.nombre in ('itba', 'none', 'other')
group by o.nombre
