CREATE OR replace FUNCTION delete_positions ( pos_ids int4[]
) returns void AS $$
    declare
        staff_ids int4[];
    begin

    select array_agg(ps.staff_id)::int4[] into  staff_ids from position_staff ps where ps.position_id = any(pos_ids);

    delete from position_staff ps where ps.position_id = any(pos_ids);
    delete from positions p where p.id = any(pos_ids);

    perform delete_staff(staff_ids);

end; $$ language plpgsql;