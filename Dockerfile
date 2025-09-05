# Dockerfile - MySQL accessible comme service web
FROM mysql:8.0

# Installer netcat pour health check HTTP
RUN apt-get update && \
    apt-get install -y netcat-openbsd supervisor && \
    rm -rf /var/lib/apt/lists/*

# Copier les scripts et configuration
COPY init-scripts/ /docker-entrypoint-initdb.d/
COPY config/my.cnf /etc/mysql/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY health-server.sh /usr/local/bin/
COPY mysql-entrypoint.sh /usr/local/bin/

# Rendre les scripts exécutables
RUN chmod +x /usr/local/bin/health-server.sh /usr/local/bin/mysql-entrypoint.sh

# Créer dossiers avec bonnes permissions
RUN mkdir -p /var/log/mysql /var/lib/mysql-files /var/log/supervisor && \
    chown -R mysql:mysql /var/log/mysql /var/lib/mysql /var/lib/mysql-files

# Exposer les ports
EXPOSE 3306 10000

# Variables d'environnement
ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE:-coeur_db}
ENV MYSQL_USER=${MYSQL_USER:-coeur_user}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}
ENV PORT=${PORT:-10000}

# Point d'entrée avec supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
