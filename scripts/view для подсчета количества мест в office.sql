create or replace view office_current_vacant_seats as 
select o.id, sum(coalesce(d.value,0)) + o.staff_number as  vacant_seats
from offices o 
left join deltas d on d.object_id = o.id 
group by o.id;


select * from office_current_vacant_seats where id = 2;

INSERT INTO "server".deltas
(id, value, object_id, delta_type_id)
VALUES(gen_random_uuid(), '-1'::integer, 2, 1);