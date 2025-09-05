#!/bin/bash
# Script de vérification des fichiers nécessaires

echo "🔍 Vérification des fichiers pour Render..."

# Fichiers obligatoires
REQUIRED_FILES=(
    "render.yaml"
    "Dockerfile" 
    "mysql-start.sh"
    "config/my.cnf"
    "init-scripts/01-init-coeur-db.sql"
)

MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file MANQUANT"
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo ""
    echo "🎉 Tous les fichiers requis sont présents !"
    echo "🚀 Prêt pour déploiement Render"
else
    echo ""
    echo "⚠️  Fichiers manquants: ${MISSING_FILES[*]}"
    echo "📋 Uploadez ces fichiers avant de déployer"
fi

# Vérifier permissions
if [ -f "mysql-start.sh" ]; then
    if [ -x "mysql-start.sh" ]; then
        echo "✅ mysql-start.sh est exécutable"
    else
        echo "⚠️  mysql-start.sh n'est pas exécutable (sera corrigé par Dockerfile)"
    fi
fi
