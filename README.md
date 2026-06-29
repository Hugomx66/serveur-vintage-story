# Serveur Vintage Story 1.22.3 (Docker)

Ce projet est lui-meme un depot Git (remote `origin` -> GitHub). Le code du
serveur (Dockerfile, scripts...) et la sauvegarde du monde (`data/`) vivent
ensemble dans le meme repo et la meme branche : un simple `git clone` donne
le projet complet **et** la derniere progression de la partie.

## Mise en route

1. Copier `.env.example` en `.env` et renseigner `GIT_TOKEN` : un Personal
   Access Token GitHub (scope `repo`) ayant acces en ecriture a ce depot.

2. Construire et lancer le serveur :

   ```
   docker compose up -d --build
   ```

3. Ajouter tes mods (fichiers `.zip` / `.dll`) dans le dossier `data/Mods`
   une fois qu'il a ete cree par le premier demarrage. Ce dossier n'est
   **pas** versionne : chaque hote ajoute ses propres mods manuellement.

4. Pour arreter le serveur proprement (et declencher la sauvegarde + push
   automatique) :

   ```
   docker compose down
   ```

   ou `docker compose stop`.

## Fonctionnement de la sauvegarde Git

- Au demarrage, le conteneur fait un `git pull` du depot (monte dans
  `/repo`) pour recuperer la derniere progression poussee par un autre hote.
- A l'arret (`docker stop`, `docker compose down`...), le serveur s'eteint
  proprement puis tout le contenu modifie (`data/Saves`, configs, etc.) est
  commit et push sur la branche `GIT_BRANCH`.
- N'importe qui peut cloner ce repo, remplir son propre `.env` avec un token
  ayant acces au depot, mettre ses mods dans `data/Mods`, lancer
  `docker compose up` et recuperera automatiquement la derniere partie.

## Port

Le serveur ecoute par defaut sur le port UDP `42420`, expose tel quel dans
`docker-compose.yml`.
