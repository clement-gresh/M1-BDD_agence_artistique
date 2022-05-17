<>

CREATE TYPE payment_list AS (contact_id INT, first_name VARCHAR(50), last_name VARCHAR(50), creation_id INT,
    creation_name VARCHAR(100), proposal_id INT, contract_start DATE, amount NUMERIC(12,2));

CREATE OR REPLACE FUNCTION payment_received(artist INT, creation INT) RETURNS payment_list AS $$
DECLARE
    movie_name varchar(20);
BEGIN
    SELECT cont.contact_id, cont.first_name, cont.last_name, creat.creation_id, creat.creation_name,
        pc.proposal_id, pc.contract_start, pr.amount
    FROM Contacts AS cont
    NATURAL JOIN Involvments
    NATURAL JOIN Creations as creat
    NATURAL JOIN Requests
    NATURAL JOIN Proposals
    NATURAL JOIN ProducerContracts AS pc
    NATURAL JOIN PaymentRecords AS pr
    WHERE cont.contact_id = artist
        AND creat.creation_id = creation
        AND pr.payment_status = 'done'::payments_status_type;
END;
$$ LANGUAGE plpgsql;


/*
INSERT INTO Contacts(email, first_name, last_name, gender, birth_date, tel, city, address, postal_code)
    VALUES('cyril.kikou@lol.fr', 'cyril', 'kikou', 'M', '1983-04-26', '0654657238', 'Paris', '4 rue du Bac', '75014');


CREATE OR REPLACE FUNCTION insert_requiredskills() RETURNS void AS $$
DECLARE
    movie_name varchar(20);
    release_date Date;
    artist1 INT;
    skill1 INT;
    movie1 INT;
BEGIN
    movie_name := 'Lalalou';
    release_date := NOW();

    SELECT contact_id INTO artist1
        FROM Contacts AS c
        NATURAL JOIN AgencyContracts AS ac
        WHERE ac.contract_start < NOW() AND (ac.contract_end > NOW() OR ac.contract_end = NULL)
        ORDER BY random()
        LIMIT 1;

    SELECT min(skil_id) INTO skill1
        FROM Contacts AS c
        NATURAL JOIN KnownSkills AS ks
        WHERE c.contact_id = artist1;

    INSERT INTO Creations(creation_name, creation_type, release_date, profits, last_update_profits)
        VALUES(movie_name, 'movie', release_date, 0, NOW());

    SELECT creation_id INTO movie1
        FROM Creations as c
        WHERE c.creation_name = movie_name and c.release_date = release_date;
END;
$$ LANGUAGE plpgsql;


INSERT INTO KnownSkills() Values();

INSERT INTO Contacts(email, first_name, last_name, gender, birth_date, tel, city, address, postal_code)
    VALUES('lefouduweb@lol.fr', 'lyria', 'ashtour', 'Nb', '1997-04-26', '0691657238', 'Paris', '17 avenue de la Marne', '75018');

*/


