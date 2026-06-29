#!/bin/bash
set -euo pipefail

VS_HOME="${VS_HOME:-/srv/vintagestory}"
REPO_DIR="${REPO_DIR:-/repo}"
VS_DATA="${VS_DATA:-${REPO_DIR}/data}"

mkdir -p "${VS_DATA}/Mods" "${VS_DATA}/Saves" "${VS_DATA}/ModConfig"

# ---------------------------------------------------------------------------
# Le depot git du projet (code + save) est monte dans /repo. On synchronise
# avec GitHub au demarrage (recuperer la derniere save) et a l'arret
# (sauvegarder la progression), pour que tout le monde partage le meme etat.
# ---------------------------------------------------------------------------
GIT_ENABLED=false

if [ -d "${REPO_DIR}/.git" ]; then
    GIT_ENABLED=true
    cd "${REPO_DIR}"

    git config --global --add safe.directory "${REPO_DIR}"
    git config user.email "${GIT_USER_EMAIL:-vintagestory@server.local}"
    git config user.name "${GIT_USER_NAME:-VintageStoryServer}"

    if [ -n "${GIT_TOKEN:-}" ]; then
        ORIGIN_URL=$(git remote get-url origin)
        PUSH_URL=$(echo "${ORIGIN_URL}" | sed -E "s#https://#https://${GIT_USER_NAME:-token}:${GIT_TOKEN}@#")
        git remote set-url origin "${PUSH_URL}"
    fi

    BRANCH="${GIT_BRANCH:-main}"
    echo "[git] Recuperation de la derniere progression depuis origin/${BRANCH}..."
    if git fetch origin "${BRANCH}" 2>/dev/null; then
        git merge --no-edit "origin/${BRANCH}" || echo "[git] Conflit de fusion, la progression locale est conservee telle quelle."
    else
        echo "[git] Impossible de recuperer origin/${BRANCH} (premier demarrage ou hors-ligne)."
    fi
else
    echo "[git] Aucun depot git monte dans ${REPO_DIR}, la sauvegarde automatique est desactivee."
fi

git_save_and_push() {
    if [ "${GIT_ENABLED}" = true ]; then
        cd "${REPO_DIR}"
        echo "[git] Sauvegarde de la progression..."
        git add -A
        if ! git diff --cached --quiet; then
            git commit -m "Sauvegarde automatique du serveur - $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
            git push origin "HEAD:${GIT_BRANCH:-main}" || echo "[git] Echec du push, la sauvegarde reste en local."
        else
            echo "[git] Rien de nouveau a sauvegarder."
        fi
    fi
}

# ---------------------------------------------------------------------------
# Lancement du serveur Vintage Story
# ---------------------------------------------------------------------------
SERVER_PID=""

terminate() {
    echo "[server] Signal d'arret recu, extinction propre du serveur..."
    if [ -n "${SERVER_PID}" ] && kill -0 "${SERVER_PID}" 2>/dev/null; then
        kill -TERM "${SERVER_PID}" 2>/dev/null || true
        wait "${SERVER_PID}" || true
    fi
    git_save_and_push
    exit 0
}

trap terminate SIGTERM SIGINT

cd "${VS_HOME}"
dotnet VintagestoryServer.dll --dataPath "${VS_DATA}" "$@" &
SERVER_PID=$!

wait "${SERVER_PID}"
git_save_and_push
