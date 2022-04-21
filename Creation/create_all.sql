
--Configurations
DROP SCHEMA IF EXISTS project_db_2021 CASCADE;
CREATE SCHEMA project_db_2021 AUTHORIZATION postgres;
SET search_path TO project_db_2021;
SET datestyle = GERMAN, YMD;

--Types
CREATE TYPE gender_type AS ENUM ('M', 'F', 'NB', 'NONE');
CREATE TYPE proposals_status_type AS ENUM ('rejected', 'accpeted', 'pending');
CREATE TYPE requests_status_type AS ENUM ('open', 'close', 'cancel');
CREATE TYPE payments_status_type AS ENUM ('done', 'todo', 'cancelled');

--Creation of Tables
CREATE TABLE Contacts 
(   
    contact_id SERIAL, 
    email VARCHAR(100) NOT NULL,  
    society VARCHAR(100),
    first_name VARCHAR(50) NOT NULL, 
    last_name VARCHAR(50) NOT NULL, 
    gender gender_type NOT NULL, 
    birth_date DATE, 
    tel VARCHAR(20) NOT NULL,
    city VARCHAR(50), 
    address VARCHAR(200),  --NOT NULL SI contact est represent par notre agent : verifier AgnecyContracts en cours
    postal_code INTEGER,
	CONSTRAINT Contacts_contact_id_pk PRIMARY KEY (contact_id),
    CONSTRAINT email_check CHECK (email ~* '^[a-zA-Z0-9.-]+@[a-z0-9._-]{2,100}\.[a-z]{2,4}$'),
    CONSTRAINT tel_check CHECK (tel ~* '^(\+)?[0-9\)\(]{10,20}$'),
    CONSTRAINT birth_date_check CHECK (birth_date > '1900-01-01' AND birth_date < NOW())
);

CREATE TABLE Creations
(   
    creation_id SERIAL CONSTRAINT Creations_creation_id_pk PRIMARY KEY
);

CREATE TABLE Requests
(
    request_id SERIAL CONSTRAINT Requests_request_id_pk PRIMARY KEY,
    contact_id INTEGER,
    creation_id INTEGER, 
    description TEXT, 
    budget NUMERIC (12,2) NOT NULL CHECK(budget >=0),  --trigger >=0
    request_status requests_status_type NOT NULL, 
    request_start DATE NOT NULL, 
    request_end DATE,
    CONSTRAINT Requests_contact_id_fk FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
    CONSTRAINT Creations_creation_id_fk FOREIGN KEY (creation_id) REFERENCES project_db_2021.Creations (creation_id),
    CHECK(request_end >= request_start)
);

sCREATE TABLE Skills
(
    skill_id SERIAL,
    skill_name TEXT NOT NULL,
    skill_type TEXT NOT NULL, 
    CONSTRAINT Skills_skill_id_pk PRIMARY KEY (skill_id)
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


