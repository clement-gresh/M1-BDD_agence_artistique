
-- Test : trigger is_skill_job on table Involvments
-- must fail (artist 2 has skill 23 but its not a skill of type job so it cannot be used in Involvments)
INSERT INTO Involvments(contact_id, creation_id, skill_id) VALUES (2, 5519, 23);

-- must succeed ()
INSERT INTO Involvments(contact_id, creation_id, skill_id) VALUES (1, 5519, 9);


-- Test : trigger has_skill on table Involvments
-- must fail (skill 4 is of type job but artist 476 does not have it so it cannot be used in Involvments)
INSERT INTO Involvments(contact_id, creation_id, skill_id) VALUES (476, 5519, 4);
-- must succeed (artist 476 has skill 13)
INSERT INTO Involvments(contact_id, creation_id, skill_id) VALUES (476, 5519, 13);


-- Test : trigger is_musician on table KnownSkills
-- must fail (skill 16 is an instrument but artist 1113 is not a a musician so the skill cannot be put in KnownSkills)
INSERT INTO KnownSkills(contact_id, skill_id) VALUES (1113, 16);
-- must succeed (artist 320 is a musician)
INSERT INTO KnownSkills(contact_id, skill_id) VALUES (320, 16);