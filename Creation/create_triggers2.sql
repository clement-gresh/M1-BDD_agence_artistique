-- TRIGGERS POST INSERT GLOBAL


-- Proposals : check that it is valid
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

CREATE OR REPLACE TRIGGER valide_annonce
BEFORE INSERT OR UPDATE ON proposals
FOR EACH ROW
EXECUTE PROCEDURE validate_proposals();



-- ProducerContract
--(1) TRIGGER : installments_number > 0, cas où installments_number peut être 0 lors Requests[budget] = 0
--(2) TRIGGER : QuAND on crée un AVENANT, on annule les paiements du contrat précédent n'ayant pas encore eu lieu
--(3) TRIGGER : Chaque nouveau contrat genere des entrées de comptabilité (Pour tous les contrats)

CREATE OR REPLACE FUNCTION generate_payments() RETURNS TRIGGER AS $$
	DECLARE 
	    nb INT;
	BEGIN
		--check si un contrat est en cours pour le contactid
		IF has_current_contract(new.contact_id, NOW()) = false  AND NEW.proposal_status != 'rejected'::proposals_status_type THEN
			RAISE EXCEPTION 'AUCUN CONTRAT EN COURS AVEC LE CLIENT !';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

--/!\ 2 triggers : 1 insert 1 uppdate
CREATE OR REPLACE TRIGGER generate_payment
BEFORE INSERT OR UPDATE ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE generate_payments();

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

CREATE OR REPLACE TRIGGER generate_payments_insert
AFTER INSERT ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE generate_payments_insert();