CREATE OR replace FUNCTION delete_staff ( staff_ids bigint[]
) returns void AS $$
	declare
    office_id bigint;
    stff_id bigint;
	begin
		for stff_id in(
            select * from unnest(staff_ids)
	    )
        loop 
            delete from staff_hierarchy sh  
            where sh.chief_staff_id = stff_id or sh.sub_staff_id = stff_id;

            delete from department_staff ds where ds.staff_id = stff_id;
            
            delete from position_staff ps where ps.staff_id = stff_id;

            select os.office_id into office_id from office_staff os  where os.staff_id = stff_id;
            
            if office_id notnull
            then
                delete from office_staff os  where os.staff_id = stff_id;
                
                INSERT INTO "server".deltas
                ( value, object_id, delta_type_id)
                VALUES( 1, office_id, 1);
            end if;
            
            raise notice 'Staff deleted id = %',stff_id;
        end loop;
end; $$ language plpgsql;