-- ======================================
-- BASE COEUR v3.0 - INITIALISATION COMPLETE
-- Optimisée pour N8N + Render + MySQL 8.0
-- ======================================

CREATE DATABASE IF NOT EXISTS coeur_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE coeur_db;

-- Table utilisateurs avec suivi modifications
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

-- Table conversations avec JSON pour historique multicanal
CREATE TABLE IF NOT EXISTS conversations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    type_conversation ENUM('WhatsApp', 'Mail', 'Direct') NOT NULL,
    date_conversation DATE NOT NULL,
    messages_json JSON NOT NULL COMMENT 'Messages avec heures et expéditeurs',
    resume_conversation TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_user_date (utilisateur_id, date_conversation),
    INDEX idx_date (date_conversation DESC),
    INDEX idx_type (type_conversation)
);

-- Table commandes avec géolocalisation complète
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
    pays_livraison VARCHAR(50) NOT NULL COMMENT 'France, Guadeloupe, Martinique, Réunion, etc.',
    region_livraison VARCHAR(100),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_date_commande (date_commande DESC),
    INDEX idx_livraison (date_livraison_reelle DESC),
    INDEX idx_pays (pays_livraison),
    INDEX idx_statut (statut_commande),
    INDEX idx_produit (nom_produit)
);

-- Table témoignages avec médias et distinction agent/client
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
    INDEX idx_conversion (utilise_pour_conversion),
    INDEX idx_valide (valide)
);

-- Table problématiques pour segmentation
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

-- Table communications externes pour traçabilité
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
    INDEX idx_type (type_communication),
    INDEX idx_statut (statut_envoi)
);

-- ======================================
-- VUES OPTIMISÉES POUR N8N
-- ======================================

-- Vue client avec analyse durée utilisation
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
    GROUP_CONCAT(DISTINCT cmd.pays_livraison) as pays_commandes,
    SUM(cmd.prix_total) as ca_total,
    AVG(cmd.prix_total) as panier_moyen
FROM utilisateurs u
LEFT JOIN conversations c ON u.id = c.utilisateur_id
LEFT JOIN commandes cmd ON u.id = cmd.utilisateur_id
LEFT JOIN temoignages t ON u.id = t.utilisateur_id
GROUP BY u.id, u.nom, u.prenom, u.email, u.telephone, u.date_creation, u.date_modification;

-- Vue témoignages pour conversion automatique
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
    u.nom as nom_client,
    CASE 
        WHEN t.nom_fichier IS NOT NULL THEN 'Média stocké'
        WHEN t.url_media IS NOT NULL THEN 'Média en ligne'
        ELSE 'Texte seul'
    END as type_contenu,
    CASE
        WHEN t.note_satisfaction = 5 THEN 'Excellent'
        WHEN t.note_satisfaction = 4 THEN 'Très bon'
        WHEN t.note_satisfaction = 3 THEN 'Bon'
        ELSE 'Moyen'
    END as niveau_satisfaction
FROM temoignages t
JOIN utilisateurs u ON t.utilisateur_id = u.id
WHERE t.type_temoignage = 'recu_du_client' 
AND t.valide = TRUE
ORDER BY t.note_satisfaction DESC, t.date_creation DESC;

-- Vue analyse géographique
CREATE OR REPLACE VIEW vue_analyse_geographique AS
SELECT 
    pays_livraison,
    COUNT(DISTINCT utilisateur_id) as nb_clients_uniques,
    COUNT(*) as nb_commandes_total,
    SUM(prix_total) as ca_total,
    AVG(prix_total) as panier_moyen,
    MIN(date_commande) as premiere_commande,
    MAX(date_commande) as derniere_commande
FROM commandes
GROUP BY pays_livraison
ORDER BY ca_total DESC;

-- ======================================
-- DONNÉES DE TEST ENRICHIES
-- ======================================

-- Utilisateurs de test
INSERT IGNORE INTO utilisateurs (nom, prenom, email, telephone) VALUES
('Dupont', 'Marie', 'marie.dupont@email.com', '+33612345678'),
('Martin', 'Jean', 'jean.martin@email.com', '+33687654321'),
('Bernard', 'Sophie', 'sophie.bernard@email.com', '+33698765432'),
('Moutoussamy', 'Céline', 'celine.moutoussamy@email.com', '+590690123456'),
('Lagrange', 'Pierre', 'pierre.lagrange@email.com', '+596696123456'),
('Rodriguez', 'Carmen', 'carmen.rodriguez@email.com', '+262692123456'),
('Leroy', 'Antoine', 'antoine.leroy@email.com', '+33698123456');

-- Problématiques variées
INSERT IGNORE INTO problematiques (utilisateur_id, type_problematique, description) VALUES
(1, 'douleurs_genou', 'Douleurs chroniques au genou droit suite à une blessure sportive'),
(2, 'gestion_stress', 'Stress important au travail, difficultés à décompresser'),
(3, 'mal_dos', 'Lombalgie chronique due à position assise prolongée'),
(4, 'douleurs_cervicales', 'Tensions cervicales fréquentes, maux de tête'),
(5, 'problemes_sommeil', 'Difficultés d''endormissement, sommeil non réparateur'),
(6, 'articulations', 'Douleurs articulaires généralisées'),
(7, 'fatigue_chronique', 'Fatigue persistante, manque d''énergie');

-- Commandes avec progression temporelle réaliste
INSERT IGNORE INTO commandes (utilisateur_id, date_commande, date_livraison_prevue, date_livraison_reelle, nombre_produits, prix_total, type_produit, nom_produit, statut_commande, pays_livraison, region_livraison) VALUES
-- Août 2025
(1, '2025-08-10', '2025-08-15', '2025-08-14', 1, 79.99, 'bien-être', 'eau_hexagonale', 'livree', 'France', 'Île-de-France'),
(2, '2025-08-12', '2025-08-17', '2025-08-16', 2, 159.98, 'bien-être', 'eau_hexagonale', 'livree', 'France', 'Provence-Alpes-Côte d''Azur'),
(4, '2025-08-15', '2025-08-22', '2025-08-20', 1, 89.99, 'bien-être', 'coussin_cervical', 'livree', 'Guadeloupe', 'Basse-Terre'),
-- Septembre 2025
(3, '2025-09-01', '2025-09-06', '2025-09-05', 1, 45.50, 'beauté', 'col_anti_age', 'livree', 'France', 'Occitanie'),
(5, '2025-09-02', '2025-09-09', '2025-09-07', 2, 134.90, 'beauté', 'col_anti_age', 'livree', 'Martinique', 'Fort-de-France'),
(6, '2025-09-03', '2025-09-10', '2025-09-08', 1, 67.80, 'bien-être', 'eau_hexagonale', 'livree', 'Réunion', 'Saint-Denis'),
(7, '2025-09-04', '2025-09-09', NULL, 3, 199.97, 'bien-être', 'pack_detox', 'expediee', 'France', 'Hauts-de-France');

-- Témoignages réalistes avec progression
INSERT IGNORE INTO temoignages (utilisateur_id, produit, type_temoignage, contenu_temoignage, url_media, type_media, date_temoignage, duree_utilisation, note_satisfaction, valide, utilise_pour_conversion) VALUES
-- Témoignages envoyés par agent (pour inspiration)
(1, 'eau_hexagonale', 'envoye_par_agent', 'Regardez le témoignage inspirant de Marie qui a retrouvé sa mobilité !', 'https://example.com/marie-temoignage.mp4', 'video/mp4', '2025-08-05', '2_semaines', 5, TRUE, TRUE),
(2, 'eau_hexagonale', 'envoye_par_agent', 'Jean partage son expérience incroyable contre le stress', 'https://example.com/jean-stress.jpg', 'image/jpeg', '2025-08-10', '1_mois', 4, TRUE, TRUE),

-- Témoignages reçus des clients (authentiques)
(1, 'eau_hexagonale', 'recu_du_client', 'C''est un miracle ! Après 3 semaines d''utilisation, mes douleurs au genou ont diminué de 80%. Je peux enfin remarcher normalement. Merci infiniment !', NULL, NULL, '2025-09-01', '3_semaines', 5, TRUE, FALSE),
(2, 'eau_hexagonale', 'recu_du_client', 'Produit fantastique ! Mon niveau de stress a considérablement baissé. Je dors mieux et je me sens plus serein au quotidien.', NULL, NULL, '2025-09-03', '3_semaines', 4, TRUE, FALSE),
(4, 'coussin_cervical', 'recu_du_client', 'Livraison ultra rapide en Guadeloupe ! Le coussin cervical soulage vraiment mes tensions. Plus de maux de tête depuis 1 semaine.', NULL, NULL, '2025-09-04', '2_semaines', 5, TRUE, FALSE),
(6, 'eau_hexagonale', 'recu_du_client', 'Excellente surprise ! Même à La Réunion, le produit est arrivé en parfait état. Déjà des améliorations notables sur mes articulations.', NULL, NULL, '2025-09-15', '1_semaine', 4, TRUE, FALSE);

-- Conversations détaillées avec historique JSON
INSERT IGNORE INTO conversations (utilisateur_id, type_conversation, date_conversation, messages_json, resume_conversation) VALUES
(1, 'WhatsApp', '2025-09-01', 
 JSON_OBJECT(
   '14:20', JSON_OBJECT('expediteur', 'client', 'message', 'Bonjour ! Je voulais vous faire un retour sur le produit'),
   '14:22', JSON_OBJECT('expediteur', 'agent', 'message', 'Bonjour Marie ! J''ai hâte d''entendre votre retour 😊'),
   '14:25', JSON_OBJECT('expediteur', 'client', 'message', 'C''est absolument incroyable ! Mes douleurs ont presque disparu en 3 semaines'),
   '14:27', JSON_OBJECT('expediteur', 'agent', 'message', 'C''est formidable ! À combien estimeriez-vous l''amélioration ?'),
   '14:30', JSON_OBJECT('expediteur', 'client', 'message', '80% d''amélioration facilement ! Je peux enfin refaire du sport'),
   '14:32', JSON_OBJECT('expediteur', 'agent', 'message', 'Merci pour ce témoignage Marie ! Puis-je le partager pour aider d''autres personnes ?'),
   '14:35', JSON_OBJECT('expediteur', 'client', 'message', 'Bien sûr ! Si ça peut aider d''autres personnes, je suis partante !')
 ), 
 'Témoignage exceptionnel - Cliente très satisfaite - Accord partage témoignage'),

(4, 'WhatsApp', '2025-09-04',
 JSON_OBJECT(
   '11:45', JSON_OBJECT('expediteur', 'client', 'message', 'Salut ! Juste pour dire que j''ai reçu ma commande hier 👍'),
   '11:47', JSON_OBJECT('expediteur', 'agent', 'message', 'Super Céline ! Comment s''est passée la livraison en Guadeloupe ?'),
   '11:50', JSON_OBJECT('expediteur', 'client', 'message', 'Parfait ! Plus rapide que prévu et emballage nickel'),
   '11:52', JSON_OBJECT('expediteur', 'agent', 'message', 'Excellent ! Avez-vous commencé à l''utiliser ?'),
   '11:55', JSON_OBJECT('expediteur', 'client', 'message', 'Oui depuis hier soir. Déjà moins de tensions dans le cou ce matin !'),
   '11:58', JSON_OBJECT('expediteur', 'agent', 'message', 'Génial ! Les premiers effets arrivent souvent rapidement'),
   '12:00', JSON_OBJECT('expediteur', 'client', 'message', 'J''ai hâte de voir l''évolution. Je vous tiens au courant ! 😊')
 ),
 'Suivi livraison DOM-TOM - Client satisfait emballage - Premiers effets positifs'),

(2, 'Mail', '2025-09-03',
 JSON_OBJECT(
   '09:15', JSON_OBJECT('expediteur', 'client', 'message', 'Objet: Retour d''expérience produit eau hexagonale'),
   '09:16', JSON_OBJECT('expediteur', 'client', 'message', 'Bonjour, Je souhaitais vous faire un retour après 3 semaines d''utilisation. Le produit dépasse mes attentes pour la gestion du stress.'),
   '10:30', JSON_OBJECT('expediteur', 'agent', 'message', 'Bonjour Jean, Merci pour votre message ! Pouvez-vous nous en dire plus sur les améliorations constatées ?'),
   '11:45', JSON_OBJECT('expediteur', 'client', 'message', 'Mon sommeil s''est nettement amélioré. Je m''endors plus facilement et me réveille plus reposé. Au travail, je gère mieux la pression.'),
   '14:20', JSON_OBJECT('expediteur', 'agent', 'message', 'C''est formidable Jean ! Quelle note donneriez-vous sur 5 ?'),
   '15:30', JSON_OBJECT('expediteur', 'client', 'message', 'Je dirais 4/5. C''est vraiment efficace, je le recommande sans hésiter.')
 ),
 'Retour mail détaillé - Amélioration stress et sommeil - Note 4/5');

-- Messages de confirmation
SELECT 'Base de données COEUR v3.0 initialisée avec succès !' as message;
SELECT 'Services web Render + N8N configurés' as status;
SELECT CONCAT('Utilisateurs créés: ', COUNT(*)) as users FROM utilisateurs;
SELECT CONCAT('Commandes de test: ', COUNT(*)) as commandes FROM commandes;  
SELECT CONCAT('Témoignages: ', COUNT(*)) as temoignages FROM temoignages;
SELECT CONCAT('Conversations: ', COUNT(*)) as conversations FROM conversations;
