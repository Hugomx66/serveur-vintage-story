#!/bin/bash
set -euo pipefail

VS_DATA="${VS_DATA:-/data}"
VS_HOME="${VS_HOME:-/srv/vintagestory}"

mkdir -p "${VS_DATA}/Mods" "${VS_DATA}/Saves" "${VS_DATA}/ModConfig"

# ---------------------------------------------------------------------------
# Git backup setup: /data is (optionally) backed by a GitHub repo so that the
# world save survives container recreation and can be shared between players.
# ---------------------------------------------------------------------------
GIT_ENABLED=false

if [ -n "${GIT_REPO_URL:-}" ]; then
    GIT_ENABLED=true

    git config --global user.email "${GIT_USER_EMAIL:-vintagestory@server.local}"
    git config --global user.name "${GIT_USER_NAME:-VintageStoryServer}"
    git config --global --add safe.directory "${VS_DATA}"

    # Build an authenticated URL if a token is provided (PAT auth over HTTPS)
    PUSH_URL="${GIT_REPO_URL}"
    if [ -n "${GIT_TOKEN:-}" ]; then
        PUSH_URL=$(echo "${GIT_REPO_URL}" | sed -E "s#https://#https://${GIT_USER_NAME:-token}:${GIT_TOKEN}@#")
    fi

    cd "${VS_DATA}"

    if [ ! -d ".git" ]; then
        echo "[git] Initialisation du depot dans ${VS_DATA}"
        git init -b "${GIT_BRANCH:-main}"
        git remote add origin "${PUSH_URL}"

        if [ ! -f ".gitignore" ]; then
            cat > .gitignore <<'EOF'
# Les mods sont fournis manuellement par chaque hote, on ne les versionne pas
Mods/
Logs/
*.log
EOF
        fi

        # Tente de recuperer une sauvegarde existante sur le repo distant
        if git fetch origin "${GIT_BRANCH:-main}" 2>/dev/null; then
            echo "[git] Sauvegarde distante trouvee, recuperation..."
            git reset --mixed "origin/${GIT_BRANCH:-main}" || true
            git checkout -- . 2>/dev/null || true
        else
            echo "[git] Aucune sauvegarde distante existante, premier demarrage."
        fi
    else
        echo "[git] Depot existant detecte, recuperation des dernieres donnees..."
        git remote set-url origin "${PUSH_URL}" 2>/dev/null || git remote add origin "${PUSH_URL}"
        git fetch origin "${GIT_BRANCH:-main}" 2>/dev/null && git reset --mixed "origin/${GIT_BRANCH:-main}" || true
    fi
fi

git_save_and_push() {
    if [ "${GIT_ENABLED}" = true ]; then
        cd "${VS_DATA}"
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
mono VintagestoryServer.exe --dataPath "${VS_DATA}" "$@" &
SERVER_PID=$!

wait "${SERVER_PID}"
git_save_and_push
