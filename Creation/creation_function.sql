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
    nb_contacts := (SELECT count(*) from contacts);
    FOR i IN 1..nb_contacts/3
    LOOP
        SELECT creation_id,release_date INTO cid,dat FROM creations ORDER BY RANDOM() LIMIT 1;
        --the value of contact_id is between 1 and nb_contacts randomly
        --for having more open in requests
        --floor(...) + 1 to avoid 0
        ran := floor(RANDOM()*10+1);
        FOR j IN 1..ran
        LOOP
            INSERT INTO Requests(contact_id, creation_id, request_status, budget,request_start, request_end) 
            VALUES( floor(RANDOM()*nb_contacts)+1, 
                    cid, 
                    (ARRAY['open', 'closed', 'cancelled', 'open', 'open'])[floor(random()*5+1)]::requests_status_type, 
                    RANDOM()*10000, 
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
    c_product CURSOR  FOR --cursor lié un pointeur interne a la prochaine ligne a ligne
        SELECT 
            proposal_id,installments_number,salary, contract_start
        FROM 
            ProducerContracts 
        WHERE 
            (proposal_id,contract_start) in ( select proposal_id,max(contract_start) from ProducerContracts group by proposal_id)
        ORDER BY 
            proposal_id ;
BEGIN
OPEN c_product;
    LOOP
        --FETCH lit et stoke la prochaine ligne du cursuer dans des variables, s'il n'en y a pas, FETCH renvoie NULL
        FETCH c_product INTO pid, nb_payment,amount,dat; 
        EXIT WHEN NOT FOUND; --FOUND : trouvé la ligne
        FOR j IN 1..nb_payment
        LOOP
            -- raise notice 'Exécuté à % % %', pid, nb_payment,amount;
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
CLOSE c_product; --fermeture curseur
END;
$$ LANGUAGE plpgsql;