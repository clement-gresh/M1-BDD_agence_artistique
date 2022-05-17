-- Test TRIGGER check_request_date

CREATE OR REPLACE FUNCTION test_check_request_date() RETURNS void AS $$
    DECLARE 
        creaid INT ;
		rel date;
		nb int := (select max(request_id) from requests);
    BEGIN
		select creation_id,release_date 
		into creaid,rel 
		from creations 
		order by random();
		raise notice 'We select a random creation : % Release : %',creaid,rel;
		raise notice 'We try to add a request with a start date and end date before the release';
		insert into requests values(nb+1,1,creaid,'Test',random()*100,'open'::requests_status_type,rel-INTERVAL '2 day',rel-INTERVAL '1 day');
		raise notice 'We try to add a request with a start date and end date after the release';
		insert into requests values(nb+2,1,creaid,'Test',random()*100,'open'::requests_status_type,rel+INTERVAL '1 day',rel+INTERVAL '2 day');
	END;
$$ LANGUAGE plpgsql;

select test_check_request_date();