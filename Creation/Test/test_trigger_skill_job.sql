-- \i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Test/test_trigger_skill_job.sql'

-- Test : trigger is_skill_job on table Involvments
-- must fail : artist 2 has skill 23 but its not a skill of type job so it cannot be used in Involvments
INSERT INTO Involvments(contact_id, creation_id, skill_id) VALUES (2, 5519, 23);

-- must succeed ()
INSERT INTO Involvments(contact_id, creation_id, skill_id) VALUES (1, 5519, 9);
