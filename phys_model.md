
# Физическая модель базы данных

## Основные таблицы

### 1. department
- id (PK, serial) – идентификатор отдела
- name (text, NOT NULL) – название отдела

### 2. offices
- id (PK, serial) – идентификатор офиса
- num (integer, уникальный, default nextval('server.offices_seq')) – номер офиса
- staff_number (integer, NOT NULL) – количество сотрудников
- address (text, по умолчанию NULL) – адрес офиса

### 3. staff
- id (PK, serial) – идентификатор сотрудника
- f_name (text, NOT NULL) – имя сотрудника
- s_name (text, по умолчанию NULL) – отчество сотрудника
- l_name (text, NOT NULL) – фамилия сотрудника
- date_birth (date, NOT NULL) – дата рождения
- salary (bigint, по умолчанию NULL) – заработная плата

### 4. positions
- id (PK, serial) – идентификатор должности
- name (text, default 'Планктон') – название должности
- salary (bigint, default 2000000) – заработная плата на должности в рублях * 100

## Кросс-таблицы 

### 1. department_offices
- depart_id (FK, integer, REFERENCES department(id)) – идентификатор отдела
- office_id (FK, integer, REFERENCES offices(id)) – идентификатор офиса
- **Уникальный ключ**: (depart_id, office_id)

### 2. department_staff
- depart_id (FK, integer, REFERENCES department(id)) – идентификатор отдела
- staff_id (FK, integer, REFERENCES staff(id)) – идентификатор сотрудника
- **Уникальный ключ**: (depart_id, staff_id)

### 3. office_staff
- office_id (FK, integer, REFERENCES offices(id)) – идентификатор офиса
- staff_id (FK, integer, REFERENCES staff(id)) – идентификатор сотрудника
- **Уникальный ключ**: (office_id, staff_id)

### 4. position_staff
- position_id (FK, integer, REFERENCES positions(id)) – идентификатор должности
- staff_id (FK, integer, REFERENCES staff(id)) – идентификатор сотрудника
- **Уникальный ключ**: (position_id, staff_id)

### 5. staff_hierarchy
- chief_staff_id (FK, integer, REFERENCES staff(id)) – идентификатор начальника
- sub_staff_id (FK, integer, REFERENCES staff(id)) – идентификатор подчиненного
- **Уникальный ключ**: (chief_staff_id, sub_staff_id)

## Таблицы для работы с дельтами (учет изменений)

### 1. deltas_type
- id (PK, serial) – идентификатор типа дельты
- tag (varchar(50)) – тип дельты (например, "увольнение", "прием")

### 2. deltas
- id (PK, uuid, default gen_random_uuid()) – идентификатор дельты
- value (int8, default -1) – значение дельты (например, 1 или -1)
- object_id (bigint, NOT NULL) – идентификатор объекта (например, офиса)
- delta_type_id (FK, integer, REFERENCES deltas_type(id)) – идентификатор типа дельты
