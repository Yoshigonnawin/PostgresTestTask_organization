/*
Создание таблиц
*/
create table department(
id serial primary key,
name text NOT NULL
);

CREATE SEQUENCE "server".offices_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;

create table offices(
id serial primary key,
num integer default nextval('server.offices_seq'), 
staff_number integer not null,
address text default NULL
);


create table staff(
id serial primary key,
f_name text not null,
s_name text,
l_name text not null,
date_birth date not null,
salary int8 default NULL,
);


create table positions(
id serial primary key,
name text default 'Планктон',
salary bigint default 2000000 -- в рублях *100
); 


/*
Создание кросс таблиц
*/

create table department_offices(
depart_id integer not null REFERENCES  department,
office_id integer not null references offices,
unique(depart_id,office_id)
);


create table department_staff(
depart_id integer not null REFERENCES  department,
staff_id integer not null references staff,
unique(depart_id,staff_id)
);

create table office_staff(
office_id integer not null REFERENCES  offices,
staff_id integer not null references staff,
unique(office_id , staff_id)
);

create table position_staff(
position_id integer not null references positions,
staff_id integer not null references staff,
unique(position_id,staff_id)
);

create table staff_hierarchy(
chief_staff_id integer references staff,
sub_staff_id integer references staff,
unique(chief_staff_id,sub_staff_id)
);

/*
Создание таблицы с дельтами для подсчета актульного количества мест в офисе
*/
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

create table deltas_type(
id serial primary key,
tag varchar(50)
);


create table deltas(
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
value int8 default -1,
object_id bigint not null,
delta_type_id integer not null references  deltas_type
);

