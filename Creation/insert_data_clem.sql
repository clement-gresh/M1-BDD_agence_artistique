/*
command to execute in psql:
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/create_all.sql'
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/create_triggers_clem.sql'
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/insert_data_clem.sql'
<>
*/


-- Remember to remove the header from csv files
-- Remove ' and space in names

\copy Agents(email, first_name, last_name, gender, birth_date, tel, address, city, postal_code) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv' WITH (FORMAT CSV)

\copy Creations(creation_name, creation_type, release_date, profits, last_update_profits) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Creations.csv' WITH (FORMAT CSV)
UPDATE Creations SET profits = 0 WHERE  release_date > NOW();
UPDATE Creations SET last_update_profits = NOW() WHERE (release_date > NOW() OR last_update_profits < release_date);

\copy Skills(skill_name, skill_type) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Skills.csv' WITH (FORMAT CSV)

SELECT * FROM Skills;

/*
-- "C:\Users\Clem\01-coding-projects\08-sql-projects\projet-bdd-2021\Creation\Agents.csv"
-- 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv'

COPY Agents(email, first_name, last_name, gender, birth_date, tel, address, postal_code)
FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv'
DELIMITER ','
CSV HEADER;
*/



-- UPDATE Contacts SET tel = '+33' || to_char( 600000000 + random() * 200000000 + 1, 'FM999999999') ;

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