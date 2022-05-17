/*
command to execute in psql:
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/create_all.sql'
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/create_triggers_clem.sql'
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/insert_data_clem.sql'
<>
*/


-- Remember to remove the header from csv files
-- Remove ' and space in names

-- Agents
\copy Agents(email, first_name, last_name, gender, birth_date, tel, address, city, postal_code) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv' WITH (FORMAT CSV)

-- Creations
\copy Creations(creation_name, creation_type, release_date, profits, last_update_profits) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Creations.csv' WITH (FORMAT CSV)
UPDATE Creations SET profits = 0 WHERE  release_date > NOW();
UPDATE Creations SET last_update_profits = NOW() WHERE (release_date > NOW() OR last_update_profits < release_date);

-- Skills
\copy Skills(skill_name, skill_type) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Skills.csv' WITH (FORMAT CSV)


-- DEBUG : LIFANG
-- Contacts
\copy Contacts(first_name, last_name, email, gender) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Contacts.csv' WITH (FORMAT CSV)
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

-- debug : remplacer par floor(11+random() *99999); pour eviter code postal decimal ou a 1 seul chiffre
-- FIN DEBUG : LIFANG

-- KnownSkills
\copy KnownSkills(contact_id, skill_id) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/KnownSkills.csv' WITH (FORMAT CSV)


-- AgencyContracts
\copy AgencyContracts(contact_id, contract_start, contract_end,	fee) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/AgencyContracts.csv' WITH (FORMAT CSV)
UPDATE AgencyContracts SET contract_end = NULL WHERE contract_end = '2099-01-01';

-- AgentRecords
\copy AgentRecords(agent_id, contact_id, represent_start, represent_end) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/AgentRecords.csv' WITH (FORMAT CSV)
UPDATE AgentRecords SET represent_end = NULL WHERE represent_end >  NOW();

/*
-- "C:\Users\Clem\01-coding-projects\08-sql-projects\projet-bdd-2021\Creation\Agents.csv"
-- 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv'

COPY Agents(email, first_name, last_name, gender, birth_date, tel, address, postal_code)
FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv'
DELIMITER ','
CSV HEADER;
*/


/*
insert into towns (
    code, article, name, department
)
select
    left(md5(i::text), 10),
    md5(random()::text),
    md5(random()::text),
    left(md5(random()::text), 4)
from generate_series(1, 1000000) s(i)
*/

/*
function (line) {
	let numero = '+33';
	for(var i = 1; i < 9; i++){
		numero = numero + (Math.floor(Math.random() * 10)).toString();
	}
	return numero;
}

function (line) {
	let numero = 0;
	for(var i = 1; i < 6; i++){
		numero = numero + Math.floor(Math.random() * Math.pow(10, i));
	}
	return numero;
} 
*/





-- REMARQUES
-- pour les cles primaire mettre comme nom de contrainte : TableName_pk
-- pour les cles etrangere mettre comme nom de contrainte : TableName_attribute_name_fk
-- pour les check, mettre comme nom de contrainte : attribute_name_check
-- pour les index : TableName_attribute_name_i


-- QUESTIONS
-- Utilise-t-on les cascades ? Pour supprimer les lignes d'une table ayant une FK qui est supprimee dans la table ou elle est definie