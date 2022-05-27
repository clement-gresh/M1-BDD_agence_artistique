--\i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Test/test_trigger_profits_payment.sql'


-- SELECT query used to find which creations artists worked on
CREATE OR REPLACE FUNCTION payment_received() RETURNS INT AS $$
DECLARE
    pid INT;
    cid INT;
    nb INT;
BEGIN
    SELECT DISTINCT ON (pc.proposal_id)
        creat.creation_id, pc.proposal_id INTO cid, pid
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
        --WHERE cont.contact_id = 264
        --    AND creat.creation_id = 8052
        --    AND pr.payment_status = 'avenant'::payments_status_type
        ORDER BY pc.proposal_id DESC, pc.signed_date DESC
        LIMIT 1;

        SELECT count(*) INTO nb
            FROM PaymentRecords
            WHERE proposal_id = pid;

        RAISE NOTICE 'Number of payments related to this proposal : %', nb;
        RAISE NOTICE 'Modification of the profits';
        UPDATE Creations SET profits = 1000 WHERE creation_id = cid;

        SELECT count(*) INTO nb
            FROM PaymentRecords
            WHERE proposal_id = pid;
        
        RAISE NOTICE 'Number of payments related to this proposal : %', nb;

        RETURN cid;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM payment_received();