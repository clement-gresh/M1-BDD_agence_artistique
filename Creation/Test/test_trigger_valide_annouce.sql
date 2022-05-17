-- Check trigger valide_annonce

CREATE OR REPLACE FUNCTION test_valide_annonce() RETURNS void AS $$
    DECLARE 
		pid int := (select max(proposal_id) from proposals);
		--cid = un contact_id n'ayant jamais eu de contrat avec l'agence
		cid int := (select contact_id from contacts where contact_id not in (select contact_id from agencycontracts) order by random() limit 1);
		--req = une requte ouverte et en cours a la date actuelle now()
		req INT;
		reqs date;
		reqe date;
		acc int;
		pen int;
		rej int;
		BEGIN
		-- on choisi une requete actuelle
			SELECT r.request_id,request_start,request_end
				into req,reqs,reqe
			FROM requests r, proposals p
			WHERE r.request_id=p.request_id and  request_start < now()
				AND request_end > now()
				AND request_status = 'open' and proposal_status != 'accepted'
				AND r.request_id in (select request_id from proposals where proposal_status = 'accepted')
				ORDER BY random() limit 1;		
				
		select count(*) into acc from proposals where request_id=req and proposal_status='accepted';
		select count(*) into pen from proposals where request_id=req and proposal_status='pending';
		select count(*) into rej from proposals where request_id=req and proposal_status='rejected';

		Raise notice 'Test sur la request % %-% Acecpted : % - Pending : % - Rejected : %',req,reqs,reqe,acc,pen,rej;
		RAISE NOTICE 'Test via le contact_id : % - aucun contrat avec agency pour le moment => KO',cid;
		insert into proposals values(pid+1,req,cid,'accepted'::proposals_status_type,reqs-INTERVAL '1 day');
		RAISE NOTICE 'Ajout contrat pour le client %',cid;
		insert into AgencyContracts values(cid,now()-INTERVAL '1 month',now()+INTERVAL '1 month',random()*10);
		RAISE NOTICE 'TEST avec ajout proposal sur  date < request start => KO ';
		insert into proposals values(pid+1,req,cid,'accepted'::proposals_status_type,reqs-INTERVAL '1 day');
		RAISE NOTICE 'TEST avec ajout proposal sur  date > request end => KO ';
		insert into proposals values(pid+1,req,cid,'accepted'::proposals_status_type,reqe+INTERVAL '1 day');
		RAISE NOTICE 'TEST avec une autre personne en accepted sur la demande => KO';
		insert into proposals values(pid+1,req,cid,'accepted'::proposals_status_type,now());
		raise notice 'TEST rejet des autres personnes en accepted sur cette demande - retry => OK';
		update  proposals set proposal_status='rejected' where request_id=req and proposal_status='accepted';
		insert into proposals values(pid+1,req,cid,'accepted'::proposals_status_type,now());
		raise notice 'TEST  Representaton de la meme personne pour la meme request';
		insert into proposals values(pid+2,req,cid,'accepted'::proposals_status_type,now());
		
		select count(*) into acc from proposals where request_id=req and proposal_status='accepted';
		select count(*) into pen from proposals where request_id=req and proposal_status='pending';
		select count(*) into rej from proposals where request_id=req and proposal_status='rejected';

		Raise notice 'Resultat de la request % %-% Acecpted : % - Pending : % - Rejected : %',req,reqs,reqe,acc,pen,rej;
	END;
$$ LANGUAGE plpgsql;

select test_valide_annonce();