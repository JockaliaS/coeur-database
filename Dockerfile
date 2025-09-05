# Dockerfile - MySQL simple avec nc seulement
FROM mysql:8.0

# Installer nc et outils réseau
RUN microdnf update && \
    microdnf install -y nc procps-ng net-tools && \
    microdnf clean all

# Copier fichiers
COPY init-scripts/ /docker-entrypoint-initdb.d/
COPY config/my.cnf /etc/mysql/conf.d/
COPY mysql-start-simple.sh /usr/local/bin/

# Permissions
RUN chmod +x /usr/local/bin/mysql-start-simple.sh && \
    mkdir -p /var/log/mysql /var/lib/mysql-files && \
    chown -R mysql:mysql /var/log/mysql /var/lib/mysql /var/lib/mysql-files

# Ports
EXPOSE 3306 10000

# Variables
ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE:-coeur_db}
ENV MYSQL_USER=${MYSQL_USER:-coeur_user}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}
ENV PORT=${PORT:-10000}

# Démarrage
CMD ["/usr/local/bin/mysql-start-simple.sh"]
