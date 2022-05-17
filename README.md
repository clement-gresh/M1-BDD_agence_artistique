projet-bdd-2021
============

| Nom   | Prénom   | Groupe de TP | n etudiant |
|-------|----------|--------------|------------|
| GRESH | Clément  | Mercredi     | 22123274   |
| SU    | LiFang   | Jeudi        | 21957835   |


### Installation 
Pour lancer le projet, se placer dans le dossier /Creation puis utiliser les commandes suivantes :

- creer les tables :							        `\i create_all.sql`
- creer les triggers :							        `\i create_triggers.sql`
- creer les fonctions auxiliaires :				        `\i create_functions.sql`
- inserer les donnees dans les tables :			        `\i insert_data.sql`
- creer des triggers arpès l'insertion des données :	`\i create_triggers2.sql`



Pour plus de rapidite, utiliser la commande `\i launcher.sql` qui executera toutes ces actions dans l'ordre.

En cas de probleme de localisation des fichiers .csv lorsque ces commandes sont executees, il peut etre necessaire de changer le chemin y menant
dans /Creation/insert_data.sql (dans les commandes \COPY)

### Tests
Les tests sont disponibles dans le dossier /Creation/Test 