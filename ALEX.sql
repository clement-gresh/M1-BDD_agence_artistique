-- SCHEMA + DB
DROP schema IF EXISTS project_db_2021 CASCADE;
CREATE SCHEMA project_db_2021 AUTHORIZATION postgres;
SET search_path TO project_db_2021;
SET datestyle = GERMAN, YMD;


-- TYPES
CREATE TYPE gender_type AS ENUM ('M', 'F', 'Nb', 'None');
CREATE TYPE proposals_status_type AS ENUM ('rejected', 'accepted', 'pending');
CREATE TYPE requests_status_type AS ENUM ('open', 'closed', 'cancelled');
CREATE TYPE payments_status_type AS ENUM ('done', 'todo', 'cancelled');
CREATE TYPE creation_type AS ENUM ('album', 'song', 'play', 'movie', 'TV show', 'commercial', 'concert', 'book');
CREATE TYPE skill_type_type AS ENUM ('job', 'instrument', 'language', 'style');
CREATE TYPE skill_name_type AS ENUM (
	'writer', 'musician', 'singer', 'actor', 'director', 'producer', 
	'comedian', 'soprano', 'tenor', 'bass', 'baritone', 'alto', 'mezzo-soprano',
	'violin', 'guitar', 'saxophone', 'piano', 'trumpet', 'flute',
	'keyboard', 'french-horn', 'drums', 'electric-guitar', 'accordion', 'cello', 'clarinet', 'bagpipes', 'bugle', 'harmonica',
	'harp', 'organ', 'pan-flute', 'sitar', 'tambourine', 'triangle', 'trombone', 'tuba', 'ukulele', 'xylophone',
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
	address VARCHAR(200),  --Trigger : vérifier NOT NULL SI contact est represent par notre agent : verifier AgnecyContracts en cours
	postal_code VARCHAR(8),
	CONSTRAINT email_check CHECK (email ~* '^[a-zA-Z0-9.-]+@[a-z0-9._-]{2,100}\.[a-z]{2,4}$'),
    CONSTRAINT tel_check CHECK (tel ~* '^(\+)?[0-9\)\(]{10,20}$'),
    CONSTRAINT birth_date_check CHECK (birth_date > '1900-01-01' AND birth_date < NOW()),
	CONSTRAINT postal_code_check CHECK (postal_code ~* '^[1-9]{1}[0-9]{1,7}$')
);

CREATE TABLE Creations(
	creation_id SERIAL NOT NULL,
	creation_name VARCHAR(50) NOT NULL,
	creation_type creation_type NOT NULL,
	release_date DATE,
	profits NUMERIC(12,2) NOT NULL,
	last_update_profits DATE NOT NULL,
	CONSTRAINT Creations_pk PRIMARY KEY (creation_id),
	CONSTRAINT release_date_check CHECK (release_date > '1900-01-01' AND release_date < '2100-01-01'),
	CONSTRAINT profits_check CHECK (profits >= 0),
	CONSTRAINT last_update_profits_check CHECK (last_update_profits >= '2000-01-01' AND last_update_profits <= NOW())
);
-- trigger : a l'ajout d'une ligne, met automatiquement profits à 0 et last_update_profits à NOW()
-- trigger : BEFORE insert/update, update 0-n ligne dans la table PaymentRecords en fonction de la Participation de tous les artistes y ayant joué


CREATE TABLE Requests
(
    request_id SERIAL CONSTRAINT Requests_request_id_pk PRIMARY KEY,
    contact_id INTEGER NOT NULL, --trigger vérifier que contact a un skill_type : job : producteur
    creation_id INTEGER NOT NULL, 
    request_description TEXT, 
    budget NUMERIC (12,2) NOT NULL CHECK(budget >=0),
    request_status requests_status_type NOT NULL, 
    request_start DATE NOT NULL DEFAULT NOW(), 
    request_end DATE,
    CONSTRAINT Requests_contact_id_fk FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
    CONSTRAINT Creations_creation_id_fk FOREIGN KEY (creation_id) REFERENCES project_db_2021.Creations (creation_id),
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
    request_id INTEGER NOT NULL, 
    contact_id INTEGER NOT NULL,  --artist
    proposal_status proposals_status_type NOT NULL, --trigger BEFORE insert/update : ('rejected', 'accpeted', 'pending');
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
	CONSTRAINT postal_code_check CHECK (postal_code ~* '^[1-9]{1}[0-9]{1,7}$')
);

CREATE TABLE AgencyContracts(
	contact_id INT NOT NULL,
	contract_start DATE NOT NULL,
	contract_end DATE,
	fee NUMERIC(6,4) NOT NULL,
	CONSTRAINT AgencyContracts_pkey PRIMARY KEY (contact_id, contract_start),
	CONSTRAINT agency_contracts_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT contract_start_check CHECK (contract_start > '1900-01-01' AND contract_start < '2100-01-01'),
	CONSTRAINT contract_end_check CHECK (contract_end > contract_start AND contract_end < '2100-01-01'),
	CONSTRAINT fee_check CHECK (fee > 0 AND fee < 100)
);
-- trigger : verifier que deux contrats avec le meme artiste n'ont pas cours au meme moment

CREATE TABLE AgentRecords(
	agent_id INT NOT NULL,
	contact_id INT NOT NULL,
	represent_start DATE NOT NULL,
	represent_end DATE,
	CONSTRAINT AgentRecord_pkey PRIMARY KEY (agent_id, contact_id),
	CONSTRAINT agent_record_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES project_db_2021.Agents (agent_id),
	CONSTRAINT agent_record_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT represent_start_check CHECK (represent_start > '2000-01-01' AND represent_start < '2100-01-01'),
	CONSTRAINT represent_end_check CHECK (represent_end > represent_start AND represent_end < '2100-01-01')
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

-- END CREATE








-- FUNC LIFANG PRE INSERT
CREATE OR REPLACE FUNCTION contrat_en_cours(contactid INT) RETURNS BOOLEAN AS $$
    DECLARE 
      nb INT;
    BEGIN
		SELECT count(*)
		INTO nb
		FROM agencycontracts
		WHERE contact_id = contactid
			AND now() BETWEEN contract_start
				AND contract_end
			OR now() BETWEEN contract_start
				AND contract_end;
        IF (nb != 0) THEN
            return true;
        END IF;
		return false;
    END;
$$ LANGUAGE plpgsql;
-- TRIGGER LIFANG PRE INSERTION



CREATE OR REPLACE FUNCTION check_address_si_agent() RETURNS TRIGGER AS $$
   DECLARE 
      nb INT;
    BEGIN
        -- met dans la variable nb le nombre de lignes de agencycontracts portant sur le new.contact_id 
        -- avec pour condition : la date de depart que l'on souhaite insert est entre un contract_start et contract end de ce contact
        -- meme chose pour le contact end
        SELECT count(*) INTO nb
        from agencycontracts 
        where contact_id = new.contact_id
        and new.contract_start between contract_start and contract_end
        or new.contract_end between contract_start and contract_end;
        
        -- si une ligne existe dans nb, c'est qu'un contrat est déja en cours !
        IF (nb != 0) THEN
            RAISE NOTICE 'Rejected line because a contrat is currently in progress for this client';
            RETURN NULL;
        END IF;
        
        -- ici on réutilise nb afin de mettre dedans le nombre de ligne de ce new.contact_id ayant une address NULL
        select count(*) INTO nb
        from contacts
        where contact_id = new.contact_id
        and address is null;
        
        -- comme avant, si l'addresse est null, on stop !
        IF (nb != 0) THEN
            RAISE NOTICE 'Rejected line because client address is null';
            RETURN NULL;
        END IF;
        
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;


CREATE or replace TRIGGER address_agent
BEFORE INSERT OR UPDATE ON agencycontracts
FOR EACH ROW
EXECUTE PROCEDURE check_address_si_agent();


-- Func Lifang

--Requests
--insert data of requests randomly
CREATE OR REPLACE FUNCTION insert_requests() RETURNS void AS $$
DECLARE
    i INTEGER;
    j INTEGER;
    nb_contacts INTEGER;
    cid INTEGER;
    ran INTEGER;
BEGIN
    nb_contacts := (SELECT count(*) from contacts);
    FOR i IN 1..nb_contacts/3
    LOOP
        SELECT creation_id INTO cid FROM creations ORDER BY RANDOM() LIMIT 1;
        --the value of contact_id is between 1 and nb_contacts randomly
        --for having more open in requests
        --floor(...) + 1 to avoid 0
        ran := floor(RANDOM()*10+1);
        FOR j IN 1..ran
        LOOP
            INSERT INTO Requests(contact_id, creation_id, request_status, budget, request_end) 
            VALUES( floor(RANDOM()*nb_contacts)+1, 
                    cid, 
                    (ARRAY['open', 'closed', 'cancelled', 'open', 'open'])[floor(random()*5+1)]::requests_status_type, 
                    RANDOM()*10000, 
                    NOW() + INTERVAL '1 day' *random()*365
                   );
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--RequiredSkills
CREATE OR REPLACE FUNCTION insert_requiredskills() RETURNS void AS $$
DECLARE
    i INTEGER;
    nb_requests INTEGER;
    skid INTEGER;
    ran INTEGER;
BEGIN
    nb_requests := (SELECT count(*) from requests);
    FOR i IN 1..nb_requests
    LOOP
        -- skid = random job
        skid := (SELECT skill_id from skills where skill_type = 'job'  ORDER BY RANDOM() LIMIT 1);
        INSERT INTO RequiredSkills(request_id, skill_id) VALUES(i, skid);              
            
        -- insert 1 to 3 non job skill (1-3 lignes)
        ran := random()*3 +1; 
        INSERT INTO RequiredSkills(request_id, skill_id)          
        SELECT i, skill_id FROM skills where skill_id != skid ORDER BY RANDOM() LIMIT ran; 
     
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--Proposals
CREATE OR REPLACE FUNCTION insert_proposals() RETURNS void AS $$
DECLARE
    i INTEGER;
    nb_requests INTEGER;
    nb_contacts INTEGER;
    rid INTEGER;
    cid INTEGER;
    ran INTEGER;
BEGIN
    nb_requests := (SELECT count(*) from requests);
    nb_contacts := (SELECT count(*) from contacts);
    -- on cree nb_request * 2 propositions
    FOR i IN 1..nb_requests*2
    LOOP
        ran := floor(RANDOM()*90); -- for generating date randomly
        rid := floor(nb_requests*random() +1);
        cid := floor(nb_contacts*random() +1);
        IF rid IN (SELECT request_id FROM Proposals) THEN
            INSERT INTO Proposals(request_id, contact_id, proposal_status, proposed_date) 
            VALUES (rid, cid, (ARRAY['rejected', 'pending', 'pending'])[floor(random()*2+1)]::proposals_status_type, NOW() - '1 day'::INTERVAL * ran);
        ELSE 
            -- unique accepted per reuqest
            INSERT INTO Proposals(request_id, contact_id, proposal_status, proposed_date) 
            VALUES (rid, cid, 'accepted'::proposals_status_type, NOW() - '1 day'::INTERVAL * ran);        

        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--A vérifier
--ProducerContracts
CREATE OR REPLACE FUNCTION insert_producercontracts() RETURNS void AS $$
DECLARE
    i INTEGER;
    nb_proposals_accpeted INTEGER;
    nb_payment INTEGER;
    pid INTEGER;
    ran INTEGER;
    dat DATE;
	bud NUMERIC(12,2);
BEGIN
    nb_proposals_accpeted := (SELECT count(*) FROM proposals WHERE proposal_status = 'accepted');
    FOR i IN 1..nb_proposals_accpeted
    LOOP
        ran := floor(RANDOM()*365+1);
        dat := cast( NOW() - '1 year'::INTERVAL * RANDOM() AS DATE );
        nb_payment := floor(RANDOM()*10+1);
        
        SELECT budget,proposal_id INTO bud,pid FROM proposals p,requests r WHERE r.request_id=p.request_id and proposal_status = 'accepted' ORDER BY RANDOM() LIMIT 1;
        
		if(random()*100) > 90 then
			bud:=bud*1.1;
		end if;
		
        IF (pid, dat) NOT IN (SELECT proposal_id, contract_start FROM producercontracts)
        THEN
            INSERT INTO ProducerContracts(proposal_id, contract_start, installments_number, salary,contract_end,is_amendment,incentive) 
            VALUES (pid, dat, nb_payment, 
                    bud,
                    NOW() + '1 day'::INTERVAL*ran,
                    CASE WHEN pid in (SELECT proposal_id FROM ProducerContracts ) THEN True ELSE False END,
                    CASE WHEN nb_payment !=0 and RANDOM() <0.1  THEN (RANDOM()*0.1) ELSE 0.00 END
                   );
        ELSE
            i=i-1;
        END IF;
        
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--A vérifier
--insert_payments
CREATE OR REPLACE FUNCTION insert_paymentrecords() RETURNS void AS $$
DECLARE
    i INTEGER;
    j INTEGER;
    pid integer;
    nb_contracts INTEGER;
    nb_payment INTEGER;
    amount NUMERIC(12,2);
    dat DATE;
    c_product CURSOR  FOR 
        SELECT 
            proposal_id,installments_number,salary, contract_start
        FROM 
            ProducerContracts 
        WHERE 
            (proposal_id,contract_start) in ( select proposal_id,max(contract_start) from ProducerContracts group by proposal_id)
        ORDER BY 
            proposal_id ;
BEGIN
    open c_product;
    LOOP
        FETCH c_product INTO pid, nb_payment,amount,dat;
        EXIT WHEN NOT FOUND;
        for j in 1..nb_payment
        LOOP
            raise notice 'Exécuté à % % %', pid, nb_payment,amount;
            INSERT INTO paymentrecords(
                proposal_id , 
                contract_start , 
                payment_number , 
                amount , 
                payment_status, 
                date_planned,
                is_incentive) 
            VALUES (pid, dat, j, 
                    amount/nb_payment,
                   'todo'::payments_status_type,
                    dat + '1 month'::INTERVAL*j,
                    false
                   );
        END LOOP;       
    END LOOP;
close c_product;
END;
$$ LANGUAGE plpgsql;











-- INSERT DATA

--Contacts
COPY contacts(first_name, last_name, email, gender) FROM 'C:\BDDA\contacts.csv' WITH (FORMAT CSV);
UPDATE contacts SET society = 'Studio ' || UPPER(last_name) WHERE contact_id IN (SELECT contact_id FROM contacts ORDER BY RANDOM() LIMIT 1000);
UPDATE contacts SET birth_date =  TO_date(to_char(  1+random() *27, '00') || '-' || to_char( 1+random() *11, '00') || '-' ||  to_char( 1925 +random() *80, '0000') ,'DD-MM-YYYY' );
UPDATE contacts SET tel= '+33' || to_char( 600000000 + random() * 200000000 + 1, 'FM999999999') ;
ALTER TABLE contacts ALTER COLUMN tel SET NOT NULL;
UPDATE contacts SET address = to_char(  1+random()*98, '00') || ' rue de ' || last_name; -- 1+random()*98 avoid generating ##
UPDATE contacts SET postal_code = floor( 10001 + random() * 89999); --10001 avoid generating 0
update contacts set city =  (array['Paris', 'Strasbourg', 'Tours', 'Lille', 'Chicago', 'London', 'Berlin', 'Tokyo', 'New York', 'Marseille', 
                                   'Toulouse', 'Nice', 'Los Angeles', 'Versailles', 'Houston', 'Seoul', 'Seattle', 'Manchester', 'Toronto', 'Prague'
                                   'Taipei', 'Havana', 'New Delhi', 'Rome', 'Manila', 'Moscow', 'Sydney', 'Dubai', 'Madrid', 'Osaka'])
                                   [floor(random() * 30 + 1)];
SELECT * FROM contacts ORDER BY RANDOM() LIMIT 5;

--Agents
COPY Agents(email, first_name, last_name, gender, birth_date, tel, address, city, postal_code) FROM 'C:\BDDA\Agents.csv' WITH (FORMAT CSV);
SELECT * FROM Agents ORDER BY RANDOM() LIMIT 5;

--Creations
COPY Creations(creation_name, creation_type, release_date, profits, last_update_profits) FROM 'C:\BDDA\Creations.csv' WITH (FORMAT CSV);
UPDATE Creations SET profits = 0 WHERE  release_date > NOW();
UPDATE Creations SET last_update_profits = NOW() WHERE (release_date > NOW() OR last_update_profits < release_date);
SELECT * FROM Creations ORDER BY RANDOM() LIMIT 5;

--Requests
SELECT insert_requests();
SELECT * FROM Requests ORDER BY RANDOM() LIMIT 5;

--Skills
COPY Skills(skill_name, skill_type) FROM 'C:\BDDA\Skills.csv' WITH (FORMAT CSV);
SELECT * FROM Skills ORDER BY RANDOM() LIMIT 5;

--RequiredSkills
SELECT insert_requiredskills();
SELECT * FROM RequiredSkills ORDER BY RANDOM() LIMIT 5;

--contacts => request => requiresSkill => proposal => ProducerContracts => PaymentRecords

--Proposals
SELECT insert_proposals();
SELECT * FROM Proposals ORDER BY RANDOM() LIMIT 5;

--ProducerContracts
SELECT insert_producercontracts();
SELECT * FROM ProducerContracts ORDER BY RANDOM() LIMIT 5;

-- --PaymentRecords
SELECT insert_paymentrecords();
SELECT * FROM paymentrecords ORDER BY RANDOM() LIMIT 5;


-- TRIGGERS LIFANG POST INSERT

--TRIGGER5

--fonction check si un contrat est en cours pour un contactid
CREATE OR REPLACE FUNCTION contrat_en_cours(contactid INT) RETURNS BOOLEAN AS $$
    DECLARE 
      nb INT;
    BEGIN
		SELECT count(*)
		INTO nb
		FROM agencycontracts
		WHERE contact_id = contactid
			AND now() BETWEEN contract_start
				AND contract_end
			OR now() BETWEEN contract_start
				AND contract_end;
        IF (nb != 0) THEN
            return true;
        END IF;
		return false;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_proposals() RETURNS TRIGGER AS $$
	DECLARE 
	    nb INT;
	BEGIN
	
		--check si un contrat est en cours pour le contactid
		IF contrat_en_cours(new.contact_id) = false  and NEW.proposal_status != 'rejected'::proposals_status_type THEN
			RAISE EXCEPTION 'AUCUN CONTRAT EN COURS AVEC LE CLIENT !';
		END IF;
	    
		--check que la proposed_date est bien dans la fenetre de la request
	 	if new.proposed_date > (select request_end from requests where request_id=new.request_id) and NEW.proposal_status != 'rejected'::proposals_status_type  THEN
			RAISE EXCEPTION 'REQUEST EXPIREE !';
		END IF;

	 	if new.proposed_date < (select request_start from requests where request_id=new.request_id) and NEW.proposal_status != 'rejected'::proposals_status_type   THEN
			RAISE EXCEPTION 'REQUEST NON DEBUTEE !';
		END IF;
		
		--si on insert/update quelqu un en "accepted", personne d'autre ne dois etre déja dans l'état "accepted"
		if NEW.proposal_status = 'accepted'::proposals_status_type and (select count(*) from proposals where request_id=new.request_id and proposal_status = 'accepted') >0 THEN
			RAISE EXCEPTION 'UNE PERSONNE EST DEJA ACCEPTEE SUR CETTE REQUEST !';
		END IF;
		
		-- verifie que l on a pas deja proposé le contact en question
		select count(*) into NB from proposals where request_id=new.request_id and contact_id=new.contact_id;
		if nb >0 and NEW.proposal_status != 'rejected'::proposals_status_type  then
			RAISE EXCEPTION 'CONTACT % DEJA PROPOSE POUR LA REQUEST % !',new.contact_id,new.request_id ;
		END IF;
	
		-- si on ajoute quelqu'un en accepted pour la 1ere fois, on rejete toutes les autres demandes
		IF NEW.proposal_status = 'accepted' THEN
			update proposals set proposal_status='rejected'::proposals_status_type 
			where request_id=NEW.request_id 
			and proposal_id!=NEW.proposal_id;
		END IF;

    	RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER valide_annonce
BEFORE INSERT OR UPDATE ON proposals
FOR EACH ROW
EXECUTE PROCEDURE validate_proposals();






-- insert into agencycontracts values ( 1,now()+ INTERVAL '1 day',now()+ INTERVAL '4 day' ,21.5);
--select proposals.request_id,count(*) from proposals,requests where proposals.request_id=requests.request_id group by proposals.request_id  order by count(*) desc ;
--update proposals set proposal_status='accepted'::proposals_status_type where proposal_id='4151';
--insert into agencycontracts values ( 2100,now()- INTERVAL '1 day',now()+ INTERVAL '4 day' ,21.5);
--select * from requests r, proposals p  where r.request_id=p.request_id and r.request_id=1705;
--select * from creations where creation_id='1157';
--insert into proposals values (100066,1705,216,'rejected'::proposals_status_type,now() );
--update proposals set proposal_status='pending' where proposal_id=100048;
--delete from proposals where proposal_id=100050;
--select count(*) from proposals where request_id=3151 and contact_id=1140

-- TRIGGER 6

--(1) TRIGGER : installments_number > 0, case où installments_number peut être 0 lors Requests[budget] = 0
--(2) TRIGGER : Quand on crée un AVENANT, on annule les paiements du contrat précédent n'ayant pas encore eu lieu
--(3) TRIGGER : Chaque nouveau contrat genere des entrées de comptabilité (Pour tous les contrats)

CREATE OR REPLACE FUNCTION generate_payments() RETURNS TRIGGER AS $$
	DECLARE 
	    nb INT;
	BEGIN
		--check si un contrat est en cours pour le contactid
		IF contrat_en_cours(new.contact_id) = false  and NEW.proposal_status != 'rejected'::proposals_status_type THEN
			RAISE EXCEPTION 'AUCUN CONTRAT EN COURS AVEC LE CLIENT !';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER generate_payment
BEFORE INSERT OR UPDATE ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE generate_payments();

--/!\ check salary = celui de request
select * from proposals where proposal_id=3991;
select * from ProducerContracts;
select * from requests;

select budget,salary from requests r,proposals p , ProducerContracts pc 
where r.request_id=p.request_id and p.proposal_id=pc.proposal_id


