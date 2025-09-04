# 🗄️ Base de Données COEUR pour N8N sur Render

Base de données MySQL spécialement conçue pour alimenter un agent N8N hébergé sur Render.com.

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

## 🚀 Déploiement Express

### Prérequis
- Compte [Render.com](https://render.com) (gratuit)
- N8N déjà déployé sur Render
- Ce repository sur votre GitHub

### Étapes de Déploiement

1. **Modifiez render.yaml**
   ```yaml
   # Ligne 6 du fichier render.yaml
   repo: https://github.com/VOTRE-USERNAME/coeur-database.git
   ```

2. **Déployez sur Render**
   - Render Dashboard → **New +** → **Blueprint**
   - Sélectionnez ce repository
   - **Apply** ✅

3. **Récupérez les infos de connexion**
   - Service **"coeur-mysql-db"** → **Environment**
   - Notez : `MYSQL_PASSWORD` et autres variables

4. **Configurez N8N**
   ```javascript
   // Dans votre N8N sur Render
   {
     "host": "coeur-mysql-db",  // Host interne Render (gratuit)
     "port": 3306,
     "database": "coeur_db",
     "user": "coeur_user",
     "password": "[VOTRE_MOT_DE_PASSE_GÉNÉRÉ]"
   }
   ```

## 📊 Structure Base de Données

### Tables Intelligentes
- **`utilisateurs`** - Clients avec tracking modifications automatique
- **`conversations`** - Historique JSON multicanal (WhatsApp/Mail/Direct)
- **`commandes`** - Avec dates livraison et géolocalisation DOM-TOM
- **`temoignages`** - Distinction agent/client + médias URL/BLOB
- **`problematiques`** - Problèmes santé/bien-être clients
- **`communications_externes`** - Traçabilité SAV et partenaires

### Vues Optimisées N8N
```sql
-- Vue client complète avec durée d'utilisation produits
SELECT * FROM vue_client_avec_utilisation WHERE email = ?;

-- Témoignages pour conversion automatique
SELECT * FROM vue_temoignages_conversion WHERE produit = ? AND note_satisfaction >= 4;
```

## 🤖 Exemples Requêtes N8N

### Segmentation Client Automatique
```sql
-- Clients prêts pour témoignage (2-4 semaines d'usage)
SELECT nom, prenom, email, nom_produit, jours_depuis_derniere_livraison
FROM vue_client_avec_utilisation 
WHERE jours_depuis_derniere_livraison BETWEEN 14 AND 30;
```

### Conversion avec Témoignages
```sql
-- Meilleurs témoignages pour un produit
SELECT contenu_temoignage, url_media, prenom_client 
FROM vue_temoignages_conversion 
WHERE produit = 'eau_hexagonale' 
ORDER BY note_satisfaction DESC LIMIT 3;
```

### Géolocalisation DOM-TOM
```sql
-- Clients par zone géographique
SELECT pays_livraison, COUNT(*) as nb_clients
FROM commandes 
GROUP BY pays_livraison 
ORDER BY nb_clients DESC;
```

## 🔗 Connexion N8N Optimisée

### Variables d'Environnement N8N
Si votre N8N est sur Render, ajoutez ces variables :

```yaml
# Dans votre render.yaml N8N
envVars:
  - key: DB_TYPE
    value: mysql
  - key: DB_MYSQL_HOST
    value: coeur-mysql-db  # Host interne gratuit
  - key: DB_MYSQL_DATABASE
    value: coeur_db
  - key: DB_MYSQL_USER
    value: coeur_user
  - key: DB_MYSQL_PASSWORD
    fromService:
      type: pserv
      name: coeur-mysql-db
      envVarKey: MYSQL_PASSWORD
```

### Node MySQL dans N8N
```javascript
// Configuration du node MySQL
{
  "operation": "executeQuery",
  "query": "SELECT * FROM vue_client_avec_utilisation WHERE email = ?",
  "parameters": ["{{$json.email}}"]
}
```

## 💰 Coûts Render

### Gratuit Inclus
- ✅ **MySQL Service** : Plan starter gratuit
- ✅ **10GB Stockage** : SSD haute performance
- ✅ **Réseau interne** : Communication gratuite avec N8N
- ✅ **Sauvegardes** : Quotidiennes automatiques

### Production (Recommandé)
- **Base MySQL** : ~7$/mois (plan basique)
- **Performance** : Nettement améliorée
- **Pas de limitations** : Connexions illimitées

## 🔐 Sécurité Render

### Automatique
- ✅ **Réseau privé** - MySQL non exposé publiquement
- ✅ **Mots de passe forts** - Générés par Render
- ✅ **Chiffrement TLS** - Entre tous les services
- ✅ **Sauvegardes chiffrées** - Au repos et en transit

### Monitoring Temps Réel
- 📊 **Dashboard Render** - Métriques en direct
- 🚨 **Alertes automatiques** - En cas de problème
- 📋 **Logs centralisés** - Debug facilité

## 🎯 Avantages vs Local

| Aspect | Docker Local | **Render** |
|--------|-------------|------------|
| **Setup** | Configuration manuelle | **3 clics** |
| **Disponibilité** | Dépend de votre machine | **24/7 garanti** |
| **Connexion N8N** | IP publique nécessaire | **Host interne gratuit** |
| **Sauvegardes** | Manuel | **Automatiques** |
| **Scaling** | Impossible | **Automatique** |
| **Maintenance** | Vous | **Render** |

## 📈 Cas d'Usage N8N

### Workflow Automatique Témoignages
1. **Trigger** : Client livré depuis 2 semaines
2. **Action** : Envoi email demande témoignage
3. **Condition** : Si témoignage reçu → Marquer comme validé
4. **Action** : Utiliser pour conversion prospects

### Segmentation Géographique
1. **Trigger** : Nouvelle commande
2. **Condition** : Si DOM-TOM → Délai livraison +3 jours
3. **Action** : Email suivi personnalisé par zone

### Intelligence Client
1. **Trigger** : Contact client
2. **Query** : Récupérer historique complet via vue
3. **Condition** : Adapter réponse selon durée d'utilisation
4. **Action** : Proposer produits complémentaires

## 🚀 Prêt pour l'Action !

Votre base de données CŒUR est maintenant **parfaitement intégrée** avec N8N sur Render :

- 🤖 **Agent intelligent** alimenté par données structurées
- ⚡ **Performance optimale** via réseau interne Render
- 📊 **Analytics en temps réel** pour décisions automatiques
- 🎯 **Conversion optimisée** via témoignages et segmentation

**Connectez votre agent N8N et automatisez votre business !** 🚀

## 💬 Support

- 📧 **Issues GitHub** pour bugs/améliorations
- 📖 **Documentation Render** : [render.com/docs](https://render.com/docs)
- 🤖 **Communauté N8N** : [community.n8n.io](https://community.n8n.io)
