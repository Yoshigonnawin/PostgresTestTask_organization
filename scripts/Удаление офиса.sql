CREATE OR replace FUNCTION delete_offices ( offices_ids int4[]
) returns void AS $$
	declare 
	begin
        delete from deltas d where d.object_id  = any(offices_ids);
        delete from office_staff os where os.office_id = any(offices_ids);
        delete from department_offices dof where dof.office_id = any(offices_ids);
        delete from offices o where o.id  = any(offices_ids);
    end; 
$$ language plpgsql;