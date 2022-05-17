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

CREATE OR REPLACE TRIGGER valide_annonce
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
CREATE OR REPLACE TRIGGER generate_payment
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

CREATE OR REPLACE TRIGGER generate_payment
AFTER INSERT ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE generate_payments_insert();

CREATE OR REPLACE FUNCTION auto_amendments() RETURNS TRIGGER AS $$
	BEGIN
		-- auto amendment :  si il y a deja un contrat sur la proposition_id , le contrat est considere comme etant un avenant
		IF (SELECT count(*)
		FROM ProducerContracts
		WHERE proposal_id = new.proposal_id
		 ) > 0 THEN
			raise notice 'Avenant detécté  : auto switch is_amendment=true ';
			new.is_amendment := true;
		end if;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auto_amendment
before INSERT ON ProducerContracts
FOR EACH ROW
EXECUTE PROCEDURE auto_amendments();


--SELECT * FROM ProducerContracts WHERE is_amendment =true;
--insert into ProducerContracts values(2000,now(),now(),10000,3,false,8);
--insert into ProducerContracts values(2000,now()+ INTERVAL '1 day',now()+ INTERVAL '2 day',10000,3,false,8);

-- REQUETE GLOBALE - Calcul des montant artiste et agence de chaque paiement par rapport a la taxe prévue dans son contrat
-- SELECT first_name
-- 	,last_name
-- 	,pay.contact_id
-- 	,fee
-- 	,creation_name
-- 	,release_date
-- 	,pay.request_id
-- 	,budget
-- 	,pay.proposal_id
-- 	,pccontract_start
-- 	,salary
-- 	,is_amendment
-- 	,installments_number
-- 	,payment_number
-- 	,amount
-- 	,payment_status
-- 	,is_incentive
-- 	,a.contract_start
-- 	,a.contract_end
-- 	,round(amount*(100-fee)/100,2) Salaire_Artiste
-- 	,round(amount*fee/100,2) Salaire_Agence FROM (
-- SELECT first_name
-- 	,last_name
-- 	,c.contact_id
-- 	,creation_name
-- 	,release_date
-- 	,r.request_id
-- 	,budget
-- 	,p.proposal_id
-- 	,pc.contract_start pccontract_start
-- 	,salary
-- 	,is_amendment
-- 	,installments_number
-- 	,payment_number
-- 	,amount
-- 	,payment_status
-- 	,is_incentive
-- FROM requests r
-- 	,creations cr
-- 	,proposals p
-- 	,ProducerContracts pc
-- 	,paymentrecords pr
-- 	,contacts c
-- WHERE r.request_id = p.request_id
-- 	AND r.creation_id = cr.creation_id
-- 	AND p.proposal_id = pc.proposal_id
-- 	AND pc.proposal_id = pr.proposal_id
-- 	AND c.contact_id = p.contact_id
-- --	AND ( pc.contract_start is null or )
-- 	AND p.proposal_id = (SELECT proposal_id FROM ProducerContracts pc WHERE is_amendment=true limit 1)
-- ) pay
-- 	left outer join agencycontracts a on ( pay.contact_id=a.contact_id AND pay.pccontract_start between a.contract_start AND a.contract_end )
-- ;


-- -- insert into agencycontracts values ( 2990,now()+ INTERVAL '1 day',now()+ INTERVAL '4 day' ,21.5);
-- --SELECT * FROM agencycontracts WHERE contact_id=1142;
-- --SELECT * FROM ProducerContracts WHERE proposal_id=996;
-- --SELECT * FROM requests;
-- --insert into requests values ( 10000,1000,9344,'blabla',1000,'open'::requests_status_type,now()+ INTERVAL '1 day',now()+ INTERVAL '10 day');
-- -- SELECT * FROM creations  c, requests r WHERE c.creation_id = r.creation_id ;
-- -- SELECT * FROM requests WHERE request_id=1489;

-- 	-- Trigger2 => sql
-- SELECT rr.request_id,skill_name,skill_type
-- FROM requests rr
-- 	,requiredskills rrs
-- 	,skills ss
-- WHERE rr.request_id = rrs.request_id
-- 	AND rrs.skill_id = ss.skill_id
-- 	AND rr.request_id NOT IN (
-- 		SELECT r.request_id
-- 		FROM requests r
-- 			,requiredskills rs
-- 			,skills s
-- 		WHERE r.request_id = rs.request_id
-- 			AND rs.skill_id = s.skill_id
-- 			AND skill_type = 'job'
-- 		GROUP BY r.request_id
-- 		)