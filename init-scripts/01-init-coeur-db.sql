-- ======================================
-- BASE COEUR - INITIALISATION RENDER WEB SERVICE
-- Script optimisé pour MySQL accessible via N8N
-- ======================================

CREATE DATABASE IF NOT EXISTS coeur_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE coeur_db;

-- Table utilisateurs avec tracking modifications
CREATE TABLE IF NOT EXISTS utilisateurs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telephone VARCHAR(20),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_modification (date_modification DESC)
);

-- Table conversations avec JSON
CREATE TABLE IF NOT EXISTS conversations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    type_conversation ENUM('WhatsApp', 'Mail', 'Direct') NOT NULL,
    date_conversation DATE NOT NULL,
    messages_json JSON NOT NULL,
    resume_conversation TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_user_date (utilisateur_id, date_conversation),
    INDEX idx_date (date_conversation DESC)
);

-- Table commandes avec géolocalisation et dates
CREATE TABLE IF NOT EXISTS commandes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    date_commande DATE NOT NULL,
    date_livraison_prevue DATE,
    date_livraison_reelle DATE,
    nombre_produits INT NOT NULL DEFAULT 1,
    prix_total DECIMAL(10,2) NOT NULL,
    type_produit ENUM('beauté', 'bien-être') NOT NULL,
    nom_produit VARCHAR(255) NOT NULL,
    statut_commande ENUM('en_attente', 'expediee', 'livree', 'annulee') DEFAULT 'en_attente',
    pays_livraison VARCHAR(50) NOT NULL,
    region_livraison VARCHAR(100),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_date_commande (date_commande DESC),
    INDEX idx_livraison (date_livraison_reelle DESC),
    INDEX idx_pays (pays_livraison),
    INDEX idx_statut (statut_commande)
);

-- Table témoignages avec médias
CREATE TABLE IF NOT EXISTS temoignages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    produit VARCHAR(255) NOT NULL,
    type_temoignage ENUM('envoye_par_agent', 'recu_du_client') NOT NULL,
    contenu_temoignage TEXT NOT NULL,
    url_media VARCHAR(500),
    fichier_media LONGBLOB,
    nom_fichier VARCHAR(255),
    type_media VARCHAR(50),
    date_temoignage DATE NOT NULL,
    duree_utilisation VARCHAR(50),
    note_satisfaction INT CHECK (note_satisfaction BETWEEN 1 AND 5),
    valide BOOLEAN DEFAULT FALSE,
    utilise_pour_conversion BOOLEAN DEFAULT FALSE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_type (type_temoignage),
    INDEX idx_produit (produit),
    INDEX idx_satisfaction (note_satisfaction),
    INDEX idx_conversion (utilise_pour_conversion)
);

-- Table problématiques
CREATE TABLE IF NOT EXISTS problematiques (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    type_problematique VARCHAR(100) NOT NULL,
    description TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut ENUM('active', 'resolue', 'en_cours') DEFAULT 'active',
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_type (type_problematique),
    INDEX idx_statut (statut)
);

-- Table communications externes
CREATE TABLE IF NOT EXISTS communications_externes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    type_communication ENUM('email', 'courrier', 'fax', 'sms') NOT NULL,
    destinataire_principal VARCHAR(255) NOT NULL,
    destinataires_copie TEXT,
    objet VARCHAR(500),
    contenu TEXT NOT NULL,
    date_envoi TIMESTAMP NOT NULL,
    statut_envoi ENUM('envoye', 'echec', 'en_cours') DEFAULT 'envoye',
    reference_externe VARCHAR(100),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_date (date_envoi DESC),
    INDEX idx_type (type_communication)
);

-- Vue client avec durée d'utilisation (optimisée pour N8N)
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
    CASE 
        WHEN MAX(cmd.date_livraison_reelle) IS NOT NULL 
        THEN DATEDIFF(CURDATE(), MAX(cmd.date_livraison_reelle))
        ELSE NULL 
    END as jours_depuis_derniere_livraison,
    GROUP_CONCAT(DISTINCT cmd.pays_livraison) as pays_commandes
FROM utilisateurs u
LEFT JOIN conversations c ON u.id = c.utilisateur_id
LEFT JOIN commandes cmd ON u.id = cmd.utilisateur_id
LEFT JOIN temoignages t ON u.id = t.utilisateur_id
GROUP BY u.id, u.nom, u.prenom, u.email, u.telephone, u.date_creation, u.date_modification;

-- Vue témoignages pour conversion
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
-- DONNÉES DE TEST POUR N8N
-- ======================================

INSERT IGNORE INTO utilisateurs (nom, prenom, email, telephone) VALUES
('Dupont', 'Marie', 'marie.dupont@email.com', '+33612345678'),
('Martin', 'Jean', 'jean.martin@email.com', '+33687654321'),
('Bernard', 'Sophie', 'sophie.bernard@email.com', '+33698765432'),
('Moutoussamy', 'Céline', 'celine.moutoussamy@email.com', '+590690123456'),
('Lagrange', 'Pierre', 'pierre.lagrange@email.com', '+596696123456');

INSERT IGNORE INTO problematiques (utilisateur_id, type_problematique, description) VALUES
(1, 'douleurs_genou', 'Douleurs chroniques au genou droit'),
(2, 'gestion_stress', 'Problèmes de stress au travail'),
(3, 'mal_dos', 'Lombalgie chronique'),
(4, 'douleurs_cervicales', 'Tensions cervicales fréquentes'),
(5, 'problemes_sommeil', 'Difficultés d''endormissement');

INSERT IGNORE INTO commandes (utilisateur_id, date_commande, date_livraison_prevue, date_livraison_reelle, nombre_produits, prix_total, type_produit, nom_produit, statut_commande, pays_livraison, region_livraison) VALUES
(1, '2025-08-15', '2025-08-20', '2025-08-19', 2, 89.99, 'bien-être', 'eau_hexagonale', 'livree', 'France', 'Île-de-France'),
(2, '2025-08-20', '2025-08-25', '2025-08-24', 1, 45.50, 'beauté', 'col_anti_age', 'livree', 'France', 'Provence-Alpes-Côte d''Azur'),
(4, '2025-08-18', '2025-08-23', '2025-08-22', 1, 67.80, 'bien-être', 'eau_hexagonale', 'livree', 'Guadeloupe', 'Basse-Terre'),
(5, '2025-08-25', '2025-08-30', '2025-08-29', 2, 134.90, 'beauté', 'col_anti_age', 'livree', 'Martinique', 'Fort-de-France');

INSERT IGNORE INTO temoignages (utilisateur_id, produit, type_temoignage, contenu_temoignage, url_media, type_media, date_temoignage, duree_utilisation, note_satisfaction, valide, utilise_pour_conversion) VALUES
(2, 'eau_hexagonale', 'envoye_par_agent', 'Voici le témoignage de Marie qui a résolu ses douleurs au genou en 2 semaines !', 'https://example.com/marie-temoignage.mp4', 'video/mp4', '2025-08-10', '2_semaines', 5, TRUE, TRUE),
(1, 'eau_hexagonale', 'recu_du_client', 'Incroyable ! Mes douleurs ont diminué de 80% en 2 semaines seulement !', NULL, NULL, '2025-09-02', '2_semaines', 5, TRUE, FALSE),
(4, 'eau_hexagonale', 'recu_du_client', 'Livraison rapide en Guadeloupe et produit très efficace ! Je recommande.', NULL, NULL, '2025-09-01', '10_jours', 4, TRUE, FALSE);

INSERT IGNORE INTO conversations (utilisateur_id, type_conversation, date_conversation, messages_json, resume_conversation) VALUES
(1, 'WhatsApp', '2025-09-04', 
 JSON_OBJECT(
   '10:30', JSON_OBJECT('expediteur', 'client', 'message', 'Bonjour ! Mes douleurs ont vraiment diminué !'),
   '10:32', JSON_OBJECT('expediteur', 'agent', 'message', 'C''est fantastique Marie ! Depuis combien de temps utilisez-vous le produit ?'),
   '10:35', JSON_OBJECT('expediteur', 'client', 'message', 'Cela fait maintenant 2 semaines et c''est un miracle !')
 ), 
 'Suivi post-utilisation - Cliente très satisfaite des résultats'),
(4, 'WhatsApp', '2025-09-03',
 JSON_OBJECT(
   '14:20', JSON_OBJECT('expediteur', 'client', 'message', 'Hello ! Je voulais vous remercier, le produit est arrivé rapidement en Guadeloupe'),
   '14:25', JSON_OBJECT('expediteur', 'agent', 'message', 'Avec plaisir Céline ! Comment vous sentez-vous après quelques jours d''utilisation ?'),
   '14:30', JSON_OBJECT('expediteur', 'client', 'message', 'Mes tensions cervicales se sont nettement améliorées ! Merci beaucoup.')
 ),
 'Feedback client DOM-TOM - Satisfaction livraison et efficacité produit');

-- Messages de confirmation
SELECT 'Base de données COEUR déployée avec succès sur Render !' as message;
SELECT 'MySQL accessible depuis N8N via service web' as info;
SELECT CONCAT('Utilisateurs créés: ', COUNT(*)) as users FROM utilisateurs;
SELECT CONCAT('Commandes test: ', COUNT(*)) as commandes FROM commandes;
SELECT CONCAT('Témoignages: ', COUNT(*)) as temoignages FROM temoignages;
