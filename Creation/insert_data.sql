
--Contacts
COPY contacts(first_name, last_name, email, gender)
FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/contacts.csv'
DELIMITER ','
CSV HEADER;

UPDATE contacts SET society = 'Studio ' || UPPER(last_name) WHERE contact_id IN (SELECT contact_id FROM contacts ORDER BY RANDOM() LIMIT 1000);

update contacts set birth_date =  TO_date(to_char(  1+random() *27, '00') || '-' || to_char( 1+random() *11, '00') || '-' ||  to_char( 1925 +random() *80, '0000') ,'DD-MM-YYYY' );

UPDATE contacts SET tel= '+33' || to_char( 600000000 + random() * 200000000 + 1, 'FM999999999') ;
ALTER TABLE contacts ALTER COLUMN tel SET NOT NULL;

-- 1+random()*99 genere des ##
UPDATE contacts SET address = to_char(  1+random()*98, '00') || ' rue de ' || last_name;

UPDATE contacts SET postal_code = 1+random() *99999;

update contacts set city =  (array['Paris', 'Strasbourg', 'Tours', 'Lille', 'Chicago', 
                                   'London', 'Berlin', 'Tokyo', 'New York', 'Marseille', 
                                   'Toulouse', 'Nice', 'Los Angeles', 'Versailles', 'Houston', 
                                   'Seoul', 'Seattle', 'Manchester', 'Toronto', 'Prague'
                                   'Taipei', 'Havana', 'New Delhi', 'Rome', 'Manila',
                                   'Moscow', 'Sydney', 'Dubai', 'Madrid', 'Osaka'])[floor(random() * 30 + 1)];
SELECT * FROM contacts LIMIT 5;

-- Requests
-- INSERT INTO requests
-- => CHECK PRODCONTACT has skill procuder , else give it to him
-- INSERT ON REQUIREDSKILL

--Requests
--insert data of requests randomly
-- CREATE OR REPLACE FUNCTION insert_reuqests() RETURNS void AS $$
-- DECLARE
--     i INTEGER; --330 open
--     j INTEGER; --330 close
--     k INTEGER; --340 pending
--     nb_contacts INTEGER;
-- BEGIN
--     nb_contacts := (SELECT count(*) from contacts)
--     FOR i IN (SELECT contact_id from contacts ORDER BY RANDOM() LIMIT 1000)
--     LOOP
--         INSERT INTO Requests(contact_id, request_status) VALUES(i, 'open', );
--     END LOOP;

-- END;
-- $$ LANGUAGE plpgsql;

-- SELECT insert_reuqests();
-- SELECT * FROM Requests LIMIT 5;


--   request_id SERIAL CONSTRAINT Requests_request_id_pk PRIMARY KEY,
--     contact_id INTEGER NOT NULL, --trigger vérifier que contact a un skill_type : job : producteur
--     creation_id INTEGER NOT NULL, 
--     request_description TEXT NOT NULL, 
--     budget NUMERIC (12,2) NOT NULL CHECK(budget >=0),  --trigger >=0
--     request_status requests_status_type NOT NULL, 
--     request_start DATE NOT NULL, 
--     request_end DATE,
--     CONSTRAINT Requests_contact_id_fk FOREIGN KEY (contact_id) REFERENCES project_db_2021.Contacts (contact_id),
--     CONSTRAINT Creations_creation_id_fk FOREIGN KEY (creation_id) REFERENCES project_db_2021.Creations (creation_id),
--     CHECK(request_end >= request_start)
