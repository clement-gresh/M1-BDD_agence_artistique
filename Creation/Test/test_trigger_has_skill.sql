-- \i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Test/test_trigger_has_skill.sql'

-- Test : trigger has_skill on table Involvments
-- must fail : skill 4 is of type job but artist 476 does not have it so it cannot be used in Involvments
INSERT INTO Involvments(contact_id, creation_id, skill_id) VALUES (476, 5519, 4);

-- must succeed : artist 476 has skill 13
INSERT INTO Involvments(contact_id, creation_id, skill_id) VALUES (476, 5519, 13);
