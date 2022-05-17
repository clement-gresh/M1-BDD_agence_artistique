
-- Test : trigger is_musician on table KnownSkills
-- must fail : skill 16 is an instrument but artist 1113 is not a a musician so the skill cannot be put in KnownSkills
INSERT INTO KnownSkills(contact_id, skill_id) VALUES (1113, 16);

-- must succeed : artist 320 is a musician
INSERT INTO KnownSkills(contact_id, skill_id) VALUES (320, 16);

