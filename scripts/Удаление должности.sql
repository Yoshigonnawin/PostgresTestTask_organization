CREATE OR replace FUNCTION delete_positions ( pos_ids int4[]
) returns void AS $$
    declare
        pos_id int4;
        staff_ids bigint[];
    begin
    for pos_id in(
        select unnest(pos_ids) 
    )
    loop
        select array_agg(ps.staff_id)::bigint[] into  staff_ids from position_staff ps where ps.position_id = pos_id;
        delete from position_staff ps where ps.position_id = pos_id;
        delete from positions p where p.id = pos_id;

        perform delete_staff(staff_ids);
    end loop;
end; $$ language plpgsql;