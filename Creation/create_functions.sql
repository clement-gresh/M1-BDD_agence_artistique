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