--Requests
--insert data of requests randomly
CREATE OR REPLACE FUNCTION insert_reuqests() RETURNS void AS $$
DECLARE
    i INTEGER;
    nb_contacts INTEGER;
BEGIN
    nb_contacts := (SELECT count(*) from contacts);
    FOR i IN 1..nb_contacts/3
    LOOP
        --the value of contact_id is between 1 and nb_contacts randomly
        --for having more open in requests
        --floor(...) + 1 to avoid 0
        INSERT INTO Requests(contact_id, request_status, budget, request_end) 
        VALUES(floor(RANDOM()*nb_contacts)+1, (ARRAY['open', 'closed', 'cancelled', 'open', 'open'])[floor(random() * 5 + 1)]::requests_status_type, RANDOM()*10000, NOW()+INTERVAL '1 day' * random()*365);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT insert_reuqests();
SELECT * FROM Requests LIMIT 5;