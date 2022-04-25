--Requests
--insert data of requests randomly
CREATE OR REPLACE FUNCTION insert_reuqests() RETURNS void AS $$
DECLARE
    i INTEGER;
    j INTEGER;
    nb_contacts INTEGER;
    cid INTEGER;
    ran INTEGER;
BEGIN
    nb_contacts := (SELECT count(*) from contacts);
    FOR i IN 1..nb_contacts/3
    LOOP
        SELECT creation_id INTO cid FROM creations ORDER BY RANDOM() LIMIT 1;
        --the value of contact_id is between 1 and nb_contacts randomly
        --for having more open in requests
        --floor(...) + 1 to avoid 0
        ran := floor(RANDOM()*10+1);
        FOR j IN 1..ran
        LOOP
            INSERT INTO Requests(contact_id, creation_id, request_status, budget, request_end) 
            VALUES( floor(RANDOM()*nb_contacts)+1, 
                    cid, 
                    (ARRAY['open', 'closed', 'cancelled', 'open', 'open'])[floor(random()*5+1)]::requests_status_type, 
                    RANDOM()*10000, 
                    NOW() + INTERVAL '1 day' *random()*365
                   );
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--RequiredSkills
CREATE OR REPLACE FUNCTION insert_requiredskills() RETURNS void AS $$
DECLARE
    i INTEGER;
    j INTEGER;
    nb_requests INTEGER;
    skid INTEGER;
    tmp INTEGER;
BEGIN
    nb_requests := (SELECT count(*) from requests);
    FOR i IN 1..nb_requests
    LOOP
        SELECT skill_id INTO skid FROM skills ORDER BY RANDOM() LIMIT 1;
        tmp := skid;
        IF (i, tmp) NOT IN (SELECT request_id, skill_id FROM RequiredSkills) THEN
            INSERT INTO RequiredSkills(request_id, skill_id) 
            VALUES(i, skid);
        ELSE
            SELECT skill_id INTO skid FROM skills ORDER BY RANDOM() LIMIT 1;
            INSERT INTO RequiredSkills(request_id, skill_id) 
            VALUES(i, skid);
        END IF; 
    END LOOP;
END;
$$ LANGUAGE plpgsql;