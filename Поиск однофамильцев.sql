

create type find_namesakes_out as (stf_fio text, others_fio text);



create or replace function find_namesakes(in staff_id integer,out outp find_namesakes_out) 
returns find_namesakes_out AS $$ 
declare
	staff_info record;
	l_name_prep text; 
begin 
	select * into staff_info from staff s where s.id = staff_id;
	l_name_prep = lower(staff_info.l_name);
	case 
		when RIGHT(l_name_prep, 2)='ый'
		then l_name_prep = regexp_replace(l_name_prep, 'ый$', '', 'g');
		when RIGHT(l_name_prep, 2)='ая'
		then l_name_prep = regexp_replace(l_name_prep, 'ая$', '', 'g');
		when RIGHT(l_name_prep, 1)='а'
		then l_name_prep = regexp_replace(l_name_prep, 'а$', '', 'g');
		when RIGHT(l_name_prep, 2)='ой'
		then l_name_prep = regexp_replace(l_name_prep, 'ой$', '', 'g');
		else 
	end case;
	l_name_prep = concat(l_name_prep,'%');

	select concat(staff_info.f_name,' ',staff_info.s_name,' ',staff_info.l_name) as stf,
	string_agg(concat(s.f_name,' ',s.s_name,' ',s.l_name),', ') as other
	into outp 
	from staff s 
	where 1=1
	and lower(s.l_name) like(l_name_prep)
	and s.id != staff_id;
	
end$$LANGUAGE plpgsql;


select * from find_namesakes(3)

--если нужно найти по каждому сотруднику


create or replace view find_namesakes_all as 
select s.id,st.* 
from staff s 
join find_namesakes(s.id) st on true
order by s.id;

select * from find_namesakes_all;