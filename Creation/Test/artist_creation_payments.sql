-- <>
--\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Test/test_trigger_profits_payment.sql'
/*
DROP TYPE payment_list CASCADE;
CREATE TABLE payment_list (contact_id INT, first_name VARCHAR(50), last_name VARCHAR(50), creation_id INT,
    creation_name VARCHAR(100), proposal_id INT, contract_start DATE, amount NUMERIC(12,2), status payments_status_type);

CREATE OR REPLACE FUNCTION payment_received(artist INT, creation INT) RETURNS payment_list AS $$
BEGIN
    SELECT cont.contact_id, cont.first_name, cont.last_name, creat.creation_id, creat.creation_name,
        pc.proposal_id, pc.contract_start, pr.amount, pr.payment_status INTO tableau
    FROM Contacts AS cont
    JOIN Involvments AS inv
        ON cont.contact_id = inv.contact_id
    JOIN Creations as creat
        ON inv.creation_id = creat.creation_id
    JOIN Requests AS req
        ON req.creation_id = creat.creation_id
    JOIN Proposals AS prop
        ON req.request_id = prop.request_id
    JOIN ProducerContracts AS pc
        ON pc.proposal_id = prop.proposal_id
    JOIN PaymentRecords AS pr
        ON (pr.proposal_id = pc.proposal_id AND pr.signed_date = pc.signed_date)
    WHERE cont.contact_id = artist
        AND creat.creation_id = creation
        AND pr.payment_status = 'avenant'::payments_status_type
    LIMIT 100;
    RETURN tableau;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM payment_received(2548, 1355);
*/

SELECT cont.contact_id, cont.first_name, cont.last_name, creat.creation_id, creat.creation_name,
        pc.proposal_id, pc.contract_start, pr.amount, pr.payment_status
    FROM Contacts AS cont
    JOIN Involvments AS inv
        ON cont.contact_id = inv.contact_id
    JOIN Creations as creat
        ON inv.creation_id = creat.creation_id
    JOIN Requests AS req
        ON req.creation_id = creat.creation_id
    JOIN Proposals AS prop
        ON req.request_id = prop.request_id
    JOIN ProducerContracts AS pc
        ON pc.proposal_id = prop.proposal_id
    JOIN PaymentRecords AS pr
        ON (pr.proposal_id = pc.proposal_id AND pr.signed_date = pc.signed_date)
    WHERE cont.contact_id = 2548
        AND creat.creation_id = 1355
        AND pr.payment_status = 'avenant'::payments_status_type
    LIMIT 100;

