SELECT position_id, staff_id
FROM "server".position_staff;

drop function link_staff_w_office;

CREATE OR replace FUNCTION link_staff_w_office( stff_id integer, 
 office_id integer
) returns void AS $$
DECLARE 
	staff_inf record;
BEGIN 
	SELECT (case when s.salary isnull
			then p.salary
			else s.salary end
	) as t_salary,
		s.*
	into staff_inf
	FROM staff s 
	JOIN position_staff ps ON ps.staff_id = s.id 
	join positions p on p.id = ps.position_id
	where s.id = stff_id;

	update staff  set salary =staff_inf.t_salary where id = staff_inf.id;
	
	if (select vacant_seats from office_current_vacant_seats where id = office_id
	) = 0 
	then
		raise exception 'Заняты все места в офисе office_id = % ',office_id;
	end if; 
	
	INSERT INTO "server".deltas
	(object_id, delta_type_id)
	VALUES(office_id, 1); 

	INSERT INTO "server".office_staff
	(office_id, staff_id)
	VALUES(office_id, stff_id);
END;
$$ LANGUAGE plpgsql;



select link_staff_w_office(1,2);