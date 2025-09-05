# 🗄️ Base de Données COEUR - Service Web Render

Base de données MySQL accessible depuis N8N externe via service web Render.

## 🚀 Déploiement sur Render

### 1. Configuration Repository
Ce repository est configuré pour déployer MySQL comme **service web** accessible depuis l'extérieur.

### 2. Architecture
```
[N8N Externe] → [MySQL Service Web sur Render] → [Base COEUR]
               HTTPS/MySQL 3306              Données persistantes
```

### 3. Déploiement
1. **Fork ce repository** sur votre GitHub
2. **Render.com** → **New** → **Blueprint**
3. **Connectez votre repository**
4. **Apply** - Le déploiement commence

## 🔗 Connexion N8N

### Informations de Connexion
Une fois déployé, votre service aura une URL publique Render :

```javascript
// Configuration N8N MySQL
{
  "host": "[VOTRE-SERVICE].onrender.com",
  "port": 3306,
  "database": "coeur_db",
  "user": "coeur_user",
  "password": "[MOT_DE_PASSE_GÉNÉRÉ]",
  "ssl": false
}
```

### Récupérer les Informations
1. **Render Dashboard** → Votre service MySQL
2. **URL** : Copiez l'URL publique (sans https://)
3. **Environment** → Variables `MYSQL_PASSWORD`, `MYSQL_USER`

## 📊 Tables Disponibles

- **`utilisateurs`** - Clients avec tracking modifications
- **`conversations`** - Historique JSON multicanal  
- **`commandes`** - Avec géolocalisation DOM-TOM + dates livraison
- **`temoignages`** - Agent/client + médias URL/BLOB
- **`problematiques`** - Segmentation par problème santé
- **`communications_externes`** - Traçabilité SAV

## 🎯 Vues N8N Optimisées

```sql
-- Vue client complète avec durée d'utilisation
SELECT * FROM vue_client_avec_utilisation WHERE email = ?;

-- Témoignages pour conversion automatique  
SELECT * FROM vue_temoignages_conversion WHERE produit = ? LIMIT 3;
```

## 📈 Exemples Requêtes N8N

### Segmentation Client
```sql
-- Clients prêts pour témoignage (2-4 semaines d'usage)
SELECT nom, prenom, email, jours_depuis_derniere_livraison
FROM vue_client_avec_utilisation 
WHERE jours_depuis_derniere_livraison BETWEEN 14 AND 30;
```

### Analyse Géographique
```sql  
-- Performance par zone DOM-TOM
SELECT pays_livraison, COUNT(*) as nb_clients, AVG(prix_total) as panier_moyen
FROM commandes 
GROUP BY pays_livraison;
```

## 🔧 Monitoring

### Health Check
Service accessible sur : `https://[VOTRE-SERVICE].onrender.com/health`

Retourne :
```json
{"status": "OK", "database": "coeur_db"}
```

### Logs
**Render Dashboard** → **Logs** pour surveiller MySQL et health server.

## 💰 Coûts

- **Service Web** : ~$7/mois (plan basic)
- **Stockage** : 10GB inclus
- **Trafic** : Illimité

## 🔐 Sécurité

- ✅ **Connexions SSL** optionnelles
- ✅ **Mots de passe générés** automatiquement
- ⚠️ **Service public** - Utilisez des mots de passe forts
- ✅ **Firewall Render** - Protection DDoS incluse

## 🎯 Prêt pour N8N !

Votre base de données CŒUR est maintenant accessible depuis n'importe quel N8N externe avec une configuration simple et performante.

**Temps de déploiement : 5-10 minutes** ⚡
