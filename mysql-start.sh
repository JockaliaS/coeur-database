#!/bin/bash
set -e

echo "🚀 Démarrage MySQL + Health Server HTTP pour Render..."

# Créer serveur HTTP Python simple en arrière-plan
cat > /tmp/health-server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import subprocess
import json
import os
import threading
import time

class HealthHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            # Vérifier MySQL
            result = subprocess.run(['mysqladmin', 'ping', '-h', 'localhost', '--silent'], 
                                  capture_output=True, timeout=3)

            if result.returncode == 0:
                # MySQL répond, tester la base
                db_name = os.environ.get('MYSQL_DATABASE', 'coeur_db')
                root_pass = os.environ.get('MYSQL_ROOT_PASSWORD', '')

                if root_pass:
                    cmd = ['mysql', '-u', 'root', f'-p{root_pass}', '-e', f'USE {db_name}; SELECT 1;']
                    db_result = subprocess.run(cmd, capture_output=True, timeout=3)

                    if db_result.returncode == 0:
                        response = {"status": "OK", "database": db_name, "mysql": "UP"}
                        self.send_response(200)
                    else:
                        response = {"status": "ERROR", "database": "access_failed"}
                        self.send_response(503)
                else:
                    response = {"status": "STARTING", "mysql": "initializing"}
                    self.send_response(503)
            else:
                response = {"status": "STARTING", "mysql": "not_ready"}
                self.send_response(503)

        except Exception as e:
            response = {"status": "ERROR", "error": str(e)}
            self.send_response(503)

        # Envoyer réponse JSON
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

        response_json = json.dumps(response)
        self.wfile.write(response_json.encode())

    def log_message(self, format, *args):
        # Supprimer les logs HTTP verbeux
        pass

# Démarrer serveur HTTP
PORT = int(os.environ.get('PORT', 10000))
httpd = socketserver.TCPServer(("0.0.0.0", PORT), HealthHandler)
httpd.allow_reuse_address = True

print(f"🌐 Health server HTTP prêt sur 0.0.0.0:{PORT}")
httpd.serve_forever()
EOF

# Démarrer le serveur HTTP Python immédiatement
echo "🌐 Lancement serveur HTTP health check..."
python3 /tmp/health-server.py &
HEALTH_PID=$!

# Attendre que le serveur soit prêt
sleep 5

# Vérifier que le port est bien ouvert
if python3 -c "
import socket
try:
    s = socket.socket()
    s.settimeout(3)
    s.connect(('localhost', $PORT))
    s.close()
    print('✅ Port $PORT accessible')
    exit(0)
except:
    print('❌ Port $PORT non accessible')
    exit(1)
"; then
    echo "🎉 Health server opérationnel sur port $PORT"
else
    echo "⚠️  Health server en cours de démarrage..."
fi

echo "📀 Démarrage MySQL..."
echo "   • Database: $MYSQL_DATABASE"
echo "   • User: $MYSQL_USER"  
echo "   • Health: http://0.0.0.0:$PORT"

# Démarrer MySQL (processus principal)
exec docker-entrypoint.sh mysqld \
    --bind-address=0.0.0.0 \
    --port=3306 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci \
    --max-connections=200
