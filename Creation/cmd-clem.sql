-- command to execute in psql: \i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/cmd-clem.sql'
-- <>

SET search_path TO postgres;

-- SCHEMA + DB
DROP schema IF EXISTS project_db_2021 CASCADE;
CREATE SCHEMA project_db_2021 AUTHORIZATION postgres;
SET search_path TO project_db_2021;
SET datestyle = GERMAN, YMD; -- que fait GERMAN


-- ENUM
CREATE TYPE gender_enum AS ENUM ('M', 'F', 'NB', 'NONE');
CREATE TYPE creation_enum AS ENUM ('album', 'song', 'play', 'movie', 'TV show', 'commercial', 'concert', 'book');
CREATE TYPE skill_type_enum AS ENUM ('job', 'instrument', 'language', 'style');
CREATE TYPE skill_name_enum AS ENUM (
	'writer', 'musician', 'singer', 'actor', 'director', 'producer',
	'violin', 'guitar', 'saxophone', 'piano', 'trumpet', 'flute',
	'french', 'english', 'arabic', 'spanish', 'german', 'italian', 'mandarin', 'hindi', 'japanese',
	'jazz', 'classical', 'RandB', 'rock', 'soul', 'rap', 'slam', 'metal'
);
-- CREATE TYPE job_enum AS ENUM ('writer', 'musician', 'singer', 'actor', 'director', 'producer');
-- CREATE TYPE instrument_enum AS ENUM ('violin', 'guitar', 'saxophone', 'piano', 'trumpet', 'flute');
-- CREATE TYPE language_enum AS ENUM ('french', 'english', 'arabic', 'spanish', 'german', 'italian', 'mandarin', 'hindi', 'japanese');
-- CREATE TYPE style_enum AS ENUM ('jazz', 'classical', 'RandB', 'rock', 'soul', 'rap', 'slam', 'metal');


-- TABLES
CREATE TABLE Agents (
	agent_id SERIAL NOT NULL,
	email VARCHAR(100) NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	gender gender_enum NOT NULL,
	birth_date DATE NOT NULL,
	tel VARCHAR(20) NOT NULL,
	address TEXT NOT NULL,
	postal_code VARCHAR(8) NOT NULL,
	CONSTRAINT Agents_pkey PRIMARY KEY (agent_id),
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
	CONSTRAINT AgencyContracts_pkey PRIMARY KEY (contact_id, start_date),
	-- CONSTRAINT agency_contracts_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT start_date_check CHECK (start_date > '2000-01-01' AND start_date < '2100-01-01'),
	CONSTRAINT end_date_check CHECK (end_date > start_date AND end_date < '2100-01-01'),
	CONSTRAINT fee_check CHECK (fee > 0 AND fee < 100)
);

CREATE TABLE AgentRecords(
	agent_id INT NOT NULL,
	contact_id INT NOT NULL,
	start_date DATE NOT NULL,
	end_date DATE,
	CONSTRAINT AgentRecord_pkey PRIMARY KEY (agent_id, contact_id),
	CONSTRAINT agent_record_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES project_db_2021.Agents (agent_id),
	-- CONSTRAINT agent_record_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT start_date_check CHECK (start_date > '2000-01-01' AND start_date < '2100-01-01'),
	CONSTRAINT end_date_check CHECK (end_date > start_date AND end_date < '2100-01-01')
);

CREATE TABLE Creations(
	creation_id SERIAL NOT NULL,
	creation_name VARCHAR(50) NOT NULL,
	creation_type creation_enum NOT NULL,
	release_date DATE,
	profits NUMERIC(12,2) NOT NULL,
	last_update_profit DATE NOT NULL,
	CONSTRAINT Creations_pk PRIMARY KEY (creation_id),
	CONSTRAINT release_date_check CHECK (release_date > '1900-01-01' AND release_date < '2100-01-01'),
	CONSTRAINT profits_check CHECK (profits > 0),
	CONSTRAINT last_update_profit_check CHECK (last_update_profit > '2000-01-01' AND last_update_profit < '2100-01-01')
);
-- trigger : a l'ajout d'une ligne, met automatiquement profits à 0 et last_update_profits à NOW()
-- trigger : BEFORE insert/update, update 0-n ligne dans la table PaymentRecords en fonction de la Participation de tous les artistes y ayant joué


CREATE TABLE Skills(
	skill_id SERIAL NOT NULL,
	skill_name skill_name_enum NOT NULL,
	skill_type skill_type_enum NOT NULL,
	CONSTRAINT Skills_pk PRIMARY KEY (skill_id)
);

CREATE TABLE Involvments(
	contact_id INT NOT NULL,
	creation_id INT NOT NULL,
	skill_id INT NOT NULL,
	description text,
	CONSTRAINT Involvments_pk PRIMARY KEY (contact_id, creation_id),
	-- CONSTRAINT Involvments_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT Involvments_creation_id_fkey FOREIGN KEY (creation_id) REFERENCES project_db_2021.Creations (creation_id),
	CONSTRAINT Involvments_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES project_db_2021.Skills (skill_id)
);
-- trigger : verifier que skill est du type job
-- trigger : verifier que skill_name apparait bien dans KnownSkills pour ce contact

CREATE OR REPLACE FUNCTION is_skill_job() RETURNS trigger AS $$
BEGIN
	SELECT skill_type FROM Involvments INNER JOIN Skills ON Skills.skill_id = Involvments.skill_id
	WHERE Involvments.skill_id = NEW.skill_id AND Skills.skill_type = 'job'::skill_type_enum;
	RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- CREATE TRIGGER Involvments_skill_id_trigger
-- BEFORE INSERT OR UPDATE ON Involvments
-- FOR EACH ROW
-- WHEN (NEW.skill_id 
-- WHEN (OLD.skill_id IS DISTINCT FROM NEW.skill_id) -- est-ce que cela marche pour les insert (car pas de old) ?
-- EXECUTE PROCEDURE is_skill_job();



CREATE TABLE KnownSkills(
	contact_id INT NOT NULL,
	skill_id INT NOT NULL,
	CONSTRAINT KnownSkills_pk PRIMARY KEY (contact_id, skill_id),
	-- CONSTRAINT KnownSkills_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT KnownSkills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES project_db_2021.Skills (skill_id)
);
-- trigger : seul un musicien peut avoir un skill_type = instrument ou style


\dt

-- REMARQUES
-- pour les cles primaire mettre comme nom de contrainte : TableName_pk
-- pour les cles etrangere mettre comme nom de contrainte : TableName_attribute_name_fk
-- pour les check, mettre comme nom de contrainte : attribute_name_check
-- pour les index : TableName_attribute_name_i

-- pour fee, j'ai mis REAL et non DOUBLE car on n'a pas besoin de plus de 6 chiffres après la virgule


-- QUESTIONS
-- Utilise-t-on les cascades ? Pour supprimer les lignes d'une table ayant une FK qui est supprimee dans la table ou elle est definie


-- PROFS
-- demander rdv
-- Qu'est ce qu'un schema ?
-- ENGINE = INNODB ???


-- KnownSkills