#!/bin/bash
set -e

echo "🚀 Démarrage MySQL pour service web Render..."

# Initialiser MySQL si nécessaire
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "📀 Initialisation première fois..."
    docker-entrypoint.sh --initialize-insecure
fi

echo "🔧 Démarrage serveur MySQL..."
exec docker-entrypoint.sh mysqld \
    --bind-address=0.0.0.0 \
    --port=3306 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci \
    --max-connections=200
