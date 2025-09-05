# Dockerfile - MySQL avec Python3 intégré pour health server
FROM mysql:8.0

# Installer Python3 et outils réseau
RUN microdnf update && \
    microdnf install -y python3 nc procps-ng net-tools && \
    microdnf clean all

# Copier fichiers de configuration
COPY init-scripts/ /docker-entrypoint-initdb.d/
COPY config/my.cnf /etc/mysql/conf.d/
COPY mysql-start.sh /usr/local/bin/

# Permissions et dossiers
RUN chmod +x /usr/local/bin/mysql-start.sh && \
    mkdir -p /var/log/mysql /var/lib/mysql-files /tmp && \
    chown -R mysql:mysql /var/log/mysql /var/lib/mysql /var/lib/mysql-files

# Ports exposés
EXPOSE 3306 10000

# Variables d'environnement
ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE:-coeur_db}
ENV MYSQL_USER=${MYSQL_USER:-coeur_user}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}
ENV PORT=${PORT:-10000}

# Script de démarrage
CMD ["/usr/local/bin/mysql-start.sh"]
