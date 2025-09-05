#!/bin/bash
set -e

echo "🚀 Démarrage pour Render - Health Server PUIS MySQL..."

# Fonction health server simple
start_simple_health() {
    echo "🌐 Health server écoute sur port $PORT..."

    while true; do
        # Réponse par défaut pendant que MySQL démarre
        RESPONSE='{"status":"STARTING","message":"MySQL initializing"}'
        HTTP_CODE="503 Service Unavailable"

        # Si MySQL répond, tester la base
        if mysqladmin ping -h localhost --silent 2>/dev/null; then
            if mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE $MYSQL_DATABASE; SELECT 1;" >/dev/null 2>&1; then
                RESPONSE='{"status":"OK","database":"'$MYSQL_DATABASE'","mysql":"UP"}'
                HTTP_CODE="200 OK"
            else
                RESPONSE='{"status":"ERROR","database":"access_failed"}'
                HTTP_CODE="503 Service Unavailable"
            fi
        fi

        # Serveur HTTP basique - IMPORTANT: écouter sur 0.0.0.0 pour Render
        echo -e "HTTP/1.1 $HTTP_CODE\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: ${#RESPONSE}\r\n\r\n$RESPONSE" | nc -l -s 0.0.0.0 -p "$PORT" -q 1 2>/dev/null || sleep 1
    done
}

# CRITIQUE: Démarrer health server EN PREMIER pour que Render détecte le port
echo "🌐 Démarrage health server sur 0.0.0.0:$PORT..."
start_simple_health &
HEALTH_PID=$!

# Attendre que le port soit ouvert
sleep 3

# Vérifier que le port est accessible
if netstat -tuln | grep -q ":$PORT "; then
    echo "✅ Port $PORT ouvert et accessible pour Render"
else
    echo "⚠️  Port $PORT en cours d'ouverture..."
fi

echo "📀 Démarrage MySQL..."
echo "   • Base: $MYSQL_DATABASE"
echo "   • User: $MYSQL_USER"
echo "   • Health Check: http://0.0.0.0:$PORT"

# MySQL en foreground (process principal)
exec docker-entrypoint.sh mysqld \
    --bind-address=0.0.0.0 \
    --port=3306 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci \
    --max-connections=200
