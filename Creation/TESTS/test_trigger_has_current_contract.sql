CREATE OR REPLACE FUNCTION test_has_current_contract() RETURNS void AS $$
    DECLARE 
        contactid INT ;
        startc date;
        endc date;
        res boolean;
    BEGIN
        raise notice 'We select a random row from agencycontracts where the contact_id have only 1 row ';
        SELECT contact_id
            ,contract_start
            ,contract_end
        INTO contactid
            ,startc
            ,endc
        FROM agencycontracts
        WHERE contact_id IN (
                SELECT contact_id
                FROM agencycontracts
                GROUP BY contact_id
                HAVING count(*) = 1
                ) order by random() limit 1  ;
        raise notice 'Currently contrat for contact_id % is on (% - %)',contactid,startc,endc;
        
        select has_current_contract(contactid,startc) into res;
        raise notice 'The following test must be true with % % : %',contactid,startc,res;
        select has_current_contract(contactid,endc) into res;
        raise notice 'The following test must be true with % % : %',contactid,endc,res;
        
        startc :=startc- INTERVAL '1 day';
        endc :=endc+ INTERVAL '1 day';
        
        select has_current_contract(contactid,startc) into res;
        raise notice 'The following test must be false with % % : %',contactid,startc,res;
        select has_current_contract(contactid,endc) into res;
        raise notice 'The following test must be false with % % : %',contactid,endc,res;
    END;
$$ LANGUAGE plpgsql;

select test_has_current_contract();