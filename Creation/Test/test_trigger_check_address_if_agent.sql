-- TEST TRIGGER check_address_if_agent

CREATE OR REPLACE FUNCTION test_check_address_if_agent() RETURNS INT AS $$
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
        
        raise notice 'We try to 3 contract to this person contact_id : % ( expected OK )',contactid;
        insert into agencycontracts values (contactid,now()+ INTERVAL '1 day',now()+ INTERVAL '1 month',20);
        insert into agencycontracts values (contactid,now()+ INTERVAL '1 month'+ INTERVAL '1 day',now()+ INTERVAL '2 month',20);
        insert into agencycontracts values (contactid,now()+ INTERVAL '2 month'+ INTERVAL '1 day',now()+ INTERVAL '3 month',20);
        
        raise notice 'We try to add a contract to this person contact_id : % during the SAME period ( expected ERROR )',contactid;
        insert into agencycontracts values (contactid,now()+ INTERVAL '2 day',now()+ INTERVAL '1 month'- INTERVAL '1 day',20);
        raise notice 'We remove his address and try to add a 4th contract (expected ERROR)';    
        update contacts set address=null where contact_id=contactid;
        insert into agencycontracts values (contactid,now()+ INTERVAL '3 month'+ INTERVAL '1 day',now()+ INTERVAL '4 month',20);
        return ( select count(*) from agencycontracts where contact_id=contactid) ;
        raise notice 'End of tests , 3 rows must remain';
        END;
$$ LANGUAGE plpgsql;

select test_check_address_if_agent();