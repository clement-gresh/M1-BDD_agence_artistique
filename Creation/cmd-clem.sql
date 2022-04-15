-- command to execute in psql: \i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/cmd-clem.sql'

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
	email VARCHAR(100) NOT NULL,					-- ajouter expression reguliere pour verifier le format
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	gender gender_type NOT NULL,
	birthdate DATE NOT NULL,						-- ajouter expression reguliere pour verifier le format
	tel VARCHAR(20) NOT NULL,						-- ajouter expression reguliere pour verifier le format : peut contenir + et ( )
	address TEXT NOT NULL,
	postal_code INT NOT NULL,						-- ajouter expression reguliere pour verifier le format
	CONSTRAINT agents_pkey PRIMARY KEY (agent_id)
);

-- AgencyContracts(*#contact_id, *start_date, end_date, fee)
CREATE TABLE AgencyContracts(
	contact_id INT,
	start_date DATE NOT NULL,
	end_date DATE,								-- check que c'est apres start_date
	fee REAL NOT NULL,
	CONSTRAINT agency_contracts_pkey PRIMARY KEY (contact_id, start_date)-- ,
	-- CONSTRAINT contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id)
);

\dt
-- SELECT * FROM agents;


-- CONSTRAINT start_date_pkey PRIMARY KEY (start_date),
--    CONSTRAINT id_proposal_pkey PRIMARY KEY (proposal_id),
--    CONSTRAINT proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES projet_bdd_2021.Proposals (proposal_id),

-- Qu'est ce qu'un schema ?
-- ENGINE = INNODB ???


-- ContractAgency
-- AgentRecords
-- Creations
-- Invloments
-- Skills
-- KnownSkills