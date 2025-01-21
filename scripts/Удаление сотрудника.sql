CREATE OR replace FUNCTION delete_staff ( staff_ids int4[]
) returns void AS $$
	declare
    office_id_num record;
	begin

        for office_id_num in (
            select os.office_id,count(staff_id) as nums 
            from office_staff os 
            where os.staff_id = any(staff_ids)
            group by os.office_id 
        )
        loop
            INSERT INTO "server".deltas
            ( value, object_id, delta_type_id)
            VALUES( office_id_num.nums, office_id_num.office_id, 1);
        end loop;
        
        delete from staff_hierarchy sh  
        where sh.chief_staff_id = any(staff_ids) or sh.sub_staff_id = any(staff_ids);

        delete from department_staff ds where ds.staff_id = any(staff_ids);
            
        delete from position_staff ps where ps.staff_id = any(staff_ids);

        delete from office_staff os  where os.staff_id = any(staff_ids);
            
        raise notice 'Staff deleted id = %',staff_ids;
     
end; $$ language plpgsql;