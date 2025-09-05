#!/bin/bash
set -e

echo "🌐 Health server démarré sur port $PORT"

while true; do
    # Vérifier état MySQL
    if mysqladmin ping -h localhost --silent 2>/dev/null; then
        # Tester accès à la base
        if mysql -u root -p$MYSQL_ROOT_PASSWORD -e "USE $MYSQL_DATABASE; SELECT 1 as test;" >/dev/null 2>&1; then
            STATUS='{"status":"OK","database":"'$MYSQL_DATABASE'","mysql":"UP"}'
            HTTP_CODE="200 OK"
        else
            STATUS='{"status":"ERROR","error":"Database access failed"}'
            HTTP_CODE="503 Service Unavailable"
        fi
    else
        STATUS='{"status":"ERROR","error":"MySQL not responding"}'
        HTTP_CODE="503 Service Unavailable"
    fi

    # Répondre aux requêtes HTTP
    RESPONSE="HTTP/1.1 $HTTP_CODE\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: ${#STATUS}\r\n\r\n$STATUS"

    echo -e "$RESPONSE" | nc -l -p "$PORT" -q 1 2>/dev/null || {
        # En cas d'erreur nc, attendre un peu
        sleep 3
        continue
    }

    # Petit délai entre les requêtes
    sleep 1
done
