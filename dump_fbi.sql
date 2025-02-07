--
-- PostgreSQL database dump
--

-- Dumped from database version 17.0 (Debian 17.0-1.pgdg120+1)
-- Dumped by pg_dump version 17.0 (Debian 17.0-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: server; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA server;


ALTER SCHEMA server OWNER TO postgres;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA server;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: find_namesakes_out; Type: TYPE; Schema: server; Owner: postgres
--

CREATE TYPE server.find_namesakes_out AS (
	stf_fio text,
	others_fio text
);


ALTER TYPE server.find_namesakes_out OWNER TO postgres;

--
-- Name: current_office_occupancy_func(boolean); Type: FUNCTION; Schema: server; Owner: postgres
--

CREATE FUNCTION server.current_office_occupancy_func(is_desc boolean) RETURNS TABLE(id integer, num integer, staff_number integer, vacant_seats bigint)
    LANGUAGE plpgsql
    AS $$
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
	
end;$$;


ALTER FUNCTION server.current_office_occupancy_func(is_desc boolean) OWNER TO postgres;

--
-- Name: find_namesakes(integer); Type: FUNCTION; Schema: server; Owner: postgres
--

CREATE FUNCTION server.find_namesakes(staff_id integer, OUT outp server.find_namesakes_out) RETURNS server.find_namesakes_out
    LANGUAGE plpgsql
    AS $_$ 
declare
	staff_info record;
	l_name_prep text; 
--	outp record;
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
	
end$_$;


ALTER FUNCTION server.find_namesakes(staff_id integer, OUT outp server.find_namesakes_out) OWNER TO postgres;

--
-- Name: link_staff_w_office(integer, integer); Type: FUNCTION; Schema: server; Owner: postgres
--

CREATE FUNCTION server.link_staff_w_office(stff_id integer, office_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION server.link_staff_w_office(stff_id integer, office_id integer) OWNER TO postgres;

--
-- Name: office_current_vacant_seats; Type: VIEW; Schema: server; Owner: postgres
--

CREATE VIEW server.office_current_vacant_seats AS
SELECT
    NULL::integer AS id,
    NULL::numeric AS vacant_seats;


ALTER VIEW server.office_current_vacant_seats OWNER TO postgres;

--
-- Name: offices_seq; Type: SEQUENCE; Schema: server; Owner: postgres
--

CREATE SEQUENCE server.offices_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE server.offices_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: offices; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.offices (
    id integer NOT NULL,
    num integer DEFAULT nextval('server.offices_seq'::regclass),
    staff_number integer NOT NULL,
    address text
);


ALTER TABLE server.offices OWNER TO postgres;

--
-- Name: current_office_occupancy; Type: VIEW; Schema: server; Owner: postgres
--

CREATE VIEW server.current_office_occupancy AS
 SELECT o.id,
    o.num,
    o.staff_number,
    ofs.vacant_seats
   FROM (server.offices o
     JOIN server.office_current_vacant_seats ofs ON ((o.id = ofs.id)))
  WHERE (ofs.vacant_seats > (0)::numeric)
  ORDER BY ofs.vacant_seats DESC;


ALTER VIEW server.current_office_occupancy OWNER TO postgres;

--
-- Name: deltas; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.deltas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    value bigint DEFAULT '-1'::integer,
    object_id bigint NOT NULL,
    delta_type_id integer NOT NULL
);


ALTER TABLE server.deltas OWNER TO postgres;

--
-- Name: deltas_type; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.deltas_type (
    id integer NOT NULL,
    tag character varying(50)
);


ALTER TABLE server.deltas_type OWNER TO postgres;

--
-- Name: deltas_type_id_seq; Type: SEQUENCE; Schema: server; Owner: postgres
--

CREATE SEQUENCE server.deltas_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE server.deltas_type_id_seq OWNER TO postgres;

--
-- Name: deltas_type_id_seq; Type: SEQUENCE OWNED BY; Schema: server; Owner: postgres
--

ALTER SEQUENCE server.deltas_type_id_seq OWNED BY server.deltas_type.id;


--
-- Name: department; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.department (
    id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE server.department OWNER TO postgres;

--
-- Name: department_id_seq; Type: SEQUENCE; Schema: server; Owner: postgres
--

CREATE SEQUENCE server.department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE server.department_id_seq OWNER TO postgres;

--
-- Name: department_id_seq; Type: SEQUENCE OWNED BY; Schema: server; Owner: postgres
--

ALTER SEQUENCE server.department_id_seq OWNED BY server.department.id;


--
-- Name: department_offices; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.department_offices (
    depart_id integer NOT NULL,
    office_id integer NOT NULL
);


ALTER TABLE server.department_offices OWNER TO postgres;

--
-- Name: department_staff; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.department_staff (
    depart_id integer NOT NULL,
    staff_id integer NOT NULL
);


ALTER TABLE server.department_staff OWNER TO postgres;

--
-- Name: position_staff; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.position_staff (
    position_id integer NOT NULL,
    staff_id integer NOT NULL
);


ALTER TABLE server.position_staff OWNER TO postgres;

--
-- Name: positions; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.positions (
    id integer NOT NULL,
    name text DEFAULT 'Планктон'::text,
    salary bigint DEFAULT 2000000
);


ALTER TABLE server.positions OWNER TO postgres;

--
-- Name: staff; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.staff (
    id integer NOT NULL,
    f_name text NOT NULL,
    s_name text,
    l_name text NOT NULL,
    date_birth date NOT NULL,
    salary bigint
);


ALTER TABLE server.staff OWNER TO postgres;

--
-- Name: departments_wealthiest_staff; Type: VIEW; Schema: server; Owner: postgres
--

CREATE VIEW server.departments_wealthiest_staff AS
 WITH staff_sallary AS (
         SELECT
                CASE
                    WHEN (s.salary IS NULL) THEN p.salary
                    ELSE s.salary
                END AS t_salary,
            s.id,
            concat(s.f_name, ' ', s.s_name, ' ', s.l_name) AS fio,
            p.name AS pos_name
           FROM ((server.staff s
             JOIN server.position_staff ps ON ((ps.staff_id = s.id)))
             JOIN server.positions p ON ((p.id = ps.position_id)))
        ), depart_sallary AS (
         SELECT row_number() OVER (PARTITION BY d.id ORDER BY s.t_salary DESC) AS rate,
            d.id AS depart_id,
            d.name AS depart_name,
            s.t_salary,
            s.id,
            s.fio,
            s.pos_name
           FROM ((staff_sallary s
             JOIN server.department_staff ds_1 ON ((ds_1.staff_id = s.id)))
             JOIN server.department d ON ((d.id = ds_1.depart_id)))
        )
 SELECT depart_id,
    depart_name,
    id AS staff_id,
    fio AS staff_fio,
    (t_salary / 100) AS salary,
    pos_name
   FROM depart_sallary ds
  WHERE (rate = 1);


ALTER VIEW server.departments_wealthiest_staff OWNER TO postgres;

--
-- Name: find_namesakes_all; Type: VIEW; Schema: server; Owner: postgres
--

CREATE VIEW server.find_namesakes_all AS
 SELECT s.id,
    st.stf_fio,
    st.others_fio
   FROM (server.staff s
     JOIN LATERAL server.find_namesakes(s.id) st(stf_fio, others_fio) ON (true))
  ORDER BY s.id;


ALTER VIEW server.find_namesakes_all OWNER TO postgres;

--
-- Name: office_staff; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.office_staff (
    office_id integer NOT NULL,
    staff_id integer NOT NULL
);


ALTER TABLE server.office_staff OWNER TO postgres;

--
-- Name: offices_id_seq; Type: SEQUENCE; Schema: server; Owner: postgres
--

CREATE SEQUENCE server.offices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE server.offices_id_seq OWNER TO postgres;

--
-- Name: offices_id_seq; Type: SEQUENCE OWNED BY; Schema: server; Owner: postgres
--

ALTER SEQUENCE server.offices_id_seq OWNED BY server.offices.id;


--
-- Name: positions_id_seq; Type: SEQUENCE; Schema: server; Owner: postgres
--

CREATE SEQUENCE server.positions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE server.positions_id_seq OWNER TO postgres;

--
-- Name: positions_id_seq; Type: SEQUENCE OWNED BY; Schema: server; Owner: postgres
--

ALTER SEQUENCE server.positions_id_seq OWNED BY server.positions.id;


--
-- Name: staff_hierarchy; Type: TABLE; Schema: server; Owner: postgres
--

CREATE TABLE server.staff_hierarchy (
    chief_staff_id integer,
    sub_staff_id integer
);


ALTER TABLE server.staff_hierarchy OWNER TO postgres;

--
-- Name: staff_id_seq; Type: SEQUENCE; Schema: server; Owner: postgres
--

CREATE SEQUENCE server.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE server.staff_id_seq OWNER TO postgres;

--
-- Name: staff_id_seq; Type: SEQUENCE OWNED BY; Schema: server; Owner: postgres
--

ALTER SEQUENCE server.staff_id_seq OWNED BY server.staff.id;


--
-- Name: deltas_type id; Type: DEFAULT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.deltas_type ALTER COLUMN id SET DEFAULT nextval('server.deltas_type_id_seq'::regclass);


--
-- Name: department id; Type: DEFAULT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.department ALTER COLUMN id SET DEFAULT nextval('server.department_id_seq'::regclass);


--
-- Name: offices id; Type: DEFAULT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.offices ALTER COLUMN id SET DEFAULT nextval('server.offices_id_seq'::regclass);


--
-- Name: positions id; Type: DEFAULT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.positions ALTER COLUMN id SET DEFAULT nextval('server.positions_id_seq'::regclass);


--
-- Name: staff id; Type: DEFAULT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.staff ALTER COLUMN id SET DEFAULT nextval('server.staff_id_seq'::regclass);


--
-- Data for Name: deltas; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.deltas (id, value, object_id, delta_type_id) FROM stdin;
c35e7998-9a2a-4260-834e-654873a494ca	-1	1	1
a69ef7e1-0ebc-4393-8c26-f9a879693974	-1	2	1
\.


--
-- Data for Name: deltas_type; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.deltas_type (id, tag) FROM stdin;
1	offices
\.


--
-- Data for Name: department; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.department (id, name) FROM stdin;
1	Генеральная штаб квартира
2	Отдел систем безопасности
3	Отдел Web-технологий
4	Отдел бухгалтерии
5	Отдел маркетинга 
\.


--
-- Data for Name: department_offices; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.department_offices (depart_id, office_id) FROM stdin;
1	1
2	5
3	6
3	21
4	1
4	2
5	8
\.


--
-- Data for Name: department_staff; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.department_staff (depart_id, staff_id) FROM stdin;
1	3
5	1
5	4
\.


--
-- Data for Name: office_staff; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.office_staff (office_id, staff_id) FROM stdin;
1	3
2	1
\.


--
-- Data for Name: offices; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.offices (id, num, staff_number, address) FROM stdin;
2	1	15	Урюпинск
1	0	30	Столица
4	2	40	Столица
5	3	50	Столица
6	4	100	Столица
7	5	25	Столица
8	6	40	Столица
9	7	40	Столица
10	8	40	Столица
11	9	40	Столица
12	10	40	Столица
13	11	40	Столица
14	12	40	Столица
15	13	40	Самара
16	14	40	Самара
17	15	40	Самара
18	16	40	Самара
19	17	40	Самара
20	18	40	Самара
21	19	40	Самара
22	20	40	Самара
23	21	40	Самара
24	22	40	Самара
25	23	40	Самара
\.


--
-- Data for Name: position_staff; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.position_staff (position_id, staff_id) FROM stdin;
2	3
6	4
6	10
3	7
3	8
5	6
4	1
4	2
1	5
1	9
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.positions (id, name, salary) FROM stdin;
2	Генеральный Директор	20000000000
3	Охранник	2000000
4	Программист	20000000
5	Безопасник	20000000
6	Маркетолог	40000000
1	Бухгалтер	2000000
\.


--
-- Data for Name: staff; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.staff (id, f_name, s_name, l_name, date_birth, salary) FROM stdin;
2	Владислав	Сергеевич	Трудный	1990-01-01	\N
4	Андрей	Валентинович	Сложный	1985-01-01	\N
7	Валентин	Николаевич	Простой	2000-01-17	\N
8	Николай	Артёмович	Куляпин	2000-10-13	\N
9	Оксана	Алексеевна	Кук	2000-07-18	\N
10	Екатерина	Вячеславовна	Куляпина	2003-02-14	\N
5	Снежанна	Дмитриевна	Сложная	2000-03-01	\N
6	Ольга	Андреевна	Сложная	2000-06-01	\N
3	Константин	Александрович	Сложный	1980-01-01	20000000000
1	Олег	Игоревич	Простой	2000-01-01	2000000
\.


--
-- Data for Name: staff_hierarchy; Type: TABLE DATA; Schema: server; Owner: postgres
--

COPY server.staff_hierarchy (chief_staff_id, sub_staff_id) FROM stdin;
3	5
3	7
3	1
3	6
3	4
5	9
7	8
1	2
4	10
\.


--
-- Name: deltas_type_id_seq; Type: SEQUENCE SET; Schema: server; Owner: postgres
--

SELECT pg_catalog.setval('server.deltas_type_id_seq', 1, true);


--
-- Name: department_id_seq; Type: SEQUENCE SET; Schema: server; Owner: postgres
--

SELECT pg_catalog.setval('server.department_id_seq', 5, true);


--
-- Name: offices_id_seq; Type: SEQUENCE SET; Schema: server; Owner: postgres
--

SELECT pg_catalog.setval('server.offices_id_seq', 25, true);


--
-- Name: offices_seq; Type: SEQUENCE SET; Schema: server; Owner: postgres
--

SELECT pg_catalog.setval('server.offices_seq', 23, true);


--
-- Name: positions_id_seq; Type: SEQUENCE SET; Schema: server; Owner: postgres
--

SELECT pg_catalog.setval('server.positions_id_seq', 6, true);


--
-- Name: staff_id_seq; Type: SEQUENCE SET; Schema: server; Owner: postgres
--

SELECT pg_catalog.setval('server.staff_id_seq', 10, true);


--
-- Name: deltas deltas_pkey; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.deltas
    ADD CONSTRAINT deltas_pkey PRIMARY KEY (id);


--
-- Name: deltas_type deltas_type_pkey; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.deltas_type
    ADD CONSTRAINT deltas_type_pkey PRIMARY KEY (id);


--
-- Name: department department_pkey; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (id);


--
-- Name: department_staff department_staff_depart_id_staff_id_key; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.department_staff
    ADD CONSTRAINT department_staff_depart_id_staff_id_key UNIQUE (depart_id, staff_id);


--
-- Name: offices offices_pkey; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.offices
    ADD CONSTRAINT offices_pkey PRIMARY KEY (id);


--
-- Name: position_staff position_staff_position_id_staff_id_key; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.position_staff
    ADD CONSTRAINT position_staff_position_id_staff_id_key UNIQUE (position_id, staff_id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: staff_hierarchy staff_hierarchy_chief_staff_id_sub_staff_id_key; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.staff_hierarchy
    ADD CONSTRAINT staff_hierarchy_chief_staff_id_sub_staff_id_key UNIQUE (chief_staff_id, sub_staff_id);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- Name: department_offices unique_depart_office; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.department_offices
    ADD CONSTRAINT unique_depart_office UNIQUE (depart_id, office_id);


--
-- Name: office_staff unique_office_staff; Type: CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.office_staff
    ADD CONSTRAINT unique_office_staff UNIQUE (office_id, staff_id);


--
-- Name: office_current_vacant_seats _RETURN; Type: RULE; Schema: server; Owner: postgres
--

CREATE OR REPLACE VIEW server.office_current_vacant_seats AS
 SELECT o.id,
    (sum(COALESCE(d.value, (0)::bigint)) + (o.staff_number)::numeric) AS vacant_seats
   FROM (server.offices o
     LEFT JOIN server.deltas d ON ((d.object_id = o.id)))
  GROUP BY o.id;


--
-- Name: deltas deltas_delta_type_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.deltas
    ADD CONSTRAINT deltas_delta_type_id_fkey FOREIGN KEY (delta_type_id) REFERENCES server.deltas_type(id);


--
-- Name: department_offices department_offices_depart_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.department_offices
    ADD CONSTRAINT department_offices_depart_id_fkey FOREIGN KEY (depart_id) REFERENCES server.department(id);


--
-- Name: department_offices department_offices_office_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.department_offices
    ADD CONSTRAINT department_offices_office_id_fkey FOREIGN KEY (office_id) REFERENCES server.offices(id);


--
-- Name: department_staff department_staff_depart_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.department_staff
    ADD CONSTRAINT department_staff_depart_id_fkey FOREIGN KEY (depart_id) REFERENCES server.department(id);


--
-- Name: department_staff department_staff_staff_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.department_staff
    ADD CONSTRAINT department_staff_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES server.staff(id);


--
-- Name: office_staff office_staff_office_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.office_staff
    ADD CONSTRAINT office_staff_office_id_fkey FOREIGN KEY (office_id) REFERENCES server.offices(id);


--
-- Name: office_staff office_staff_staff_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.office_staff
    ADD CONSTRAINT office_staff_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES server.staff(id);


--
-- Name: position_staff position_staff_position_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.position_staff
    ADD CONSTRAINT position_staff_position_id_fkey FOREIGN KEY (position_id) REFERENCES server.positions(id);


--
-- Name: position_staff position_staff_staff_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.position_staff
    ADD CONSTRAINT position_staff_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES server.staff(id);


--
-- Name: staff_hierarchy staff_hierarchy_chief_staff_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.staff_hierarchy
    ADD CONSTRAINT staff_hierarchy_chief_staff_id_fkey FOREIGN KEY (chief_staff_id) REFERENCES server.staff(id);


--
-- Name: staff_hierarchy staff_hierarchy_sub_staff_id_fkey; Type: FK CONSTRAINT; Schema: server; Owner: postgres
--

ALTER TABLE ONLY server.staff_hierarchy
    ADD CONSTRAINT staff_hierarchy_sub_staff_id_fkey FOREIGN KEY (sub_staff_id) REFERENCES server.staff(id);


--
-- PostgreSQL database dump complete
--

