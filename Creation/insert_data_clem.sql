/*
command to execute in psql:
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/create_all.sql'
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/create_triggers_clem.sql'
\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/insert_data_clem.sql'
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

/*
-- "C:\Users\Clem\01-coding-projects\08-sql-projects\projet-bdd-2021\Creation\Agents.csv"
-- 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv'

COPY Agents(email, first_name, last_name, gender, birth_date, tel, address, postal_code)
FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv'
DELIMITER ','
CSV HEADER;
*/


-- Remember to remove the header
-- Remove the ' and space in names
\copy Agents(email, first_name, last_name, gender, birth_date, tel, address, postal_code) FROM 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Agents.csv' WITH (FORMAT CSV)

SELECT * FROM Agents;




-- REMARQUES
-- pour les cles primaire mettre comme nom de contrainte : TableName_pk
-- pour les cles etrangere mettre comme nom de contrainte : TableName_attribute_name_fk
-- pour les check, mettre comme nom de contrainte : attribute_name_check
-- pour les index : TableName_attribute_name_i

-- pour fee, j'ai mis REAL et non DOUBLE car on n'a pas besoin de plus de 6 chiffres après la virgule


-- QUESTIONS
-- Utilise-t-on les cascades ? Pour supprimer les lignes d'une table ayant une FK qui est supprimee dans la table ou elle est definie


-- PROFS
-- quelle difference entre faire un check(function) et un TRIGGER(function) ? Quand les 2 sont possibles, lequel est preferable ?
-- dans un check, une fonction doit toujours retourner le meme resultat pour un meme contenu de ligne (ce qui n'est pas le cas pour un trigger).
-- Si on met une fonction dans un check, il peut donc y avoir de "l'etat cache" car on peut utiliser les valeurs d'autres tables. Il faut donc mettre
-- les fonctions dans les triggers et non dans les check.