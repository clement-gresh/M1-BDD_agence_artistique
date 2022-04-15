-- command to execute in psql: \i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/cmd-clem.sql'
-- <>

SET search_path TO postgres;

-- SCHEMA + DB
DROP schema IF EXISTS project_db_2021 CASCADE;
CREATE SCHEMA project_db_2021 AUTHORIZATION postgres;
SET search_path TO project_db_2021;
SET datestyle = GERMAN, YMD; -- que fait GERMAN


-- ENUM
CREATE TYPE gender_type AS ENUM ('M', 'F', 'NB', 'NONE');


-- TABLES
CREATE TABLE Agents (
	agent_id SERIAL NOT NULL,
	email VARCHAR(100) NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	gender gender_type NOT NULL,
	birth_date DATE NOT NULL,
	tel VARCHAR(20) NOT NULL,
	address TEXT NOT NULL,
	postal_code VARCHAR(8) NOT NULL,
	CONSTRAINT agents_pkey PRIMARY KEY (agent_id),
	CONSTRAINT email_check CHECK (email ~* '^[a-z0-9._-]+@[a-z0-9._-]{2,100}\.[a-z]{2,4}$'),
	CONSTRAINT birth_date_check CHECK (birth_date > '1900-01-01' AND birth_date < NOW()),
	CONSTRAINT tel_check CHECK (tel ~* '^(+)?[0-9\)\(]{10,20}$'),
	CONSTRAINT postal_code_check CHECK (postal_code ~* '^[0-9]{2,8}$')
);

CREATE TABLE AgencyContracts(
	contact_id INT NOT NULL,
	start_date DATE NOT NULL,
	end_date DATE,
	fee REAL NOT NULL,
	CONSTRAINT agency_contracts_pkey PRIMARY KEY (contact_id, start_date),
	-- CONSTRAINT contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT start_date_check CHECK (start_date > '2000-01-01' AND start_date < '2100-01-01'),
	CONSTRAINT end_date_check CHECK (end_date > start_date AND end_date < '2100-01-01'),
	CONSTRAINT fee_check CHECK (fee > 0 AND fee < 100)
);

\dt
-- SELECT * FROM agents;

-- pour les cles primaire mettre comme nom de contrainte : table_name_pk
-- pour les cles etrangere mettre comme nom de contrainte : attribute_name_fk
-- pour les check, mettre comme nom de contrainte : attribute_name_check

-- pour fee, j'ai mis REAL et non DOUBLE car on n'a pas besoin de plus de 6 chiffres après la virgule

-- PROFS
-- demander rdv
-- Qu'est ce qu'un schema ?
-- ENGINE = INNODB ???


-- ContractAgency
-- AgentRecords
-- Creations
-- Invloments
-- Skills
-- KnownSkills