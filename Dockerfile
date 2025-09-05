# Dockerfile - MySQL 8.0 pour service web Render
FROM mysql:8.0

# Installer packages avec microdnf (Oracle Linux dans mysql:8.0)
RUN microdnf update && \
    microdnf install -y nc procps-ng && \
    microdnf clean all

# Copier les scripts et configuration
COPY init-scripts/ /docker-entrypoint-initdb.d/
COPY config/my.cnf /etc/mysql/conf.d/
COPY health-server.sh /usr/local/bin/
COPY mysql-start.sh /usr/local/bin/

# Rendre les scripts exécutables
RUN chmod +x /usr/local/bin/health-server.sh /usr/local/bin/mysql-start.sh

# Créer dossiers avec permissions correctes
RUN mkdir -p /var/log/mysql /var/lib/mysql-files && \
    chown -R mysql:mysql /var/log/mysql /var/lib/mysql /var/lib/mysql-files

# Exposer ports MySQL et Health Check
EXPOSE 3306 10000

# Variables d'environnement
ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE:-coeur_db}
ENV MYSQL_USER=${MYSQL_USER:-coeur_user}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}
ENV PORT=${PORT:-10000}

# Script de démarrage
CMD ["/usr/local/bin/mysql-start.sh"]
