--Ввиде view
drop view current_office_occupancy;

CREATE OR replace VIEW current_office_occupancy AS
	SELECT o.id,o.num,o.staff_number,ofs.vacant_seats
	FROM offices o
	join office_current_vacant_seats ofs on o.id = ofs.id
	where ofs.vacant_seats>0
	order by ofs.vacant_seats desc;


select * from current_office_occupancy;





--ввиде функции
create or replace function current_office_occupancy_func(is_desc boolean)
returns table(id integer,num integer,staff_number integer,vacant_seats bigint)  as $$
declare
	quer text; 
	
begin
	if  is_desc = false
		then
			quer = 'SELECT o.id,o.num,o.staff_number,ofs.vacant_seats
					FROM offices o
					join office_current_vacant_seats ofs on o.id = ofs.id
					where ofs.vacant_seats>0
					order by ofs.vacant_seats';
		else
			quer = 'SELECT o.id,o.num,o.staff_number,ofs.vacant_seats
					FROM offices o
					join office_current_vacant_seats ofs on o.id = ofs.id
					where ofs.vacant_seats>0
					order by ofs.vacant_seats desc';
	end if;
	return query execute quer;
	
end;$$ language plpgsql;

select * from current_office_occupancy_func(false);
