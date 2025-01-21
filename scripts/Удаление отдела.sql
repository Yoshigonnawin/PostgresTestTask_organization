CREATE OR replace FUNCTION delete_department ( depart_ids int4[]
) returns void AS $$
    declare
    staff_ids int4[];
    begin
        select array_agg(ds.staff_id) into staff_ids 
        from department_staff ds 
        where ds.depart_id = any(depart_ids); 

        delete from department_staff ds  where ds.depart_id = any(depart_ids);
        delete from department_offices dof where dof.depart_id = any(depart_ids);
        delete from department d where d.id = any(depart_ids);

        perform delete_staff(staff_ids); 
    end; 
$$ language plpgsql;