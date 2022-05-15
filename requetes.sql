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
