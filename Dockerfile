# Dockerfile - MySQL optimisé pour Render
FROM mysql:8.0

# Labels
LABEL maintainer="votre-email@example.com"
LABEL description="Base de données COEUR pour N8N sur Render"

# Copier les scripts d'initialisation
COPY init-scripts/ /docker-entrypoint-initdb.d/

# Copier la configuration MySQL
COPY config/my.cnf /etc/mysql/conf.d/

# Créer les dossiers nécessaires avec bonnes permissions
RUN mkdir -p /var/log/mysql /var/lib/mysql-files \
    && chown -R mysql:mysql /var/log/mysql /var/lib/mysql /var/lib/mysql-files

# Exposer le port MySQL
EXPOSE 3306

# Variables d'environnement (surchargées par Render)
ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE:-coeur_db}
ENV MYSQL_USER=${MYSQL_USER:-coeur_user}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}

# Point d'entrée MySQL avec configuration optimisée
CMD ["mysqld", \
     "--character-set-server=utf8mb4", \
     "--collation-server=utf8mb4_unicode_ci", \
     "--max_connections=200", \
     "--innodb_buffer_pool_size=256M"]
