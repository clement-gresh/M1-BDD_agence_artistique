-- Creations : a l'ajout d'une ligne, met automatiquement profits à 0 et last_update_profits à NOW()
CREATE OR REPLACE FUNCTION profits_1_null() RETURNS TRIGGER AS $$
	BEGIN
		SET NEW.profits = 0;
		SET last_update_profits = NOW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Creations_profits
AFTER INSERT ON Creations
FOR EACH ROW
WHEN NEW.profits != 0
EXECUTE PROCEDURE profits_1_null();

-- Creations : BEFORE insert/update, update 0-n ligne dans la table PaymentRecords en fonction de la Participation de tous les artistes y ayant joué
/*CREATE OR REPLACE FUNCTION profits_2_payment() RETURNS TRIGGER AS $$
	BEGIN
		INSERT INTO PaymentRecords
			SELECT 
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Creations_profits_payment
AFTER INSERT OR UPDATE Creations
FOR EACH ROW
WHEN NEW.profits != 0
EXECUTE PROCEDURE profits_2_payment()*/

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
