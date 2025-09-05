#!/bin/bash
set -e

echo "🚀 Démarrage MySQL + Health Server pour Render..."

# Gestion des signaux d'arrêt
cleanup() {
    echo "🛑 Arrêt propre des services..."
    if [ -n "$MYSQL_PID" ]; then
        kill $MYSQL_PID 2>/dev/null || true
    fi
    if [ -n "$HEALTH_PID" ]; then
        kill $HEALTH_PID 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT

# Démarrer MySQL en arrière-plan
echo "📀 Initialisation MySQL..."
docker-entrypoint.sh mysqld \
    --bind-address=0.0.0.0 \
    --port=3306 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci \
    --max-connections=200 &

MYSQL_PID=$!

# Attendre que MySQL soit opérationnel
echo "⏳ Attente démarrage MySQL..."
for i in {1..60}; do
    if mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo "✅ MySQL prêt sur port 3306 !"
        break
    fi
    echo "   Tentative $i/60..."
    sleep 2
done

# Vérification finale
if ! mysqladmin ping -h localhost --silent 2>/dev/null; then
    echo "❌ ERREUR: MySQL n'a pas pu démarrer dans les temps"
    exit 1
fi

# Démarrer health server
echo "🌐 Démarrage health check sur port $PORT..."
/usr/local/bin/health-server.sh &
HEALTH_PID=$!

echo "🎉 Services opérationnels !"
echo "   • MySQL: localhost:3306"
echo "   • Health Check: localhost:$PORT"
echo "   • Base: $MYSQL_DATABASE"
echo "   • User: $MYSQL_USER"

# Maintenir le processus principal actif
wait $MYSQL_PID
