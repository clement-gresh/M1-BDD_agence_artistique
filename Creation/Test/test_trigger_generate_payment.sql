-- Test generate_payment

CREATE OR REPLACE FUNCTION test_generate_payment() RETURNS void AS $$
    DECLARE 
        contactid INT ;
    BEGIN
		raise notice 'We select a random contacts who never have a contract but address is filles ';
		SELECT contact_id
		INTO contactid
		from contacts
		WHERE contact_id not IN (
				SELECT contact_id
				FROM agencycontracts
				) and  address is not null order by random() limit 1;
		raise notice 'we try to generate a contract for this contact id %',contactid;
		insert into ProducerContracts values(
			(select proposal_id from proposals where proposal_status ='accepted' order by random() limit 1),
			now(),
			now()+INTERVAL '1 day',
			random()*10000,
			1,
			now(),
			1
		);
    END;
$$ LANGUAGE plpgsql;

select test_generate_payment();