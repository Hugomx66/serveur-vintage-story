# Serveur Vintage Story 1.22.3 (Docker)

## Mise en route

1. Copier `.env.example` en `.env` et remplir :
   - `GIT_REPO_URL` : URL HTTPS d'un repo GitHub **vide** que tu as cree pour stocker la sauvegarde (ex: `https://github.com/ton-compte/vintagestory-save.git`).
   - `GIT_TOKEN` : un Personal Access Token GitHub avec le scope `repo` (Settings > Developer settings > Personal access tokens).

2. Construire et lancer le serveur :

   ```
   docker compose up -d --build
   ```

3. Ajouter tes mods (fichiers `.zip` / `.cs` / `.dll`) dans le dossier `data/Mods` une fois qu'il a ete cree par le premier demarrage.

4. Pour arreter le serveur proprement (et declencher la sauvegarde + push automatique) :

   ```
   docker compose down
   ```

   ou `docker compose stop`.

## Fonctionnement de la sauvegarde Git

- Au demarrage, le conteneur clone/recupere la derniere sauvegarde depuis `GIT_REPO_URL` dans `/data` (mappe sur `./data`).
- A l'arret (`docker stop`, `docker compose down`, ou redemarrage du conteneur), le serveur s'eteint proprement puis le contenu de `/data` (sauvegardes, configs) est commit et push sur la branche `GIT_BRANCH`.
- Le dossier `Mods/` n'est volontairement **pas** versionne (chaque hote ajoute ses propres mods manuellement).
- Tout autre joueur/hote qui clone ce projet, remplit le meme `.env` (memes `GIT_REPO_URL`/`GIT_TOKEN`, ou un token avec acces au repo), met ses mods dans `data/Mods` et lance `docker compose up`, recuperera automatiquement la derniere progression.

## Port

Le serveur ecoute par defaut sur le port UDP `42420`, expose tel quel dans `docker-compose.yml`.
