
-- launch for creating functions
\i creation_function.sql

--Contacts
COPY contacts(first_name, last_name, email, gender) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/contacts.csv' WITH (FORMAT CSV);
UPDATE contacts SET society = 'Studio ' || UPPER(last_name) WHERE contact_id IN (SELECT contact_id FROM contacts ORDER BY RANDOM() LIMIT 1000);
UPDATE contacts SET birth_date =  TO_date(to_char(  1+random() *27, '00') || '-' || to_char( 1+random() *11, '00') || '-' ||  to_char( 1925 +random() *80, '0000') ,'DD-MM-YYYY' );
UPDATE contacts SET tel= '+33' || to_char( 600000000 + random() * 200000000 + 1, 'FM999999999') ;
ALTER TABLE contacts ALTER COLUMN tel SET NOT NULL;
UPDATE contacts SET address = to_char(  1+random()*98, '00') || ' rue de ' || last_name; -- 1+random()*98 avoid generating ##
UPDATE contacts SET postal_code = floor( 10001 + random() * 89999); --10001 avoid generating 0
update contacts set city =  (array['Paris', 'Strasbourg', 'Tours', 'Lille', 'Chicago', 'London', 'Berlin', 'Tokyo', 'New York', 'Marseille', 
                                   'Toulouse', 'Nice', 'Los Angeles', 'Versailles', 'Houston', 'Seoul', 'Seattle', 'Manchester', 'Toronto', 'Prague'
                                   'Taipei', 'Havana', 'New Delhi', 'Rome', 'Manila', 'Moscow', 'Sydney', 'Dubai', 'Madrid', 'Osaka'])
                                   [floor(random() * 30 + 1)];
SELECT * FROM contacts ORDER BY RANDOM() LIMIT 5;

--Agents
COPY Agents(email, first_name, last_name, gender, birth_date, tel, address, city, postal_code) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Agents.csv' WITH (FORMAT CSV);
SELECT * FROM Agents ORDER BY RANDOM() LIMIT 5;

--Creations
COPY Creations(creation_name, creation_type, release_date, profits, last_update_profits) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Creations.csv' WITH (FORMAT CSV);
UPDATE Creations SET profits = 0 WHERE  release_date > NOW();
UPDATE Creations SET last_update_profits = NOW() WHERE (release_date > NOW() OR last_update_profits < release_date);
SELECT * FROM Creations ORDER BY RANDOM() LIMIT 5;

--Requests
SELECT insert_reuqests();
SELECT * FROM Requests ORDER BY RANDOM() LIMIT 5;

--Skills
COPY Skills(skill_name, skill_type) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Skills.csv' WITH (FORMAT CSV);
SELECT * FROM Skills ORDER BY RANDOM() LIMIT 5;
