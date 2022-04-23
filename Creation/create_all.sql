-- SCHEMA + DB
DROP schema IF EXISTS project_db_2021 CASCADE;
CREATE SCHEMA project_db_2021 AUTHORIZATION postgres;
SET search_path TO project_db_2021;
SET datestyle = GERMAN, YMD;


-- TYPES
CREATE TYPE gender_type AS ENUM ('M', 'F', 'Nb', 'None');
CREATE TYPE proposals_status_type AS ENUM ('rejected', 'accpeted', 'pending');
CREATE TYPE requests_status_type AS ENUM ('open', 'close', 'cancel');
CREATE TYPE payments_status_type AS ENUM ('done', 'todo', 'cancelled');
CREATE TYPE creation_type AS ENUM ('album', 'song', 'play', 'movie', 'TV show', 'commercial', 'concert', 'book');
CREATE TYPE skill_type_type AS ENUM ('job', 'instrument', 'language', 'style');
CREATE TYPE skill_name_type AS ENUM (
	'writer', 'musician', 'singer', 'actor', 'director', 'producer',
	'violin', 'guitar', 'saxophone', 'piano', 'trumpet', 'flute',
	'french', 'english', 'arabic', 'spanish', 'german', 'italian', 'mandarin', 'hindi', 'japanese',
	'jazz', 'classical', 'RandB', 'rock', 'soul', 'rap', 'slam', 'metal'
);

-- TABLES
CREATE TABLE Contacts 
(   
    contact_id SERIAL CONSTRAINT Contacts_contact_id_pk PRIMARY KEY,
    email VARCHAR(100) NOT NULL,  
    society VARCHAR(100),
    first_name VARCHAR(50) NOT NULL, 
    last_name VARCHAR(50) NOT NULL, 
    gender gender_type NOT NULL, 
    birth_date DATE,
    tel VARCHAR(20),  --NOT NULL : ALTER après l'inserction 
    city VARCHAR(50), 
    address VARCHAR(200),  -- Trigger : vérifier NOT NULL SI contact est represent par notre agent : verifier AgnecyContracts en cours
    postal_code INTEGER,
    CONSTRAINT email_check CHECK (email ~* '^[a-zA-Z0-9.-]+@[a-z0-9._-]{2,100}\.[a-z]{2,4}$'),
    CONSTRAINT tel_check CHECK (tel ~* '^(\+)?[0-9\)\(]{10,20}$'),
    CONSTRAINT birth_date_check CHECK (birth_date > '1900-01-01' AND birth_date < NOW())
);

CREATE TABLE Creations(
	creation_id SERIAL NOT NULL,
	creation_name VARCHAR(50) NOT NULL,
	creation_type creation_type NOT NULL,
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


CREATE TABLE Requests
(
    request_id SERIAL CONSTRAINT Requests_request_id_pk PRIMARY KEY,
    contact_id INTEGER NOT NULL, --trigger vérifier que contact a un skill_type : job : producteur
    --creation_id INTEGER NOT NULL, 
    request_description TEXT, 
    budget NUMERIC (12,2) NOT NULL CHECK(budget >=0),  --trigger >=0
    request_status requests_status_type NOT NULL, 
    request_start DATE NOT NULL, 
    request_end DATE,
    CONSTRAINT Requests_contact_id_fk FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
    --CONSTRAINT Creations_creation_id_fk FOREIGN KEY (creation_id) REFERENCES project_db_2021.Creations (creation_id),
    CHECK(request_end >= request_start)
);


CREATE TABLE Skills(
	skill_id SERIAL NOT NULL,
	skill_name skill_name_type NOT NULL,
	skill_type skill_type_type NOT NULL,
	CONSTRAINT Skills_pk PRIMARY KEY (skill_id)
);


CREATE TABLE RequiredSkills
(
    request_id INTEGER, 
    skill_id INTEGER,
    CONSTRAINT RequiredSkills_request_id_skill_id_pk PRIMARY KEY (request_id, skill_id),
    CONSTRAINT RequiredSkills_request_id_fk FOREIGN KEY (request_id) REFERENCES project_db_2021.Requests (request_id),
    CONSTRAINT RequiredSkills_skill_id_fk FOREIGN KEY (skill_id) REFERENCES project_db_2021.Skills (skill_id)
);


CREATE TABLE Proposals
(
    proposal_id SERIAL CONSTRAINT Proposals_proposal_id_pk PRIMARY KEY, 
    request_id INTEGER, 
    contact_id INTEGER,  --artist
    proposals_status proposals_status_type NOT NULL, --trigger BEFORE insert/update
    proposed_date DATE, --trigger request_end > proposed_date > request_date
    CONSTRAINT Proposals_request_id_fk FOREIGN KEY (request_id) REFERENCES project_db_2021.Requests (request_id),
    CONSTRAINT Proposals_contact_id_fk FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id)
);

CREATE TABLE ProducerContracts
(   
    proposal_id INTEGER,
    contract_start DATE,
    contract_end DATE CHECK(contract_end > contract_start),
    salary NUMERIC(12,2) NOT NULL CHECK(salary >=0),
    installments_number INTEGER NOT NULL,
    is_amendment BOOLEAN,
    incentive NUMERIC(6, 4), --0.0001% 
    CONSTRAINT ProContracts_proposal_id_date_pk PRIMARY KEY (proposal_id, contract_start),
    CONSTRAINT ProContracts_proposal_id_fk FOREIGN KEY (proposal_id) REFERENCES project_db_2021.Proposals (proposal_id)
);

CREATE TABLE PaymentRecords
(
    proposal_id INTEGER, 
    contract_start DATE, 
    payment_number INTEGER, 
    amount NUMERIC(12,2) NOT NULL CHECK (amount >=0), 
    payment_status payments_status_type NOT NULL, 
    date_planned DATE NOT NULL, 
    date_paid DATE, 
    is_incentive BOOLEAN NOT NULL,
    CONSTRAINT Payment_proposal_id_pk PRIMARY KEY (proposal_id, contract_start, payment_number),
    CONSTRAINT Payment_proposal_id_date_fk FOREIGN KEY (proposal_id, contract_start) REFERENCES project_db_2021.ProducerContracts (proposal_id, contract_start)
);

CREATE TABLE Agents (
	agent_id SERIAL NOT NULL,
	email VARCHAR(100) NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	gender gender_type NOT NULL,
	birth_date DATE NOT NULL,
	tel VARCHAR(20) NOT NULL,
	address TEXT NOT NULL,
	city VARCHAR(50) NOT NULL,
	postal_code VARCHAR(8) NOT NULL,
	CONSTRAINT Agents_pkey PRIMARY KEY (agent_id),
	CONSTRAINT email_check CHECK (email ~* '^[a-zA-Z0-9._-]+@[a-z0-9._-]{2,100}\.[a-z]{2,4}$'),
	CONSTRAINT birth_date_check CHECK (birth_date > '1900-01-01' AND birth_date < NOW()),
	CONSTRAINT tel_check CHECK (tel ~* '^(\+)?[0-9\)\(]{10,20}$'),
	CONSTRAINT postal_code_check CHECK (postal_code ~* '^[0-9]{2,8}$')
);

CREATE TABLE AgencyContracts(
	contact_id INT NOT NULL,
	start_date DATE NOT NULL,	--contract_start
	end_date DATE,				--contract_end
	fee NUMERIC(6,4) NOT NULL,  --commission
	CONSTRAINT AgencyContracts_pkey PRIMARY KEY (contact_id, start_date),
	CONSTRAINT agency_contracts_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT start_date_check CHECK (start_date > '1900-01-01' AND start_date < '2100-01-01'),
	CONSTRAINT end_date_check CHECK (end_date > start_date AND end_date < '2100-01-01'),
	CONSTRAINT fee_check CHECK (fee > 0 AND fee < 100)
);

CREATE TABLE AgentRecords(
	agent_id INT NOT NULL,
	contact_id INT NOT NULL,
	start_date DATE NOT NULL, -- represent_start
	end_date DATE,				-- represent_end
	CONSTRAINT AgentRecord_pkey PRIMARY KEY (agent_id, contact_id),
	CONSTRAINT agent_record_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES project_db_2021.Agents (agent_id),
	CONSTRAINT agent_record_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT start_date_check CHECK (start_date > '1900-01-01' AND start_date < '2100-01-01'),
	CONSTRAINT end_date_check CHECK (end_date > start_date AND end_date < '2100-01-01')
);


CREATE TABLE Involvments(
	contact_id INT NOT NULL,
	creation_id INT NOT NULL,
	skill_id INT NOT NULL,
	description text,
	CONSTRAINT Involvments_pk PRIMARY KEY (contact_id, creation_id),
	CONSTRAINT Involvments_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT Involvments_creation_id_fkey FOREIGN KEY (creation_id) REFERENCES project_db_2021.Creations (creation_id),
	CONSTRAINT Involvments_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES project_db_2021.Skills (skill_id)
);


CREATE TABLE KnownSkills(
	contact_id INT NOT NULL,
	skill_id INT NOT NULL,
	CONSTRAINT KnownSkills_pk PRIMARY KEY (contact_id, skill_id),
	CONSTRAINT KnownSkills_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT KnownSkills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES project_db_2021.Skills (skill_id)
);
-- trigger : seul un musicien peut avoir un skill_type = instrument ou style


