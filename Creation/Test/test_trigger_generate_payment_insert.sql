
CREATE OR REPLACE FUNCTION test_generate_payment_insert() RETURNS void AS $$
    DECLARE 
        nb INT ;
		pid int;
		pr_a int;
		pr_d int;
		pr_c int;
		pr_t int;
		crid int;
		cid int;
    BEGIN
		raise notice 'We select a random proposal with multiple contracts on a single proposal ';
		SELECT p.proposal_id
		into pid
		FROM ProducerContracts p
			,paymentrecords pr
		WHERE p.proposal_id = pr.proposal_id
			and p.signed_date=pr.signed_date
			AND p.proposal_id IN (
				SELECT proposal_id
				FROM ProducerContracts
				GROUP BY proposal_id
				HAVING count(*) > 1
				ORDER BY random() limit 1
				);
		select contact_id into cid from proposals where proposal_id=pid;
		select count(*) into pr_a from paymentrecords where proposal_id=pid and payment_status='avenant' ;
		select count(*) into pr_d from paymentrecords where proposal_id=pid and payment_status='done' ;
		select count(*) into pr_c from paymentrecords where proposal_id=pid and payment_status='cancelled' ;
		select count(*) into pr_t from paymentrecords where proposal_id=pid and payment_status='todo' ;
		raise notice 'We select a random proposal with multiple contracts : % Avenant :% Done:% Cancelled:% Todo:%',pid,pr_a,pr_d,pr_c,pr_t;

		RAISE NOTICE 'We add a new Contract on Agencycontracts for this proposal => ';
		select creation_id into crid from requests,proposals where requests.request_id = proposals.request_id and proposal_id=pid;
		update creations set release_date =now()+INTERVAL '10 month' where creation_id=crid;
		insert into AgencyContracts values(cid,now()-INTERVAL '1 day',now()+INTERVAL '1 day',random()*10);
		RAISE NOTICE 'We add a new Contract on ProducerContracts for this proposal => ';
		insert into ProducerContracts values(pid,now()+INTERVAL '1 month',now()+INTERVAL '1 month',round(1000*random()),round(random()*10+3),now(),0);
		select count(*) into pr_a from paymentrecords where proposal_id=pid and payment_status='avenant' ;
		select count(*) into pr_d from paymentrecords where proposal_id=pid and payment_status='done' ;
		select count(*) into pr_c from paymentrecords where proposal_id=pid and payment_status='cancelled' ;
		select count(*) into pr_t from paymentrecords where proposal_id=pid and payment_status='todo' ;
		raise notice 'We select a random proposal with multiple contracts : % Avenant :% Done:% Cancelled:% Todo:%',pid,pr_a,pr_d,pr_c,pr_t;
END;
$$ LANGUAGE plpgsql;

select test_generate_payment_insert();