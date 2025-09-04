-- ======================================
-- SCRIPT D'INITIALISATION BASE COEUR - RENDER
-- Compatible avec N8N hébergé sur Render
-- ======================================

-- Sécurité : créer la base si elle n'existe pas
CREATE DATABASE IF NOT EXISTS coeur_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE coeur_db;

-- Table des utilisateurs avec suivi modifications
CREATE TABLE IF NOT EXISTS utilisateurs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telephone VARCHAR(20),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table des conversations avec JSON optimisé
CREATE TABLE IF NOT EXISTS conversations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    type_conversation ENUM('WhatsApp', 'Mail', 'Direct') NOT NULL,
    date_conversation DATE NOT NULL,
    messages_json JSON NOT NULL COMMENT 'Messages de la journée avec heures',
    resume_conversation TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_user_date (utilisateur_id, date_conversation)
);

-- Table des problématiques santé
CREATE TABLE IF NOT EXISTS problematiques (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    type_problematique VARCHAR(100) NOT NULL COMMENT 'stress, sciatique, genou, etc.',
    description TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut ENUM('active', 'resolue', 'en_cours') DEFAULT 'active',
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Table des commandes avec géolocalisation
CREATE TABLE IF NOT EXISTS commandes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    date_commande DATE NOT NULL,
    date_livraison_prevue DATE COMMENT 'Date estimée',
    date_livraison_reelle DATE COMMENT 'Date réelle réception client',
    nombre_produits INT NOT NULL DEFAULT 1,
    prix_total DECIMAL(10,2) NOT NULL,
    type_produit ENUM('beauté', 'bien-être') NOT NULL,
    nom_produit VARCHAR(255) NOT NULL,
    statut_commande ENUM('en_attente', 'expediee', 'livree', 'annulee') DEFAULT 'en_attente',
    pays_livraison VARCHAR(50) NOT NULL COMMENT 'France, Guadeloupe, Martinique, Réunion...',
    region_livraison VARCHAR(100) COMMENT 'Département/région détaillée',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Table des témoignages avec médias
CREATE TABLE IF NOT EXISTS temoignages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    produit VARCHAR(255) NOT NULL,
    type_temoignage ENUM('envoye_par_agent', 'recu_du_client') NOT NULL,
    contenu_temoignage TEXT NOT NULL,
    url_media VARCHAR(500) COMMENT 'URL vers média en ligne',
    fichier_media LONGBLOB COMMENT 'Fichier stocké en base',
    nom_fichier VARCHAR(255) COMMENT 'Nom original fichier',
    type_media VARCHAR(50) COMMENT 'image/jpeg, video/mp4, audio/mp3...',
    date_temoignage DATE NOT NULL,
    duree_utilisation VARCHAR(50) COMMENT '2_semaines, 1_mois...',
    note_satisfaction INT CHECK (note_satisfaction BETWEEN 1 AND 5),
    valide BOOLEAN DEFAULT FALSE COMMENT 'Validé par équipe',
    utilise_pour_conversion BOOLEAN DEFAULT FALSE COMMENT 'Utilisé pour convertir prospects',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Table des communications externes (SAV, partenaires)
CREATE TABLE IF NOT EXISTS communications_externes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    type_communication ENUM('email', 'courrier', 'fax', 'sms') NOT NULL,
    destinataire_principal VARCHAR(255) NOT NULL,
    destinataires_copie TEXT COMMENT 'Emails séparés par point-virgule',
    objet VARCHAR(500),
    contenu TEXT NOT NULL,
    date_envoi TIMESTAMP NOT NULL,
    statut_envoi ENUM('envoye', 'echec', 'en_cours') DEFAULT 'envoye',
    reference_externe VARCHAR(100) COMMENT 'Numéro ticket, référence...',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Index pour performance N8N
CREATE INDEX IF NOT EXISTS idx_conversations_date ON conversations(date_conversation DESC);
CREATE INDEX IF NOT EXISTS idx_commandes_date ON commandes(date_commande DESC);
CREATE INDEX IF NOT EXISTS idx_commandes_livraison ON commandes(date_livraison_reelle DESC);
CREATE INDEX IF NOT EXISTS idx_commandes_pays ON commandes(pays_livraison);
CREATE INDEX IF NOT EXISTS idx_temoignages_type ON temoignages(type_temoignage);
CREATE INDEX IF NOT EXISTS idx_temoignages_produit ON temoignages(produit);
CREATE INDEX IF NOT EXISTS idx_temoignages_conversion ON temoignages(utilise_pour_conversion);
CREATE INDEX IF NOT EXISTS idx_communications_date ON communications_externes(date_envoi DESC);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_modification ON utilisateurs(date_modification DESC);

-- Vue client complète avec durée d'utilisation
CREATE OR REPLACE VIEW vue_client_avec_utilisation AS
SELECT 
    u.id,
    u.nom,
    u.prenom,
    u.email,
    u.telephone,
    u.date_creation,
    u.date_modification,
    COUNT(DISTINCT c.id) as nb_conversations,
    COUNT(DISTINCT cmd.id) as nb_commandes,
    COUNT(DISTINCT t.id) as nb_temoignages,
    MAX(c.date_conversation) as derniere_conversation,
    MAX(cmd.date_commande) as derniere_commande,
    MAX(cmd.date_livraison_reelle) as derniere_livraison,
    DATEDIFF(CURDATE(), MAX(cmd.date_livraison_reelle)) as jours_depuis_derniere_livraison,
    GROUP_CONCAT(DISTINCT cmd.pays_livraison) as pays_commandes
FROM utilisateurs u
LEFT JOIN conversations c ON u.id = c.utilisateur_id
LEFT JOIN commandes cmd ON u.id = cmd.utilisateur_id
LEFT JOIN temoignages t ON u.id = t.utilisateur_id
GROUP BY u.id, u.nom, u.prenom, u.email, u.telephone, u.date_creation, u.date_modification;

-- Vue témoignages pour conversion (utilisés par agent N8N)
CREATE OR REPLACE VIEW vue_temoignages_conversion AS
SELECT 
    t.id,
    t.produit,
    t.contenu_temoignage,
    t.url_media,
    t.type_media,
    t.note_satisfaction,
    t.duree_utilisation,
    u.prenom as prenom_client,
    CASE 
        WHEN t.nom_fichier IS NOT NULL THEN 'Média en base'
        WHEN t.url_media IS NOT NULL THEN 'Média en ligne'
        ELSE 'Texte seul'
    END as type_contenu
FROM temoignages t
JOIN utilisateurs u ON t.utilisateur_id = u.id
WHERE t.type_temoignage = 'recu_du_client' 
AND t.valide = TRUE
ORDER BY t.note_satisfaction DESC, t.date_creation DESC;

-- ======================================
-- DONNÉES DE TEST N8N-READY
-- ======================================

-- Utilisateurs de test
INSERT IGNORE INTO utilisateurs (nom, prenom, email, telephone) VALUES
('Dupont', 'Marie', 'marie.dupont@email.com', '+33612345678'),
('Martin', 'Jean', 'jean.martin@email.com', '+33687654321'),
('Bernard', 'Sophie', 'sophie.bernard@email.com', '+33698765432'),
('Moutoussamy', 'Céline', 'celine.moutoussamy@email.com', '+590690123456'),
('Lagrange', 'Pierre', 'pierre.lagrange@email.com', '+596696123456');

-- Problématiques
INSERT IGNORE INTO problematiques (utilisateur_id, type_problematique, description) VALUES
(1, 'douleurs_genou', 'Douleurs chroniques au genou droit'),
(2, 'gestion_stress', 'Problèmes de stress au travail'),
(3, 'mal_dos', 'Lombalgie chronique'),
(4, 'douleurs_cervicales', 'Tensions cervicales fréquentes'),
(5, 'problemes_sommeil', 'Difficultés d''endormissement');

-- Commandes avec dates et géolocalisation
INSERT IGNORE INTO commandes (id, utilisateur_id, date_commande, date_livraison_prevue, date_livraison_reelle, nombre_produits, prix_total, type_produit, nom_produit, statut_commande, pays_livraison, region_livraison) VALUES
(1, 1, '2025-09-01', '2025-09-05', '2025-09-04', 2, 89.99, 'bien-être', 'eau_hexagonale', 'livree', 'France', 'Île-de-France'),
(2, 2, '2025-08-28', '2025-09-02', '2025-08-31', 1, 45.50, 'beauté', 'col_anti_age', 'livree', 'France', 'Provence-Alpes-Côte d''Azur'),
(3, 4, '2025-08-25', '2025-08-30', '2025-08-29', 1, 67.80, 'bien-être', 'eau_hexagonale', 'livree', 'Guadeloupe', 'Basse-Terre'),
(4, 5, '2025-08-30', '2025-09-05', '2025-09-03', 2, 134.90, 'beauté', 'col_anti_age', 'livree', 'Martinique', 'Fort-de-France');

-- Témoignages avec distinction agent/client
INSERT IGNORE INTO temoignages (id, utilisateur_id, produit, type_temoignage, contenu_temoignage, url_media, type_media, date_temoignage, duree_utilisation, note_satisfaction, valide, utilise_pour_conversion) VALUES
(1, 2, 'eau_hexagonale', 'envoye_par_agent', 'Voici le témoignage de Marie qui a résolu ses douleurs !', 'https://example.com/marie-temoignage.mp4', 'video/mp4', '2025-08-15', '2_semaines', 5, TRUE, TRUE),
(2, 1, 'eau_hexagonale', 'recu_du_client', 'Incroyable ! Mes douleurs ont diminué de 80% en 10 jours !', NULL, NULL, '2025-09-11', '10_jours', 5, TRUE, FALSE),
(3, 4, 'eau_hexagonale', 'recu_du_client', 'Livraison rapide en Guadeloupe et très efficace !', NULL, NULL, '2025-09-05', '1_semaine', 4, TRUE, FALSE);

-- Conversations JSON pour test N8N
INSERT IGNORE INTO conversations (utilisateur_id, type_conversation, date_conversation, messages_json, resume_conversation) VALUES
(1, 'WhatsApp', '2025-09-04', 
 JSON_OBJECT(
   '10:30', JSON_OBJECT('expediteur', 'client', 'message', 'Bonjour, j''ai reçu ma commande !'),
   '10:32', JSON_OBJECT('expediteur', 'agent', 'message', 'Parfait Marie ! Comment vous sentez-vous ?'),
   '10:35', JSON_OBJECT('expediteur', 'client', 'message', 'Déjà une amélioration visible !')
 ), 
 'Suivi post-livraison - Client satisfait'),
(4, 'WhatsApp', '2025-09-03',
 JSON_OBJECT(
   '14:20', JSON_OBJECT('expediteur', 'client', 'message', 'Commande reçue en Guadeloupe !'),
   '14:25', JSON_OBJECT('expediteur', 'agent', 'message', 'Parfait ! Tenez-nous au courant des résultats.')
 ),
 'Confirmation livraison DOM-TOM');

-- Message de confirmation
SELECT 'Base de données COEUR v3.0 initialisée pour Render + N8N !' as message;
SELECT 'Toutes les tables, vues et données de test sont prêtes' as status;
