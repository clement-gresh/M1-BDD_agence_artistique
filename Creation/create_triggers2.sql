-- TRIGGERS POST INSERT GLOBAL


-- Proposals : check that it is valid
CREATE OR REPLACE FUNCTION validate_proposals() RETURNS TRIGGER AS $$
	DECLARE 
	    nb INT;
	BEGIN
	
		--check si un contrat est en cours pour le contactid
		IF has_current_contract(new.contact_id,now()) = false  AND NEW.proposal_status != 'rejected'::proposals_status_type THEN
			RAISE NOTICE 'AUCUN CONTRAT EN COURS AVEC LE CLIENT !';
			return null;
		END IF;
	    
		--check que la proposed_date est bien dans la fenetre de la request
	 	if new.proposed_date > (SELECT request_end FROM requests WHERE request_id=new.request_id) AND NEW.proposal_status != 'rejected'::proposals_status_type  THEN
			RAISE notice 'REQUEST EXPIREE !';
			return null;
		END IF;

	 	if new.proposed_date < (SELECT request_start FROM requests WHERE request_id=new.request_id) AND NEW.proposal_status != 'rejected'::proposals_status_type   THEN
			RAISE notice 'REQUEST NON DEBUTEE !';
			return null;
		END IF;

		-- verifie que l on a pas deja proposé le contact en question
		SELECT count(*) into NB FROM proposals WHERE request_id=new.request_id AND contact_id=new.contact_id;
		if nb >0 AND NEW.proposal_status != 'rejected'::proposals_status_type  then
			RAISE notice 'CONTACT % DEJA PROPOSE POUR LA REQUEST % !',new.contact_id,new.request_id ;
			return null;
		END IF;
		
		--si on insert/update quelqu un en "accepted", personne d'autre ne dois etre déja dans l'état "accepted"
		if NEW.proposal_status = 'accepted'::proposals_status_type AND (SELECT count(*) FROM proposals WHERE request_id=new.request_id AND proposal_status = 'accepted') >0 THEN
			RAISE notice 'UNE PERSONNE EST DEJA ACCEPTEE SUR CETTE REQUEST !';
			return null;
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



-- TRIGGER 6 
--/!\ 2 triggers : 1 before insert or update (check contrat en cour avec contact ) 1 after  insert ( genere lignes de paiements )
--(1) TRIGGER : installments_number > 0, case où installments_number peut être 0 lors Requests[budget] = 0
--(2) TRIGGER : QuAND on crée un AVENANT, on annule les paiements du contrat précédent n'ayant pas encore eu lieu
--(3) TRIGGER : Chaque nouveau contrat genere des entrées de comptabilité (Pour tous les contrats)

CREATE OR REPLACE FUNCTION generate_payments() RETURNS TRIGGER AS $$
    DECLARE 
        nb INT;
        cid int;
        stat proposals_status_type;
    BEGIN
        select contact_id,proposal_status into cid,stat from proposals where proposal_id=new.proposal_id;
        --check si un contrat est en cours pour le contactid
        IF has_current_contract(cid, NOW()) = false  AND stat != 'rejected'::proposals_status_type THEN
            RAISE NOTICE 'AUCUN CONTRAT EN COURS AVEC LE CLIENT !';
            RETURN NULL;
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER generate_payment
BEFORE INSERT OR UPDATE ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE generate_payments();

CREATE OR REPLACE FUNCTION generate_payments_insert() RETURNS TRIGGER AS $$
    DECLARE 
        compteur INT := 0;
    BEGIN
        UPDATE paymentrecords
        SET payment_status = 'avenant'::payments_status_type
        WHERE proposal_id = new.proposal_id
            AND payment_status != 'done'::payments_status_type;

        -- creation des lignes de paiements en fonction du nombre de paiements.
        LOOP
            compteur := compteur +1 ;    
            EXIT when compteur > new.installments_number;
            INSERT INTO paymentrecords values(new.proposal_id,new.signed_date,compteur,new.salary/new.installments_number,'todo'::payments_status_type, NOW() + INTERVAL '1 month' * (compteur-1),null,false );
        END LOOP;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER generate_payments_insert
AFTER INSERT ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE generate_payments_insert();