# 🗄️ Base de Données COEUR - MySQL sur Render

Base de données MySQL professionnelle accessible depuis N8N, hébergée sur Render.com.

## 🚀 Déploiement Automatique

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

## 📋 Configuration

### Structure Repository
```
coeur-database/
├── render.yaml                 # Configuration Render
├── Dockerfile                  # Image MySQL personnalisée  
├── mysql-start.sh              # Script de démarrage
├── health-server.sh            # Health check HTTP
├── config/my.cnf              # Configuration MySQL
└── init-scripts/01-init-coeur-db.sql  # Base + données
```

### Déploiement sur Render
1. **Render.com** → **New** → **Blueprint**
2. **Connectez** votre repository GitHub
3. **Apply** → Déploiement automatique

## 🔗 Connexion N8N

### Informations de Connexion
```javascript
{
  "host": "[VOTRE-SERVICE].onrender.com",
  "port": 3306,
  "database": "coeur_db",
  "user": "coeur_user",
  "password": "[GÉNÉRÉ_PAR_RENDER]"
}
```

### Variables depuis Render
- **URL Service** : Copiez depuis Dashboard Render
- **Password** : Environment → `MYSQL_PASSWORD`

## 📊 Base de Données

### Tables Principales
- **`utilisateurs`** - Clients avec tracking modifications
- **`conversations`** - Historique JSON multicanal (WhatsApp/Mail/Direct)
- **`commandes`** - Géolocalisation + dates livraison DOM-TOM
- **`temoignages`** - Distinction agent/client + médias
- **`problematiques`** - Segmentation par problème santé
- **`communications_externes`** - Traçabilité SAV

### Vues N8N Optimisées
```sql
-- Profil client complet avec durée utilisation
SELECT * FROM vue_client_avec_utilisation WHERE email = ?;

-- Témoignages pour conversion automatique
SELECT * FROM vue_temoignages_conversion WHERE note_satisfaction >= 4;

-- Analyse géographique DOM-TOM
SELECT * FROM vue_analyse_geographique ORDER BY ca_total DESC;
```

## 🎯 Exemples Requêtes N8N

### Segmentation Client
```sql
-- Clients prêts pour témoignage (2-4 semaines d'usage)
SELECT nom, prenom, email, jours_depuis_derniere_livraison
FROM vue_client_avec_utilisation 
WHERE jours_depuis_derniere_livraison BETWEEN 14 AND 30;
```

### Intelligence Géographique
```sql
-- Performance par zone avec détails livraison
SELECT pays_livraison, nb_clients_uniques, ca_total, panier_moyen
FROM vue_analyse_geographique;
```

### Conversion Témoignages
```sql
-- Meilleurs témoignages par produit pour prospects
SELECT contenu_temoignage, prenom_client, niveau_satisfaction
FROM vue_temoignages_conversion 
WHERE produit = ? AND note_satisfaction >= 4 
LIMIT 3;
```

## 🔧 Monitoring

### Health Check
Service disponible : `https://[VOTRE-SERVICE].onrender.com/health`

Retourne :
```json
{
  "status": "OK",
  "database": "coeur_db",
  "mysql": "UP"
}
```

### Logs Render
**Dashboard** → **Logs** pour surveiller :
- Démarrage MySQL
- Initialisation base
- Health server
- Requêtes N8N

## 💰 Coûts Render

- **Service Web** : ~$7/mois (starter)
- **Stockage** : 10GB inclus  
- **Trafic** : Illimité

## 🔐 Sécurité

- ✅ **Connexions chiffrées** disponibles
- ✅ **Mots de passe forts** générés automatiquement
- ✅ **Firewall Render** intégré
- ⚠️ **Service public** - Configurez des mots de passe robustes

## 🎉 Données de Test

La base est pré-remplie avec :
- **7 utilisateurs** de test avec profils variés
- **7 commandes** France + DOM-TOM avec dates réalistes
- **6 témoignages** agent + clients avec notes
- **3 conversations** JSON détaillées WhatsApp/Mail
- **7 problématiques** santé pour segmentation

## ⚡ Prêt pour Production

Votre base COEUR est immédiatement opérationnelle avec :
- **Architecture scalable** sur infrastructure Render
- **Vues pré-calculées** pour requêtes N8N rapides
- **Géolocalisation** France + DOM-TOM intégrée
- **Témoignages** structurés pour conversion automatique
- **Monitoring** et health checks intégrés

**Connectez votre agent N8N et automatisez !** 🚀
