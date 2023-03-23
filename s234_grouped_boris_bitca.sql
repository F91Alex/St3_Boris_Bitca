-- Create tables people, location and people_audit_log
drop table if exists location, people, people_audit_log; 

create table location (
	location_id int not null primary key,
	town varchar(30) not null
);

create table people (
	person_id int not null primary key,
	first_name varchar(20) not null,
	last_name varchar(30) not null,
	location_id int not null,
	foreign key (location_id) references location(location_id) 
);

insert into location (location_id, town) 
values (1, 'Chisinau'), 
       (2, 'Balti'),
       (3, 'Cahul');

insert into people (person_id, first_name, last_name, location_id)
values (1, 'Bill', 'Taylor', 1),
	   (2, 'John', 'Cena', 2),
	   (3, 'Connor', 'Mcgregor', 3);
	  
-- Create a trigger for a table 'People'
create table people_audit_log(
	id serial,
	old_data_row jsonb, 
	new_data_row jsonb,
	dml_timestamp timestamp not null default now(),
	dml_type varchar(10) not null
);

CREATE OR REPLACE FUNCTION people_audit_trig()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
begin
	IF TG_OP = 'INSERT'
	THEN
	INSERT INTO people_audit_log (dml_type, new_data_row)
	VALUES (TG_OP, to_jsonb(NEW));
	RETURN NEW;
	
	ELSIF TG_OP = 'UPDATE'
	THEN
	IF NEW != OLD THEN
	INSERT INTO people_audit_log (dml_type, old_data_row, new_data_row)
	VALUES (TG_OP, to_jsonb(OLD), to_jsonb(NEW));
	END IF;
	RETURN NEW;
	
	ELSIF TG_OP = 'DELETE'
	THEN
		raise exception 'Delete operation is not permitted';
	END IF;
	end;
$function$;

CREATE TRIGGER people_audit_trig
	BEFORE INSERT OR UPDATE OR DELETE
	ON people
	FOR EACH ROW
	EXECUTE PROCEDURE people_audit_trig();

-- Create an interface (API) to previously created tables that allows to Add/Update Locations table and Add/Update Peoples table 
drop procedure AddNewLocation;
	  
create or replace procedure AddNewLocation (
	location_id int,
	town varchar(30)
)
language sql    
as $$
    insert into "location" 
    values (location_id, town);
$$; 

drop procedure UpdateLocationName;

create or replace procedure UpdateLocationName (
	p_location_id int,
	p_town varchar(30)
)
language sql
as $$
	update "location" 
	set town = p_town
	where location_id = p_location_id;
$$;

drop procedure AddNewPerson;
	  
create or replace procedure AddNewPerson (
	person_id int,
	first_name varchar(20),
	last_name varchar(30),
	location_id int
)
language sql    
as $$
    insert into people  
    values (person_id, first_name, last_name, location_id);
$$; 

drop procedure UpdatePersonDetails;

create or replace procedure UpdatePersonDetails (
	p_person_id int,
	p_first_name varchar(20),
	p_last_name varchar(30),
	p_location_id int
)
language sql
as $$
	update people  
	set first_name  = p_first_name,
		last_name = p_last_name,
		location_id = p_location_id
	where person_id = p_person_id;
$$;

call AddNewLocation(4, 'Moscow');
call AddNewLocation(5, 'California')

call UpdateLocationName(4, 'London');
call UpdateLocationName(5, 'Paris');

call AddNewPerson(4, 'Steve', 'Rambo', 4);
call AddNewPerson(5, 'John', 'Price', 5);

call UpdatePersonDetails(4, 'Van', 'Darkholme', 4);
call UpdatePersonDetails(5, 'Billy', 'Herrington', 5); 

select * from location
order by location_id;

select * from people;

select * from people_audit_log;