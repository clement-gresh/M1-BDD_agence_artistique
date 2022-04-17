

-- UPDATE Contacts SET tel = '+33' || to_char( 600000000 + random() * 200000000 + 1, 'FM999999999') ;

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