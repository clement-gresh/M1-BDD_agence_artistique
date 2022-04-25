--Requests
--insert data of requests randomly
CREATE OR REPLACE FUNCTION insert_reuqests() RETURNS void AS $$
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
    j INTEGER;
    nb_requests INTEGER;
    skid INTEGER;
    tmp INTEGER;
BEGIN
    nb_requests := (SELECT count(*) from requests);
    FOR i IN 1..nb_requests
    LOOP
        SELECT skill_id INTO skid FROM skills ORDER BY RANDOM() LIMIT 1;
        tmp := skid;
        IF (i, tmp) NOT IN (SELECT request_id, skill_id FROM RequiredSkills) THEN
            INSERT INTO RequiredSkills(request_id, skill_id) 
            VALUES(i, skid);
        ELSE
            SELECT skill_id INTO skid FROM skills ORDER BY RANDOM() LIMIT 1;
            INSERT INTO RequiredSkills(request_id, skill_id) 
            VALUES(i, skid);
        END IF; 
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--Proposals
CREATE OR REPLACE FUNCTION insert_proposals() RETURNS void AS $$
DECLARE
    i INTEGER;
    nb_requests INTEGER;
    rid INTEGER;
    cid INTEGER;
    ran INTEGER;
BEGIN
    nb_requests := (SELECT count(*) from requests);
    FOR i IN 1..nb_requests
    LOOP
        ran := floor(RANDOM()*90);
        SELECT request_id INTO rid FROM requests ORDER BY RANDOM() LIMIT 1;
        SELECT contact_id INTO cid FROM contacts ORDER BY RANDOM() LIMIT 1;
        INSERT INTO Proposals(request_id, contact_id, proposal_status, proposed_date) 
        VALUES (rid, cid, (ARRAY['rejected', 'accpeted', 'accpeted', 'pending', 'pending'])[floor(random()*4+1)]::proposals_status_type, NOW() - '1 day'::INTERVAL * ran);
    END LOOP;
END;
$$ LANGUAGE plpgsql;


--ProducerContracts
CREATE OR REPLACE FUNCTION insert_producercontracts() RETURNS void AS $$
DECLARE
    i INTEGER;
    nb_proposals_accpeted INTEGER;
    nb_payment INTEGER;
    pid INTEGER;
    ran INTEGER;
    dat DATE;
BEGIN
    nb_proposals_accpeted := (SELECT count(*) FROM proposals WHERE proposal_status = 'accpeted');
    FOR i IN 1..nb_proposals_accpeted
    LOOP
        ran := floor(RANDOM()*365);
        dat := cast( NOW() - '1 year'::INTERVAL * RANDOM() AS DATE );
        nb_payment := floor(RANDOM()*10);
        SELECT proposal_id INTO pid FROM proposals WHERE  proposal_status = 'accpeted' ORDER BY RANDOM() LIMIT 1;
        IF (pid, dat) NOT IN (SELECT proposal_id, contract_start FROM producercontracts)
        THEN
            INSERT INTO ProducerContracts(proposal_id, contract_start, installments_number, salary) 
            VALUES (pid, dat, nb_payment, CASE WHEN nb_payment != 0 THEN 100 + RANDOM()*5000 ELSE 0 END);
        ELSE
            SELECT proposal_id INTO pid FROM proposals WHERE  proposal_status = 'accpeted' ORDER BY RANDOM() LIMIT 1;
            dat := cast( NOW() - '1 year'::INTERVAL * RANDOM() AS DATE );
        END IF;
    END LOOP;
    UPDATE ProducerContracts SET contract_end = NOW() + '1 day'::INTERVAL*ran WHERE proposal_id in (SELECT proposal_id FROM proposals WHERE proposal_status = 'accpeted' ORDER BY RANDOM() LIMIT 1000);
    UPDATE ProducerContracts SET is_amendment = CASE WHEN proposal_id in (SELECT proposal_id FROM proposals WHERE proposal_status = 'accpeted' ORDER BY RANDOM() LIMIT 500) THEN True ELSE False END;
    UPDATE ProducerContracts SET incentive = CASE WHEN is_amendment = True AND installments_number !=0 THEN (RANDOM()*0.1) ELSE 0.00 END;
END;
$$ LANGUAGE plpgsql;

--trigger : contract_end <= release_date

--PaymentRecords
--   proposal_id INTEGER, 
--     contract_start DATE, 
--     payment_number INTEGER, 
--     amount NUMERIC(12,2) NOT NULL CHECK (amount >=0), 
--     payment_status payments_status_type NOT NULL, 
--     date_planned DATE NOT NULL, 
--     date_paid DATE, 
--     is_incentive BOOLEAN NOT NULL,
--     CONSTRAINT Payment_proposal_id_pk PRIMARY KEY (proposal_id, contract_start, payment_number),
--     CONSTRAINT Payment_proposal_id_date_fk FOREIGN KEY (proposal_id, contract_start) REFERENCES project_db_2021.ProducerContracts (proposal_id, contract_start)
