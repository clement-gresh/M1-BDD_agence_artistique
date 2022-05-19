-- \i 'C:/Users/Clem/01-coding-projects/08-sql-projects/projet-bdd-2021/Creation/Test/test_trigger_profits_null.sql'

-- Test : trigger profits_1_null on table Creations
-- must succeed : profits and last_update_profits are filled through a trigger and the INSERT works even thoug these fields are 
-- missing and cannot be NULL
INSERT INTO  Creations(creation_name, creation_type, release_date) VALUES('Cyranno', 'movie', '2016-12-04');
