
--Contacts
COPY contacts(first_name, last_name, email, gender) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/contacts.csv' WITH (FORMAT CSV);

UPDATE contacts SET society = 'Studio ' || UPPER(last_name) WHERE contact_id IN (SELECT contact_id FROM contacts ORDER BY RANDOM() LIMIT 1000);

update contacts set birth_date =  TO_date(to_char(  1+random() *27, '00') || '-' || to_char( 1+random() *11, '00') || '-' ||  to_char( 1925 +random() *80, '0000') ,'DD-MM-YYYY' );

UPDATE contacts SET tel= '+33' || to_char( 600000000 + random() * 200000000 + 1, 'FM999999999') ;
ALTER TABLE contacts ALTER COLUMN tel SET NOT NULL;

-- 1+random()*98 avoid generating ##
UPDATE contacts SET address = to_char(  1+random()*98, '00') || ' rue de ' || last_name;

UPDATE contacts SET postal_code = floor(1+random()*99999);

update contacts set city =  (array['Paris', 'Strasbourg', 'Tours', 'Lille', 'Chicago', 
                                   'London', 'Berlin', 'Tokyo', 'New York', 'Marseille', 
                                   'Toulouse', 'Nice', 'Los Angeles', 'Versailles', 'Houston', 
                                   'Seoul', 'Seattle', 'Manchester', 'Toronto', 'Prague'
                                   'Taipei', 'Havana', 'New Delhi', 'Rome', 'Manila',
                                   'Moscow', 'Sydney', 'Dubai', 'Madrid', 'Osaka'])[floor(random() * 30 + 1)];
SELECT * FROM contacts LIMIT 5;

--Agents
COPY Agents(email, first_name, last_name, gender, birth_date, tel, address, city, postal_code) 
FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Agents.csv' WITH (FORMAT CSV);
SELECT * FROM Agents LIMIT 5;

-- --Creations
COPY Creations(creation_name, creation_type, release_date, profits, last_update_profits) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Creations.csv' WITH (FORMAT CSV);
UPDATE Creations SET profits = 0 WHERE  release_date > NOW();
UPDATE Creations SET last_update_profits = NOW() WHERE (release_date > NOW() OR last_update_profits < release_date);
SELECT * FROM Creations LIMIT 5;

-- --Skills
COPY Skills(skill_name, skill_type) 
FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Skills.csv' WITH (FORMAT CSV);
SELECT * FROM Skills LIMIT 5;
