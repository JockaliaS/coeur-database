#!/bin/bash
set -e

echo "🚀 Démarrage pour Render - Health Server PUIS MySQL..."

# Fonction health server simple
start_simple_health() {
    while true; do
        # Réponse par défaut pendant que MySQL démarre
        RESPONSE='{"status":"STARTING","message":"MySQL initializing"}'

        # Si MySQL répond, tester la base
        if mysqladmin ping -h localhost --silent 2>/dev/null; then
            if mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE $MYSQL_DATABASE; SELECT 1;" >/dev/null 2>&1; then
                RESPONSE='{"status":"OK","database":"'$MYSQL_DATABASE'","mysql":"UP"}'
                HTTP_CODE="200 OK"
            else
                RESPONSE='{"status":"ERROR","database":"access_failed"}'
                HTTP_CODE="503 Service Unavailable"
            fi
        else
            HTTP_CODE="503 Service Unavailable"
        fi

        # Serveur HTTP basique
        echo -e "HTTP/1.1 ${HTTP_CODE:-503 Service Unavailable}\r\nContent-Type: application/json\r\nContent-Length: ${#RESPONSE}\r\n\r\n$RESPONSE" | nc -l -p "$PORT" -q 1 2>/dev/null || sleep 1
    done
}

# CRITIQUE: Démarrer health server EN PREMIER pour que Render détecte le port
echo "🌐 Health server sur port $PORT..."
start_simple_health &
HEALTH_PID=$!

# Attendre un peu que le port soit ouvert
sleep 2

echo "📀 Démarrage MySQL..."
# MySQL en foreground (process principal)
exec docker-entrypoint.sh mysqld \
    --bind-address=0.0.0.0 \
    --port=3306 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci
