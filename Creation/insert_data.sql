
-- INSERT DATA

--PATH C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/filename
--PATH /Users/sulifang/Projets/projet-bdd-2021/Creation/filename

--Contacts
\COPY contacts(first_name, last_name, email, gender) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/contacts.csv' WITH (FORMAT CSV);
UPDATE contacts SET society = 'Studio ' || UPPER(last_name) WHERE contact_id IN (SELECT contact_id FROM contacts ORDER BY random() LIMIT 1000);
UPDATE contacts SET birth_date =  TO_date(to_char(  1+random() *27, '00') || '-' || to_char( 1+random() *11, '00') || '-' ||  to_char( 1925 +random() *80, '0000') ,'DD-MM-YYYY' );
UPDATE contacts SET tel= '+33' || to_char( 600000000 + random() * 200000000 + 1, 'FM999999999') ;
ALTER TABLE contacts ALTER COLUMN tel SET NOT NULL;
UPDATE contacts SET address = to_char(  1+random()*98, '00') || ' rue de ' || last_name; -- 1+random()*98 avoid generating ##
UPDATE contacts SET postal_code = floor( 10001 + random() * 89999); --10001 avoid generating 0
update contacts set city =  (array['Paris', 'Strasbourg', 'Tours', 'Lille', 'Chicago', 'London', 'Berlin', 'Tokyo', 'New York', 'Marseille', 
                                   'Toulouse', 'Nice', 'Los Angeles', 'Versailles', 'Houston', 'Seoul', 'Seattle', 'Manchester', 'Toronto', 'Prague'
                                   'Taipei', 'Havana', 'New Delhi', 'Rome', 'Manila', 'Moscow', 'Sydney', 'Dubai', 'Madrid', 'Osaka'])
                                   [floor(random() * 30 + 1)];
SELECT * FROM contacts ORDER BY random() LIMIT 5;

--Agents
\COPY Agents(email, first_name, last_name, gender, birth_date, tel, address, city, postal_code) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Agents.csv' WITH (FORMAT CSV);
SELECT * FROM Agents ORDER BY random() LIMIT 5;

--Creations
\COPY Creations(creation_name, creation_type, release_date, profits, last_update_profits) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Creations.csv' WITH (FORMAT CSV);
UPDATE Creations SET profits = 0 WHERE  release_date > NOW();
UPDATE Creations SET last_update_profits = NOW() WHERE (release_date > NOW() OR last_update_profits < release_date);
SELECT * FROM Creations ORDER BY random() LIMIT 5;

--Skills
\COPY Skills(skill_name, skill_type) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Skills.csv' WITH (FORMAT CSV);
SELECT * FROM Skills ORDER BY random() LIMIT 5;

-- KnownSkills
\COPY KnownSkills(contact_id, skill_id) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/KnownSkills.csv' WITH (FORMAT CSV);

--Requests
SELECT insert_requests();
SELECT * FROM Requests ORDER BY random() LIMIT 5;

-- AgencyContracts
\COPY AgencyContracts(contact_id, contract_start, contract_end,fee) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/AgencyContracts.csv' WITH (FORMAT CSV);
UPDATE AgencyContracts SET contract_end = NULL WHERE contract_end = '2099-01-01';

--Involvments
\COPY Involvments(contact_id, creation_id, skill_id) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Involvments.csv' WITH (FORMAT CSV);

--RequiredSkills
SELECT insert_requiredskills();
SELECT * FROM RequiredSkills ORDER BY random() LIMIT 5;

--Skills
\COPY Skills(skill_name, skill_type) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/Skills.csv' WITH (FORMAT CSV);
SELECT * FROM Skills ORDER BY random() LIMIT 5;
 
-- AgentRecords
\COPY AgentRecords(agent_id, contact_id, represent_start, represent_end) FROM '/Users/sulifang/Projets/projet-bdd-2021/Creation/AgentRecords.csv' WITH (FORMAT CSV);
UPDATE AgentRecords SET represent_end = NULL WHERE represent_end >  NOW();

--Proposals
SELECT insert_proposals();
SELECT * FROM Proposals ORDER BY random() LIMIT 5;

--ProducerContracts
SELECT insert_producercontracts();
SELECT * FROM ProducerContracts ORDER BY random() LIMIT 5;

-- --PaymentRecords
SELECT insert_paymentrecords();
SELECT * FROM paymentrecords ORDER BY random() LIMIT 5;
-- mise a jour des paiements des contrats obsoletes suite aux avenants
update paymentrecords set payment_status ='avenant' where
(proposal_id, signed_date) in ( 
	select proposal_id,signed_date 
	from ProducerContracts 
	where (proposal_id,signed_date) not in (
		select proposal_id,max(signed_date) from ProducerContracts group by proposal_id )
);
