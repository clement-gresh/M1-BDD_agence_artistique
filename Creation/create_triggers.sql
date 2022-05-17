--Contacts
--Verify address is NOT NULL if the contact related to the adress is represented by agent
CREATE OR REPLACE FUNCTION check_address_if_agent() RETURNS TRIGGER AS $$
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


CREATE TRIGGER Agencycontracts_address_agent_trigger
BEFORE INSERT OR UPDATE ON agencycontracts
FOR EACH ROW
EXECUTE PROCEDURE check_address_if_agent();

--RequiredSkills
--A FAIRE, UNE FONCTIION

--Requests
--TRIGGER : request_start < Creations[release_date] et request_end < Creations[release_date]
CREATE OR REPLACE FUNCTION check_request_date() RETURNS TRIGGER AS $$
    BEGIN
        -- si la nouvelle request que l'on insert a une date de debut superieure a la date de release de la creation
        if new.request_start > ( select release_date from creations where creation_id=new.creation_id ) then 
            RAISE NOTICE 'Rejected line because the date of request ("%", "%") did not respect the contraint.', NEW.request_start, NEW.request_end;
            RETURN NULL;                
        end if;      
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Requests_reuqests_date_trigger
BEFORE INSERT OR UPDATE ON Requests
FOR EACH ROW
EXECUTE PROCEDURE check_request_date();


--Proposals
--ProducerContracts
--PaymentRecords

