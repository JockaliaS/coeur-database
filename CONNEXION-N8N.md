# 🔗 Guide de Connexion N8N ↔ Base COEUR

## Configuration N8N sur Render

### 1. Variables d'Environnement N8N

Dans votre service N8N sur Render, ajoutez ces variables :

```yaml
envVars:
  - key: DB_TYPE
    value: mysql
  - key: DB_MYSQL_HOST
    value: coeur-mysql-db  # Nom du service MySQL
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

### 2. Node MySQL dans N8N

Configuration du node "MySQL" :
```javascript
{
  "host": "coeur-mysql-db",
  "port": 3306,
  "database": "coeur_db",
  "user": "coeur_user",
  "password": "={{$env.DB_MYSQL_PASSWORD}}"
}
```

## Requêtes Types pour N8N

### Récupérer Profil Client Complet
```sql
SELECT * FROM vue_client_avec_utilisation 
WHERE email = '{{$json.email}}';
```

### Clients Prêts pour Témoignage
```sql
SELECT nom, prenom, email, telephone, nom_produit
FROM vue_client_avec_utilisation 
WHERE jours_depuis_derniere_livraison BETWEEN 14 AND 30
AND nb_temoignages = 0;
```

### Témoignages pour Conversion
```sql
SELECT contenu_temoignage, url_media, note_satisfaction
FROM vue_temoignages_conversion 
WHERE produit = '{{$json.produit_interesse}}'
AND note_satisfaction >= 4
LIMIT 3;
```

### Historique Conversations Client
```sql
SELECT type_conversation, date_conversation, messages_json, resume_conversation
FROM conversations 
WHERE utilisateur_id = (
  SELECT id FROM utilisateurs WHERE email = '{{$json.email}}'
)
ORDER BY date_conversation DESC
LIMIT 5;
```

## Workflows N8N Recommandés

### 1. Suivi Post-Livraison Automatique

**Trigger** : Webhook quotidien
```sql
-- Clients livrés il y a exactement 7 jours
SELECT u.nom, u.prenom, u.email, c.nom_produit
FROM utilisateurs u
JOIN commandes c ON u.id = c.utilisateur_id
WHERE c.date_livraison_reelle = DATE_SUB(CURDATE(), INTERVAL 7 DAY);
```

**Action** : Email de suivi personnalisé

### 2. Détection Clients Insatisfaits

**Trigger** : Webhook sur nouvelle conversation
```sql
-- Détecter mots-clés négatifs dans conversations récentes
SELECT u.email, c.messages_json, c.resume_conversation
FROM conversations c
JOIN utilisateurs u ON c.utilisateur_id = u.id
WHERE c.date_conversation >= CURDATE()
AND (c.resume_conversation LIKE '%problème%' 
     OR c.resume_conversation LIKE '%insatisfait%'
     OR c.resume_conversation LIKE '%remboursement%');
```

**Action** : Alerte équipe + workflow récupération

### 3. Conversion Intelligente

**Trigger** : Nouveau prospect
```sql
-- Récupérer témoignages pertinents selon problématique
SELECT t.contenu_temoignage, t.url_media, u.prenom
FROM temoignages t
JOIN utilisateurs u ON t.utilisateur_id = u.id
JOIN problematiques p ON u.id = p.utilisateur_id
WHERE p.type_problematique = '{{$json.problematique_prospect}}'
AND t.valide = TRUE
AND t.note_satisfaction >= 4
ORDER BY t.note_satisfaction DESC
LIMIT 2;
```

**Action** : Email avec témoignages ciblés

## Debug & Monitoring

### Test de Connexion
```sql
SELECT 'Connexion OK' as status, COUNT(*) as nb_users FROM utilisateurs;
```

### Performance Monitoring
```sql
SELECT 
  COUNT(DISTINCT u.id) as total_clients,
  COUNT(DISTINCT c.id) as total_conversations_today,
  COUNT(DISTINCT cmd.id) as total_commandes
FROM utilisateurs u
LEFT JOIN conversations c ON u.id = c.utilisateur_id AND c.date_conversation = CURDATE()
LEFT JOIN commandes cmd ON u.id = cmd.utilisateur_id AND cmd.date_commande = CURDATE();
```

### Santé Base de Données
```sql
SHOW PROCESSLIST;
SHOW VARIABLES LIKE 'max_connections';
SELECT COUNT(*) as connexions_actives FROM INFORMATION_SCHEMA.PROCESSLIST;
```

## Bonnes Pratiques

1. **Utilisez les vues** plutôt que les joins complexes
2. **Limitez les résultats** avec LIMIT pour performance
3. **Indexez vos requêtes** selon vos patterns d'usage
4. **Gérez les erreurs** avec try-catch dans N8N
5. **Loggez les opérations** critiques pour debug

## Exemple Workflow Complet

```json
{
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "client-delivered"
      }
    },
    {
      "name": "Get Client Info",
      "type": "n8n-nodes-base.mysql",
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT * FROM vue_client_avec_utilisation WHERE email = ?",
        "parameters": ["{{$json.email}}"]
      }
    },
    {
      "name": "Check Usage Duration",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "number": [
            {
              "value1": "={{$json.jours_depuis_derniere_livraison}}",
              "operation": "between",
              "value2": 14,
              "value3": 30
            }
          ]
        }
      }
    },
    {
      "name": "Send Testimonial Request",
      "type": "n8n-nodes-base.emailSend",
      "parameters": {
        "toEmail": "={{$json.email}}",
        "subject": "Comment se passe votre utilisation ?",
        "text": "Bonjour {{$json.prenom}}, cela fait {{$json.jours_depuis_derniere_livraison}} jours que vous utilisez {{$json.nom_produit}}..."
      }
    }
  ]
}
```

Cette configuration vous donne une base solide pour automatiser intelligemment votre relation client ! 🚀
