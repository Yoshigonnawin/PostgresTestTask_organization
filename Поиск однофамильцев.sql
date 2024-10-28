

create type find_namesakes_out as (stf_fio text, others_fio text);



create or replace function find_namesakes(in staff_id integer,out outp find_namesakes_out) 
returns find_namesakes_out AS $$ 
declare
	staff_info record;
	l_name_prep text; 
begin 
	select * into staff_info from staff s where s.id = staff_id;
	case 
		when RIGHT(staff_info.l_name, 2)='ый'
		then 
			l_name_prep = regexp_replace(staff_info.l_name, 'ый$', '', 'g');
			l_name_prep = concat(l_name_prep,'%');
			
		when RIGHT(staff_info.l_name, 2)='ая'
		then l_name_prep = regexp_replace(staff_info.l_name, 'ая$', '', 'g');
			l_name_prep = concat(l_name_prep,'%');
			
		when RIGHT(staff_info.l_name, 1)='а'
		then l_name_prep = regexp_replace(staff_info.l_name, 'а$', '', 'g');
			l_name_prep = concat(l_name_prep,'%');
			
		when RIGHT(staff_info.l_name, 2)='ой'
		then l_name_prep = regexp_replace(staff_info.l_name, 'ой$', '', 'g');
			l_name_prep = concat(l_name_prep,'%');
		else
			l_name_prep = concat(staff_info.l_name,'%');
	end case;
	
	select concat(staff_info.f_name,' ',staff_info.s_name,' ',staff_info.l_name) as stf,
	string_agg(concat(s.f_name,' ',s.s_name,' ',s.l_name),', ') as other
	into outp 
	from staff s 
	where 1=1
	and s.l_name like(l_name_prep)
	and s.id != staff_id;
	
end$$LANGUAGE plpgsql;


select * from find_namesakes(3)
