--Requests 
CREATE OR REPLACE FUNCTION has_job() RETURNS TRIGGER AS $$
   DECLARE 
      nb INT;
	BEGIN
		SELECT count(*) INTO nb
		FROM Involvments INNER JOIN Skills
			ON Skills.skill_id = Involvments.skill_id
		WHERE Involvments.skill_id = NEW.skill_id AND Skills.skill_type = 'job'::skill_type_enum;
		
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