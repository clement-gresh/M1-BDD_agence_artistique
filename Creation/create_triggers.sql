-- TRIGGER LiFang
-- fonction check si un contrat est en cours pour un contactid - utilisée pour le trigger 
CREATE OR REPLACE FUNCTION has_current_contract(contactid INT, dat date) RETURNS BOOLEAN AS $$
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
			raise notice 'CONTRAT % %',contactid,dat;
            return true;
        END IF;
		raise notice 'PAS DE CONTRAT % %',contactid,dat;
		return false;
    END;
$$ LANGUAGE plpgsql;

--TRIGGER pour table contacts
CREATE OR REPLACE FUNCTION check_address_if_agent() RETURNS TRIGGER AS $$
DECLARE 
    nb INT;
BEGIN     
    -- si une ligne existe dans nb, c'est qu'un contrat est déja en cours !
	IF (has_current_contract(new.contact_id,new.contract_start)=true) or (has_current_contract(new.contact_id,new.contract_end)=true)  THEN
        RAISE NOTICE 'Rejected line because a contrat is currently in progress for this client %',nb;
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

CREATE OR REPLACE TRIGGER address_agent
BEFORE INSERT OR UPDATE ON agencycontracts
FOR EACH ROW
EXECUTE PROCEDURE check_address_if_agent();

SELECT * FROM agencycontracts;

--TRIGGER
--Requests : check request_start < Creations[release_date] AND request_end < Creations[release_date]
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


-- TRIGGER Clément
-- Involvments : checks that the skills referenced in this table are of type 'job'
CREATE OR REPLACE FUNCTION is_skill_job() RETURNS TRIGGER AS $$
   DECLARE 
      nb INT;
	BEGIN
		SELECT count(*) INTO nb
		FROM Involvments INNER JOIN Skills
			ON Skills.skill_id = Involvments.skill_id
		WHERE Involvments.skill_id = NEW.skill_id AND Skills.skill_type = 'job'::skill_type_type;
		
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
		FROM Involvments INNER JOIN KnownSkills -- est-ce toutes les skills de chaque artiste apparraissent ? Ou faut-il LEFT/RIGHT JOIN ?
			ON Involvments.contact_id = KnownSkills.contact_id
		WHERE NEW.contact_id = KnownSkills.contact_id AND NEW.skill_id = KnownSkills.skill_id;
		
		IF (nb = 0) THEN
			RAISE NOTICE 'Rejected line ("%", "%", "%") because the artist does not appear to have that skill (see KnownSkills).',
				NEW.contact_id, NEW.creation_id, NEW.skill_id;
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


-- debug : /!\ a revoir avec Lifang
-- KnownSkills : checks that only a musician or singer can have a skill of type 'instrument' or 'style'
CREATE OR REPLACE FUNCTION is_musician() RETURNS TRIGGER AS $$
	DECLARE
      musician_skill INT;
	  is_musician INT;
	BEGIN
		SELECT count(*) INTO musician_skill
		FROM KnownSkills INNER JOIN Skills
			ON Skills.skill_id = KnownSkills.skill_id
		WHERE NEW.contact_id = KnownSkills.contact_id AND NEW.skill_id = KnownSkills.skill_id 
			AND (Skills.skill_type = 'instrument'::skill_type_type OR Skills.skill_type = 'style'::skill_type_type);
		
		IF (musician_skill > 0) THEN
			SELECT count(*) INTO is_musician
			FROM KnownSkills INNER JOIN Skills
				ON Skills.skill_id = KnownSkills.skill_id
			WHERE NEW.contact_id = KnownSkills.contact_id
				AND (Skills.skill_name = 'musician'::skill_name_type OR Skills.skill_name = 'singer'::skill_name_type);

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


