-- SCHEMA + DB
DROP schema IF EXISTS project_db_2021 CASCADE;
CREATE SCHEMA project_db_2021 AUTHORIZATION postgres;
SET search_path TO project_db_2021;
SET datestyle = GERMAN, YMD;


-- TYPES
CREATE TYPE gender_type AS ENUM ('M', 'F', 'Nb', 'None');
CREATE TYPE proposals_status_type AS ENUM ('rejected', 'accepted', 'pending');
CREATE TYPE requests_status_type AS ENUM ('open', 'closed', 'cancelled');
CREATE TYPE payments_status_type AS ENUM ('done', 'todo', 'cancelled','avenant');
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
	address VARCHAR(200), 
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
    contract_end DATE CHECK(contract_end >= contract_start),
    salary NUMERIC(12,2) NOT NULL CHECK(salary >=0),
    installments_number INTEGER NOT NULL,
    signed_date DATE NOT NULL DEFAULT NOW() check (signed_date <= contract_start ),
    incentive NUMERIC(6, 4), --0.0001% 
    CONSTRAINT ProContracts_proposal_id_date_pk PRIMARY KEY (proposal_id, signed_date),
    CONSTRAINT ProContracts_proposal_id_fk FOREIGN KEY (proposal_id) REFERENCES project_db_2021.Proposals (proposal_id)
);

CREATE TABLE PaymentRecords
(
    proposal_id INTEGER, 
    signed_date DATE, 
    payment_number INTEGER, 
    amount NUMERIC(12,2) NOT NULL CHECK (amount >=0), 
    payment_status payments_status_type NOT NULL, 
    date_planned DATE NOT NULL, 
    date_paid DATE, 
    is_incentive BOOLEAN NOT NULL,
    CONSTRAINT Payment_proposal_id_pk PRIMARY KEY (proposal_id, signed_date, payment_number),
    CONSTRAINT Payment_proposal_id_date_fk FOREIGN KEY (proposal_id, signed_date) REFERENCES project_db_2021.ProducerContracts (proposal_id, signed_date),
    CHECK (date_paid >= signed_date) 
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
-- trigger : verifier que deux contrats avec le meme artiste n'ont pas cours au meme moment ?

CREATE TABLE AgentRecords(
	agent_id INT NOT NULL,
	contact_id INT NOT NULL,
	represent_start DATE NOT NULL,
	represent_end DATE,
	CONSTRAINT AgentRecord_pkey PRIMARY KEY (agent_id, contact_id),
	CONSTRAINT agent_record_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES project_db_2021.Agents (agent_id),
	CONSTRAINT agent_record_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
	CONSTRAINT represent_start_check CHECK (represent_start > '1900-01-01' AND represent_start < '2035-01-01'),
	CONSTRAINT represent_end_check CHECK (represent_end > represent_start AND represent_end < '2100-01-01')
);
-- trigger : verifier qu'un agent ne peut representer un artiste que quAND l'artiste a un contrat en cours avec l'agence ?


CREATE TABLE Involvments(
	contact_id INT NOT NULL,
	creation_id INT NOT NULL,
	skill_id INT NOT NULL,
	description text,
	CONSTRAINT Involvments_pk PRIMARY KEY (contact_id, creation_id,skill_id),
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




-- END CREATE







-- Function LIFANG 

-- fonction check si un contrat est en cours pour un contactid - utilisée pour le trigger 
CREATE OR REPLACE FUNCTION has_current_contract(contactid INT, dat timestamp with time zone) RETURNS BOOLEAN AS $$
    DECLARE 
      nb INT;
    BEGIN
		SELECT count(*)
		INTO nb
		FROM agencycontracts
		WHERE contact_id = contactid
			AND dat BETWEEN contract_start
				AND contract_end;
			
		
        IF (nb != 0) THEN
			--raise notice 'CONTRAT % %',contactid,dat;
            return true;
        END IF;
			--raise notice 'PAS DE CONTRAT % %',contactid,dat;
		return false;
    END;
$$ LANGUAGE plpgsql;





-- TRIGGER LIFANG PRE INSERTION
	--TRIGGER 1
CREATE OR REPLACE FUNCTION check_address_if_agent() RETURNS TRIGGER AS $$
   DECLARE 
      nb INT;
    BEGIN     
		--RAISE NOTICE 'TRIGGER check_address_if_agent % % %',new.contact_id,new.contract_start,new.contract_end;
        -- si une ligne existe dans nb, c'est qu'un contrat est déja en cours !
        IF (has_current_contract(new.contact_id,new.contract_start)=true) or (has_current_contract(new.contact_id,new.contract_end)=true)  THEN			
            RAISE NOTICE 'Rejected line because a contrat is currently in progress for this client contact id : % => % (%) - % (%)',new.contact_id,new.contract_start,has_current_contract(new.contact_id,new.contract_start),new.contract_end,has_current_contract(new.contact_id,new.contract_end);
            RETURN NULL;
        END IF;
        
        -- ici on réutilise nb afin de mettre dedans le nombre de ligne de ce new.contact_id ayant une address NULL
        SELECT count(*) INTO nb
        FROM contacts
        WHERE contact_id = new.contact_id
        AND address is null;
        
        -- comme avant, si l'addresse est null, on stop !
        IF (nb != 0) THEN
            RAISE NOTICE 'Rejected line because client address is null';
            RETURN NULL;
        END IF;
        
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER address_agent
BEFORE INSERT ON agencycontracts
FOR EACH ROW
EXECUTE PROCEDURE check_address_if_agent();


--trigger4
CREATE OR REPLACE FUNCTION check_request_date() RETURNS TRIGGER AS $$
    BEGIN
        -- si la nouvelle request que l'on insert a une date de debut ou de fin superieure a la date de release de la creation
        if new.request_start > ( SELECT release_date FROM creations WHERE creation_id=new.creation_id ) OR
		new.request_end > ( SELECT release_date FROM creations WHERE creation_id=new.creation_id )
		then 
            RAISE NOTICE 'Rejected line because the date of request ("%", "%") T4.', NEW.request_start, NEW.request_end;
            RETURN NULL;                
        end if;         
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Requests_reuqests_date_trigger
BEFORE INSERT OR UPDATE ON Requests
FOR EACH ROW
EXECUTE PROCEDURE check_request_date();

-- TRIGGER CLEM

-- TRIGGER Clément
-- Involvments : checks that the skills referenced in this table are of type 'job'
CREATE OR REPLACE FUNCTION is_skill_job() RETURNS TRIGGER AS $$
   DECLARE 
      nb INT;
	BEGIN
		SELECT count(*) INTO nb
		FROM Skills
		WHERE NEW.skill_id = Skills.skill_id and Skills.skill_type = 'job'::skill_type_type;
		
		IF (nb = 0) THEN
			RAISE NOTICE 'Rejected line ("%", "%", "%") because the skill is not of type job.',
				NEW.contact_id, NEW.creation_id, NEW.skill_id;
			RETURN NULL;
		ELSE
			RETURN NEW;
		END IF;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Involvments_is_skill_job_trigger
BEFORE INSERT OR UPDATE ON Involvments
FOR EACH ROW
EXECUTE PROCEDURE is_skill_job();



-- Involvments : checks in KnownSkills that the artist has the skill referenced here
CREATE OR REPLACE FUNCTION has_skill() RETURNS TRIGGER AS $$
	DECLARE
		nb INT;
	BEGIN
		SELECT count(*) INTO nb
		FROM KnownSkills
		WHERE NEW.contact_id = KnownSkills.contact_id AND NEW.skill_id = KnownSkills.skill_id;

		IF (nb = 0) THEN
			--RAISE NOTICE 'Rejected line ("%", "%", "%") because the artist does not appear to have that skill (see KnownSkills).',
			--	NEW.contact_id, NEW.creation_id, NEW.skill_id;
			RETURN NULL;
		ELSE
			RETURN NEW;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Involvments_has_skill_trigger
BEFORE INSERT OR UPDATE ON Involvments
FOR EACH ROW
EXECUTE PROCEDURE has_skill();
-- debug : est-ce toutes les skills de chaque artiste apparraissent ? Ou faut-il LEFT/RIGHT JOIN ?

-- KnownSkills : checks that only a musician or singer can have a skill of type 'instrument' or 'style'
CREATE OR REPLACE FUNCTION is_musician() RETURNS TRIGGER AS $$
	DECLARE
      musician_skill INT;
	  is_musician INT;
	BEGIN
		-- Checks if the new known skill is an instrument or a style
		SELECT count(*) INTO musician_skill
		FROM Skills
		WHERE NEW.skill_id = Skills.skill_id
			AND (Skills.skill_type = 'instrument'::skill_type_type OR Skills.skill_type = 'style'::skill_type_type);

		-- If it is, checks that the artist is a musician or a singer
		IF (musician_skill > 0) THEN
			SELECT count(*) INTO is_musician
			FROM KnownSkills INNER JOIN Skills
				ON Skills.skill_id = KnownSkills.skill_id
			WHERE NEW.contact_id = KnownSkills.contact_id
				AND (Skills.skill_name = 'musician'::skill_name_type OR Skills.skill_name = 'singer'::skill_name_type);

			-- If not, the insert/update is rejected
			IF (is_musician = 0) THEN
				RAISE NOTICE 'Rejected line ("%", "%") because only a musician or singer can know an instrument or have a style.',
					NEW.contact_id, NEW.skill_id;
				RETURN NULL;
			ELSE
				RETURN NEW;
			END IF;
		ELSE
			RETURN NEW;
		END IF;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER KnownSkills_is_musician_trigger
BEFORE INSERT OR UPDATE ON KnownSkills
FOR EACH ROW
EXECUTE PROCEDURE is_musician();

-- Creations : when a line is inserted, sets profits to 0 if it doesn't have a value and sets last_update_profits to NOW()
CREATE OR REPLACE FUNCTION profits_1_null() RETURNS TRIGGER AS $$
	BEGIN
		SET NEW.profits = 0;
		SET last_update_profits = NOW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Creations_profits
BEFORE INSERT ON Creations
FOR EACH ROW
WHEN (NEW.profits = NULL)
EXECUTE PROCEDURE profits_1_null();

-- Creations : when the profits are updated, adds a new line in PaymentRecords for each artist who was part of the creation.
-- The amount of the payment is the artist incentive for that creation times the increase in profits.
CREATE OR REPLACE FUNCTION profits_2_payment() RETURNS TRIGGER AS $$
	DECLARE
		incent NUMERIC(6, 4);
		prop_id INT;
		c_start DATE;
		p_nb INT;

		c_payment CURSOR FOR
			SELECT proposal_id, contract_start, incentive, payment_number
			FROM  Requests
				NATURAL JOIN Proposals
				NATURAL JOIN ProducerContracts
				NATURAL JOIN PaymentRecords
			WHERE Requests.creation_id = NEW.creation_id AND Proposals.proposal_status = 'accepted'::proposals_status_type
				AND (proposal_id, contract_start)
					in ( select proposal_id,max(contract_start) from ProducerContracts group by proposal_id)
				AND (proposal_id, contract_start, payment_number)
					in ( select proposal_id,contract_start, max(payment_number) from PaymentRecords group by (proposal_id,contract_start));

	BEGIN
		OPEN c_payment;
		LOOP
			FETCH c_payment INTO prop_id, c_start, incent, p_nb;
			EXIT WHEN NOT FOUND;

			INSERT INTO PaymentRecords(
				proposal_id,
				contract_start,
				payment_number,
				amount,
				payment_status,
				date_planned,
				date_paid,
				is_incentive)
			VALUES (prop_id,
				c_start,
				p_nb + 1,
				incent * (NEW.profits - OLD.profits),
				'todo',
				NOW(),
				NULL,
				true);
		END LOOP;
		CLOSE c_payment;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Creations_profits_payment
AFTER UPDATE ON Creations -- debug : add INSERT ? But then cannot use old so might need to do another trigger
FOR EACH ROW
WHEN (NEW.profits != 0)
EXECUTE PROCEDURE profits_2_payment();

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
	dat date;
BEGIN
    nb_contacts := (SELECT count(*) FROM contacts);
    FOR i IN 1..nb_contacts/3
    LOOP
        SELECT creation_id,release_date INTO cid,dat FROM creations ORDER BY random() LIMIT 1;
        --the value of contact_id is between 1 AND nb_contacts randomly
        --for having more open in requests
        --floor(...) + 1 to avoid 0
        ran := floor(random()*10+1);
        FOR j IN 1..ran
        LOOP
            INSERT INTO Requests(contact_id, creation_id, request_status, budget,request_start, request_end) 
            VALUES( floor(random()*nb_contacts)+1, 
                    cid, 
                    (ARRAY['open', 'closed', 'cancelled', 'open', 'open'])[floor(random()*5+1)]::requests_status_type, 
                    random()*10000, 
				    dat - INTERVAL '1 day' *(random()*100 +100),
                    dat - INTERVAL '1 day' *random()*100
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
    nb_requests := (SELECT count(*) FROM requests);
	-- pour chaque request on ajoute un job au minimum et 1 a 3 autres skills
    FOR i IN 1..nb_requests
    LOOP
        -- skid = rANDom job
        skid := (SELECT skill_id FROM skills WHERE skill_type = 'job'  ORDER BY random() LIMIT 1);
        INSERT INTO RequiredSkills(request_id, skill_id) VALUES(i, skid);              
        -- insert 1 to 3 non job skill (1-3 lignes)
        ran := random()*3 +1; 
        INSERT INTO RequiredSkills(request_id, skill_id)          
        SELECT i, skill_id FROM skills WHERE skill_id != skid ORDER BY random() LIMIT ran; 
     
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
    nb_requests := (SELECT count(*) FROM requests);
    nb_contacts := (SELECT count(*) FROM contacts);
    -- on cree nb_request * 2 propositions
    FOR i IN 1..nb_requests*2
    LOOP
        ran := floor(random()*90); -- for generating date rANDomly
        rid := floor(nb_requests*random() +1);
        cid := floor(nb_contacts*random() +1);
        IF rid IN (SELECT request_id FROM Proposals) THEN
            INSERT INTO Proposals(request_id, contact_id, proposal_status, proposed_date) 
            VALUES (rid, cid, (ARRAY['rejected', 'pending', 'pending'])[floor(random()*2+1)]::proposals_status_type, NOW() - '1 day'::INTERVAL * ran);
        ELSE 
            -- unique accepted per request
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
    ran float;
	cid integer;
    signed DATE;
	date_release date;
	--tz date;
	bud NUMERIC(12,2);
BEGIN
	-- pour le nombre de propositions acceptées, on génère un contrat ( certaines propositions auront 2 contrats ou +, d'autres 0 contrat)
    nb_proposals_accpeted := (SELECT count(*) FROM proposals WHERE proposal_status = 'accepted');
    FOR i IN 1..nb_proposals_accpeted
    LOOP
        ran := random(); -- pour conserver un random précis pour la contract_start, réutilisé pour agencycontracts
        nb_payment := floor(random()*10+1);
        
		-- on choisi une proposition aleatoire pour travailler dessus
        SELECT budget,proposal_id,p.contact_id,c.release_date INTO bud,pid,cid,date_release FROM proposals p,requests r,creations c WHERE r.request_id=p.request_id  and r.creation_id=c.creation_id AND proposal_status = 'accepted' ORDER BY random() LIMIT 1;
		-- la signature du contrat_start se fait dans l'année précédent la date_release
		signed := cast( date_release - '1 year'::INTERVAL*random() AS DATE );
      
		-- 10% des contrats ont un salaire supérieur a ce qui était prévu (négociation)
		if(random()*100) > 90 then
			bud:=bud*(1+random());
		end if;
		
		-- evite doublons
        IF (pid, signed) NOT IN (SELECT proposal_id, signed_date FROM producercontracts )
        THEN
			--on insert un contrat avec la signed_date
            INSERT INTO ProducerContracts(proposal_id, contract_start, installments_number, salary,contract_end,signed_date,incentive) 
            VALUES (pid, 
					signed + '1 year'::INTERVAL * ran,  --start = signed_date+ 1 an max
					nb_payment, 
                    bud,
                    signed + '1 year'::INTERVAL * ran + '1 year'::INTERVAL * random(), -- end = contract_start + 1 an max = signed_date + 1 an max + 1 an max
                    signed,
                    CASE WHEN nb_payment !=0 AND random() <0.1  THEN (random()*0.1) ELSE 0.00 END
                   );
			-- on insert un contrat avec l'agence dans agencycontract, avec les dates appropriées au contrat
			if has_current_contract(cid,signed) = false and has_current_contract(cid,signed - '1 month'::INTERVAL) = false  and has_current_contract(cid,signed+ '1 month'::INTERVAL) = false  then
				-- /!\ on insert des agencycontracts qui peuvent fail si la date de debut ou de fin du contrat chevauche avec un autre agencycontracts existant => visualisation par request
				INSERT INTO agencycontracts values(cid, signed - '1 month'::INTERVAL, signed + '1 month'::INTERVAL, 25*random()+0.001  );
			end if;
        ELSE
            i=i-1;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


--select * from agencycontracts where contact_id=2201;
--SELECT * FROM agencycontracts
--SELECT * FROM ProducerContracts limit 10;
--SELECT * FROM paymentrecords WHERE proposal_id=4;
--SELECT count(*) FROM ProducerContracts;
--SELECT count(*) FROM agencycontracts;
--SELECT count(*) FROM agencycontracts WHERE contact_id=1671;
--INSERT INTO agencycontracts values(1671, now()- '1 day'::INTERVAL* random()*1000, now()+ '1 day'::INTERVAL* random()*1000 , 25*random()  );

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
            proposal_id,installments_number,salary, signed_date
        FROM 
            ProducerContracts 
        --WHERE 
        --    (proposal_id,signed_date) in ( SELECT proposal_id,max(signed_date) FROM ProducerContracts group by proposal_id)
        ORDER BY 
            proposal_id ;
BEGIN
    open c_product;
    LOOP
        FETCH c_product INTO pid, nb_payment,amount,dat;
        EXIT WHEN NOT FOUND;
        for j in 1..nb_payment
        LOOP
            --raise notice 'Exécuté à % % %', pid, nb_payment,amount;
            INSERT INTO paymentrecords(
                proposal_id , 
                signed_date , 
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
select * from paymentrecords where proposal_id=4;






-- PATH : /Users/sulifang/Projets/projet-bdd-2021/Creation/Agents.csv
-- PATH : /Users/sulifang/Projets/projet-bdd-2021/Creation/

-- INSERT DATA

--Contacts
COPY contacts(first_name, last_name, email, gender) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/contacts.csv' WITH (FORMAT CSV);
UPDATE contacts SET society = 'Studio ' || UPPER(last_name) WHERE contact_id IN (SELECT contact_id FROM contacts ORDER BY random() LIMIT 1000);
UPDATE contacts SET birth_date =  TO_date(to_char(  1+random() *27, '00') || '-' || to_char( 1+random() *11, '00') || '-' ||  to_char( 1925 +random() *80, '0000') ,'DD-MM-YYYY' );
UPDATE contacts SET tel= '+33' || to_char( 600000000 + random() * 200000000 + 1, 'FM999999999') ;
ALTER TABLE contacts ALTER COLUMN tel SET NOT NULL;
UPDATE contacts SET address = to_char(  1+random()*98, '00') || ' rue de ' || last_name; -- 1+random()*98 avoid generating ##
UPDATE contacts SET postal_code = floor( 10001 + random() * 89999); --10001 avoid generating 0
update contacts set city =  (array['Paris', 'Strasbourg', 'Tours', 'Lille', 'Chicago', 'London', 'Berlin', 'Tokyo', 'New York', 'Marseille', 
                                   'Toulouse', 'Nice', 'Los Angeles', 'Versailles', 'Houston', 'Seoul', 'Seattle', 'Manchester', 'Toronto', 'Prague'
                                   'Taipei', 'Havana', 'New Delhi', 'Rome', 'Manila', 'Moscow', 'Sydney', 'Dubai', 'Madrid', 'Osaka'])
                                   [floor(random() * 30 + 1)];
SELECT * FROM contacts ORDER BY random() LIMIT 5;

--Agents
COPY Agents(email, first_name, last_name, gender, birth_date, tel, address, city, postal_code) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Agents.csv' WITH (FORMAT CSV);
SELECT * FROM Agents ORDER BY random() LIMIT 5;

--Creations
COPY Creations(creation_name, creation_type, release_date, profits, last_update_profits) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Creations.csv' WITH (FORMAT CSV);
UPDATE Creations SET profits = 0 WHERE  release_date > NOW();
UPDATE Creations SET last_update_profits = NOW() WHERE (release_date > NOW() OR last_update_profits < release_date);
SELECT * FROM Creations ORDER BY random() LIMIT 5;

--Skills
COPY Skills(skill_name, skill_type) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Skills.csv' WITH (FORMAT CSV);
SELECT * FROM Skills ORDER BY random() LIMIT 5;

-- KnownSkills
COPY KnownSkills(contact_id, skill_id) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/KnownSkills.csv' WITH (FORMAT CSV);

--Requests
SELECT insert_requests();
SELECT * FROM Requests ORDER BY random() LIMIT 5;

-- AgencyContracts
COPY AgencyContracts(contact_id, contract_start, contract_end,fee) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/AgencyContracts.csv' WITH (FORMAT CSV);
UPDATE AgencyContracts SET contract_end = NULL WHERE contract_end = '2099-01-01';

--Involvments
COPY Involvments(contact_id, creation_id, skill_id) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Involvments.csv' WITH (FORMAT CSV);

--RequiredSkills
SELECT insert_requiredskills();
SELECT * FROM RequiredSkills ORDER BY random() LIMIT 5;

--Skills
COPY Skills(skill_name, skill_type) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Skills.csv' WITH (FORMAT CSV);
SELECT * FROM Skills ORDER BY random() LIMIT 5;
 
-- AgentRecords
COPY AgentRecords(agent_id, contact_id, represent_start, represent_end) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/AgentRecords.csv' WITH (FORMAT CSV);
UPDATE AgentRecords SET represent_end = NULL WHERE represent_end >  NOW();

--Proposals
SELECT insert_proposals();
SELECT * FROM Proposals ORDER BY random() LIMIT 5;

--ProducerContracts
SELECT insert_producercontracts();
SELECT * FROM ProducerContracts ORDER BY random() LIMIT 5;

-- --PaymentRecords
SELECT insert_paymentrecords();
SELECT * FROM paymentrecords ORDER BY random() LIMIT 5;
-- mise a jour des paiements des contrats obsoletes suite aux avenants
update paymentrecords set payment_status ='avenant' where
(proposal_id, signed_date) in ( 
	select proposal_id,signed_date 
	from ProducerContracts 
	where (proposal_id,signed_date) not in (
		select proposal_id,max(signed_date) from ProducerContracts group by proposal_id )
);


-- TRIGGERS LIFANG POST INSERT GLOBAL

--TRIGGER 5

CREATE OR REPLACE FUNCTION validate_proposals() RETURNS TRIGGER AS $$
	DECLARE 
	    nb INT;
	BEGIN
	
		--check si un contrat est en cours pour le contactid
		IF has_current_contract(new.contact_id,now()) = false  AND NEW.proposal_status != 'rejected'::proposals_status_type THEN
			RAISE EXCEPTION 'AUCUN CONTRAT EN COURS AVEC LE CLIENT !';
		END IF;
	    
		--check que la proposed_date est bien dans la fenetre de la request
	 	if new.proposed_date > (SELECT request_end FROM requests WHERE request_id=new.request_id) AND NEW.proposal_status != 'rejected'::proposals_status_type  THEN
			RAISE EXCEPTION 'REQUEST EXPIREE !';
		END IF;

	 	if new.proposed_date < (SELECT request_start FROM requests WHERE request_id=new.request_id) AND NEW.proposal_status != 'rejected'::proposals_status_type   THEN
			RAISE EXCEPTION 'REQUEST NON DEBUTEE !';
		END IF;
		
		--si on insert/update quelqu un en "accepted", personne d'autre ne dois etre déja dans l'état "accepted"
		if NEW.proposal_status = 'accepted'::proposals_status_type AND (SELECT count(*) FROM proposals WHERE request_id=new.request_id AND proposal_status = 'accepted') >0 THEN
			RAISE EXCEPTION 'UNE PERSONNE EST DEJA ACCEPTEE SUR CETTE REQUEST !';
		END IF;
		
		-- verifie que l on a pas deja proposé le contact en question
		SELECT count(*) into NB FROM proposals WHERE request_id=new.request_id AND contact_id=new.contact_id;
		if nb >0 AND NEW.proposal_status != 'rejected'::proposals_status_type  then
			RAISE EXCEPTION 'CONTACT % DEJA PROPOSE POUR LA REQUEST % !',new.contact_id,new.request_id ;
		END IF;
	
		-- si on ajoute quelqu'un en accepted pour la 1ere fois, on rejete toutes les autres demANDes
		IF NEW.proposal_status = 'accepted' THEN
			update proposals set proposal_status='rejected'::proposals_status_type 
			WHERE request_id=NEW.request_id 
			AND proposal_id!=NEW.proposal_id;
		END IF;

    	RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER valide_annonce
BEFORE INSERT OR UPDATE ON proposals
FOR EACH ROW
EXECUTE PROCEDURE validate_proposals();






-- insert into agencycontracts values ( 1,now()+ INTERVAL '1 day',now()+ INTERVAL '4 day' ,21.5);
--SELECT proposals.request_id,count(*) FROM proposals,requests WHERE proposals.request_id=requests.request_id group by proposals.request_id  order by count(*) desc ;
--update proposals set proposal_status='accepted'::proposals_status_type WHERE proposal_id='4151';
--insert into agencycontracts values ( 2100,now()- INTERVAL '1 day',now()+ INTERVAL '4 day' ,21.5);
--SELECT * FROM requests r, proposals p  WHERE r.request_id=p.request_id AND r.request_id=1705;
--SELECT * FROM creations WHERE creation_id='1157';
--insert into proposals values (100066,1705,216,'rejected'::proposals_status_type,now() );
--update proposals set proposal_status='pending' WHERE proposal_id=100048;
--delete FROM proposals WHERE proposal_id=100050;
--SELECT count(*) FROM proposals WHERE request_id=3151 AND contact_id=1140

-- TRIGGER 6

--(1) TRIGGER : installments_number > 0, case où installments_number peut être 0 lors Requests[budget] = 0
--(2) TRIGGER : QuAND on crée un AVENANT, on annule les paiements du contrat précédent n'ayant pas encore eu lieu
--(3) TRIGGER : Chaque nouveau contrat genere des entrées de comptabilité (Pour tous les contrats)

CREATE OR REPLACE FUNCTION generate_payments() RETURNS TRIGGER AS $$
	DECLARE 
	    nb INT;
	BEGIN
		--check si un contrat est en cours pour le contactid
		IF has_current_contract(new.contact_id) = false  AND NEW.proposal_status != 'rejected'::proposals_status_type THEN
			RAISE EXCEPTION 'AUCUN CONTRAT EN COURS AVEC LE CLIENT !';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

--/!\ 2 triggers : 1 insert 1 uppdate

CREATE TRIGGER generate_payment
BEFORE INSERT OR UPDATE ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE generate_payments();

--/!\ check salary = celui de request
--SELECT * FROM proposals WHERE proposal_id=3991;
--SELECT * FROM requests;
--SELECT budget,salary FROM requests r,proposals p , ProducerContracts pc WHERE r.request_id=p.request_id AND p.proposal_id=pc.proposal_id;
--SELECT * FROM ProducerContracts;
--SELECT * FROM paymentrecords;
--insert into ProducerContracts values(2000,now(),now(),10000,3,false,8);
--SELECT * FROM paymentrecords WHERE proposal_id=2000;
--SELECT * FROM producercontracts WHERE proposal_id=7704;

CREATE OR REPLACE FUNCTION generate_payments_insert() RETURNS TRIGGER AS $$
	DECLARE 
	    compteur INT := 0;
	BEGIN
		-- annulation des paiements planifié par les autres contrats si le nouveau contrat est un avenant
		UPDATE paymentrecords
		SET payment_status = 'avenant'::payments_status_type
		WHERE proposal_id = new.proposal_id
			AND payment_status = 'todo'::payments_status_type
			AND date_planned > now();

		-- creation des lignes de paiements en fonction du nombre de paiements.
		LOOP
			compteur := compteur +1 ;	
			EXIT when compteur > new.installments_number;
			INSERT INTO paymentrecords values(new.proposal_id,new.contract_start,compteur,new.salary/new.installments_number,'todo'::payments_status_type, NOW() + INTERVAL '1 month' * (compteur-1),null,false );
		END LOOP;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_payment
AFTER INSERT ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE generate_payments_insert();

--CREATE OR REPLACE FUNCTION auto_amendments() RETURNS TRIGGER AS $$
--	BEGIN
		-- auto amendment :  si il y a deja un contrat sur la proposition_id , le contrat est considere comme etant un avenant
--		IF (SELECT count(*)
--		FROM ProducerContracts
--		WHERE proposal_id = new.proposal_id
--		 ) > 0 THEN
--			raise notice 'Avenant detécté  : auto switch is_amendment=true ';
--			new.is_amendment := true;
--		end if;
--		RETURN NEW;
--	END;
--$$ LANGUAGE plpgsql;

--CREATE TRIGGER auto_amendment
--before INSERT ON ProducerContracts
--FOR EACH ROW
--EXECUTE PROCEDURE auto_amendments();


--SELECT * FROM ProducerContracts WHERE is_amendment =true;
--insert into ProducerContracts values(2000,now(),now(),10000,3,false,8);
--insert into ProducerContracts values(2000,now()+ INTERVAL '1 day',now()+ INTERVAL '2 day',10000,3,false,8);

	-- Trigger2 => sql
SELECT rr.request_id,skill_name,skill_type
FROM requests rr
	,requiredskills rrs
	,skills ss
WHERE rr.request_id = rrs.request_id
	AND rrs.skill_id = ss.skill_id
	AND rr.request_id NOT IN (
		SELECT r.request_id
		FROM requests r
			,requiredskills rs
			,skills s
		WHERE r.request_id = rs.request_id
			AND rs.skill_id = s.skill_id
			AND skill_type = 'job'
		GROUP BY r.request_id
		);

-- REQUETE GLOBALE - Calcul des montant artiste et agence de chaque paiement par rapport a la taxe prévue dans son contrat
SELECT first_name
	,last_name
	,pay.contact_id
	,fee
	,creation_name
	,release_date
	,pay.request_id
	,budget
	,pay.proposal_id
	,pccontract_start
	,salary
	,signed_date
	,nb_installments_number
	,amount
	,payment_status
	,is_incentive
	,a.contract_start
	,a.contract_end
	,round(amount * (100 - fee) / 100, 2) Salaire_Artiste
	,round(amount * fee / 100, 2) Salaire_Agence
FROM (
	SELECT first_name
		,last_name
		,c.contact_id
		,creation_name
		,release_date
		,r.request_id
		,budget
		,p.proposal_id
		,pc.contract_start pccontract_start
		,salary
		,pc.signed_date
		,payment_number
		,installments_number
		,payment_number || '/' || installments_number nb_installments_number
		,amount
		,payment_status
		,is_incentive
	FROM requests r
		,creations cr
		,proposals p
		,ProducerContracts pc
		,paymentrecords pr
		,contacts c
	WHERE r.request_id = p.request_id
		AND r.creation_id = cr.creation_id
		AND p.proposal_id = pc.proposal_id
		AND pc.proposal_id = pr.proposal_id
		AND pc.signed_date = pr.signed_date
		AND c.contact_id = p.contact_id
		AND p.proposal_id = (
			SELECT proposal_id
			FROM ProducerContracts pc
			GROUP BY proposal_id
			HAVING count(*) > 1 limit 1
			)
	ORDER BY signed_date
		,payment_number
	) pay
LEFT OUTER JOIN agencycontracts a ON (
		pay.contact_id = a.contact_id
		AND pay.pccontract_start BETWEEN a.contract_start
			AND a.contract_end
		)
ORDER BY first_name
	,last_name
	,request_id
	,signed_date
	,payment_number;

-- insert into agencycontracts values ( 2990,now()+ INTERVAL '1 day',now()+ INTERVAL '4 day' ,21.5);
--SELECT * FROM agencycontracts WHERE contact_id=1142;

--SELECT * FROM requests;
--insert into requests values ( 10000,1000,9344,'blabla',1000,'open'::requests_status_type,now()+ INTERVAL '1 day',now()+ INTERVAL '10 day');
-- SELECT * FROM creations  c, requests r WHERE c.creation_id = r.creation_id ;
-- SELECT * FROM requests WHERE request_id=1489;
--SELECT * FROM ProducerContracts WHERE proposal_id=2;
--SELECT * FROM paymentrecords WHERE proposal_id=2;
--select * from paymentrecords where proposal_id=5


