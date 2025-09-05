#!/bin/bash
set -e

echo "🚀 Démarrage MySQL directement sur port 3306 pour N8N..."

echo "📀 Configuration MySQL publique..."
echo "   • Database: $MYSQL_DATABASE"
echo "   • User: $MYSQL_USER"
echo "   • Port: 3306 (accessible depuis N8N)"
echo "   • Bind: 0.0.0.0 (toutes interfaces)"

# MySQL en mode public sur port 3306 - accessible depuis l'extérieur
exec docker-entrypoint.sh mysqld \
    --bind-address=0.0.0.0 \
    --port=3306 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci \
    --max-connections=200 \
    --default-authentication-plugin=mysql_native_password \
    --skip-ssl \
    --explicit_defaults_for_timestamp=1
