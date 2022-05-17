SELECT r.creation_id, r.request_id, s.skill_name
FROM requests r NATURAL JOIN RequiredSkills rs NATURAL JOIN skills s
LIMIT 5; 

--verify request
select creation_name,r.creation_id,r.request_id, skill_name ,skill_type
from creations c  , requests r , RequiredSkills rs , skills s
where c.creation_id = r.creation_id
and r.request_id = rs.request_id
and rs.skill_id = s.skill_id
order by creation_id; 

--TESTS
--trigger de table Contacts
INSERT INTO Agencycontracts VALUES ( 1, now()+ INTERVAL '1 day',now()+ INTERVAL '4 day' ,21.5); --ok
INSERT INTO Agencycontracts VALUES ( 1, now()+ INTERVAL '3 day',now()+ INTERVAL '6 day' ,21.5); --fail
INSERT INTO Agencycontracts VALUES ( 1, now()+ INTERVAL '5 day',now()+ INTERVAL '8 day' ,21.5); --ok

--trigger de table Requests 
--INSERT INTO Requests(contact_id, creation_id, request_status, budget,request_start, request_end)
INSERT INTO Requests(contact_id, creation_id, request_status, budget,request_start, request_end) VALUES (1, 108, 'open', 5000, NOW() - INTERVAL '6000 days', NULL); --ok
INSERT INTO Requests(contact_id, creation_id, request_status, budget,request_start, request_end) VALUES (2, 108, 'cancelled', 1000, NOW() - INTERVAL '6000 days', NOW() - INTERVAL'4000 day'); --ok
INSERT INTO Requests(contact_id, creation_id, request_status, budget,request_start, request_end) VALUES (3, 108, 'closed', 2000, NOW() + INTERVAL '1 days', NULL); --fail
--NOTICE:  Rejected line because the date of request ("18.05.2022", "<NULL>") T4.

--trigger de table RequiredSkills



--trigger de table Proposals
--trigger de table ProducerContracts
--trigger de table PaymentRecords