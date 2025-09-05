#!/bin/bash
set -e

echo "🌐 Démarrage serveur health check sur port $PORT..."

while true; do
    # Attendre que MySQL soit prêt
    while ! mysqladmin ping -h localhost --silent 2>/dev/null; do
        sleep 2
    done

    # Serveur HTTP simple
    {
        echo "🔍 Health check MySQL..."

        if mysqladmin ping -h localhost --silent 2>/dev/null; then
            # Test connexion base
            mysql -u root -p$MYSQL_ROOT_PASSWORD -e "USE $MYSQL_DATABASE; SELECT 'OK' as status;" 2>/dev/null
            if [ $? -eq 0 ]; then
                HTTP_RESPONSE="HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: 45\r\n\r\n{"status":"OK", "database":"$MYSQL_DATABASE"}"
            else
                HTTP_RESPONSE="HTTP/1.1 503 Service Unavailable\r\nContent-Type: application/json\r\nContent-Length: 27\r\n\r\n{"error":"Database error"}"
            fi
        else
            HTTP_RESPONSE="HTTP/1.1 503 Service Unavailable\r\nContent-Type: application/json\r\nContent-Length: 25\r\n\r\n{"error":"MySQL down"}"
        fi

        echo -e "$HTTP_RESPONSE"
    } | nc -l -p "$PORT" -q 1 2>/dev/null || true

    sleep 1
done
